
// =============================================================================
// Module: des_round_stage
// Description: 
//   Implement a single stage of the 16-round DES pipeline with masking 
//   countermeasures. Breaks the critical path using registered outputs.
//   Now supports per-data keying by pipelining the C and D key states.
// =============================================================================

module des_round_stage (
    input clk,                  // System clock
    input rst_n,                // Asynchronous active-low reset
    input [31:0] L_in,          // LH masked data
    input [31:0] R_in,          // RH masked data
    input [31:0] ML_in,         // LH corresponding mask
    input [31:0] MR_in,         // RH corresponding mask
    
    // Key Pipeline Ports
    input [27:0] C_in,          // Input C half of key state
    input [27:0] D_in,          // Input D half of key state
    input [4:0]  shift_amt,     // Shift amount for this round (1 or 2)
    
    input [31:0] rnd_mask,      // Random mask for re-masking
    input in_valid,             // Input valid signal

    output reg [31:0] L_out,    // Updated LH masked data
    output reg [31:0] R_out,    // Updated RH masked data
    output reg [31:0] ML_out,   // Updated LH mask
    output reg [31:0] MR_out,   // Updated RH mask
    
    // Key Pipeline Outputs
    output reg [27:0] C_out,    // Output C half (shifted)
    output reg [27:0] D_out,    // Output D half (shifted)
    
    output reg out_valid        // Output valid signal
);

    `include "des_defines.vh"

    // Key Shift Logic: Circular left shift
    wire [27:0] C_shifted = (shift_amt == 5'd1) ? {C_in[26:0], C_in[27]} : {C_in[25:0], C_in[27:26]};
    wire [27:0] D_shifted = (shift_amt == 5'd1) ? {D_in[26:0], D_in[27]} : {D_in[25:0], D_in[27:26]};
    
    // Generate the 48-bit subkey for the current round using PC-2
    wire [47:0] K_current = permute_PC2({C_shifted, D_shifted});

    wire [31:0] f_out;     // Masked output data from the Feistel function
    wire [31:0] m_f_out;   // New mask corresponding to the Feistel function output data

    // Instantiate the masked Feistel function
    masked_feistel_function f_func (
        .R_masked(R_in),
        .MR_in(MR_in),
        .K(K_current),
        .rnd_mask(rnd_mask),
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
            C_out <= 28'b0;
            D_out <= 28'b0;
            out_valid <= 1'b0;
        end
        else begin
            // valid signal follows the pipeline latency
            out_valid <= in_valid;

            // L_i = R_{i-1}
            L_out <= R_in;              // 資料運算
            ML_out <= MR_in;            // 掩碼運算
            
            // R_i = L_{i-1} ^ F(R_{i-1}, K_i)
            R_out <= L_in ^ f_out;      // 資料運算
            MR_out <= ML_in ^ m_f_out;  // 掩碼運算
            // 透過 (L_in ^ ML_in) ^ (f_out ^ m_f_out) 的數學等價性，能確保 R_out ^ MR_out 等於原本未掩碼資料

            // Pipeline the key state
            C_out <= C_shifted;
            D_out <= D_shifted;
        end
    end
endmodule
