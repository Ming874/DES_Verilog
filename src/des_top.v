module des_top (
    input clk,                 // System clock
    input rst_n,               // Asynchronous active-low reset
    input in_valid,            // Input valid signal

    input [63:0] plaintext,    // 64-bit plaintext input
    input [63:0] key,          // 64-bit key input (Sampled when in_valid is high)
    input [63:0] mask_in,      // 64-bit initial random mask for SCA defense

    output [63:0] ciphertext,  // 64-bit ciphertext output
    output out_valid           // Output valid signal
);

    `include "des_defines.vh"

    // 1. Initial Processing
    wire [63:0] lfsr_out;
    lfsr_64 prng (
        .clk(clk),
        .rst_n(rst_n),
        .load(1'b0),
        .seed(64'h0),
        .q(lfsr_out)
    );

    // Combine input mask with LFSR for dynamic masking
    wire [63:0] dynamic_mask = mask_in ^ lfsr_out;

    // Masking Initialization
    wire [63:0] masked_plaintext = plaintext ^ dynamic_mask;
    
    // Apply IP to both data and mask
    wire [63:0] ip_masked_data = permute_IP(masked_plaintext);
    wire [63:0] ip_mask = permute_IP(dynamic_mask);

    // Split into left and right halves
    wire [31:0] L0_masked = ip_masked_data[63:32];
    wire [31:0] R0_masked = ip_masked_data[31:0];
    wire [31:0] ML0 = ip_mask[63:32];
    wire [31:0] MR0 = ip_mask[31:0];

    // 2. Key Schedule Initialization (PC-1)
    // Key is now pipelined, so we perform PC-1 once at the beginning.
    wire [55:0] pc1_key = permute_PC1(key);
    wire [27:0] C0 = pc1_key[55:28];
    wire [27:0] D0 = pc1_key[27:0];

    // 3. 16-Stage Pipeline
    // Data and Mask pipeline arrays
    wire [543:0] L_stages;
    wire [543:0] R_stages;
    wire [543:0] ML_stages;
    wire [543:0] MR_stages;
    
    // Key state pipeline arrays (C and D halves)
    wire [475:0] C_stages;
    wire [475:0] D_stages;

    wire [16:0] valid_stages;

    // Initialize Stage 0 inputs
    assign L_stages[31:0] = L0_masked;
    assign R_stages[31:0] = R0_masked;
    assign ML_stages[31:0] = ML0;
    assign MR_stages[31:0] = MR0;
    
    assign C_stages[27:0] = C0;
    assign D_stages[27:0] = D0;

    assign valid_stages[0] = in_valid;

    // Use lower 32 bits of LFSR for internal re-masking
    wire [31:0] rnd_mask = lfsr_out[31:0];

    // Instantiate 16 DES round modules in a pipeline
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : pipe_stages
            // Shift amount for each round: 1 bit for rounds 1, 2, 9, 16; 2 bits for others.
            // (Indices: 0, 1, 8, 15)
            wire [4:0] current_shift;
            assign current_shift = (i==0 || i==1 || i==8 || i==15) ? 5'd1 : 5'd2;

            des_round_stage stage (
                .clk(clk),
                .rst_n(rst_n),

                .L_in(L_stages[(i*32)+31:(i*32)]),
                .R_in(R_stages[(i*32)+31:(i*32)]),
                .ML_in(ML_stages[(i*32)+31:(i*32)]),
                .MR_in(MR_stages[(i*32)+31:(i*32)]),
                
                .C_in(C_stages[(i*28)+27:(i*28)]),
                .D_in(D_stages[(i*28)+27:(i*28)]),
                .shift_amt(current_shift),

                .rnd_mask(rnd_mask),
                .in_valid(valid_stages[i]),

                .L_out(L_stages[((i+1)*32)+31:((i+1)*32)]),
                .R_out(R_stages[((i+1)*32)+31:((i+1)*32)]),
                .ML_out(ML_stages[((i+1)*32)+31:((i+1)*32)]),
                .MR_out(MR_stages[((i+1)*32)+31:((i+1)*32)]),
                
                .C_out(C_stages[((i+1)*28)+27:((i+1)*28)]),
                .D_out(D_stages[((i+1)*28)+27:((i+1)*28)]),

                .out_valid(valid_stages[i+1])
            );
        end
    endgenerate

    // 4. Final Processing (IP_INV)
    assign out_valid = valid_stages[16];

    // 32-bit Swap and concatenation
    wire [63:0] pre_fp_masked = {R_stages[(16*32)+31:(16*32)], L_stages[(16*32)+31:(16*32)]};
    wire [63:0] final_mask = {MR_stages[(16*32)+31:(16*32)], ML_stages[(16*32)+31:(16*32)]};
    
    wire [63:0] fp_masked_data = permute_IP_INV(pre_fp_masked);
    wire [63:0] fp_mask = permute_IP_INV(final_mask);

    // Final Unmasking
    assign ciphertext = fp_masked_data ^ fp_mask;

endmodule
