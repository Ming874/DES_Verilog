
`include "des_defines.vh"

// =================================================
// Module: DES Round Stage
// This module implements a single stage in the 16-stage pipeline, 
// responsible for executing one Feistel function and storing data and masks in flip-flops to break the combinational logic critical path.
// =================================================

module des_round_stage (
    input clk,             // System clock
    input rst_n,           // Asynchronous active-low reset
    input [31:0] L_in,     // Input: Left-half masked data
    input [31:0] R_in,     // Input: Right-half masked data
    input [31:0] ML_in,    // Input: Left-half corresponding mask
    input [31:0] MR_in,    // Input: Right-half corresponding mask
    input [47:0] K_in,     // Input: 48-bit subkey for the current round
    output reg [31:0] L_out, // Output: Updated left-half masked data (register output)
    output reg [31:0] R_out, // Output: Updated right-half masked data (register output)
    output reg [31:0] ML_out,// Output: Updated left-half mask (register output)
    output reg [31:0] MR_out // Output: Updated right-half mask (register output)
);

    wire [31:0] f_out;     // Masked output data from the Feistel function
    wire [31:0] m_f_out;   // New mask corresponding to the Feistel function output data

    // Instantiate the masked Feistel function
    // Pass the right-half data, mask, and current subkey into it
    masked_feistel_function f_func (
        .R_masked(R_in),
        .MR_in(MR_in),
        .K(K_in),
        .F_masked(f_out),
        .MF_out(m_f_out)
    );

    // Sequential Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            L_out <= 32'b0;
            R_out <= 32'b0;
            ML_out <= 32'b0;
            MR_out <= 32'b0;
        end else begin
            // L_i = R_{i-1}，資料與掩碼同步更新，確保安全性
            L_out <= R_in;
            ML_out <= MR_in;
            
            // R_i = L_{i-1} ^ F(R_{i-1}, K_i)
            // 右半部資料 = 舊左半部資料 ^ Feistel 輸出資料
            R_out <= L_in ^ f_out;

            // 右半部掩碼 = 舊左半部掩碼 ^ Feistel 輸出掩碼
            MR_out <= ML_in ^ m_f_out;
            
            // Ps. 透過 (L_in ^ ML_in) ^ (f_out ^ m_f_out) 的數學等價性，能確保 R_out ^ MR_out 等於真實的未掩碼資料
        end
    end
endmodule
