	// verilator_coverage annotation
	///////// HARDCODED SXX LUT /////////
	
	module lut_sXX_hardcode #(
	    parameter INPUTS=4, MEM_SIZE=2**INPUTS
	) (
 001785	    input [INPUTS*2-2:0] addr,
 000252	    output out,
	
	    // Block Style Configuration
%000002	    input cclk,
%000001	    input cen,
%000017	    input [2*MEM_SIZE-1:0] config_in
	);
	
 000253	wire intermediate;
	
	lut #(.INPUTS(INPUTS)) first_lut (
	    .addr(addr[INPUTS*2-2:INPUTS-1]),
	    .out(intermediate),
	    .cclk(cclk),
	    .cen(cen),
	    .config_in(config_in[2*MEM_SIZE-1:MEM_SIZE])
	);
	
	lut #(.INPUTS(INPUTS)) second_lut (
	    .addr({intermediate, addr[INPUTS-2:0]}),
	    .out(out),
	    .cclk(cclk),
	    .cen(cen),
	    .config_in(config_in[MEM_SIZE-1:0])
	);
	endmodule
	
	
