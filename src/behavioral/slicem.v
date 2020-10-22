// Memory Logic Slice //

// TODO: support muxing of LUT outputs
// like MUX7 and MUX8

module slicem #(
    parameter S_XX_BASE=4, CFG_SIZE=2**S_XX_BASE+1,
    parameter NUM_LUTS = 4
) (
    input [2*S_XX_BASE-1:0] luts_in [NUM_LUTS-1:0],
    input [2*CFG_SIZE-1:0] luts_config_in [NUM_LUTS-1:0],
    input config_use_cc,
    input cclk,
    input clk,
    input reg_ce,
    input cen,
    input Ci,
    // Single-bit Write
    input data_in,
    input write_en,
    // Dual-Port Write
    input [NUM_LUTS-1:0] write_lut_select,
    output Co,
    output [1:0] out [NUM_LUTS-1:0],
    output reg [1:0] sync_out [NUM_LUTS-1:0]
);

wire [1:0] luts_out [NUM_LUTS-1:0];
wire [NUM_LUTS-1:0] cc_p;
wire [NUM_LUTS-1:0] cc_g;
wire [NUM_LUTS-1:0] cc_s;

wire use_cc;
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
            .config_in(luts_config_in[i]),
            .data_in(data_in),
            .write_en(write_en),
            .write_lut_select(write_lut_select)
        );

        cc_p[i] = luts_out[i][1];
        cc_g[i] = luts_out[i][0];

        assign out[i] = use_cc ? 
                        {luts_out[i][1], cc_s[i]} :
                        luts_out[i]; // more config for this?
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


endmodule