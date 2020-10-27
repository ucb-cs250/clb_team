///////// MEMORY LUT /////////
// Assumptions:
//  MEM_SIZE is a multiple of CONFIG_WIDTH 

module lut_m #(
    parameter INPUTS=4, 
    parameter MEM_SIZE=2**INPUTS
) (
    // IO
    input [INPUTS-1:0] addr, 
    output out,

    // user-write clock
    input clk,

    // Block Style Configuration
    input cclk,
    input cen,
    input [MEM_SIZE-1:0] config_in,

    // Single-bit, single-port Write
    input data_in,
    input write_en,
);

bit_writable_latches #(.ADDR_BITS(INPUTS)) latches0 (
    .addr(addr), 
    .out(out),
    .clk(clk),
    .cclk(cclk),
    .cen(cen),
    .config_in(config_in),
    .data_in(data_in),
    .write_en(write_en),
    .waddr(addr)
);

endmodule

