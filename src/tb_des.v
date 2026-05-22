
`timescale 1ns/1ps

// Module: DES Simulation Testbench
// Verifies functional correctness and per-data key pipelining.

module tb_des;

    reg clk;                   // System clock
    reg rst_n;                 // Asynchronous active-low reset
    reg in_valid;              // Input valid signal

    reg [63:0] plaintext;      // Test plaintext input
    reg [63:0] key;            // Test key input
    reg [63:0] mask_in;        // Test initial random mask
    wire [63:0] ciphertext;    // Ciphertext output from DUT
    wire out_valid;            // Output valid signal from DUT (indicates valid pipeline output)
    integer i;

    des_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .plaintext(plaintext),
        .key(key),
        .mask_in(mask_in),
        .ciphertext(ciphertext),
        .out_valid(out_valid)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_des);
    end

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        plaintext = 64'h0;
        key = 64'h0;
        mask_in = 64'hA5A5A5A55A5A5A5A; 

        #20;
        rst_n = 1;
        in_valid = 1;

        $display("--- Starting Per-Data Keying Verification ---");
        
        // Cycle 0: Case 1
        plaintext = 64'h4E6F772069732074;
        key = 64'h0123456789ABCDEF;
        @(posedge clk);

        // Cycle 1: Case 2 (Different key and data)
        plaintext = 64'h0123456789ABCDEF;
        key = 64'h133457799BBCDFF1;
        @(posedge clk);

        // Cycle 2-15: Stream more data with different keys
        for (i = 0; i < 14; i = i + 1) begin
            plaintext = 64'hAAAA_AAAA_AAAA_AAAA + i;
            key = 64'hFFFF_FFFF_FFFF_FFFF - i;
            @(posedge clk);
        end

        in_valid = 0;
        
        // Wait for all 16 results
        repeat(32) @(posedge clk);

        $display("--- Verification Finished ---");
        $finish;
    end

    // Result Checker
    reg [4:0] out_cnt = 0;
    always @(posedge clk) begin
        if (out_valid) begin
            out_cnt <= out_cnt + 1;
            case (out_cnt)
                0: begin
                    $display("Time: %0t | Case 1 | Ciphertext: %h | Expected: 3fa40e8a984d4815", $time, ciphertext);
                    if (ciphertext !== 64'h3fa40e8a984d4815) $display(">> ERROR: Case 1 Mismatch!");
                end
                1: begin
                    $display("Time: %0t | Case 2 | Ciphertext: %h | Expected: 85e813540f0ab405", $time, ciphertext);
                    if (ciphertext !== 64'h85e813540f0ab405) $display(">> ERROR: Case 2 Mismatch!");
                end
                default: $display("Time: %0t | Case %0d | Ciphertext: %h", $time, out_cnt + 1, ciphertext);
            endcase
        end
    end

endmodule
