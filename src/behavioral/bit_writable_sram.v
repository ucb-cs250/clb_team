module bit_writable_sram #(
    parameter ADDR_BITS=4, MEM_SIZE=2**ADDR_BITS
) (
    // IO
    input [ADDR_BITS-1:0] addr, 
    output out,

    // Block Style Configuration
    input config_clk,
    input config_en,
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
always @(posedge config_clk) begin
    if (config_en) begin
        mem <= config_in;
    end else if (write_en) begin
        mem[waddr] <= data_in;
    end
end

endmodule

