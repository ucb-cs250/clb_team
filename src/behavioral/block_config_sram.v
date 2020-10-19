module block_config_sram #(
    parameter ADDR_BITS=4, MEM_SIZE=2**ADDR_BITS
) (
    // IO
    input [ADDR_BITS-1:0] addr, 
    output out,

    // Stream Style Configuration
    input config_clk,
    input config_en,
    input [MEM_SIZE-1:0] config_in
);

reg [MEM_SIZE-1:0] mem = 0;
assign out = mem[addr];

// Block Style Configuration Logic
always @(posedge config_clk) begin
    if (config_en) begin
        mem <= config_in;
    end
end

endmodule

