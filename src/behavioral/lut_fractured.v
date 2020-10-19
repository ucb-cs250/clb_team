///////// GENERIC FRACTURED LUT /////////

module lut_fractured #(
    parameter INPUTS=4, FRACTURING=1, MEM_SIZE=2**INPUTS,
    parameter OUTPUTS=2**(FRACTURING), SUBOUTPUTS=2**(FRACTURING-1)
) (
    input  [INPUTS-1:0] addr,
    output [OUTPUTS-1:0] out,

    // Block Style Configuration
    input config_clk,
    input config_en,
    input [MEM_SIZE-1:0] config_in
);

wire [SUBOUTPUTS-1:0] upper_out, lower_out;
assign out = {addr[INPUTS-1] ? upper_out[SUBOUTPUTS-1] : lower_out[SUBOUTPUTS-1], 
                upper_out, lower_out};

localparam HALF_MEM_SIZE = MEM_SIZE / 2;

generate
    if (FRACTURING==1) begin
        lut #(
            .INPUTS(INPUTS-1)
        ) upper_lut (
            .addr(addr[INPUTS-2:0]),
            .out(upper_out),
            .config_clk(config_clk),
            .config_en(config_en),
            .config_in(MEM_SIZE-1:HALF_MEM_SIZE)
        );

        lut #(
            .INPUTS(INPUTS-1)
        ) lower_lut (
            .addr(addr[INPUTS-2:0]),
            .out(lower_out),
            .config_clk(config_clk),
            .config_en(config_en),
            .config_in(HALF_MEM_SIZE-1:0)
        );
    end else begin
        lut_fractured #(
            .INPUTS(INPUTS-1),
            .FRACTURING(FRACTURING-1)
        ) upper_lut (
            .addr(addr[INPUTS-2:0]),
            .out(upper_out),
            .config_clk(config_clk),
            .config_en(config_en),
            .config_in(MEM_SIZE-1:HALF_MEM_SIZE)
        );

        lut_fractured #(
            .INPUTS(INPUTS-1),
            .FRACTURING(FRACTURING-1)
        ) lower_lut (
            .addr(addr[INPUTS-2:0]),
            .out(lower_out),
            .config_clk(config_clk),
            .config_en(HALF_MEM_SIZE-1:0)
        );
    end
endgenerate

endmodule

