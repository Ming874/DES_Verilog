
`timescale 1ns/1ps

// Module: DES Dual Clock Testbench
// Verifies the iterative DES engine running with separate slow (IO) and fast (Core) clocks.

module tb_des_dual_clk;

    reg clk_slow;              // IO/Display Clock (10 MHz)
    reg clk_fast;              // Internal Core Clock (200 MHz)
    reg rst_n;
    reg [63:0] plaintext;
    reg [63:0] key;
    reg [63:0] mask_in;
    wire [63:0] ciphertext;
    wire done;
    integer i;

    // Instantiate Device Under Test
    des_top_dual_clk dut (
        .clk_slow(clk_slow),
        .clk_fast(clk_fast),
        .rst_n(rst_n),
        .plaintext(plaintext),
        .key(key),
        .mask_in(mask_in),
        .ciphertext(ciphertext),
        .done(done)
    );

    // Clock Generation
    // clk_slow: 100 ns period (10 MHz)
    initial clk_slow = 0;
    always #50 clk_slow = ~clk_slow;

    // clk_fast: 5 ns period (200 MHz)
    initial clk_fast = 0;
    always #2.5 clk_fast = ~clk_fast;

    initial begin
        // Initialize
        rst_n = 0;
        plaintext = 64'h0;
        key = 64'h0123456789ABCDEF;
        mask_in = 64'hA5A5A5A55A5A5A5A; 

        #200;
        rst_n = 1;

        $display("--- Starting Dual Clock Iterative Test ---");
        $display("clk_slow = 10 MHz, clk_fast = 200 MHz");

        // Feed multiple plaintexts sequentially on clk_slow
        // Each plaintext should be processed by the fast clock and 
        // ready by the next slow clock cycle.
        
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk_slow);
            plaintext = 64'h4E6F772069732074 + i;
            $display("Time: %0t | [Input] Plaintext: %h", $time, plaintext);
        end
        
        // Wait for all processing to finish
        repeat(10) @(posedge clk_slow);

        $display("--- Test Finished ---");
        $finish;
    end

    // Monitor Output
    always @(posedge clk_slow) begin
        if (done) begin
            $display("Time: %0t | [Output] Ciphertext: %h | Done: %b", $time, ciphertext, done);
        end
    end

endmodule
