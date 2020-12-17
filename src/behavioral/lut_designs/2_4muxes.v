///////// LUT with two layers of 4-muxes /////////
// Assumptions:
// This is a 4-LUT only.

module lut #(
    parameter INPUTS=4, 
    parameter MEM_SIZE=2**INPUTS
) (
    // IO
    input [INPUTS-1:0] addr, 
    output out,

    // Block Style Configuration
    input clk,
    input comb_set,
    input [MEM_SIZE-1:0] config_in
);

reg [MEM_SIZE-1:0] mem = 0;

// Block Style Configuration Logic
always @(clk) begin
    if (comb_set) begin
        mem = config_in;
    end
end

// 4 muxes -> 1 predecoded mux
wire [3:0] intermediate_out; 
sky130_fd_sc_hd__mux4_1 _TECHMAP_MUX4 (
    .X(out),
    .A0(intermediate_out[0]),
    .A1(intermediate_out[1]),
    .A2(intermediate_out[2]),
    .A3(intermediate_out[3]),
    .S0(addr[3]),
    .S1(addr[2])
);
genvar i;
generate
    for (i = 0; i < MEM_SIZE/4; i=i+1) begin
        sky130_fd_sc_hd__mux4_1 _TECHMAP_MUX4 (
            .X(intermediate_out[i]),
            .A0(mem[4*i]),
            .A1(mem[4*i + 1]),
            .A2(mem[4*i + 2]),
            .A3(mem[4*i + 3]),
            .S0(addr[0]),
            .S1(addr[1])
        );
    end
endgenerate

endmodule

