`timescale 1ns/1ps

module lut_tb;

    parameter CLK_PERIOD = 10;
    parameter LUT_NINPUTS = 4;
    parameter CONFIG_WIDTH = 1;
    
    
    localparam LUT_MEM_SIZE = 2 ** LUT_NINPUTS;
    localparam HALF_CYCLE = CLK_PERIOD / 2;
    localparam LOADING_CYCLES = LUT_MEM_SIZE / CONFIG_WIDTH;

    // Configure number of LUTs here
    localparam NUM_LUTS = 1


    // tick the clock with period CLK_PERIOD
    reg clk;
    initial clk = 0;
    always #(HALF_CYCLE) clk = ~clk;

    // General testing regs and wires
    reg [31:0] REFout;
    wire [31:0] DUTout;
    reg all_tests_passed = 0;
    reg [CONFIG_WIDTH-1:0] init_cfg_vec;

    // Check LUT output
    task checkOutput; // TODO: change to correct inputs
        input [6:0] opcode;
        input [2:0] funct;
        input add_rshift_type;
        if ( REFout !== DUTout ) begin
            $display("FAIL: Incorrect result for opcode %b, funct: %b, add_rshift_type: %b", opcode, funct, add_rshift_type);
            $display("\tA: 0x%h, B: 0x%h, DUTout: 0x%h, REFout: 0x%h", A, B, DUTout, REFout);
        $finish();
        end
        else begin
            $display("PASS: opcode %b, funct %b, add_rshift_type %b", opcode, funct, add_rshift_type);
            $display("\tA: 0x%h, B: 0x%h, DUTout: 0x%h, REFout: 0x%h", A, B, DUTout, REFout);
        end
    endtask

    // Load LUT/LUTS under testing
    // CFG enable bits must be set before function.
    // Initial LUT must have input init_cfg_vec
    task loadLUTs;
        input [CONFIG_WIDTH-1:0] config_bits [NUM_LUTS*LOADING_CYCLES-1:0];
        integer j;
        begin
            for (j = 0; j < NUM_LUTS*LOADING_CYCLES-1) begin
                init_cfg_vec = config_bits[j];
                @(posedge clk);
            end
        end
    endtask

    // LUT I/O declared here:
    reg [LUT_NINPUTS-1:0] lut_addr [NUM_LUTS-1:0];
    wire lut_out [NUM_LUTS-1:0];
    reg cfg_en [NUM_LUTS-1:0];
    wire [CONFIG_WIDTH-1:0] lut_cfg_chain [NUM_LUTS:0];
    assign lut_cfg_chain[0] = init_cfg_vec;


    // MODULES TO TEST
    genvar k;
    generate
        for (k = 0; k < NUM_LUTS; k = k + 1) begin
            lut #(
                .INPUTS(LUT_NINPUTS), 
                .MEM_SIZE=(LUT_MEM_SIZE), 
                .CONFIG_WIDTH(CONFIG_WIDTH)
            ) DUT (
                .addr(lut_addr[k]),
                .out(lut_out[k]),
                .config_clk(clk),
                .config_en(cfg_en[k]),
                .config_in(lut_cfg_chain[k]),
                .config_out(lut_cfg_chain[k+1])
            );
        end
    endgenerate
   


    // Check for timeout
    // If a test does not return correct value in a given timeout cycle,
    // terminate the testbench
    initial begin
        while (all_tests_passed == 0) begin
            @(posedge clk);
            if (cycle == timeout_cycle) begin
                $display("[Failed] Timeout at [%d] test %s, expected_result = %h, got = %h",
                         current_test_id, current_test_type, current_result, current_output);
                $dumpoff;
                $finish();
            end
        end
    end


    localparam testcases = 4;
    reg [LUT_MEM_SIZE*NUM_LUTS-1:0] testvector [0:testcases-1];
    integer i;

    initial begin
        $dumpfile("LUT_TB0.vcd");
        $dumpvars(0, LUT0);
        $dumpon;
        $readmemb("../tests/lut_tests0.input", testvector);

        for (i = 0;  i < testcases; i = i + 1) begin
            // set lut CFG_EN to high
            cfg_en = {NUM_LUTS{1'b`1}};
            // load config vector
            loadLUTs(testvector[i]);
            // load LUT inputs
            checkOutput();
        end

        all_tests_passed = 1;
        $display("\n\nALL TESTS PASSED!");
        $vcdplusoff;
        $finish();

    end

endmodule