
`include "des_defines.vh"

module des_top (
    input clk,                 // System clock
    input rst_n,               // Asynchronous active-low reset
    input [63:0] plaintext,    // 64-bit plaintext input
    input [63:0] key,          // 64-bit key input
    input [63:0] mask_in,      // 64-bit initial random mask for SCA defense
    output [63:0] ciphertext,  // 64-bit ciphertext output
    output done                // Done signal, indicating valid pipeline output
);

    // Initial Permutation, IP
    wire [63:0] ip_data;
    assign ip_data = permute_IP(plaintext);

    // Masking Initialization
    // In the entire encryption/decryption process, the true data D is always hidden in D' (Masked Data), D' = D ^ M.
    wire [63:0] masked_plaintext = plaintext ^ mask_in;
    // Apply IP to the masked data
    wire [63:0] ip_masked_data = permute_IP(masked_plaintext);
    
    // To decode correctly later, we must also apply the same permutation to the mask itself to track its position.
    wire [63:0] ip_mask = permute_IP(mask_in);

    // Split the 64-bit data and mask into left and right halves (L0, R0)
    wire [31:0] L0_masked = ip_masked_data[63:32];
    wire [31:0] R0_masked = ip_masked_data[31:0];
    wire [31:0] ML0 = ip_mask[63:32]; // Mask for L0
    wire [31:0] MR0 = ip_mask[31:0];  // Mask for R0

    // 3. Key Schedule
    // Implements a parallel key generator to produce all 16 subkeys at once.
    // To simplify the design and match the 16-stage pipeline, we use combinational logic to generate all subkeys concurrently,
    // and then feed these subkeys directly into their corresponding pipeline stages.
    wire [47:0] subkeys[16];
    
    key_gen kg (
        .key(key),
        .subkeys(subkeys)
    );

    // 4. 16-Stage Pipeline
    // Declare arrays to connect the inputs and outputs of each pipeline stage. Includes data and masks.
    wire [31:0] L_stages[17];
    wire [31:0] R_stages[17];
    wire [31:0] ML_stages[17];
    wire [31:0] MR_stages[17];

    // Initialize the input data of stage 0
    assign L_stages[0] = L0_masked;
    assign R_stages[0] = R0_masked;
    assign ML_stages[0] = ML0;
    assign MR_stages[0] = MR0;

    // Use generate block to instantiate 16 independent DES round modules
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : pipe_stages
            des_round_stage stage (
                .clk(clk),
                .rst_n(rst_n),
                .L_in(L_stages[i]),
                .R_in(R_stages[i]),
                .ML_in(ML_stages[i]),
                .MR_in(MR_stages[i]),
                .K_in(subkeys[i]), // Feed the corresponding round subkey
                .L_out(L_stages[i+1]),
                .R_out(R_stages[i+1]),
                .ML_out(ML_stages[i+1]),
                .MR_out(MR_stages[i+1])
            );
        end
    endgenerate

    // 5. Final Inverse Permutation (IP_INV)
    wire [63:0] pre_fp_masked = {R_stages[16], L_stages[16]};
    wire [63:0] final_mask = {MR_stages[16], ML_stages[16]};
    
    // Apply inverse permutation to the combined data and mask
    wire [63:0] fp_masked_data = permute_IP_INV(pre_fp_masked);
    wire [63:0] fp_mask = permute_IP_INV(final_mask);

    // Remove the mask at the last moment of module output to recover the true ciphertext.
    assign ciphertext = fp_masked_data ^ fp_mask;

    // Done Signal Generation: Use a shift register to track data flow through the 16-stage pipeline, outputting a valid signal after 16 cycles delay.
    reg [15:0] done_pipe;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) done_pipe <= 16'b0;
        else done_pipe <= {done_pipe[14:0], 1'b1};
    end
    assign done = done_pipe[15];

endmodule

// =================================================
// Sub-module: Key Generation
// Responsible for generating 16 48-bit subkeys from the 64-bit main key.
// =================================================
module key_gen (
    input [63:0] key,
    output [47:0] subkeys[16]
);
    
    logic [55:0] pc1_data;
    logic [27:0] C[17], D[17];
    
    // PC-1 Permutation: Discard 8 parity bits and rearrange the remaining 56 bits
    assign pc1_data = {
        key[64-57], key[64-49], key[64-41], key[64-33], key[64-25], key[64-17], key[64-9],
        key[64-1],  key[64-58], key[64-50], key[64-42], key[64-34], key[64-26], key[64-18],
        key[64-10], key[64-2],  key[64-59], key[64-51], key[64-43], key[64-35], key[64-27],
        key[64-19], key[64-11], key[64-3],  key[64-60], key[64-52], key[64-44], key[64-36],
        key[64-63], key[64-55], key[64-47], key[64-39], key[64-31], key[64-23], key[64-15],
        key[64-7],  key[64-62], key[64-54], key[64-46], key[64-38], key[64-30], key[64-22],
        key[64-14], key[64-6],  key[64-61], key[64-53], key[64-45], key[64-37], key[64-29],
        key[64-21], key[64-13], key[64-5],  key[64-28], key[64-20], key[64-12], key[64-4]
    };

    // Split the 56-bit key into two 28-bit halves, C0 and D0
    assign C[0] = pc1_data[55:28];
    assign D[0] = pc1_data[27:0];

    // Loop to generate 16 rounds of subkeys
    generate
        for (genvar i = 0; i < 16; i = i + 1) begin : key_gen_loop
            // Determine left shift amount (1 or 2 bits)
            wire [4:0] shifts = (i==0 || i==1 || i==8 || i==15) ? 5'd1 : 5'd2;
            
            // Circular left shift
            assign C[i+1] = (shifts == 1) ? {C[i][26:0], C[i][27]} : {C[i][25:0], C[i][27:26]};
            assign D[i+1] = (shifts == 1) ? {D[i][26:0], D[i][27]} : {D[i][25:0], D[i][27:26]};
            
            // PC-2 Permutation: Combine C and D, then compress into a 48-bit subkey
            wire [55:0] combined = {C[i+1], D[i+1]};
            assign subkeys[i] = {
                combined[56-14], combined[56-17], combined[56-11], combined[56-24], combined[56-1],  combined[56-5],
                combined[56-3],  combined[56-28], combined[56-15], combined[56-6],  combined[56-21], combined[56-10],
                combined[56-23], combined[56-19], combined[56-12], combined[56-4],  combined[56-26], combined[56-8],
                combined[56-16], combined[56-7],  combined[56-27], combined[56-20], combined[56-13], combined[56-2],
                combined[56-41], combined[56-52], combined[56-31], combined[56-37], combined[56-47], combined[56-55],
                combined[56-30], combined[56-40], combined[56-51], combined[56-45], combined[56-33], combined[56-48],
                combined[56-44], combined[56-49], combined[56-39], combined[56-56], combined[56-34], combined[56-53],
                combined[56-46], combined[56-42], combined[56-50], combined[56-36], combined[56-29], combined[56-32]
            };
        end
    endgenerate
endmodule
