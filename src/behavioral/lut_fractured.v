///////// GENERIC FRACTURED LUT /////////

module lut_fractured #(
    parameter INPUTS=4, FRACTURING=1, 
    parameter OUTPUTS=2^(FRACTURING+1)-1, SUBOUTPUTS=2^(FRACTURING)-1,
    parameter CONFIG_WIDTH=8
) (
    input  [INPUTS-1:0] addr,
    output [OUTPUTS-1:0] out,

    // Stream Style Configuration
    input config_clk,
    input config_en,
    input [CONFIG_WIDTH-1:0] config_in,
    output [CONFIG_WIDTH-1:0] config_out
);

wire [SUBOUTPUTS-1:0] upper_out, lower_out;
assign out = {addr[INPUTS-1] ? upper_out[SUBOUTPUTS-1] : lower_out[SUBOUTPUTS-1], upper_out, lower_out};

wire [CONFIG_WIDTH-1:0] config_in2;

generate
    if (FRACTURING==1) begin
        lut #(
            .INPUTS(INPUTS-1),
            .CONFIG_WIDTH(CONFIG_WIDTH)
        ) upper_lut (
            .addr(addr[INPUTS-2:0]),
            .out(upper_out),
            .config_clk(config_clk),
            .config_en(config_en),
            .config_in(config_in),
            .config_out(config_in2)
        );

        lut #(
            .INPUTS(INPUTS-1),
            .CONFIG_WIDTH(CONFIG_WIDTH)
        ) lower_lut (
            .addr(addr[INPUTS-2:0]),
            .out(lower_out),
            .config_clk(config_clk),
            .config_en(config_en),
            .config_in(config_in2),
            .config_out(config_out)
        );
    end else begin
        lut_fractured #(
            .INPUTS(INPUTS-1),
            .FRACTURING(FRACTURING-1),
            .CONFIG_WIDTH(CONFIG_WIDTH)
        ) upper_lut (
            .addr(addr[INPUTS-2:0]),
            .out(upper_out),
            .config_clk(config_clk),
            .config_en(config_en),
            .config_in(config_in),
            .config_out(config_in2)
        );

        lut_fractured #(
            .INPUTS(INPUTS-1),
            .FRACTURING(FRACTURING-1),
            .CONFIG_WIDTH(CONFIG_WIDTH)
        ) lower_lut (
            .addr(addr[INPUTS-2:0]),
            .out(lower_out),
            .config_clk(config_clk),
            .config_en(config_en),
            .config_in(config_in2),
            .config_out(config_out)
        );
    end
endgenerate

endmodule

