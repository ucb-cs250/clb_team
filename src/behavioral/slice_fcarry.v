// Ulta-Fractured Logic Slice //
// Uses Fracturable S_XX LUTs //

// TODO: support muxing of LUT outputs

module slice_fcarry #(
    parameter S_XX_BASE=4, L_MEM_SIZE=2**S_XX_BASE+1,
    parameter FRACTURE_LEVEL = 2,
    parameter OUTPUTS=2**(FRACTURE_LEVEL),
    parameter NUM_LUTS = 4
) (
    input [2*S_XX_BASE-1:0] luts_in [NUM_LUTS-1:0],
    input [2*L_MEM_SIZE-1:0] luts_config_in [NUM_LUTS-1:0],
    input config_use_cc,
    input config_clk,
    input config_en,
    input Ci,
    output Co,
    output [OUTPUTS-1:0] out [NUM_LUTS-1:0]
);

localparam CC_INPUTS=2**(FRACTURE_LEVEL-1);

wire [2*OUTPUTS+1:0] luts_out [NUM_LUTS-1:0];
wire [CC_INPUTS-1:0] cc_p [NUM_LUTS-1:0];
wire [CC_INPUTS-1:0] cc_g [NUM_LUTS-1:0];
wire [CC_INPUTS-1:0] cc_s [NUM_LUTS-1:0];
             

generate
    genvar i;
    genvar j;
    for (i = 0; i < NUM_LUTS; i=i+1) begin
        lut_sXX_frac #(.INPUTS(S_XX_BASE), .FRACTURING(FRACTURE_LEVEL)) (
            .addr(luts_in[i]),
            .out(luts_out[i]),
            .config_clk(config_clk),
            .config_en(config_en),
            .config_in(luts_config_in[i])
        );
        for (j = 0; j < OUTPUTS; j = j + 1) begin
            cc_p[i][j] = luts_out[i][2*j];
            cc_g[i][j] = luts_out[i][2*j+1];
        end
        assign out[i] = config_use_cc ? 
                        {luts_out[i][2*OUTPUTS+1:2*OUTPUTS-1], cc_s[i]} :
                        luts_out[i];
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
)


endmodule