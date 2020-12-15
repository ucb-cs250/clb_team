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
wire invout;
assign out = ~invout;

generate
    if (PREDEC==1) begin
        wire [3:0] intermediate_out; // 4 muxes -> 1 predecoded mux
        genvar i;
        for (i = 0; i < MEM_SIZE/4; i=i+1) begin
            mux_kareem impl(mem[4*i+3:4*i], intermediate_out[i], addr[1:0]);
            transmission_gate tg(intermediate_out[i], invout, intermediate_use[i]);
            if (i==0)
                assign intermediate_use[i] = ~addr[1] & ~addr[0];
            else if (i==1) 
                assign intermediate_use[i] = ~addr[1] & addr[0];
            else if (i==2) 
                assign intermediate_use[i] = addr[1] & ~addr[0];
            else 
                assign intermediate_use[i] = addr[1] & addr[0];
        end
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

