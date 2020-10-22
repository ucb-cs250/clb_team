module block_config_sram #(
    parameter ADDR_BITS=4, MEM_SIZE=2**ADDR_BITS
) (
    // IO
    input [ADDR_BITS-1:0] addr, 
    output out,

    // Block Style Configuration
    input cclk,
    input cen,
    input [MEM_SIZE-1:0] config_in
);

reg [MEM_SIZE-1:0] mem = 0;
assign out = mem[addr];

// Block Style Configuration Logic
always @(posedge cclk) begin
    if (cen) begin
        mem <= config_in;
    end
end

endmodule

