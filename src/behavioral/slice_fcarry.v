// Ulta-Fractured Logic Slice //
// Uses Fracturable S_XX LUTs //

// TODO: support muxing of LUT outputs
// like MUX7 and MUX8

module slice_fcarry #(
    parameter S_XX_BASE=4, CFG_SIZE=2**S_XX_BASE+1,
    parameter FRACTURE_LEVEL = 2, 
    parameter OUTPUTS=2**(FRACTURE_LEVEL),
    parameter NUM_LUTS = 4, MUX_LVLS = $clog2(NUM_LUTS) // assume NUM_LUTS is a power of 2
) (
    input [2*S_XX_BASE-1:0] luts_in [NUM_LUTS-1:0],
    input [MUX_LVLS-1:0] higher_order_addr,
    input [2*CFG_SIZE-1:0] luts_config_in [NUM_LUTS-1:0],
    input config_use_cc,
    input [MUX_LVLS-1:0] inter_lut_mux_config,
    input cclk,
    input clk,
    input reg_ce,
    input cen,
    input Ci,
    output Co,
    output [1:0] primary_out [NUM_LUTS-1:0],
    output [OUTPUTS-1:0] carry_chain_out [NUM_LUTS-1:0],
    output reg [1:0] sync_out [NUM_LUTS-1:0]
);

localparam CC_INPUTS=2**(FRACTURE_LEVEL-1);

wire [2*OUTPUTS+1:0] luts_out [NUM_LUTS-1:0];
wire [CC_INPUTS-1:0] cc_p [NUM_LUTS-1:0];
wire [CC_INPUTS-1:0] cc_g [NUM_LUTS-1:0];
wire [CC_INPUTS-1:0] cc_s [NUM_LUTS-1:0];
wire [NUM_LUTS-2:0] f_mux_intermediate;
wire main_luts_out [NUM_LUTS-1:0];
wire secondary_luts_out [NUM_LUTS-1:0];
wire muxes_out [NUM_LUTS-1:0];

reg use_cc;
always @(posedge cclk) begin
    if (cen) begin
        use_cc <= config_use_cc;
    end
end
             

generate
    genvar i;
    genvar j;
    for (i = 0; i < NUM_LUTS; i=i+1) begin
        lut_sXX_frac #(.INPUTS(S_XX_BASE), .FRACTURING(FRACTURE_LEVEL)) (
            .addr(luts_in[i]),
            .out(luts_out[i]),
            .cclk(cclk),
            .cen(cen),
            .config_in(luts_config_in[i])
        );
        for (j = 0; j < OUTPUTS; j = j + 1) begin
            cc_p[i][j] = luts_out[i][2*j];
            cc_g[i][j] = luts_out[i][2*j+1];
        end
        assign main_luts_out[i] = luts_out[i][2*OUTPUTS+1];
        assign secondary_luts_out[i] = luts_out[i][2*OUTPUTS];
        assign primary_out[i] = {muxes_out[i], secondary_luts_out[i]};
        assign carry_chain_out[i] = cc_s[i]; // Do we want to pass on fractured output too/instead?
        // Registers capture main LUT outputs
        always @(posedge clk) begin
            if (reg_ce) begin
                sync_out[i] <= luts_out[i][2*OUTPUTS+1:2*OUTPUTS-1];
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
    .luts_out(muxes_out);
    .addr(higher_order_addr),
    .out(main_luts_out),
    .cclk(cclk),
    .cen(cen),
    .config_in(inter_lut_mux_config)
);

endmodule