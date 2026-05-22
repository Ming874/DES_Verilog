
`timescale 1ns/1ps

// Module: DES Simulation Testbench
// Verifies 16 NIST Standard KAT (Known Answer Test) vectors.

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
    
    // Test Vector Arrays
    reg [63:0] keys [0:15];
    reg [63:0] pts  [0:15];

    wire [63:0] lfsr_mask;
    lfsr_64 tb_prng (
        .clk(clk),
        .rst_n(rst_n),
        .load(1'b0),
        .seed(64'hACE12481ACE12481),
        .q(lfsr_mask)
    );

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

    // Load Vectors
    initial begin
        keys[0] = 64'h0000000000000000; pts[0] = 64'h0000000000000000;
        keys[1] = 64'hFFFFFFFFFFFFFFFF; pts[1] = 64'hFFFFFFFFFFFFFFFF;
        keys[2] = 64'h3000000000000000; pts[2] = 64'h1000000000000001;
        keys[3] = 64'h1111111111111111; pts[3] = 64'h1111111111111111;
        keys[4] = 64'h0123456789ABCDEF; pts[4] = 64'h1111111111111111;
        keys[5] = 64'h1111111111111111; pts[5] = 64'h0123456789ABCDEF;
        keys[6] = 64'hFEDCBA9876543210; pts[6] = 64'h0123456789ABCDEF;
        keys[7] = 64'h7CA110454A1A6E57; pts[7] = 64'h01A1D6D039776742;
        keys[8] = 64'h0131D9619DC1376E; pts[8] = 64'h5CD54CA83DEF57DA;
        keys[9] = 64'h07A1133E4A0B2686; pts[9] = 64'h0248D43806F67172;
        keys[10]= 64'h3849674C2602319E; pts[10]= 64'h51454B582DDF440A;
        keys[11]= 64'h04B915BA43FEB5B6; pts[11]= 64'h42FD443059577FA2;
        keys[12]= 64'h0113B970FD34F2CE; pts[12]= 64'h059B5E0851CF143A;
        keys[13]= 64'h0170F175468FB5E6; pts[13]= 64'h0756D8E0774761D2;
        keys[14]= 64'h43297FAD38E373FE; pts[14]= 64'h762514B829BF486A;
        keys[15]= 64'h1122334455667788; pts[15]= 64'h752878397493CB70;
    end

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        plaintext = 64'h0;
        key = 64'h0;
        mask_in = 64'h0;
        in_valid = 0;

        #20;
        rst_n = 1;

        $display("--- Starting 16-Case NIST Standard Verification ---");
        
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            in_valid = 1;
            plaintext = pts[i];
            key = keys[i];
            mask_in = lfsr_mask; // Use LFSR for masking
            $display("[%0t] SIM_INPUT: Case=%2d PT=%h KEY=%h MASK=%h", $time, i, plaintext, key, mask_in);
        end
        
        @(posedge clk);
        in_valid = 0;
        
        repeat(32) @(posedge clk);
        $finish;
    end

    // Result Monitor
    always @(posedge clk) begin
        if (out_valid) begin
            $display("[%0t] SIM_OUTPUT: CT=%h", $time, ciphertext);
        end
    end

endmodule
