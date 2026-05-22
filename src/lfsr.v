// Module: Linear Feedback Shift Register (LFSR)
// Provides pseudo-random numbers for masking to enhance SCA resistance.
// Polynomial: x^64 + x^63 + x^61 + x^60 + 1 (A primitive polynomial for 64-bit LFSR)

module lfsr_64 (
    input clk,
    input rst_n,
    input load,
    input [63:0] seed,
    output [63:0] q
);

    reg [63:0] data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 64'hACE12481ACE12481; // Non-zero default seed
        end else if (load) begin
            data <= seed;
        end else begin
            // LFSR feedback logic for 64-bit
            // Taps: 64, 63, 61, 60 (indices 63, 62, 60, 59)
            data <= {data[62:0], data[63] ^ data[62] ^ data[60] ^ data[59]};
        end
    end

    assign q = data;

endmodule
