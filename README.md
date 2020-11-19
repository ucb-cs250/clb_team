# clb_team
## SLICEL current design:
![SLICEL](resources/slicel.png?raw=true "SLICEL")
## SLICEM address mapping:
To reduce strain on the interconnect, as few wires as possible were added to the SLICEM.
* Highest order bits: The $clog2(NUM_LUTS) highest bits should be tied to the higher_order_addr input.  This is the same bits that are used for the mux7/mux8 analogs.
* Since S44 LUTs are used, we have an 7/8-bit "address" input, there is only 2^5 bits of memory within the LUT.  To address the soft-coded S44 structures without adding complex logic, a bank select was added.  This bank select bit acts as the 5th (for S44 LUTs) bit of the address.
* The lowest bits of the address should simply be the inputs to the LUTs.  The lowest bits of the address must be sent to every bank of every LUT, like `{NUM_LUTS*2{addr[3:0]}}`
## Fractured SLICE info:
* The fractured SLICE allows for a larger carry chain.  A standard 4 S44 LUT SLICE allows a 4-bit carry chain.  To add more carry chain functionality for a small-scale reconfigurable fabric, the carry chain is moved to an earlier stage of the LUT.  Fully fracturing an S44 SLICE (such that the carry chain uses the outputs of 2-LUTs) allows for a 16-bit carry chain.
* The carry chain is returned separately from the standard LUT output.
## Configuration:
luts_config_in {s44_mode (0 is s44), early_lut, late_lut} x 4 luts
inter_lut_mux_config // config bit means to use as an f8/7 (else pass lower input) (cfg & special_input) 
                    {use_f8, use_f7 (both are the same)}
use_cc // ie use sum

## Testbench
The verilator testbenches for the slicel module can be found in `sim/behavioral` and can be run with `make slicel_tb.vcd`. The slicel tests themselves can be found in `sim/behavioral/slicel_tb.ccp`. 
There are two slicel tests `test_slicel_crand` and `test_slicel_directed`.
* `test_slicel_crand(argc, argv, env, mode, seed, configs, iterations, verbosity)` : A constrained random test that runs `configs` independent tests for `iterations` clock cycles.
* `test_slicel_directed(argc, argv, env, mode, seed, iterations, verbosity)` : A constrained random test that runs a single test for `iterations` clock cycles. (Used for debugging once a failing seed has been found).
Options
* `argc, argv, env` : The arguments to the `main` function should be forwarded to verilator.
* `mode` : The style of test to run
  * `RAND` : Fully random configurations and inputs.
  * `BASIC_S44` : Luts are configured in s44 mode with random look up tables. Higher order muxes and carry chain is disabled. Inputs are random. 
  * `BASIC_FRAC` : Luts are configured as two 4-luts with random look up tables. Higher order muxes and carry chain is disabled. Inputs are random. 
  * `ADDER` : The slicel is configured to add 2 4-bit numbers. Inputs are constrained to add two 4-bit numbers per cycle. 
* `seed` : The random seed from which tests are generated. The `crand` test prints the seed for each individual test for use in `directed`.
* `configs` : `crand` only: The number of test to run. Each run has a different configuration.
* `iterations` : How long to run the test for a single configuration. Ie the number of inputs to pass the slicel. 
* `verbosity` : The level of detail of the output when running a test. (`min = 100`, `max = 400`).

## Running Directed Tests
In directed tests, the dut is manually configured and passed inputs, and the outputs can be read directly. This is useful for verifying cross-communication with other blocks.
The basic options when writing a directed test can be found in the basic skeleton/example: `sim/behavioral/slicel_directed.cpp`. 

This can be run from the `sim/behavioral` directory with `make slicel_directed.vcd`

### Configuration
#### Option 1: Generated
To use an automatically generated configuration, use `test->generate_config(mode)`, where mode is as described in #Testbench. 
#### Option 2: Semi-Manual
You can alternatively generate a specific configuration without having to manually construct a bitstream with this option.
    test->assemble_config(lut0, lut1, lut2, lut3, soft, cc, inter_lut_muxes, register_reset) 
The options are
* `lut[0-3]` : A 32-bit truth table for each s44 lut. The highest bit corresponds to the highest bit of the upper 4-lut.
* `soft` : A 4-bit value giving whether a lut is configured as 2 fractured 4-luts or an s44 lut. (0=s44, 1=fractured). The upper bit corresponds to lut3. 
* `cc` : A single bit value giving whether the carry chain should be used to drive slicel outputs. (1=carry_chain enabled)
* `inter_lut_muxes` : A two bit value `{f8_enable, f7_enable}` that determines if the f7 and f8 muxes should be treated as muxes or simply pass their lower input. (0=pass_through, 1=enabled)
* `register_reset`  : An eight bit value giving the reset values of each register. The upper bit corresponds to reg7.
#### Option 3: Fully Manual
Use this option to configure the slicel with a bitstream. The bitstream is given as an argument as an `int cfg[5]` list, where cfg[4] gives the upper bits of the bitstream (and has its upper bits unused).
     int cfg[5] = {0,0,0,0,0};
     // set cfg here
     dut->configure(cfg, 5);
The configuration bitstream is defined as follows. See (Option 2: Semi-Manual) for descriptions of each item and its size.
     {register_reset, cc, f8_enable, f7_enable, lut3_s, lut3, lut2_s, lut2, lut1_s, lut1, lut0_s, lut_0}
Register_reset[7] is MSB.


