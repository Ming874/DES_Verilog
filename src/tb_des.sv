
`timescale 1ns/1ps

// Module: DES Simulation Testbench
// Used to verify the functional correctness and timing behavior of the 16-stage pipelined DES accelerator.

module tb_des;

    reg clk;                   // System clock
    reg rst_n;                 // Asynchronous active-low reset
    reg [63:0] plaintext;      // Test plaintext input
    reg [63:0] key;            // Test key input
    reg [63:0] mask_in;        // Test initial random mask
    wire [63:0] ciphertext;    // Ciphertext output from DUT
    wire done;                 // Done signal from DUT (indicates valid pipeline output)

    // Instantiate Device Under Test
    des_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .plaintext(plaintext),
        .key(key),
        .mask_in(mask_in),
        .ciphertext(ciphertext),
        .done(done)
    );

    // Clock Generation (10 ns period, 100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Initialize System State
        rst_n = 0;
        plaintext = 64'h0;
        key = 64'h0;
        
        // Provide a random mask. In real hardware this should come from a TRNG,
        // but for simulation we provide a fixed value to observe its protection and recovery effect.
        mask_in = 64'hA5A5A5A55A5A5A5A; 

        #20;
        rst_n = 1;

        // Test Case 1:
        // Key: 0123456789ABCDEF
        // Plaintext: 4E6F772069732074
        // Expected Ciphertext: 3FA40E8A984D4815
        key = 64'h0123456789ABCDEF;
        plaintext = 64'h4E6F772069732074;
        
        // Wait for pipeline to fill (16 cycles) then check done signal
        wait(done);
        #1;
        $display("Time: %0t | Key: %h | Plaintext: %h | Ciphertext: %h", $time, key, plaintext, ciphertext);
        
        // Test Case 2:
        // Key: 133457799BBCDFF1
        // Plaintext: 0123456789ABCDEF
        // Expected Ciphertext: 85E813540F0AB405
        #10;
        key = 64'h133457799BBCDFF1;
        plaintext = 64'h0123456789ABCDEF;
        
        // Wait long enough for new data to flow through the 16-stage pipeline
        #200; 
        $display("Time: %0t | Key: %h | Plaintext: %h | Ciphertext: %h", $time, key, plaintext, ciphertext);

        // End simulation
        #100;
        $finish;
    end

    // Observe valid output on every positive clock edge
    always @(posedge clk) begin
        if (done) begin
            $display("Valid pipeline output at %0t: %h", $time, ciphertext);
        end
    end

endmodule
