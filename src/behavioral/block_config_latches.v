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
        wire [MEM_SIZE/4-1:0] intermediate_out;
        wire [MEM_SIZE/4-1:0] intermediate_use; 
        genvar i;
        for (i = 0; i < MEM_SIZE/4; i=i+1) begin
            assign intermediate_out[i] = mem[{addr[ADDR_BITS-1:ADDR_BITS-2], {(ADDR_BITS-2){1'b0}}}];
            transmission_gate tg(intermediate_out[i], out, intermediate_use[i]);
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
        mem <= config_in;
    end
end

endmodule

