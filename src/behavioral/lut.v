///////// BASIC LUT /////////
// Assumptions:
//  MEM_SIZE is a multiple of CONFIG_WIDTH 

module lut #(
    parameter INPUTS=4, MEM_SIZE=2**INPUTS
) (
    // IO
    input [INPUTS-1:0] addr, 
    output out,

    // Stream Style Configuration
    input config_clk,
    input config_en,
    input [MEM_SIZE-1:0] config_in
);

block_config_sram #(.ADDR_BITS(INPUTS)) sram0 (
    .addr(addr), 
    .out(out),
    .config_clk(config_clk),
    .config_en(config_en),
    .config_in(config_in)
);

endmodule

