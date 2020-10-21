#include <verilated.h>
#include "Vlut.h"
#if VM_TRACE
# include <verilated_vcd_c.h>
#endif

#define LUT_SIZE 16

VerilatedVcdC* tfp = NULL;
vluint64_t main_time = 0;
double sc_time_stamp() {
    return main_time;  // $time
}

void tick(Vlut_sXX_hardcode* lut) {
    //lut->clk = 1;
    lut->eval();
    main_time++;
    lut->config_clk = 1;
    lut->eval();
    if (tfp) tfp->dump(main_time);
}
void tock(Vlut_sXX_hardcode* lut) {
    //lut->clk = 0;
    lut->eval();
    main_time++;
    lut->config_clk = 0;
    lut->eval();
    if (tfp) tfp->dump(main_time);
}
void ticktock(Vlut_sXX_hardcode* lut) {
    tick(lut);
    tock(lut);
}

class lut_s44 {
    public :
        int lut_size;
        int lut_mask;
        int *upper_config;
        int *lower_config;
        Vlut_sXX_hardcode* lut;

        lut_s44(int size, Vlut_sXX_hardcode* lut) {
            int config = rand();
            lut_size = size;
            lut_mask = 0;
            upper_config = malloc(sizeof(int) * size);
            lower_config = malloc(sizeof(int) * size);
            for (int i=0; i<lut_size; ++i) {
                lut_mask = (lut_mask << 1) | 1;
                upper_config[i] = rand() & 1;
                lower_config[i] = rand() & 1;
            }
        }

        int fetch(int addr) { // 1111 111
            int upper_addr = (addr >> (lut_size-1)) & lut_mask; 
            int lower_addr = (addr & (lut_mask >> 1));
            lower_addr |= (upper_config[upper_addr] << (lut_size - 1));
            return lower_config[lower_addr];
        }

        int configure(Vlut_sXX_hardcode *lut) {
            lut->config_en = config;
            
        }
}

int main(int argc, char** argv, char** env) {
    if (0 && argc && argv && env) {}
    Verilated::debug(0);
    //Verilated::randReset(5); // randomly init all registers
    Verilated::randReset(2); // randomly init all registers
    Verilated::commandArgs(argc, argv);

    Vlut* lut = new Vlut;  

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

    // Reset
    lut->config_clk=0;
    lut->addr = 0;
    lut->eval();

    ticktock(lut);

    // Generate lut configuration
    int lut_data[LUT_SIZE] = {};

    for (int i=0; i<LUT_SIZE; i++)
        lut_data[i] = rand() & 1;

    // Load lut configuration
    int temp;
#if LUT_SIZE > 64
    int k = 0;
    for (int i=0; i<LUT_SIZE; i+=32) {
        temp = 0;
        for (int j=i; j<i+32 and j<LUT_SIZE; j+=1) temp |= lut_data[j] << (j - i);
        lut->config_in[k++] = temp;
    }
#else
    temp = rand();
    lut->config_in = temp;
    for (int i=0; i<LUT_SIZE; ++i) {
        lut_data[i] = (temp & 1);
        temp = temp >> 1;
    }
    VL_PRINTF("din: %x\n", temp);
#endif

    lut->config_en = 1;
    ticktock(lut);
    lut->config_en = 0;
    ticktock(lut);
    lut->eval();

    // Tests
    int addr;
    int errors;

    // Sequential Access
    errors = 0;
    for (int i=0; i<LUT_SIZE; ++i) {
        lut->addr = i;
        ticktock(lut);
        if (lut->out != lut_data[i]) {
            errors += 1;
            printf("Got %d Expected %d\n", lut->out, lut_data[i]);
        }
    }
    if (errors) printf("SEQUENTIAL ACCESS TEST FAILED: %d/200 Errors.\n", errors);
    else printf("SEQUENTIAL ACCESS TEST PASSED!\n");

    // Random Access
    errors = 0;
    for (int i=0; i<200; ++i) {
        addr = rand() % LUT_SIZE;
        lut->addr = addr;
        ticktock(lut);
        if (lut->out != lut_data[addr]) {
            errors += 1;
            printf("At addr: %x: Got %d Expected %d\n", addr, lut->out, lut_data[addr]);
        }
    }
    if (errors) printf("RANDOM ACCESS TEST FAILED: %d/200 Errors.\n", errors);
    else printf("RANDOM ACCESS TEST PASSED!\n");

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
