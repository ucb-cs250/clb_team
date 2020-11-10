#include <string.h>
#include <bitset>
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
            dut->cclk = 0; ticktock(); //eval();

            for (int i=0; i<5; ++i) {
                dut->luts_config_in[i] = config[i];
                printf("cfg[%d] %x ", i, config[i]);
            }
            config[4] &= 0b1111;
            dut->inter_lut_mux_config = config[5] & 0b11;
            dut->config_use_cc        = (config[5] >> 2) & 1;
            dut->regs_config_in       = config[6];
            //dut->reg_ce               = (config[5] >> 3) & 1;

            dut->cen = 1;
            dut->cclk = 1; ticktock(); //eval();
            dut->cen = 0;
            dut->cclk = 0; ticktock();
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
            //dut->eval();
            ticktock();
            if (check) {
                if (carry_out != dut->Co) {
                    errors += 1;
                    printf("%s #%d [%ld] : ERROR : carry_out   : expected %x, got %x\n",
                            &name[0], test_id, time, carry_out, dut->Co);
                } else if (verbosity >= 300)
                    printf("%s #%d [%ld] :       : carry_out   : expected %x, got %x\n",
                            &name[0], test_id, time, carry_out, dut->Co);
                for (int i=0; i<8; ++i) {
                    if (comb_out[i] != ((dut->out >> i) & 1)) {
                        errors += 1;
                        printf("%s #%d [%ld] : ERROR : comb_out[%d] : expected %x, got %x\n", 
                                &name[0], test_id, time, i, comb_out[i], ((dut->out >> i) & 1));
                    } else if (verbosity >= 300)
                        printf("%s #%d [%ld] :       : comb_out[%d] : expected %x, got %x\n", 
                                &name[0], test_id, time, i, comb_out[i], ((dut->out >> i) & 1));
                }
            //}
            // reg_out
            //ticktock();
            //if (check) {
                for (int i=0; i<8; ++i) {
                    if (reg_out[i] != ((dut->sync_out >> i) & 1)) {
                        errors += 1;
                        printf("%s #%d [%ld] : ERROR : reg_out[%d]  : expected %x, got %x\n",
                                &name[0], test_id, time, i, reg_out[i], ((dut->sync_out >> i) & 1));
                    } else if (verbosity >= 300)
                        printf("%s #%d [%ld] :       : reg_out[%d]  : expected %x, got %x\n",
                                &name[0], test_id, time, i, reg_out[i], ((dut->sync_out >> i) & 1));
                }
            }
            if (verbosity >= 300 && test_id == ADDER) {
                printf("%s #%d [%ld] : CHECK OUTPUTS: SUM: %d%d%d%d%d\n", 
                    &name[0], test_id, get_time(), carry_out, comb_out[3], comb_out[2], comb_out[1], comb_out[0]);
            }
            return errors;
        }
};

class SliceTest : public luts::Test<SliceDut> {
    protected :
        // Config
        int  config_luts[4] = {};
        int  config_soft[4] = {};
        char config_lmuxes  = 0;
        bool config_cc      = 0;
        
        // Internal signals
        int comb_out[8] = {};
        int reg_out[8]  = {};
        int carry_out   =  0;

        void print_config() {
            printf("\n ======================= \n \t CONFIG \n ======================= \n");
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

            // internal configuration
            for (int i=0; i<8; ++i) reg_out[i] = (config[6] >> i) & 1;

            int j, k;
            for (int j=0; j<iterations; ++j) {
                // GENERATE INPUTS 
                generate_inputs(test_id, verbosity, lut_inputs, carry_in, reg_ce, ho_addr);
                if (verbosity >= 400)
                    printf("\t\tlut_in: %x, carry_in %d, ho_addr %x, reg_ce %d\n", lut_inputs, carry_in, ho_addr, reg_ce);

                // DUT
                dut->input_set(lut_inputs, carry_in, reg_ce, ho_addr);

                // SIMULATION
                // lut_outputs
                int l_out[8] = {};
                for (int i=0; i<4; ++i) {
                    // upper lut
                    l_out[i*2 + 1] = luts::lookup(config_luts[i] >> 16, (lut_inputs >> (i*8 + 4)) & 0b1111); 
                    
                    // lower_lut
                    if (config_soft[i]) 
                        l_out[i*2] = luts::lookup(config_luts[i], (lut_inputs >> (i * 8)) & 0b1111);

                    // s44_lut
                    else {
                        l_out[i*2] = luts::s44_lookup(config_luts[i], (lut_inputs >> (i * 8)) & 0b11111111);
                    }
                }
                if (verbosity >= 400)
                    printf("\t\tlut_out: %x %x, %x %x, %x %x, %x %x \n", l_out[0], l_out[1], l_out[2], l_out[3], l_out[4], l_out[5], l_out[6], l_out[7]);
                
                // carry_chain
                int sums[4] = {};
                int carry[5] = {};
                int p, g;
                carry[0] = carry_in;
                for (int i=0; i<4; ++i) {
                    p = l_out[i*2], g = l_out[i*2 + 1];
                    sums[i] = carry[i] ^ p;
                    //carry[i+1] = luts::mux(p, g, carry[i]); // both of these should be valid implementations
                    carry[i+1] = p && carry[i] || g;
                    //printf("p %x, g %x, ci %x, s %x, co %x\n", p, g, carry[i], sums[i], carry[i+1]);
                }

                // interlut_muxes
                int f7_0, f7_1, f8; // 1 is upper mux
                f7_1 = luts::mux(1 & ho_addr & config_lmuxes, l_out[4], l_out[6]);
                f7_0 = luts::mux(1 & ho_addr & config_lmuxes, l_out[0], l_out[2]);
                f8   = luts::mux(2 & ho_addr & config_lmuxes, f7_0    , f7_1    );
                
                // outputs
                if (reg_ce) for (int i=0; i<8; ++i) reg_out[i] = comb_out[i];
                for (int i=1; i<8; i+=2) comb_out[i] = l_out[i];
                if (config_cc) for (int i=0; i<8; i+=2) comb_out[i] = sums[i >> 1];
                else                   for (int i=0; i<8; i+=2) comb_out[i] = l_out[i];
                if (ho_addr & 0b01) comb_out[4] = f7_1;
                if (ho_addr & 0b11) comb_out[0] = f8;
                carry_out = carry[4];


                printf("%s #%d [%ld] : VALUE : comb_out %d%d%d%d%d%d%d%d: reg_out %d%d%d%d%d%d%d%d\n",
                        &name[0], test_id, get_time(), 
                        comb_out[7], comb_out[6], comb_out[5], comb_out[4], comb_out[3], comb_out[2], comb_out[1], comb_out[0],
                        reg_out[7], reg_out[6], reg_out[5], reg_out[4], reg_out[3], reg_out[2], reg_out[1], reg_out[0]);

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
                return assemble_config(rand(), rand(), rand(), rand(), 0b0000, 0b0, 0b00, rand());
            else if (mode == BASIC_FRAC) 
                return assemble_config(rand(), rand(), rand(), rand(), 0b1111, 0b0, 0b00, rand());
            else if (mode == ADDER)         // 3 - ADDER 
                // upper_lut = AND :: 1000 = 8
                // lower_lut = XOR :: 0110 = 6
                // config 00080006 or 88886666
                return assemble_config(0x88886666, 0x88886666, 0x88886666, 0x88886666, 0b1111, 0b1, 0b00, rand());
            return 1;
        }

        int rand_config() {
            return assemble_config(rand(), rand(), rand(), rand(), rand(), rand(), rand(), rand());
        }

        int assemble_config(int lut0, int lut1, int lut2, int lut3, char soft, bool cc, char lmuxes, int regs) {
            free(config);
            config_len = 7;
            config = (int*) malloc(sizeof(int) * config_len); 
            config[0] = lut0;
            config[1] = (lut1 << 1) | (soft & 1)               ;
            config[2] = (lut2 << 2) | (soft & 2) | (lut1 >> 31);
            config[3] = (lut3 << 3) | (soft & 4) | (lut2 >> 30);
            config[4] =               (soft & 8) | (lut3 >> 29);
            config[5] = (cc << 2)   | (lmuxes & 0b11);
            config[6] = regs & 0xFF;
            config_luts[0] = lut0;
            config_luts[1] = lut1;
            config_luts[2] = lut2;
            config_luts[3] = lut3;
            config_soft[0] = soft & 1;
            config_soft[1] = (soft >> 1) & 1;
            config_soft[2] = (soft >> 2) & 1;
            config_soft[3] = (soft >> 3) & 1;
            config_cc     = cc;
            config_lmuxes = lmuxes;
            return 0;
        }

        int generate_inputs(int mode, int verbosity, int &lut_inputs, bool &carry_in, bool &reg_ce, char &ho_addr) {
            if (mode == RAND) { 
                lut_inputs = rand();
                carry_in   = rand() & 1;
                reg_ce     = rand() & 1;
                ho_addr    = rand() & 0b11;
            } else if (mode == ADDER) {
                char a = rand();
                char b = rand();
                //lut_inputs = rand(); // ________ ________ ________ __ab__ab 
                lut_inputs  =  ((a & 1) << 1) | (b & 1);
                lut_inputs |= (((a & 2) << 1) | (b & 2)) << 7;
                lut_inputs |= (((a & 3) << 1) | (b & 3)) << 14;
                lut_inputs |= (((a & 4) << 1) | (b & 4)) << 21;
                if (verbosity >= 300) {
                    std::bitset<4> _a(a);
                    std::bitset<4> _b(b);
                    std::bitset<32> l(lut_inputs);
                    printf("%s #%d [%ld] : GEN INPUTS : A (", //%x) + B (%x) : lut_inputs ", 
                        &name[0], test_id, get_time());
                    std::cout << _a << ") B (" << _b << ") : lut_inputs " << l << "\n";
                }
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

void test_luts() {
    int addrs[] = {0x51, 0x29, 0xF2, 0x7C, 0x1B, 0x76, 0x33, 0x66, 0x31, 0x25};
    for (int i=0; i<10; ++i) {
        printf("%d ", luts::s44_lookup(0x66334873, addrs[i]));
    }
}

int main(int argc, char** argv, char** env) {
    int mode = ADDER;
    test = new SliceTest("slicel", mode);
    test->config_args(argc, argv, env);
    test->generate_config(mode);
    test->run_test(mode, 400, 40);
    exit(0);
}

