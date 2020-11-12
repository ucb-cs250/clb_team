///////// SOFTCODED SXX LUT /////////

module lut_sXX_m #(
    parameter INPUTS=4, 
    parameter MEM_SIZE=2**INPUTS
) (
    input [INPUTS*2-1:0] addr,
    output [1:0] out,

    // user-write clock
    input clk,

    // Block Style Configuration
    // NOTE: MOST SIGNIFICANT BIT OF CFG DETERMINES FRACTURING
    input cclk,
    input cen,
    input [2*MEM_SIZE:0] config_in,

    // Single-bit, single-port Write
    input data_in,
    input write_en,
    input write_lut_select
);

wire second_in;
reg split = 1'b0;
assign second_in = split ? addr[INPUTS] : out[1];

always @(cclk) begin
    if (cen) begin
        split <= config_in[2*MEM_SIZE];
    end
end

lut #(.INPUTS(INPUTS)) first_lut (
    .addr(addr[INPUTS*2-1:INPUTS]),
    .out(out[1]),
    .clk(clk),
    .cclk(cclk),
    .cen(cen),
    .config_in(config_in[2*MEM_SIZE-1:MEM_SIZE]),
    .data_in(data_in),
    .write_en(write_en&write_lut_select)
);

lut #(.INPUTS(INPUTS)) second_lut (
    .addr({second_in, addr[INPUTS-2:0]}),
    .out(out[0]),
    .clk(clk),
    .cclk(cclk),
    .cen(cen),
    .config_in(config_in[MEM_SIZE-1:0]),
    .data_in(data_in),
    .write_en(write_en&(~write_lut_select))
);

endmodule
