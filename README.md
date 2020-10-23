# clb_team
##SLICEL current design
![SLICEL](resources/slicel.png?raw=true "SLICEL")
##SLICEM address mapping:
To reduce strain on the interconnect, as few wires as possible were added to the SLICEM.
* Highest order bits: The $clog2(NUM_LUTS) highest bits should be tied to the higher_order_addr input.  This is the same bits that are used for the mux7/mux8 analogs.
* Since S44 LUTs are used, we have an 7/8-bit "address" input, there is only 2^5 bits of memory within the LUT.  To address the soft-coded S44 structures without adding complex logic, a bank select was added.  This bank select bit acts as the 5th (for S44 LUTs) bit of the address.
* The lowest bits of the address should simply be the inputs to the LUTs.  The lowest bits of the address must be sent to every bank of every LUT, like `{NUM_LUTS*2{addr[3:0]}}`