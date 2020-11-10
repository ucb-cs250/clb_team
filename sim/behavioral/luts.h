#ifndef LUTS_H
#define LUTS_H
// Include Guard

#include <verilated.h>
#include <iostream>
#if VM_TRACE
# include <verilated_vcd_c.h>
#endif

namespace luts {

bool lookup(unsigned int config, char addr) {
    return (config >> addr) & 1;
}
bool s44_lookup(unsigned int config, unsigned char addr) {
    int upper_config = config >> 16;
    int lower_config = config & 0b1111111111111111;
    int upper_addr = (addr >> 4) & 0b1111;              // OLD TB DID 3 HERE 
    int upper_out = lookup(upper_config, upper_addr);
    //printf("(%x->[%x]->%d, %x) ", upper_addr, upper_config, upper_out, addr & 0b111 | (upper_out << 3));
    return lookup(lower_config, (upper_out << 3) | addr & 0b111);
}
int mux(bool select, int _0, int _1) {
    if (select) return _1;
    return _0;
}

template <class D> class Dut {
    // D is a verilated class
    public : 
        Dut() : dut(new D), sim_time(0) {}
        Dut(std::string name, int test_id) : dut(new D), sim_time(0), name(name), test_id(test_id) {
            std::cout << "ID<" << test_id << ">\n";
        }
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
        std::string name;
        int test_id;
};

template <class D> class Test {
    // D is a Dut class
    public :
        Test(std::string name) : name(name), tfp(NULL), test_id(0) {}
        Test(std::string name, int test_id) : name(name), tfp(NULL), test_id(test_id) {
            std::cout << "NAME:: <" << name << ">\n";
            std::cout << "ID  :: <" << test_id << ">\n";
        }

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

        int run_test(int test_id, int verbosity, int iterations) {
            std::cout << name << " Starting Test #" << test_id << "\n";
            std::string dummy;

            // Verilator init
            if (0 && argc && argv && env) {}
            Verilated::debug(0);
            Verilated::randReset(5); // randomly init all registers
            Verilated::commandArgs(argc, argv);

            dut = new D(name, test_id);

            // Trace 
#if VM_TRACE
            const char* flag = Verilated::commandArgsPlusMatch("trace");
            if (flag && 0==strcmp(flag, "+trace")) {
                Verilated::traceEverOn(true);  // Verilator must compute traced signals
                std::cout << "Enabling waves into waves/" << name << ".vcd...\n";
                tfp = new VerilatedVcdC;
                dut->vdut()->trace(tfp, 99);  // Trace 99 levels of hierarchy
                dut->set_tfp(tfp);
                Verilated::mkdir("logs");
                dummy = "waves/" + name + ".vcd";
                tfp->open(&dummy[0]);  // Open the dump file
            }
#endif

            // Reset Dut
            dut->reset();

            // Configure Dut
            std::cout << name << " Test #" << test_id << " Configuring... \n";
            int temp;
            temp = configure(config, config_len);
            printf("finsihed config %ld", get_time());
            if (temp != 0)
                std::cout << name << " Test #" << test_id << " FAILED::Invalid Configuration (" << temp << ")\n";
            else if (verbosity >= 200) print_config();

            // Run Test
            int errors = test_main(test_id, verbosity, iterations);
            std::cout << name << " Test #" << test_id << " Finished\n";
            if (errors == 0)
                std::cout << name << " Test #" << test_id << " PASS\n";
            else
                std::cout << name << " Test #" << test_id << " FAIL " << errors << "/" << iterations << "\n";

            // Cleanup
            if (tfp) tfp->dump(get_time());
            dut->final();
            if (tfp) { tfp->close(); tfp = NULL; }

            // Logs
#if VM_COVERAGE
            Verilated::mkdir("logs");
            dummy = "logs/" + name + "_coverage.dat";
            VerilatedCov::write(&dummy[0]);
#endif

            // Final cleanup
            delete dut; dut = NULL;
            return 1;
        }

        virtual int configure(int *cfg, int cfg_len) {
            return dut->configure(cfg, cfg_len);
        }

    protected : 
        D *dut;
        std::string name;
        VerilatedVcdC *tfp = NULL;
        int test_id;

        int argc;
        char **argv;
        char **env;
        int *config;
        int config_len;
        
        virtual int test_main(int test_id, int verbosity, int iterations) = 0;
        virtual void print_config() {
            for (int i=0; i<config_len; ++i)
                printf("config[%d] = 0x%x\n", i, config[i]);
        }

        void tfp_dump() {
            if (tfp) tfp->dump(get_time());
        }
};

} // end namespace

// End Include Guard
#endif 

