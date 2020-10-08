///////// CARRY CHAIN /////////

module carry_chain_single (
        input P, G, Ci
        output Co, S
    );

    assign Co = P ? Ci : G;
    assign S  = P ^ Ci;
endmodule

module carry_chain #(
        parameter INPUTS=4
    ) (
        input  [INPUTS-1:0] P,
        input  [INPUTS-1:0] G,
        output [INPUTS-1:0] S
        input  Ci,
        output Co
    );

    wire [INPUTS:0] C;
    assign Co = C[INPUTS]
    assign C[0] = Ci;

    generate 
        genvar i
        for (i = 0; i < INPUTS; i=i+1) begin
            carry_chain_single (
                .P(P[i]),
                .G(G[i]),
                .S(S[i]),
                .Ci(C[i]),
                .Co(C[i+1]),
            )
        end
    endgenerate
endmodule

