`timescale 1ns/1ps

`include "../behavioral/lut.v"

module lut_tb;

    parameter CLK_PERIOD = 10;
    parameter LUT_NINPUTS = 4;
    parameter NUM_TESTS = 4;
    
    
    localparam LUT_MEM_SIZE = 2 ** LUT_NINPUTS;
    localparam HALF_CYCLE = CLK_PERIOD / 2;
    localparam CFG_SIZE = LUT_MEM_SIZE * NUM_LUTS;

    // Configure number of LUTs here
    localparam NUM_LUTS = 1;
    localparam TIMEOUT = 1000;


    // tick the clock with period CLK_PERIOD
    reg clk;
    initial clk = 0;
    always #(HALF_CYCLE) clk = ~clk;

    // General testing regs and wires
    reg [NUM_LUTS-1:0] REFout;
    wire [NUM_LUTS-1:0] DUTout;
    reg all_tests_passed = 0;
    reg running = 0;
    reg [CONFIG_WIDTH-1:0] init_cfg_vec;
    reg [31:0] current_test_id = 0;

    // Check LUT output
    task checkOutput; // TODO: change to correct inputs
        input [NUM_LUTS*LUT_NINPUTS-1:0] luts_in;
        if ( REFout !== DUTout ) begin
            $display("FAIL: Incorrect result for input addresses %b:", luts_in);
            $display("\tDUTout: 0x%h, REFout: 0x%h", DUTout, REFout);
            $finish();
        end
        else begin
            $display("PASS: inputs %b:", luts_in);
            $display("\tDUTout: 0x%h, REFout: 0x%h", DUTout, REFout);
        end
    endtask

    // LUT I/O declared here:
    reg [LUT_NINPUTS-1:0] lut_addr [NUM_LUTS-1:0];

    wire lut_out [NUM_LUTS-1:0];
    assign DUTout = lut_out;

    reg cfg_en [NUM_LUTS-1:0];

    reg [LUT_MEM_SIZE-1:0] lut_cfg_chain [NUM_LUTS-1:0];


    // MODULES TO TEST
    genvar k;
    generate
        for (k = 0; k < NUM_LUTS; k = k + 1) begin
            lut #(
                .INPUTS(LUT_NINPUTS), 
                .MEM_SIZE=(LUT_MEM_SIZE)
            ) DUT (
                .addr(lut_addr[k]),
                .out(lut_out[k]),
                .config_clk(clk),
                .config_en(cfg_en[k]),
                .config_in(lut_cfg_chain[k])
            );
        end
    endgenerate

    // Load LUT/LUTS under testing
    // CFG enable bits must be set before function.
    // Initial LUT must have input init_cfg_vec
    task loadLUTs;
        input [LUT_MEM_SIZE-1:0] config_bits [NUM_LUTS-1:0];
        integer j;
        begin
            for (j = 0; j < NUM_LUTS-1) begin
                lut_cfg_chain[j] = config_bits[j];
            end
        end
        @posedge clk;
    endtask
   

    wire [31:0] timeout_cycle = TIMEOUT;

    // keep track of cycles
    reg [31:0] cycles;
    always @(posedge clk) begin
        if (running)
            cycle <= cycle + 1;
        else
            cycle <= 0;
    end
    // Check for timeout
    // If a test does not return correct value in a given timeout cycle,
    // terminate the testbench
    initial begin
        while (all_tests_passed == 0) begin
            @(posedge clk);
            if (cycle == timeout_cycle) begin
                $display("[Failed] Timeout at during test %s, expected_result = %h, got = %h",
                         current_test_id, REFout, DUTout);
                $dumpoff;
                $finish();
            end
        end
    end


    reg [(LUT_MEM_SIZE + LUT_NINPUTS + 1) * NUM_LUTS:0] testvector [0:NUM_TESTS-1];
    integer i;

    reg [CFG_SIZE-1:0] cfg_vec;

    localparam INPUTS_START = CFG_SIZE;
    localparam OUTPUTS_START = LUT_NINPUTS * NUM_LUTS + INPUTS_START;
    localparam RELOAD_LOC = (LUT_MEM_SIZE + LUT_NINPUTS + 1) * NUM_LUTS - 1;

    reg reload;

    initial begin
        $dumpfile("LUT_TB0.vcd");
        $dumpvars(0, LUT0);
        $dumpon;
        $readmemb("../vectors/sanity0.input", testvector);
        running = 0;
        current_test_id = 0;
        // Set initial state
        repeat (2) @(negedge clk);
        running = 1;
        reload = 0;
        for (i = 0;  i < NUM_TESTS; i = i + 1) begin

            // load or reload LUTs if desired
            reload = testvector[i][RELOAD_LOC];
            if (reload) begin
                // set lut CFG_EN to high
                cfg_en = {NUM_LUTS{1'b1}};
                // load full configuration vector
                cfg_vec = testvector[i][CFG_SIZE-1:0];
                loadLUTs(cfg_vec);
            end

            // load LUT inputs
            cfg_en = {NUM_LUTS{1'b0}};
            lut_addr = testvector[i][OUTPUTS_START-1:INPUTS_START];
            REFout = testvector[i][OUTPUTS_START + NUM_LUTS - 1 : OUTPUTS_START]

            // Check result
            checkOutput(lut_addr);
            current_test_id = current_test_id + 1;
        end
        running = 0;
        all_tests_passed = 1;
        $display("\n\nALL TESTS PASSED");
        $vcdplusoff;
        $finish();

    end

endmodule