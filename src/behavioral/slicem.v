// Memory Logic Slice //
// current address mapping:
//             {addr[N-1:N-MUX_LVLS], addr[SXX_BASE+1], {NUM_LUTS*2{addr[3:0]}}}
// Write address is {higher_order_addr, write_lut_select, luts_in} //

module slicem #(
    parameter S_XX_BASE=4, 
    parameter CFG_SIZE=2**S_XX_BASE+1,
    parameter NUM_LUTS = 4, 
    parameter MUX_LVLS = $clog2(NUM_LUTS) // assume NUM_LUTS is a power of 2
) (
    input [2*S_XX_BASE*NUM_LUTS-1:0] luts_in, // [NUM_LUTS-1:0],
    input [MUX_LVLS-1:0] higher_order_addr,
    input [2*CFG_SIZE*NUM_LUTS-1:0] luts_config_in, // [NUM_LUTS-1:0],
    input [MUX_LVLS-1:0] inter_lut_mux_config,
    input config_use_cc,
    input cclk,
    input clk,
    input reg_ce,
    input cen,
    input Ci,
    output Co,

    // Single-bit Write
    input data_in,
    input write_en,
    // Dual-Port Write
    input write_lut_select,
    
    output [2*NUM_LUTS-1:0] out,
    output reg [2*NUM_LUTS-1:0] sync_out
);

wire [2*NUM_LUTS-1:0] luts_out; // [NUM_LUTS-1:0];
wire [NUM_LUTS-1:0] muxes_out;
wire [NUM_LUTS-1:0] muxes_in;
wire [NUM_LUTS-1:0] cc_p;
wire [NUM_LUTS-1:0] cc_g;
wire [NUM_LUTS-1:0] cc_s;
wire [NUM_LUTS-1:0] one_hot_wen;
assign one_hot_wen = 1'b1 << higher_order_addr;

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
        lut_sXX_m #(.INPUTS(S_XX_BASE)) lut (
            .addr(luts_in[2*S_XX_BASE*(i+1)-1:2*S_XX_BASE*i]),
            .out(luts_out[2*i+1:2*i]),
            .clk(clk),
            .cclk(cclk),
            .cen(cen),
            .config_in(luts_config_in[2*CFG_SIZE*(i+1)-1:2*CFG_SIZE*i]),
            .data_in(data_in),
            .write_en(write_en & one_hot_wen[i]),
            .write_lut_select(write_lut_select)
        );

        assign cc_p[i] = luts_out[2*i];
        assign cc_g[i] = luts_out[2*i+1];
        assign muxes_in = luts_out[2*i];
        assign out[2*i+1:2*i] = use_cc ? 
                        {luts_out[2*i+1], cc_s[i]} :
                        {luts_out[2*i+1], muxes_out[i]};
        // Registers capture main LUT outputs
        always @(posedge clk) begin
            if (reg_ce) begin
                sync_out[2*i+1:2*i] <= luts_out[2*i+1:2*i];
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
    .luts_out(muxes_in),
    .addr(higher_order_addr),
    .out(muxes_out),
    .cclk(cclk),
    .cen(cen),
    .config_in(inter_lut_mux_config)
);


endmodule
