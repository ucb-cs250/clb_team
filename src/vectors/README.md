#Description of input vectors

**Formatting for TBs:**
* lut_tb.v
    {{RELOAD}
    {OUTPUTS[NUM_LUTS-1:0]}
    {[LUT_NINPUTS-1:0]INPUT_ADDRS[NUM_LUTS-1:0]}
    {[LUT_MEM_SIZE-1:0]LUT_MEM[NUM_LUTS-1:0]}}

**sanity0:** very simple test for framework and basic LUT.
    * NUM_LUTS: 2
    * NUM_TESTS: 4
    * LUT_NINPUTS: 4
    * CONFIG_WIDTH: 1
    * CLK_PERIOD: 10
    * Description of tests:
        0. Basic access of LUT as memory
        0. XOR of inputs
        0. XOR of inputs (no reload)
        0. Ensure LUTs configured to exact location (only 1 bit on)

