///////// GENERIC FRACTURED LUT /////////
// outputs: {N-LUT_OUT,{FRAC_LVL_OUT}} //

module lut_fractured #(
    parameter INPUTS=4, FRACTURING=1, 
    parameter MEM_SIZE=2**INPUTS,
    parameter OUTPUTS=2**(FRACTURING), 
    parameter SUBOUTPUTS=2**(FRACTURING-1)
) (
    input  [INPUTS-1:0] addr,
    output [OUTPUTS-1:0] out,

    // Block Style Configuration
    input cclk,
    input cen,
    input [MEM_SIZE-1:0] config_in
);

wire [SUBOUTPUTS-1:0] upper_out, lower_out;

localparam HALF_MEM_SIZE = MEM_SIZE / 2;

generate
    if (FRACTURING==1) begin
        lut #(
            .INPUTS(INPUTS-1)
        ) upper_lut (
            .addr(addr[INPUTS-2:0]),
            .out(upper_out),
            .cclk(cclk),
            .cen(cen),
            .config_in(config_in[MEM_SIZE-1:HALF_MEM_SIZE])
        );

        lut #(
            .INPUTS(INPUTS-1)
        ) lower_lut (
            .addr(addr[INPUTS-2:0]),
            .out(lower_out),
            .cclk(cclk),
            .cen(cen),
            .config_in(config_in[HALF_MEM_SIZE-1:0])
        );
        assign out = {addr[INPUTS-1] ? upper_out[SUBOUTPUTS-1] : 
                                       lower_out[SUBOUTPUTS-1], 
                upper_out, lower_out};
    end else begin
        lut_fractured #(
            .INPUTS(INPUTS-1),
            .FRACTURING(FRACTURING-1)
        ) upper_lut (
            .addr(addr[INPUTS-2:0]),
            .out(upper_out),
            .cclk(cclk),
            .cen(cen),
            .config_in(config_in[MEM_SIZE-1:HALF_MEM_SIZE])
        );

        lut_fractured #(
            .INPUTS(INPUTS-1),
            .FRACTURING(FRACTURING-1)
        ) lower_lut (
            .addr(addr[INPUTS-2:0]),
            .out(lower_out),
            .cclk(cclk),
            .cen(cen[HALF_MEM_SIZE-1:0])
        );

        assign out = {addr[INPUTS-1] ? upper_out[SUBOUTPUTS-1] : 
                                       lower_out[SUBOUTPUTS-1], 
                upper_out[SUBOUTPUTS-2:0], lower_out[SUBOUTPUTS-2:0]};
    end
endgenerate

endmodule

