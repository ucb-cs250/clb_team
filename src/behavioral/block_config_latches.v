/* 
 * Block of latches for use of SLICEL
 * This exists to make it easier to swap in a custom config of latches
 */
module block_config_latches #(
    parameter ADDR_BITS=4, 
    parameter MEM_SIZE=2**ADDR_BITS,
    parameter PREDEC=0 // useful only for 4-LUT right now
) (
    // IO
    input [ADDR_BITS-1:0] addr, 
    output out,

    // Block Style Configuration
    input clk,
    input comb_set,
    input [MEM_SIZE-1:0] config_in
);

reg [MEM_SIZE-1:0] mem = 0;

generate
    if (PREDEC==1) begin
        wire [3:0] intermediate_out; // 4 muxes -> 1 predecoded mux
        genvar i;
        for (i = 0; i < MEM_SIZE/4; i=i+1)
            mux m4(mem[4*i+3:4*i], intermediate_out[i], addr[1:0]);
        mux_predecoded mp4 (intermediate_out, out, addr[3:2]);
    end
    else begin
        assign out = mem[addr];
    end
endgenerate

// Block Style Configuration Logic
always @(clk) begin
    if (comb_set) begin
        mem = config_in;
    end
end

endmodule

