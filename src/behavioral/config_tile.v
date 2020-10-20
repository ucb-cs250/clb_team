`include "REGISTER.v"
module config_tile #(
  parameter comb_N = 7,
  parameter mem_N = 7
  
) (
  input clk,
  input rst,
  
  input [comb_N-2:0] comb_config,
  input [mem_N-1:0] mem_config,
  
  input set_config,
  input shift_in_hard,
  input shift_in_soft,
  
  input mem_config_en,
  
  output shift_out
);
  
  wire shift_en = set_config ? shift_in_soft : shift_in_hard;
  
  wire [comb_N-1:0] comb_shift_out;
  wire [comb_N-1:0] comb_shift_in = shift_en ? {comb_shift_out[comb_N - 2:0], set_config} : {comb_config, set_config};
  
  REGISTER #(.N(comb_N)) comb_shift (
    .q(comb_shift_out),
    .d(comb_shift_in),
    .clk(clk),
    .rst(rst)
  );
  
  wire mem_clk = !mem_config_en && clk;
  wire [mem_N-1:0] mem_shift_out;
  wire [mem_N-1:0] mem_shift_in = shift_en ? {mem_shift_out[mem_N - 2:0], comb_shift_out[comb_N - 1]} : {mem_config, comb_shift_out[comb_N - 1]};
  
  REGISTER #(.N(mem_N)) mem_shift (
    .q(mem_shift_out),
    .d(mem_shift_in),
    .clk(mem_clk),
    .rst(rst)
  );
  
  wire shift_out_final = mem_config_en ? comb_shift_out[comb_N - 1] : mem_shift_out[mem_N - 1];
  
  assign shift_out = shift_out_final;
  
endmodule
