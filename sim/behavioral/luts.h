#ifndef LUTS_H
#define LUTS_H
// Include Guard

#include <verilated.h>
#include <string>
#include <format>
#include <iostream>

namespace luts {

bool lookup(unsigned int config, char addr) {
    return (config >> addr) & 1
}
bool s44_lookup(unsigned int config, char addr) {
    int upper_config = config >> 16;
    int lower_config = config & 0b1111111111111111;
    return lookup(lower_config, (lookup(upper_config, addr >> 3) << 3) | addr & 0b111);
}

template <class D> class Dut {
    // D is a verilated class
    public : 
        Dut(D *dut) : dut(dut), sim_time(0) {}
        ~Dut() {delete dut; dut = NULL;}

        void eval() {
            dut->eval();
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
            dut->cclk = 0; eval();
            for (int i=0; i<len; ++i)
                dut->config_in[i] = config[i];
            dut->cen = 1;
            dut->cclk = 1; eval();
            dut->cclk = 0;
            return 0;
        }

        vluint64_t get_time() {
            return sim_time;
        }

        void final() {
            dut->final();
        }

    protected : 
        D *dut;
        vluint64_t sim_time;
};

template <class D> class Test {
    // D is a Dut class
    public :
        Test(string name) : name(name), tfp(NULL) {}

        int config_args(int _argc, char** _argv, char** _env) {
            argc = _argc; argv = _argv; env = _env;
        }

        int set_config(int *_config, int _len) {
            config = _config;
            config_len = _len;
        }

        int get_time() {
            return dut->time();
        }

        int run_test(int test_id, int verbosity, int iterations) {
            cout << name << " Starting Test #" << test_id << "\n";

            // Verilator init
            if (0 && argc && argv && env) {}
            Verilated::debug(0);
            Verilated::randReset(5); // randomly init all registers
            Verilated::commandArgs(argc, argv);

            // Configure Dut
            cout << name << " Test #" << test_id << " Configuring... \n";
            dut = new D{};
            int temp;
            temp = dut->configure(config, config_len);
            if (temp != 0)
                cout << name << " Test #" << test_id << " FAILED::Invalid Configuration (" << temp << ")\n";
            else if (verbosity >= 200) print_config();
            sim_time = 0;

            // Trace 
#if VM_TRACE
            const char* flag = Verilated::commandArgsPlusMatch("trace");
            if (flag && 0==strcmp(flag, "+trace")) {
                Verilated::traceEverOn(true);  // Verilator must compute traced signals
                VL_PRINTF(std::format("Enabling waves into waves/{}.vcd...\n", name));
                tfp = new VerilatedVcdC;
                lut->trace(tfp, 99);  // Trace 99 levels of hierarchy
                Verilated::mkdir("logs");
                tfp->open(std::format("waves/{}.vcd", name));  // Open the dump file
            }
#endif

            // Run Test
            int errors = test_main(test_id, iterations, verbosity);
            cout << name << " Test #" << test_id << " Finished" 
            if (errors == 0)
                cout << name << " Test #" << test_id << " PASS" "\n";
            else
                cout << name << " Test #" << test_id << " FAIL" << errors << "/" << iterations << "\n";

            // Cleanup
            if (tfp) tfp->dump(get_time());
            dut->final();
            if (tfp) { tfp->close(); tfp = NULL; }

            // Logs
#if VM_COVERAGE
            Verilated::mkdir("logs");
            VerilatedCov::write(std::format("logs/{}_coverage.dat", name));
#endif

            // Final cleanup
            delete dut; dut = NULL;
            return 1;
        }

    protected : 
        D *dut;
        string name;
        VerilatedVcdC* tfp = NULL;

        int argc;
        char **argv;
        char **env;
        int *config;
        int config_len;
        
        virtual int test_main(int test_id, int verbosity, int iterations) = 0;
        void print_config() {
            for (int i=0; i<config_len; ++i)
                printf("config[%d] = 0x%x", i, config[i]);
        }
};

} // end namespace

// End Include Guard
#endif 
