#include <verilated.h>
#include "Vslicel.h"
#include "luts.h"
#if VM_TRACE
# include <verilated_vcd_c.h>
#endif

class SliceDut : public Luts::Dut<Vslicel> {
    public :
        SliceDut(Vslicel dut) : Dut(dut) {}

    protected :
        char *lower_config;
}

class SliceTest : public Luts::Test<SliceDut> {
    public : 
        SliceTest(string name) : Test(name){}

        int test_main(int test_id, int verbosity, int iterations) {
            ;
        };

        int configure(int *config, int len) {
            dut->cclk = 0; eval();

            for (int i=0; i<5; ++i) dut->luts_config_in[i] = config[i];
            dut->inter_lut_mux_config = config[5] & 0b11;
            dut->config_use_cc = (config[5] >> 2);

            dut->cen = 1;
            dut->cclk = 1; eval();
            dut->cclk = 0;
            return 0;

    protected :
        // config is {lut0, lut1, lut2, lut3, cc, lmux}

        int rand_config() {
            config_len = 6;
            config = malloc(sizof(int) * config_len); 
            for (int i=0; i<4; ++i) config[i] = rand();
            config[4] = rand() & 0b1111; // soft s44 luts take 33 bits to configure
            config[5] = rand() & 0b111;  // {cc, lmuxes}
        }

        void print_config() {
            int soft, mem, j, k;
            for (int i=0; i<5; ++i) {
                j = i * 33 / 32;
                k = i * 33 % 32;
                mem = (config[j] >> k) | (config[j+1]) << (32 - k);
                soft = (config[j+1] >> k) & 0b1;
                printf("%s Test #%d config : lut[%d] = mem: 0x%x, soft: %x", name, test_id, i, mem, soft);
            }
        }


        // luts_config_in {s44_mode (0 is s44), early_lut, late_lut} x 4 luts
        // inter_lut_mux_config // config bit means to use as an f8/7 (else pass lower input) (cfg & special_input) 
        //                     {use_f8, use_f7 (both are the same)}
        // use_cc // ie use sum

        }

};

lut::test 
double sc_time_stamp() {return test.get_time();}

int main(int argc, char** argv, char** env) {
    ;
    exit(0);
}
