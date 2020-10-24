	// verilator_coverage annotation
	///////// BASIC LUT /////////
	// Assumptions:
	//  MEM_SIZE is a multiple of CONFIG_WIDTH 
	
	module lut #(
	    parameter INPUTS=4, MEM_SIZE=2**INPUTS
	) (
	    // IO
 002038	    input [INPUTS-1:0] addr, 
 000505	    output out,
	
	    // Block Style Configuration
%000004	    input cclk,
%000002	    input cen,
%000017	    input [MEM_SIZE-1:0] config_in
	);
	
	block_config_latches #(.ADDR_BITS(INPUTS)) latches0 (
	    .addr(addr), 
	    .out(out),
	    .cclk(cclk),
	    .cen(cen),
	    .config_in(config_in)
	);
	
	always @(*) begin
	    $display("[%0t] Model running \n", $time);
	end
	
	endmodule
	
	
