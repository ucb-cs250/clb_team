///////// HARD S44 LUT /////////

module lut_s44 #(
    paramter CONFIG_WIDTH=8
) (
    input addr[6:0],
    output out,

    // Stream Style Configuration
    input config_clk,
    input config_en,
    input [CONFIG_WIDTH-1:0] config_in,
    output [CONFIG_WIDTH-1:0] config_out
)

wire intermediate;
wire [CONFIG_WIDTH-1:0] config_in2;

lut #(.INPUTS(4)) first_lut (
    .addr(addr[6:3]),
    .out(intermediate)
    .config_clk(config_clk),
    .config_en(config_en),
    .config_in(config_in),
    .config_out(config_in2)
);

lut #(.INPUTS(4)) second_lut (
    .addr({intermediate, addr[2:0]}),
    .out(out)
    .config_clk(config_clk),
    .config_en(config_en),
    .config_in(config_in2),
    .config_out(config_out)
);
endmodule

