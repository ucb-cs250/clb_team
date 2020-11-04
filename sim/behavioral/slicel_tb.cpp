#include <string.h>
#include <verilated.h>
#include "Vslicel.h"
#include "luts.h"

#define RST_COUNT 4
#define RAND 0
#define BASIC_S44  1
#define BASIC_FRAC 2
#define ADDER 3

class SliceDut : public luts::Dut<Vslicel> {
    public :
        SliceDut() : Dut() {}
        SliceDut(std::string name, int id) : Dut(name, id) {}

        int configure(int *config, int len) {
            dut->cclk = 0; eval();

            for (int i=0; i<5; ++i) dut->luts_config_in[i] = config[i];
            config[4] &= 0b1111;
            dut->inter_lut_mux_config = config[5] & 0b11;
            dut->config_use_cc        = (config[5] >> 2) & 1;
            //dut->reg_ce               = (config[5] >> 3) & 1;

            dut->cen = 1;
            dut->cclk = 1; eval();
            dut->cclk = 0;
            return 0;
        }
        
        void input_set(int lut_inputs, bool carry_in, bool reg_ce, char ho_addr) {
            dut->luts_in = lut_inputs;
            dut->Ci = carry_in;
            dut->higher_order_addr = ho_addr;
            dut->reg_ce = reg_ce;
        }
        
        int output(bool check, int verbosity, vluint64_t time, int *comb_out, int *reg_out, bool carry_out) {
            int errors = 0;
            dut->eval();
            if (check) {
                if (carry_out != dut->Co) {
                    errors += 1;
                    printf("%s #%d [%ld] : ERROR : carry_out   : expected %x, got %x\n",
                            &name[0], test_id, time, carry_out, dut->Co);
                } else if (verbosity > 200)
                    printf("%s #%d [%ld] :       : carry_out   : expected %x, got %x\n",
                            &name[0], test_id, time, carry_out, dut->Co);
                for (int i=0; i<8; ++i) {
                    if (comb_out[i] != ((dut->out >> i) & 1)) {
                        errors += 1;
                        printf("%s #%d [%ld] : ERROR : comb_out[%d] : expected %x, got %x\n", 
                                &name[0], test_id, time, i, comb_out[i], ((dut->out >> i) & 1));
                    } else if (verbosity > 200)
                        printf("%s #%d [%ld] :       : comb_out[%d] : expected %x, got %x\n", 
                                &name[0], test_id, time, i, comb_out[i], ((dut->out >> i) & 1));
                }
            }
            // reg_out
            ticktock();
            if (check) {
                for (int i=0; i<8; ++i) {
                    if (reg_out[i] != ((dut->sync_out >> i) & 1)) {
                        errors += 1;
                        printf("%s #%d [%ld] : ERROR : reg_out[%d]  : expected %x, got %x\n",
                                &name[0], test_id, time, i, reg_out[i], ((dut->sync_out >> i) & 1));
                    } else if (verbosity > 200)
                        printf("%s #%d [%ld] :       : reg_out[%d]  : expected %x, got %x\n",
                                &name[0], test_id, time, i, reg_out[i], ((dut->sync_out >> i) & 1));
                }
            }
            return errors;
        }
};

class SliceTest : public luts::Test<SliceDut> {
    protected :
        int comb_out[8] = {};
        int reg_out[8]  = {};
        int carry_out   =  0;

        void print_config() {
            int soft, mem, j, k;
            for (int i=0; i<4; ++i) {
                j = i * 33 / 32;
                k = i * 33 % 32;
                mem = (config[j] >> k) | (config[j+1]) << (32 - k);
                soft = (config[j+1] >> k) & 0b1;
                printf("%s #%d [%ld] config : lut[%d] = mem: 0x%x, soft: %x\n", 
                        &name[0], test_id, get_time(), i, mem, soft);
            }
            printf("%s #%d [%ld] config : use_cc: %d, lmuxes: %d\n",
                    &name[0], test_id, get_time(), config[5] >> 2, config[5] & 0b11);
        }

    public : 
        SliceTest(std::string name) : Test(name){}
        SliceTest(std::string name, int test_id) : Test(name, test_id) {}
        
        int test_main(int test_id, int verbosity, int iterations) {
            int errors = 0;
            int lut_inputs; // 4x2x4bits
            bool carry_in;  // 1b
            bool reg_ce;    // 1b
            char ho_addr;   // 2b

            int l_cfg[4] = {};
            int l_cfg_s[4] = {};
            int j, k;

            for (int i=0; i<4; ++i) {
                j = i * 33 / 32;
                k = i * 33 % 32;
                l_cfg[i]   = (config[j] >> k) | (config[j+1]) << (32 - k);
                l_cfg_s[i] = (config[j+1] >> k) & 0b1;
            }

            for (int j=0; j<iterations; ++j) {
                // GENERATE INPUTS 
                generate_inputs(test_id, lut_inputs, carry_in, reg_ce, ho_addr);

                // DUT
                dut->input_set(lut_inputs, carry_in, reg_ce, ho_addr);

                // SIMULATION
                // lut_outputs
                int l_out[8] = {};
                for (int i=0; i<4; ++i) {
                    // upper lut
                    l_out[i*2] = luts::lookup(l_cfg[i] >> 16, (lut_inputs >> (i*8 + 4)) & 0b1111); 
                    
                    // lower_lut
                    if (l_cfg_s[i]) 
                        l_out[i*2 + 1] = luts::lookup(l_cfg[i], (lut_inputs >> (i * 8)) & 0b1111);

                    // s44_lut
                    else
                        l_out[i*2 + 1] = luts::s44_lookup(l_cfg[i], (lut_inputs >> (i * 8)) & 0b11111111);
                }
                
                // carry_chain
                int sums[4] = {};
                int carry[5] = {};
                carry[0] = carry_in;
                for (int i=0; i<4; ++i) {
                    sums[i] = carry[i] ^ l_out[i*2 + 1];
                    carry[i+1] = luts::mux(carry[i], l_out[i], carry[i]);
                }

                // interlut_muxes
                int f7_0, f7_1, f8; // 1 is upper mux
                f7_1 = luts::mux(1 & ho_addr & config[5], l_out[4], l_out[6]);
                f7_0 = luts::mux(1 & ho_addr & config[5], l_out[0], l_out[2]);
                f8   = luts::mux(2 & ho_addr & config[5], f7_0    , f7_1    );
                
                // outputs
                if (reg_ce) for (int i=1; i<8; ++i) reg_out[i] = comb_out[i];
                for (int i=1; i<8; i+=2) comb_out[i] = l_out[i];
                if (config[5] & 0b100) for (int i=0; i<8; i+=2) comb_out[i] = sums[i >> 1];
                else                   for (int i=0; i<8; i+=2) comb_out[i] = l_out[i];
                if (ho_addr & 0b01) comb_out[4] = f7_1;
                if (ho_addr & 0b11) comb_out[0] = f8;
                carry_out = carry[5];

                // CHECKING
                errors += dut->output(j >= RST_COUNT, verbosity, get_time(), comb_out, reg_out, carry_out);
                tfp_dump();

                /*// comb_out
                dut->eval();
                if (!(iterations < RST_COUNT)) {
                    if (carry_out != dut->Co) {
                        errors += 1;
                        printf("%s #%d [%d] : ERROR : carry_out : expected %x, got %x", name, test_id, get_time(), carry_out, dut->Co);
                    } 
                    for (int i=0; i<8; ++i) {
                        if (comb_out[i] != ((dut->out >> i) & 1)) {
                            errors += 1;
                            printf("%s #%d [%d] : ERROR : comb_out  : expected %x, got %x", name, test_id, get_time(), comb_out[i], ((dut->out >> i) & 1));
                        }
                    }
                }
                // reg_out
                dut->ticktock();
                if (!(iterations < RST_COUNT)) {
                    for (int i=0; i<8; ++i) {
                        if (reg_out[i] != ((dut->sync_out >> i) & 1)) {
                            errors += 1;
                            printf("%s #%d [%d] : ERROR : reg_out   : expected %x, got %x", name, test_id, get_time(), reg_out[i], ((dut->sync_out >> i) & 1));
                        }
                    }
                } */
            } // end for 

            return errors;
        }
        
        int generate_config(int mode) {
            if (mode == RAND)
                return rand_config();
            else if (mode == BASIC_S44) 
                return assemble_config(rand(), rand(), rand(), rand(), 0b0000, 0b0, 0b00);
            else if (mode == BASIC_FRAC) 
                return assemble_config(rand(), rand(), rand(), rand(), 0b1111, 0b0, 0b00);
            //else if (mode == 3)         // 3 - ADDER 
            //    return assemble_config(rand(), rand(), rand(), rand(), 0b1111, 0b0, 0b00);
            return 1;
        }

        int rand_config() {
            free(config);
            config_len = 6;
            config = (int*) malloc(sizeof(int) * config_len); 
            for (int i=0; i<4; ++i) config[i] = rand();
            config[4] = rand() & 0b1111;  // soft s44 luts take 33 bits to configure
            config[5] = rand() & 0b111;  // {cc, lmuxes}
            //config[5] = rand() & 0b1111;  // {reg, cc, lmuxes}
            if (config[5] & 0b100) config[5] = 0b100; // lmuxes should not conflict cc enable
            return 0;
        }

        int assemble_config(int lut0, int lut1, int lut2, int lut3, char soft, bool cc, char lmuxes) {
            free(config);
            config_len = 6;
            config = (int*) malloc(sizeof(int) * config_len); 
            config[0] = lut0;
            config[1] = (lut1 << 1) |  (soft & 1)                     ;
            config[2] = (lut2 << 2) | ((soft & 2) << 1) | (lut1 >> 31);
            config[3] = (lut3 << 3) | ((soft & 4) << 2) | (lut2 >> 30);
            config[4] =               ((soft & 8) << 3) | (lut3 >> 29);
            config[5] = (cc << 2) | (lmuxes & 0b11);
            return 0;
        }

        int generate_inputs(int mode, int &lut_inputs, bool &carry_in, bool &reg_ce, char &ho_addr) {
            if (mode == RAND) { 
                lut_inputs = rand();
                carry_in   = rand() & 1;
                reg_ce     = rand() & 1;
                ho_addr    = rand() & 0b11;
            } else if (mode == ADDER) {
                lut_inputs = rand();
                carry_in   = 0;
                reg_ce     = 1;
                ho_addr    = 0;
            }
            return 0;
        }

        /*int configure(int *config, int len) {
            dut->cclk = 0; eval();

            for (int i=0; i<5; ++i) dut->luts_config_in[i] = config[i];
            config[4] &= 0b1111;
            dut->inter_lut_mux_config = config[5] & 0b11;
            dut->config_use_cc        = (config[5] >> 2) & 1;
            //dut->reg_ce               = (config[5] >> 3) & 1;

            dut->cen = 1;
            dut->cclk = 1; eval();
            dut->cclk = 0;
            return 0;
        }*/

};

SliceTest *test;
double sc_time_stamp() {
    return test->get_time();
}

int main(int argc, char** argv, char** env) {
    test = new SliceTest("slicel", ADDER);
    test->config_args(argc, argv, env);
    test->generate_config(BASIC_S44);
    test->run_test(0, 100, 10);
    exit(0);
}

