#include "slicel.h"

SliceTest *test;
double sc_time_stamp() {
    return test->get_time();
}
int main(int argc, char** argv, char** env) {
    test = new SliceTest("slicel_directed", 100);
    test->config_args(argc, argv, env);
    test->initialize();
    SliceDut *dut = test->get_dut();

    dut->reset();

    /* CONFIGURATION */

    /* Configuration option 1: Generated
     test->generate_config(RAND); // Options: RAND, BASIC_S44, BASIC_FRAC, ADDER
     */

    /* Configuration option 2: Semi-manual
     * soft is 0 active-low, and is {lut3_s, lut2_s, lut1_s, lut0_s} (big endian)
     * lmux is {f8_enable, f7_enable} 
     * reg  is the intial values of all registers (big endian)
     *                    lut0 lut1 lut2 lut3  soft   cc   lmux  reg
     test->assemble_config(0x0, 0x0, 0x0, 0x0, 0b0000, 0b0, 0b00, 0x00); 
     */

    /* Configuration option 3: Fully manual
     * the configuration stream is {regs, cc, f8_enable, f7_enable, lut3_s, lut3, lut2_s, lut2, lut1_s, lut1, lut0_s, lut_0}
     * bits:                        2     1   1          1          1       32    1       32    1       32    1       32    */
     int cfg[5] = {0,0,0,0,0};
     // set cfg here
     dut->configure(cfg, 5);
     //*/


    /* INPUTS */
    
    /* Input option 1: Generated
     int lut_inputs; bool carry_in, reg_ce; char ho_addr;
     test->generate_inputs(RAND, lut_inputs, carry_in, reg_ce, ho_addr); // Options: RAND, ADDER;
     dut->input_set(lut_inputs, carry_in, reg_ce, ho_addr);
     */

    /* Input option 2: Manual
     * lut_inputs {lut3, lut2, lut1, lut0} // each is 8 bits
     * carry_in   1 bit
     * reg_ce     1 bit  // (register enable)
     * ho_addr    2 bits // {f8_mux_select, f7_mux_select} */
     dut->input_set(0x0, 0b0, 0b0, 0b11);
     //*/

    // End INPUTS


    /* SIMULATE TIME */ 
    dut->ticktock(); // tick() = posedge, tock() = negedge

    /* OUTPUTS */
    dut->info("out: %x, sync_out: %x, Co: %d\n", 
              dut->get_out(),
              dut->get_sync_out(),
              dut->get_carry_out()
            ); // info, warn are printf that also display time


    return 0;
}

