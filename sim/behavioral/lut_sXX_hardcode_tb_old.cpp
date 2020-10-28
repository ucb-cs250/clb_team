#define DUT Vlut_sXX_hardcode
#define LUT_ASIZE 4
#define LUT_MSIZE 16
#define LUT_FMASK 0b1111111
#define LUT_LMASK 0b1111

#include <verilated.h>
#include "Vlut_sXX_hardcode.h"
#if VM_TRACE
# include <verilated_vcd_c.h>
#endif

VerilatedVcdC* tfp = NULL;
vluint64_t main_time = 0;
double sc_time_stamp() {
    return main_time;  // $time
}

class lut_s44 {
    public :
        int config;
        char *upper_config;
        char *lower_config;
        DUT* lut;
        
        lut_s44(DUT* _lut) {
            int temp;
            temp = config = rand();
            upper_config = (char *) malloc(sizeof(char) * LUT_MSIZE);
            lower_config = (char *) malloc(sizeof(char) * LUT_MSIZE);
            lut = _lut;

            for (int i=0; i<LUT_MSIZE; ++i) {
                lower_config[i] = temp & 1;
                temp = temp >> 1;
            }

            for (int i=0; i<LUT_MSIZE; ++i) {
                upper_config[i] = temp & 1;
                temp = temp >> 1;
            }

        }
        
        int test_lut(int iterations) {
            int addr, data_exp, data_dut, errors = 0;
            lut_configure();
            for (int i=0; i<iterations; ++i) {
                addr = rand() & LUT_FMASK;
                data_exp = fetch(addr);
                data_dut = lut_fetch(addr);
                if (data_exp != data_dut) {
                    ++errors;
                    printf("Errors: Expected %d Got %d\n", data_exp, data_dut);
                }
            }
            if (errors)
                printf("FAILED: %d/%d\n", errors, iterations);
            else
                printf("SUCCESS: TEST PASSED\n");
            return errors;
        }
            
        int fetch(int addr) { // 1111 111
            int upper_addr = (addr >> (LUT_ASIZE-1)) & LUT_LMASK; 
            int lower_addr = (addr & (LUT_LMASK >> 1));
            lower_addr |= (upper_config[upper_addr] << (LUT_ASIZE - 1));
            return lower_config[lower_addr];
        }

        int lut_fetch(int addr) {
            lut->addr = addr;
            lut->eval();
            return lut->out;
        }
        
        void lut_configure() {
            lut->cen = 1;
            lut->config_in = config; 
            ticktock();
            lut->cen = 0;
        }

    private :
        void tick() {
            lut->eval();
            main_time++;
            lut->cclk = 1;
            lut->eval();
            if (tfp) tfp->dump(main_time);
        }
        void tock() {
            lut->eval();
            main_time++;
            lut->cclk = 0;
            lut->eval();
            if (tfp) tfp->dump(main_time);
        }
        void ticktock() {
            tick();
            tock();
        }
};

int main(int argc, char** argv, char** env) {
    if (0 && argc && argv && env) {}
    Verilated::debug(0);
    Verilated::randReset(5); // randomly init all registers
    Verilated::commandArgs(argc, argv);

    DUT* lut = new DUT;  

#if VM_TRACE
    tfp = NULL;
    const char* flag = Verilated::commandArgsPlusMatch("trace");
    if (flag && 0==strcmp(flag, "+trace")) {
        Verilated::traceEverOn(true);  // Verilator must compute traced signals
        VL_PRINTF("Enabling waves into logs/vlt_dump.vcd...\n");
        tfp = new VerilatedVcdC;
        lut->trace(tfp, 99);  // Trace 99 levels of hierarchy
        Verilated::mkdir("logs");
        tfp->open("waves/lut.vcd");  // Open the dump file
    }
#endif

    // Main Test
    lut_s44 test(lut);
    test.test_lut(500);

#if VM_TRACE // Dump trace
    if (tfp) tfp->dump(main_time);
#endif

    lut->final();

#if VM_TRACE // Close trace file
    if (tfp) { tfp->close(); tfp = NULL; }
#endif

#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif

    delete lut; lut = NULL;
    exit(0);
}
