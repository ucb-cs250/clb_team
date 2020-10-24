	// verilator_coverage annotation
	/* 
	 * Block of latches for use of SLICEL
	 * This exists to make it easier to swap in a custom config of latches
	 */
	module block_config_latches #(
	    parameter ADDR_BITS=4, MEM_SIZE=2**ADDR_BITS
	) (
	    // IO
 002038	    input [ADDR_BITS-1:0] addr, 
 000505	    output out,
	
	    // Block Style Configuration
%000004	    input cclk,
%000002	    input cen,
%000017	    input [MEM_SIZE-1:0] config_in
	);
	
%000039	reg [MEM_SIZE-1:0] mem = 0;
	assign out = mem[addr];
	
	// Block Style Configuration Logic
	always @(posedge cclk) begin
%000002	    if (cen) begin
	        mem <= config_in;
	    end
	end
	
	endmodule
	
	
