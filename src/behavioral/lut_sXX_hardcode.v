///////// HARDCODED SXX LUT /////////

module lut_sXX_hardcode #(
    parameter INPUTS=4, 
    parameter MEM_SIZE=2**INPUTS
) (
    input [INPUTS*2-2:0] addr,
    output out,

    // Block Style Configuration
    input cclk,
    input cen,
    input [2*MEM_SIZE-1:0] config_in
);

wire intermediate;

lut #(.INPUTS(INPUTS)) first_lut (
    .addr(addr[INPUTS*2-2:INPUTS-1]),
    .out(intermediate),
    .cclk(cclk),
    .cen(cen),
    .config_in(config_in[2*MEM_SIZE-1:MEM_SIZE])
);

lut #(.INPUTS(INPUTS)) second_lut (
    .addr({intermediate, addr[INPUTS-2:0]}),
    .out(out),
    .cclk(cclk),
    .cen(cen),
    .config_in(config_in[MEM_SIZE-1:0])
);
endmodule

