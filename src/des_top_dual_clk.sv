
`include "des_defines.vh"

// =================================================
// Module: DES Top Dual Clock (Iterative Version)
// This module separates the internal processing clock (clk_fast) 
// from the display/IO clock (clk_slow).
// One complete encryption is performed every clk_slow cycle.
// =================================================

module des_top_dual_clk (
    input clk_slow,            // Display/IO clock (e.g., 10 MHz)
    input clk_fast,            // Internal processing clock (e.g., 200 MHz, >= 16x clk_slow)
    input rst_n,               // Asynchronous active-low reset
    input [63:0] plaintext,    // 64-bit plaintext input (clk_slow domain)
    input [63:0] key,          // 64-bit key input (clk_slow domain)
    input [63:0] mask_in,      // 64-bit initial random mask (clk_slow domain)
    output reg [63:0] ciphertext, // 64-bit ciphertext output (clk_slow domain)
    output reg done            // Valid signal (clk_slow domain)
);

    // --- clk_slow Domain: Input Sampling & Start Signal ---
    reg [63:0] p_reg, k_reg, m_reg;
    reg start_toggle;
    
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            p_reg <= 64'b0;
            k_reg <= 64'b0;
            m_reg <= 64'b0;
            start_toggle <= 1'b0;
        end else begin
            p_reg <= plaintext;
            k_reg <= key;
            m_reg <= mask_in;
            start_toggle <= ~start_toggle; // Toggle every slow clock to trigger fast core
        end
    end

    // --- clk_fast Domain: Iterative Core ---
    
    // Synchronize start_toggle to clk_fast domain
    reg [2:0] start_sync;
    always @(posedge clk_fast or negedge rst_n) begin
        if (!rst_n) start_sync <= 3'b0;
        else start_sync <= {start_sync[1:0], start_toggle};
    end
    wire start_pulse = start_sync[2] ^ start_sync[1]; // Detect toggle edge

    // Iterative State Machine
    typedef enum logic [1:0] {IDLE, RUN, FINISH} state_t;
    state_t state;
    reg [3:0] round_cnt;
    
    reg [31:0] L, R, ML, MR;
    wire [31:0] next_L, next_R, next_ML, next_MR;
    wire [47:0] subkeys[16];
    
    // Subkey Generation (Reusing key_gen from des_top.sv)
    // In a real area-optimized design, key_gen would also be iterative,
    // but for clarity we reuse the parallel version here.
    key_gen kg_inst (
        .key(k_reg),
        .subkeys(subkeys)
    );

    // Round Logic Instance (Combinational part of the round)
    wire [31:0] f_out, m_f_out;
    masked_feistel_function f_func (
        .R_masked(R),
        .MR_in(MR),
        .K(subkeys[round_cnt]),
        .F_masked(f_out),
        .MF_out(m_f_out)
    );
    
    assign next_L  = R;
    assign next_ML = MR;
    assign next_R  = L ^ f_out;
    assign next_MR = ML ^ m_f_out;

    reg [63:0] result_buffer;

    always @(posedge clk_fast or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            round_cnt <= 4'd0;
            L <= 32'b0; R <= 32'b0; ML <= 32'b0; MR <= 32'b0;
            result_buffer <= 64'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_pulse) begin
                        // 1. Initial Masking & IP
                        wire [63:0] masked_p = p_reg ^ m_reg;
                        wire [63:0] ip_masked = permute_IP(masked_p);
                        wire [63:0] ip_mask   = permute_IP(m_reg);
                        
                        L <= ip_masked[63:32];
                        R <= ip_masked[31:0];
                        ML <= ip_mask[63:32];
                        MR <= ip_mask[31:0];
                        
                        round_cnt <= 4'd0;
                        state <= RUN;
                    end
                end
                
                RUN: begin
                    L <= next_L;
                    R <= next_R;
                    ML <= next_ML;
                    MR <= next_MR;
                    
                    if (round_cnt == 4'd15) begin
                        state <= FINISH;
                    end else begin
                        round_cnt <= round_cnt + 4'd1;
                    end
                end
                
                FINISH: begin
                    // 2. Final Swap & IP_INV & Unmasking
                    wire [63:0] pre_fp_masked = {R, L};
                    wire [63:0] final_mask = {MR, ML};
                    result_buffer <= permute_IP_INV(pre_fp_masked) ^ permute_IP_INV(final_mask);
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

    // --- clk_slow Domain: Output Capture ---
    reg [2:0] finish_sync;
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            finish_sync <= 3'b0;
            ciphertext <= 64'b0;
            done <= 1'b0;
        end else begin
            // Sync the 'state == FINISH' signal back to clk_slow
            finish_sync <= {finish_sync[1:0], (state == FINISH)};
            
            // On the rising edge of the synchronized finish signal, capture the result
            if (finish_sync[1] && !finish_sync[2]) begin
                ciphertext <= result_buffer;
                done <= 1'b1;
            end else begin
                done <= 1'b0;
            end
        end
    end

endmodule
