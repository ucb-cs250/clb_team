/* 
 * Block of latches for use of SLICEM
 * This exists to make it easier to swap in a custom config of latches
 */
module bit_writable_latches #(
    parameter ADDR_BITS=4, 
    parameter MEM_SIZE=2**ADDR_BITS
) (
    // IO
    input [ADDR_BITS-1:0] addr, 
    output out,

    // user-write clock
    input clk,

    // Block Style Configuration
    input cclk,
    input cen,
    input [MEM_SIZE-1:0] config_in,

    // Single-bit Write
    input data_in,
    input write_en,
    // Dual-Port Write
    input [ADDR_BITS-1:0] waddr
);

reg [MEM_SIZE-1:0] mem = 0;
assign out = mem[addr];

// Block Style Configuration Logic
always @(cclk) begin
    if (cen) begin
        mem <= config_in;
    end 
end

always @(clk) begin
    if (write_en & (~cen)) begin
        mem[waddr] <= data_in;
    end
end

endmodule

