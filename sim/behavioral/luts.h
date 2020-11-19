#ifndef LUTS_H
#define LUTS_H
// Include Guard

#include <verilated.h>
#include <iostream>
#if VM_TRACE
# include <verilated_vcd_c.h>
#endif

#define BUFFER_SIZE 256

namespace luts {

bool lookup(unsigned int config, char addr) {
    return (config >> addr) & 1;
}
bool s44_lookup(unsigned int config, unsigned char addr) {
    int upper_config = config >> 16;
    int lower_config = config & 0b1111111111111111;
    int upper_addr = (addr >> 4) & 0b1111;              // OLD TB DID 3 HERE 
    int upper_out = lookup(upper_config, upper_addr);
    return lookup(lower_config, (upper_out << 3) | addr & 0b111);
}
int mux(bool select, int _0, int _1) {
    if (select) return _1;
    return _0;
}

class Object {
    protected :
        Object(const char *name, const int test_id, const int verbosity) :
                name(name), test_id(test_id), verbosity(verbosity) {}

        const char *name;
        const int test_id;
        const int verbosity; 

    public :
        virtual vluint64_t get_time() = 0; 

        void info(const char *format, ...) {
            va_list args;
            printf("%s #%x [%ld] : INFO  : ", name, test_id, get_time());
            va_start(args, format); vprintf(format, args); va_end(args);
        }

        void error(const char *format, ...) {
            va_list args;
            printf("%s #%x [%ld] : ERROR : ", name, test_id, get_time());
            va_start(args, format); vprintf(format, args); va_end(args);
        }


        void debug(int threshold, const char *format, ...) {
            if (verbosity < threshold) return;
            va_list args;
            printf("%s #%x [%ld] : DEBUG : ", name, test_id, get_time());
            va_start(args, format); vprintf(format, args); va_end(args);
        }

};

template <class D> class Dut : public Object {
    // D is a verilated class
    public : 
        //Dut() : dut(new D), sim_time(0) {
        //    name = "Unnamed";
        //}
        Dut(const char *name, int test_id, int verbosity) : 
                Object(name, test_id, verbosity), dut(new D), sim_time(0) {}
        ~Dut() {delete dut; dut = NULL;}

        void eval() {
            dut->eval();
            tfp_dump();
        }
        void tick() {
            sim_time += 1;
            dut->clk = 1;
            eval();
        }
        void tock() {
            sim_time += 1;
            dut->clk = 0;
            eval();
        }
        void ticktock() {tick(); tock();}

        int configure(int *config, int len) {
            dut->cclk = 0; 
            eval();
            for (int i=0; i<len; ++i)
                dut->config_in[i] = config[i];
            dut->cen = 1;
            dut->cclk = 1; 
            eval();
            dut->cclk = 0;
            return 0;
        }

        vluint64_t get_time() {
            return sim_time;
        }

        void final() {
            dut->final();
        }

        void reset() {
            sim_time = 0;
        }

        D* vdut() {
            return dut;
        }

        void set_tfp(VerilatedVcdC *_tfp) {
            tfp = _tfp;
        }

        void tfp_dump() {
            if (tfp) tfp->dump(get_time());
        }


    protected : 
        D *dut;
        vluint64_t sim_time;
        VerilatedVcdC *tfp = NULL;
};

template <class D> class Test : public Object {
    // D is a Dut class
    public :
        Test(const char *name) : 
                Object(name, 0, 100), tfp(NULL) {}

        Test(const char *name, int test_id, int verbosity, int seed) : 
                Object(name, test_id, verbosity), tfp(NULL), seed(seed) {srand(seed);}

        void config_args(int _argc, char** _argv, char** _env) {
            argc = _argc; argv = _argv; env = _env;
        }

        int set_config(int *_config, int _len) {
            config = _config;
            config_len = _len;
            return 0;
        }

        vluint64_t get_time() {
            return dut->get_time();
        }

        int initialize() {
            char buffer[BUFFER_SIZE];
            printf("\n ============================        STARTING        ============================ \n");
            printf("TestName: %s\nTestId: %d\nSeed: %d\n", name, test_id, seed);

            // Verilator init
            if (0 && argc && argv && env) {}
            Verilated::debug(0);
            Verilated::randReset(5); // randomly init all registers
            Verilated::commandArgs(argc, argv);

            dut = new D{name, test_id, verbosity}; 

            // Trace 
#if VM_TRACE
            const char* flag = Verilated::commandArgsPlusMatch("trace");
            if (flag && 0==strcmp(flag, "+trace")) {
                Verilated::traceEverOn(true);  // Verilator must compute traced signals
                tfp = new VerilatedVcdC;
                dut->vdut()->trace(tfp, 99);   // Trace 99 levels of hierarchy
                dut->set_tfp(tfp);
                Verilated::mkdir("logs");
                sprintf(buffer, "waves/%s.vcd", name);
                printf("Writing waves to %s...\n", buffer);
                tfp->open(buffer); 
            }
#endif

            // Reset Dut
            dut->reset();
            return 0;
        }

        int run_test(int test_id, int iterations) {
            char buffer[BUFFER_SIZE];
            
            initialize();

            // Configure Dut
            int temp;
            temp = configure(config, config_len);
            if (temp != 0) {
                printf("Configuration Failed. Exiting...\n");
                exit(temp);
            } else if (verbosity >= 100) {
                printf("\n ============================         CONFIG         ============================ \n");
                print_config();
            }

            // Run Test
            printf("\n ============================      RUNNING TEST      ============================ \n");
            int errors = test_main(test_id, iterations);
            printf(" ============================      TEST COMPLETE     ============================ \n");
            if (errors == 0) info("PASS");
            else info("FAILED: %d/%d\n", errors, iterations);

            // Cleanup
            if (tfp) tfp->dump(get_time());
            dut->final();
            if (tfp) { tfp->close(); tfp = NULL; }

            // Logs
#if VM_COVERAGE
            Verilated::mkdir("logs");
            sprintf(buffer, "logs/%s_coverage.dat", name);
            VerilatedCov::write(buffer);
#endif

            // Final cleanup
            delete dut; dut = NULL;
            printf("\n");
            return errors == 0 ? 0 : 1;
        }

        virtual int configure(int *cfg, int cfg_len) {
            return dut->configure(cfg, cfg_len);
        }

    protected : 
        D *dut;
        VerilatedVcdC *tfp = NULL;

        int argc;
        char **argv;
        char **env;
        int *config;
        int config_len;
        int seed;
        
        virtual int test_main(int test_id, int iterations) = 0;
        virtual void print_config() {
            for (int i=0; i<config_len; ++i) info("config[%d] = 0x%x\n", i, config[i]);
        }

        void tfp_dump() {
            if (tfp) tfp->dump(get_time());
        }
};

} // end namespace

// End Include Guard
#endif 

