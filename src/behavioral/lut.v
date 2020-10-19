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
reg [MEM_SIZE-1:0] mem = 0;
assign out = mem[addr];

// Block Style Configuration Logic
always @(posedge config_clk) begin
    if (config_en) begin
        mem <= config_in;
    end
end
endmodule

