///////// LUT with one layer of 4-mux, then transmission gates /////////
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
wire [3:0] intermediate_use;
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
        transmission_gate tg(intermediate_out[i], out, intermediate_use[i]);
        if (i==0)
            assign intermediate_use[i] = ~addr[ADDR_BITS-1] & ~addr[ADDR_BITS-2];
        else if (i==1) 
            assign intermediate_use[i] = ~addr[ADDR_BITS-1] & addr[ADDR_BITS-2];
        else if (i==2) 
            assign intermediate_use[i] = addr[ADDR_BITS-1] & ~addr[ADDR_BITS-2];
        else 
            assign intermediate_use[i] = addr[ADDR_BITS-1] & addr[ADDR_BITS-2];
    end
endgenerate

endmodule

