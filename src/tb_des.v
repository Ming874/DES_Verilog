
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
    integer i;

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

    // waveform dumping for simulation
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_des);
    end

    // Clock Generation (10 ns period, 100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Initialize System State
        rst_n = 0;
        plaintext = 64'h0;
        key = 64'h0123456789ABCDEF; // Fixed key for streaming test
        mask_in = 64'hA5A5A5A55A5A5A5A; 

        #20;
        rst_n = 1;

        // Start streaming data
        $display("--- Starting Streaming Test ---");
        for (i = 0; i < 32; i = i + 1) begin
            plaintext = 64'h4E6F772069732074 + i;
            @(posedge clk);
        end
        
        // Wait for last data to exit pipeline
        repeat(20) @(posedge clk);

        $display("--- Streaming Test Finished ---");
        $finish;
    end

    // Observe valid output on every positive clock edge
    always @(posedge clk) begin
        if (done) begin
            $display("Time: %0t | Ciphertext Out: %h", $time, ciphertext);
        end
    end

endmodule
