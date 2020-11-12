///////// SOFTCODED S_XX LUT /////////
///////// Supports Fracturing ////////
// out: s_xx_chain, s_xx_start, {f_lvl_out}

module lut_sXX_frac #(
    parameter INPUTS=4, 
    parameter FRACTURING=2, 
    parameter MEM_SIZE=2**INPUTS,
    parameter OUTPUTS=2**(FRACTURING), 
    parameter SUBOUTPUTS=2**(FRACTURING-1)
) (
    input [INPUTS*2-1:0] addr,
    output [2*OUTPUTS+1:0] out,

    // Block Style Configuration
    // NOTE: MOST SIGNIFICANT BIT OF CFG DETERMINES FRACTURING
    input cclk,
    input cen,
    input [2*MEM_SIZE:0] config_in
);

wire [SUBOUTPUTS:0] upper_out, lower_out;
assign out = {upper_out[SUBOUTPUTS], lower_out[SUBOUTPUTS], 
              upper_out[SUBOUTPUTS-1:0], lower_out[SUBOUTPUTS-1:0]};
wire second_in;
reg split = 1'b0;
assign second_in = split ? addr[INPUTS] : lower_out[SUBOUTPUTS];

always @(cclk) begin
    if (cen) begin
        split <= config_in[2*MEM_SIZE];
    end
end

lut_fractured #(.INPUTS(INPUTS), .FRACTURING(FRACTURING)) first_lut (
    .addr(addr[INPUTS*2-1:INPUTS]),
    .out(lower_out),
    .cclk(cclk),
    .cen(cen),
    .config_in(config_in[2*MEM_SIZE-1:MEM_SIZE])
);

lut_fractured #(.INPUTS(INPUTS), .FRACTURING(FRACTURING)) second_lut (
    .addr({second_in, addr[INPUTS-2:0]}),
    .out(upper_out),
    .cclk(cclk),
    .cen(cen),
    .config_in(config_in[MEM_SIZE-1:0])
);

endmodule

