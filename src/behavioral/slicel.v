// Standard Logic Slice //

// TODO: support muxing of LUT outputs
// like MUX7 and MUX8

module slicel #(
    parameter S_XX_BASE=4, CFG_SIZE=2**S_XX_BASE+1,
    parameter NUM_LUTS = 4, MUX_LVLS = $clog2(NUM_LUTS) // assume NUM_LUTS is a power of 2
) (
    input [2*S_XX_BASE-1:0] luts_in [NUM_LUTS-1:0],
    input [MUX_LVLS-1:0] higher_order_addr,
    input [2*CFG_SIZE-1:0] luts_config_in [NUM_LUTS-1:0],
    input [MUX_LVLS-1:0] inter_lut_mux_config,
    input config_use_cc,
    input cclk,
    input clk,
    input reg_ce,
    input cen,
    input Ci,
    output Co,
    output [1:0] out [NUM_LUTS-1:0],
    output reg [1:0] sync_out [NUM_LUTS-1:0]
);

wire [1:0] luts_out [NUM_LUTS-1:0];
wire muxes_out [NUM_LUTS-1:0];
wire muxes_in [NUM_LUTS-1:0];
wire [NUM_LUTS-1:0] cc_p;
wire [NUM_LUTS-1:0] cc_g;
wire [NUM_LUTS-1:0] cc_s;

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
        lut_sXX_softcode #(.INPUTS(S_XX_BASE)) (
            .addr(luts_in[i]),
            .out(luts_out[i]),
            .cclk(cclk),
            .cen(cen),
            .config_in(luts_config_in[i])
        );

        cc_p[i] = luts_out[i][0];
        cc_g[i] = luts_out[i][1];
        assign muxes_in = luts_out[i][0]
        assign out[i] = use_cc ? 
                        {luts_out[i][1], cc_s[i]} :
                        {luts_out[i][1], muxes_out[i]};
        // Registers capture main LUT outputs
        always @(posedge clk) begin
            if (reg_ce) begin
                sync_out[i] <= luts_out[i];
            end
        end
    end
endgenerate

// carry chain will utilize outputs of smallest fracture size
// 2**(fraclvl-1) will be the number of propegate/generates
carry_chain #(.INPUTS(NUM_LUTS)) cc (
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
    .luts_out(muxes_in);
    .addr(higher_order_addr),
    .out(muxes_out),
    .cclk(cclk),
    .cen(cen),
    .config_in(inter_lut_mux_config)
);


endmodule