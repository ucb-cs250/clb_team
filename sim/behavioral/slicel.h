#ifndef SLICEL_H
#define SLICEL_H
// Include Guard

#include <verilated.h>
#include "Vslicel.h"
#include <stdio.h>
#include <bitset>
#include "luts.h"

#define RST_COUNT 5
#define RAND 0
#define BASIC_S44  1
#define BASIC_FRAC 2
#define ADDER 3

class SliceDut : public luts::Dut<Vslicel> {
    public :
        SliceDut(const char *name, int id, int verbosity) : Dut(name, id, verbosity) {}
        SliceDut(int verbosity) : Dut("Slicel Dut Standalone", 0, verbosity) {}

        int configure(int *config, int len) {
            //dut->cclk = 0; ticktock(); //eval();
            dut->comb_set = 0;
            dut->mem_set  = 0; 
            ticktock();

            dut->luts_config_in[0] = config[0];
            dut->luts_config_in[1] = config[1];
            dut->luts_config_in[2] = config[2];
            dut->luts_config_in[3] = config[3];
            dut->luts_config_in[4] = config[4] & 0xF;

            dut->inter_lut_mux_config = (config[4] >> 4) & 0b11;
            dut->config_use_cc        = (config[4] >> 6) & 1;
            dut->regs_config_in       = (config[4] >> 7) & 0xFF; 

            dut->comb_set = 1;
            dut->mem_set  = 1; 
            tick();
            //dut->cclk = 1; ticktock(); //eval();
            dut->comb_set = 0;
            dut->mem_set  = 0; 
            tock();
            //dut->cclk = 0; ticktock();
            return 0;
        }
        
        void input_set(int lut_inputs, bool carry_in, bool reg_ce, char ho_addr) {
            dut->luts_in = lut_inputs;
            dut->Ci = carry_in;
            dut->higher_order_addr = ho_addr;
            dut->reg_ce = reg_ce;
        }

        void reset() {
            Dut::reset();
            input_set(0,0,0,0);
        }
        
        int output(bool check, int *comb_out, int *reg_out, bool carry_out) {
            int errors = 0;
            ticktock();
            if (check) {
                // comb_out
                if (carry_out != dut->Co) {
                    errors += 1;
                    error("carry_out   : expected %x, got %x\n", carry_out, dut->Co);
                } else if (verbosity >= 400)
                    info("      : carry_out   : expected %x, got %x\n", carry_out, dut->Co);
                for (int i=0; i<8; ++i) {
                    if (comb_out[i] != ((dut->out >> i) & 1)) {
                        errors += 1;
                        error("comb_out[%d] : expected %x, got %x\n", i, comb_out[i], ((dut->out >> i) & 1));
                    } else if (verbosity >= 400)
                        info("      : comb_out[%d] : expected %x, got %x\n", i, comb_out[i], ((dut->out >> i) & 1));
                }

                // reg_out
                for (int i=0; i<8; ++i) {
                    if (reg_out[i] != ((dut->sync_out >> i) & 1)) {
                        errors += 1;
                        error("reg_out[%d]  : expected %x, got %x\n", i, reg_out[i], ((dut->sync_out >> i) & 1));
                    } else if (verbosity >= 400)
                        info("      : reg_out[%d]  : expected %x, got %x\n", i, reg_out[i], ((dut->sync_out >> i) & 1));
                }
            }
            if (verbosity >= 200 && test_id == ADDER) {
                info("CHECK OUTPUTS: SUM (sim): %d%d%d%d%d, (dut) %d%d%d%d%d\n", 
                    carry_out, comb_out[6], comb_out[4], comb_out[2], comb_out[0], dut->Co, 
                    (dut->out >> 6) & 1, (dut->out >> 4) & 1, (dut->out >> 2) & 1, (dut->out >> 0) & 1);
            }
            return errors;
        }

        int get_out() {return dut->out;}
        int get_sync_out() {return dut->sync_out;}
        int get_carry_out() {return dut->Co;}

}; // END SliceDut

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
            int soft, mem, j, k;
            for (int i=0; i<4; ++i) {
                j = i * 33 / 32;
                k = i * 33 % 32;
                mem = (config[j] >> k) | (config[j+1]) << (32 - k);
                soft = (config[j+1] >> k) & 0b1;
                info("lut[%d] = mem: 0x%x, soft: %x\n", i, mem, soft);
            }
            info("use_cc: %d, lmuxes: %d\n", (config[4] >> 6) & 1, (config[4] >> 4) & 0b11);
            info("regs: %x\n", (config[4] >> 7) & 0xFF);
        }
    
    public : 
        SliceTest(const char *name) : Test(name) {}
        SliceTest(const char *name, int verbosity) : Test(name, 0, verbosity, 0) {}
        SliceTest(const char *name, int test_id, int verbosity, int seed) : Test(name, test_id, verbosity, seed) {}
        
        // Constrained Random
        int test_main(int test_id, int iterations) {
            int errors = 0;
            int lut_inputs; // 4x2x4bits
            bool carry_in;  // 1b
            bool reg_ce;    // 1b
            char ho_addr;   // 2b

            // internal configuration
            for (int i=0; i<8; ++i) reg_out[i] = (config[4] >> (i+7)) & 1;

            int j, k;
            for (int j=0; j<iterations; ++j) {
                // GENERATE INPUTS 
                generate_inputs(test_id, lut_inputs, carry_in, reg_ce, ho_addr);
                if (verbosity >= 300)
                    info("lut_in: 0x%x, carry_in %d, ho_addr %x, reg_ce %d\n", lut_inputs, carry_in, ho_addr, reg_ce);
                if (j==0) reg_ce = 0;

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
                if (verbosity >= 300)
                    info("lut_out: %x%x%x%x%x%x%x%x \n", 
                            l_out[7], l_out[6], l_out[5], l_out[4], l_out[3], l_out[2], l_out[1], l_out[0]);
                
                // carry_chain
                int sums[4] = {};
                int carry[5] = {};
                int p, g;
                carry[0] = carry_in;
                for (int i=0; i<4; ++i) {
                    p = l_out[i*2], g = l_out[i*2 + 1];
                    sums[i] = carry[i] ^ p;
                    carry[i+1] = luts::mux(p, g, carry[i]); // both of these should be valid implementations
                    //carry[i+1] = p && carry[i] || g;
                }
                if (verbosity >= 300)
                    info("carry_chain: sums: %x%x%x%x, carry: %x%x%x%x.%x \n", 
                            sums[3], sums[2], sums[1], sums[0], carry[4], carry[3], carry[2], carry[1], carry[0]);

                // interlut_muxes
                int f7_0, f7_1, f8; // 1 is upper mux
                f7_1 = 1 & ho_addr & config_lmuxes ? l_out[6] : l_out[4]; 
                f7_0 = 1 & ho_addr & config_lmuxes ? l_out[2] : l_out[0]; 
                f8   = 2 & ho_addr & config_lmuxes ? f7_1     : f7_0    ; 
                
                if (verbosity >= 300)
                    info("pre_com: %x%x%x%x%x%x%x%x \n", 
                            comb_out[7], comb_out[6], comb_out[5], comb_out[4], comb_out[3], comb_out[2], comb_out[1], comb_out[0]);
                // outputs
                if (reg_ce) for (int i=0; i<8; ++i) reg_out[i] = comb_out[i];
                for (int i=1; i<8; i+=2) comb_out[i] = l_out[i];
                if (config_cc) for (int i=0; i<8; i+=2) comb_out[i] = sums[i >> 1];
                else           for (int i=0; i<8; i+=2) comb_out[i] = l_out[i];
                if (ho_addr & 0b01 & config_lmuxes) comb_out[4] = f7_1;
                if (ho_addr & 0b11 & config_lmuxes) comb_out[0] = f8;
                carry_out = carry[4];

                if (verbosity >= 300)
                    info("reg_out: %x%x%x%x%x%x%x%x \n", 
                            reg_out[7], reg_out[6], reg_out[5], reg_out[4], reg_out[3], reg_out[2], reg_out[1], reg_out[0]);


                // CHECKING
                errors += dut->output(j >= RST_COUNT, comb_out, reg_out, carry_out);
                tfp_dump();

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
            else if (mode == ADDER)
                return assemble_config(0x88886666, 0x88886666, 0x88886666, 0x88886666, 0b1111, 0b1, 0b00, rand());
            return 1;
        }

        int rand_config() {
            char lmuxes = rand() & 0xFF;
            bool cc = rand() & 1;
            if  (lmuxes & 2) lmuxes |= 1;
            return assemble_config(rand(), rand(), rand(), rand(), cc ? 0b1111 : rand(), cc, cc ? 0 : lmuxes, rand());
        }

        int assemble_config(int lut0, int lut1, int lut2, int lut3, char soft, bool cc, char lmuxes, int regs) {
            // verify config
            if (cc && lmuxes) {
                printf("Carry chain and higher order muxes cannot both be set.\n");
                return 2;
            } else if (!soft && cc) {
                printf("Carry chain and s44 mode luts cannot both be set.\n");
                return 2;
            }
            // assemble config
            free(config);
            config_len = 6;
            config = (int*) malloc(sizeof(int) * config_len); 
            config[0]  = lut0;
            config[1]  = (lut1 << 1) | (soft & 1)               ;
            config[2]  = (lut2 << 2) | (soft & 2) | ((lut1 >> 31) & 1);
            config[3]  = (lut3 << 3) | (soft & 4) | ((lut2 >> 30) & 3);
            config[4]  =               (soft & 8) | ((lut3 >> 29) & 7); // 4 bits
            config[4] |= (((regs & 0xFF) << 3) | (cc << 2) | (lmuxes & 0b11)) << 4;
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

        int generate_inputs(int mode, int &lut_inputs, bool &carry_in, bool &reg_ce, char &ho_addr) {
            if (mode == ADDER) {
                char a = rand();
                char b = rand();
                lut_inputs  =  ((a & 1) << 1) | (b & 1);
                lut_inputs |= (((a & 2) << 1) | (b & 2)) << 7;
                lut_inputs |= (((a & 4) << 1) | (b & 4)) << 14;
                lut_inputs |= (((a & 8) << 1) | (b & 8)) << 21;
                lut_inputs |= lut_inputs << 4;
                if (verbosity >= 200) {
                    std::bitset<4> _a(a);
                    std::bitset<4> _b(b);
                    std::bitset<32> l(lut_inputs);
                    info("GEN INPUTS : A ("); std::cout << _a << ") B (" << _b << ") : lut_inputs " << l << "\n";
                }
                carry_in   = 0;
                reg_ce     = 1;
                ho_addr    = 0;
            } else { 
                lut_inputs = rand();
                carry_in   = rand() & 1;
                reg_ce     = rand() & 1;
                ho_addr    = rand() & 0b11;
            }
            return 0;
        }

        void config_coverage(int &cc, int &m7, int &m8, int *soft) {
            if (config_cc) cc += 1;
            if (config_lmuxes & 1) m7 += 1;
            if (config_lmuxes & 2) m8 += 1;
            if (config_soft[0]) soft[0] += 1;
            if (config_soft[1]) soft[1] += 1;
            if (config_soft[2]) soft[2] += 1;
            if (config_soft[3]) soft[3] += 1;
        }

        SliceDut *get_dut() {
            return dut;
        }

}; // END SliceTest
  
// End Include Guard
#endif 
