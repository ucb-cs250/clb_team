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

