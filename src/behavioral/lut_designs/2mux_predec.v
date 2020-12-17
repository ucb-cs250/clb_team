///////// LUT with one layer of 2-mux, then transmission gates /////////
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
wire [7:0] intermediate_out; 
wire [7:0] intermediate_use;
genvar i;
generate
    for (i = 0; i < MEM_SIZE/2; i=i+1) begin
        sky130_fd_sc_hd__mux2_1 _TECHMAP_MUX2 (
            .X(intermediate_out[i]),
            .A0(mem[2*i]),
            .A1(mem[2*i+1]),
            .S(addr[0])
        );
        transmission_gate tg(intermediate_out[i], out, intermediate_use[i]);
        if (i==0)
            assign intermediate_use[i] = ~addr[3] & ~addr[2] & ~addr[1];
        else if (i==1) 
            assign intermediate_use[i] = ~addr[3] & ~addr[2] & addr[1];
        else if (i==2) 
            assign intermediate_use[i] = ~addr[3] & addr[2] & ~addr[1];
        else if (i == 3)
            assign intermediate_use[i] = ~addr[3] & addr[2] & addr[1];
        else if (i==4)
            assign intermediate_use[i] = addr[3] & ~addr[2] & ~addr[1];
        else if (i==5) 
            assign intermediate_use[i] = addr[3] & ~addr[2] & addr[1];
        else if (i==6) 
            assign intermediate_use[i] = addr[3] & addr[2] & ~addr[1];
        else if (i == 7)
            assign intermediate_use[i] = addr[3] & addr[2] & addr[1];
        
    end
endgenerate

endmodule

