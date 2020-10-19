///////// SOFTCODED SXX LUT /////////

module lut_sXX_softcode #(
    parameter INPUTS=4, MEM_SIZE=2^INPUTS
) (
    input [INPUTS*2-1:0] addr,
    output out,

    // Block Style Configuration
    // NOTE: MOST SIGNIFICANT BIT OF CFG DETERMINES FRACTURING
    input config_clk,
    input config_en,
    input [2*MEM_SIZE:0] config_in
);

wire intermediate;
wire second_in;
reg split = 1'b1;
assign second_in = split ? addr[INPUTS] : intermediate;

always @(posedge config_clk) begin
    if (config_en) begin
        split <= config_in[2*MEM_SIZE];
    end
end

lut #(.INPUTS(INPUTS)) first_lut (
    .addr(addr[INPUTS*2-1:INPUTS]),
    .out(intermediate),
    .config_clk(config_clk),
    .config_en(config_en),
    .config_in(config_in[2*MEM_SIZE-1:MEM_SIZE])
);

lut #(.INPUTS(INPUTS)) second_lut (
    .addr({second_in, addr[INPUTS-2:0]}),
    .out(out),
    .config_clk(config_clk),
    .config_en(config_en),
    .config_in(config_in[MEM_SIZE-1:0])
);

endmodule
