///////// MEMORY LUT /////////
// Assumptions:
//  MEM_SIZE is a multiple of CONFIG_WIDTH 

module lut_m #(
    parameter INPUTS=4, MEM_SIZE=2**INPUTS
) (
    // IO
    input [INPUTS-1:0] addr, 
    output out,

    // Block Style Configuration
    input cclk,
    input cen,
    input [MEM_SIZE-1:0] config_in,

    // Single-bit Write
    input data_in,
    input write_en,
    // Dual-Port Write
    input [INPUTS-1:0] waddr
);

bit_writable_sram #(.ADDR_BITS(INPUTS)) sram0 (
    .addr(addr), 
    .out(out),
    .cclk(cclk),
    .cen(cen),
    .config_in(config_in),
    .data_in(data_in),
    .write_en(write_en)
);

endmodule

