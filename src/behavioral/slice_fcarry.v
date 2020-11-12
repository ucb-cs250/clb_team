// Ulta-Fractured Logic Slice //
// Uses Fracturable S_XX LUTs //

// TODO: support muxing of LUT outputs
// like MUX7 and MUX8

module slice_fcarry #(
    parameter S_XX_BASE=4, 
    parameter CFG_SIZE=2**S_XX_BASE+1,
    parameter FRACTURE_LEVEL = 2, 
    parameter OUTPUTS=2**(FRACTURE_LEVEL),
    parameter NUM_LUTS = 4, MUX_LVLS = $clog2(NUM_LUTS) // assume NUM_LUTS is a power of 2
) (
    input [2*S_XX_BASE*NUM_LUTS-1:0] luts_in, // [NUM_LUTS-1:0],
    input [MUX_LVLS-1:0] higher_order_addr,
    input [2*CFG_SIZE*NUM_LUTS-1:0] luts_config_in, // [NUM_LUTS-1:0],
    input config_use_cc,
    input [MUX_LVLS-1:0] inter_lut_mux_config,
    input cclk,
    input clk,
    input reg_ce,
    input cen,
    input Ci,
    output Co,
    output [NUM_LUTS*2-1:0] primary_out, // [NUM_LUTS-1:0],
    output [OUTPUTS*NUM_LUTS-1:0] carry_chain_out, // [NUM_LUTS-1:0],
    output reg [2*NUM_LUTS-1:0] sync_out // [NUM_LUTS-1:0]
);

localparam CC_INPUTS=2**(FRACTURE_LEVEL-1);

wire [(2*OUTPUTS+2)*NUM_LUTS-1:0] luts_out; // [NUM_LUTS-1:0];
wire [CC_INPUTS*NUM_LUTS-1:0] cc_p; // [NUM_LUTS-1:0];
wire [CC_INPUTS*NUM_LUTS-1:0] cc_g; // [NUM_LUTS-1:0];
wire [CC_INPUTS*NUM_LUTS-1:0] cc_s; // [NUM_LUTS-1:0];
wire [NUM_LUTS-2:0] f_mux_intermediate;
wire [NUM_LUTS-1:0] main_luts_out;
wire [NUM_LUTS-1:0] secondary_luts_out;
wire [NUM_LUTS-1:0] muxes_out;

assign carry_chain_out = cc_s; 

reg use_cc;
always @(cclk) begin
    if (cen) begin
        use_cc <= config_use_cc;
    end
end
             

generate
    genvar i;
    genvar j;
    for (i = 0; i < NUM_LUTS; i=i+1) begin
        lut_sXX_frac #(.INPUTS(S_XX_BASE), .FRACTURING(FRACTURE_LEVEL)) lut (
            .addr(luts_in[2*S_XX_BASE*(i+1)-1:2*S_XX_BASE*i]),
            .out(luts_out[(2*OUTPUTS+2)*(i+1)-1:(2*OUTPUTS+2)*i]),
            .cclk(cclk),
            .cen(cen),
            .config_in(luts_config_in[2*CFG_SIZE*(i+1)-1:2*CFG_SIZE*i])
        );
        for (j = 0; j < OUTPUTS; j = j + 1) begin
            assign cc_p[CC_INPUTS*i+j] = luts_out[(2*OUTPUTS+2)*i+2*j];
            assign cc_g[CC_INPUTS*i+j] = luts_out[(2*OUTPUTS+2)*i+2*j+1];
        end
        assign main_luts_out[i] = luts_out[(2*OUTPUTS+2)*i+2*OUTPUTS+1];
        assign secondary_luts_out[i] = luts_out[(2*OUTPUTS+2)*i+2*OUTPUTS];
        assign primary_out[2*i+1:2*i] = {muxes_out[i], secondary_luts_out[i]};
        // Registers capture main LUT outputs
        always @(posedge clk) begin
            if (reg_ce) begin
                sync_out[2*i+1:2*i] <= luts_out[(2*OUTPUTS+2)*i+2*OUTPUTS+1:(2*OUTPUTS+2)*i+2*OUTPUTS-1];
            end
        end
    end
endgenerate

// carry chain will utilize outputs of smallest fracture size
// 2**(fraclvl-1) will be the number of propegate/generates
carry_chain #(.INPUTS(NUM_LUTS*CC_INPUTS)) cc (
    .P(cc_p),
    .G(cc_g),
    .S(cc_s),
    .Ci(Ci),
    .Co(Co)
);

// MUX the primary S44 outputs, analog to MUX7 and MUX8
mux_f_slice #(
    .NUM_LUTS(NUM_LUTS), .MUX_LEVEL(MUX_LVLS)
) muxes (
    .luts_out(muxes_out),
    .addr(higher_order_addr),
    .out(main_luts_out),
    .cclk(cclk),
    .cen(cen),
    .config_in(inter_lut_mux_config)
);

endmodule
