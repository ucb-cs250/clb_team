//////////////////////////////////////
// BEHAVIORAL MODEL DEFINITIONS
//////////////////////////////////////
/*

///////// BASIC LUT /////////
module lut #(
        parameter INPUTS=4, MEM_SIZE=2^NUM_INPUTS
    ) (
        input [INPUTS-1:0] addr, 
        output out
    )
    reg [MEM_SIZE-1:0] mem = 0;
    assign out = mem[addr];
endmodule

///////// Level 1 FRACTURED LUT /////////
module lut_fractured_1 #(
        parameter INPUTS=4
    ) (
        input [INPUTS-1:0] addr,
        output out, fout[1:0]
    );

    assign out = addr[INPUTS-1] ? fout[1]: fout[0];

    lut #(.INPUTS(INPUTS-1)) upper_lut (
        .addr(addr[INPUTS-2:0]),
        .out(fout[1])
    );

    lut #(.INPUTS(INPUTS-1)) lower_lut (
        .addr(addr[INPUTS-2:0]),
        .out(fout[0])
    );
endmodule

///////// Level 2 FRACTURED LUT /////////
module lut_fractured_2 #(
        parameter INPUTS=4
    ) (
        input [INPUTS-1:0] addr,
        output out, fout[1:0], ffout[3:0]
    );

    assign out = addr[INPUTS-1] ? fout[1]: fout[0];

    lut_fractured_1 #(.INPUTS(INPUTS-1)) upper_lut (
        .addr(addr[INPUTS-2:0]),
        .out(fout[1]),
        .fout(ffout[3:2])
    );

    lut_fractured_1 #(.INPUTS(INPUTS-1)) lower_lut (
        .addr(addr[INPUTS-2:0]),
        .out(fout[0]),
        .fout(ffout[1:0])
    );
endmodule

///////// Generalized FRACTURED LUT /////////
// fracturing = 0: 2^(f+1)-1 = 1 output             [top]                                         [top]
// fracturing = 1: 2^(f+1)-1 = 3 outputs (1 + 2*1)  [top, subh, subl]                             [top, subh, subl]
// fracturing = 2: 2^(f+1)-1 = 7 outputs (1 + 2*3)  [top, subh, subl, subhh, subhl, sublh, subll] [top, subh, subhh, subhl, subl, sublh, subll]
//                                                                                                  heap-like and easier to recursively create
module lut_fractured_g #(
        parameter INPUTS=4, FRACTURING=1. OUTPUTS=2^(FRACTURING+1)-1, SUBOUTPUTS=2^(FRACTURING)-1
    ) (
        input  [INPUTS-1:0] addr,
        output [OUTPUTS-1:0] out,
    );
    
    wire [SUBOUTPUTS-1:0] upper_out, lower_out;
    assign out = {addr[INPUTS-1] ? upper_out[SUBOUTPUTS-1] : lower_out[SUBOUTPUTS-1], 
                  upper_out, lower_out};
    generate
        if (FRACTURING==1) begin
            lut #(
                .INPUTS(INPUTS-1),
            ) upper_lut (
                .addr(addr[INPUTS-2:0]),
                .out(upper_out),
            );
    
            lut #(
                .INPUTS(INPUTS-1),
            ) lower_lut (
                .addr(addr[INPUTS-2:0]),
                .out(lower_out),
            );
        end else begin
            lut_fractured_g #(
                .INPUTS(INPUTS-1),
                .FRACTURING(FRACTURING-1)
            ) upper_lut (
                .addr(addr[INPUTS-2:0]),
                .out(upper_out),
            );
    
            lut_fractured_g #(
                .INPUTS(INPUTS-1),
                .FRACTURING(FRACTURING-1)
            ) lower_lut (
                .addr(addr[INPUTS-2:0]),
                .out(lower_out),
            );
        end
    endgenerate
endmodule

///////// S44 LUT /////////
module lut_s44 (
        input addr[6:0],
        output out
    )
    wire intermediate;
    
    lut #(.INPUTS(4)) first_lut (
        .addr(addr[6:3]),
        .out(intermediate)
    );
    
    lut #(.INPUTS(4)) second_lut (
        .addr({intermediate, addr[2:0]}),
        .out(out)
    );
endmodule

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
*/

