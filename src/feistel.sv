
`include "des_defines.vh"

module masked_feistel_function (
    input [31:0] R_masked, // Masked right-half data (R' = R ^ Mask)
    input [31:0] MR_in,    // Input mask value (Mask)
    input [47:0] K,        // 48-bit subkey for the current round
    output [31:0] F_masked,// Masked output of the Feistel function
    output [31:0] MF_out   // New mask value corresponding to the output data
);

    // 1. Expansion Permutation
    // Expands the 32-bit data and mask to 48-bit. Since expansion is a linear operation, we can conclude that the masking logic holds.
    wire [47:0] E_masked = expand_32_48(R_masked);
    wire [47:0] ME = expand_32_48(MR_in);

    // 2. XOR with Key
    // XORs the expanded masked data with the subkey.
    // The mask value ME remains unchanged here because (E(R) ^ K) ^ E(MR) = (E(R) ^ E(MR)) ^ K = E_masked ^ K.
    // This securely mixes the key without leaking the actual E(R).
    wire [47:0] X_masked = E_masked ^ K;

    // 3. Substitution Boxes (S-Boxes)
    wire [3:0] s_out_masked[8];
    
    // To resist high-order SCA and implement "re-masking", we must provide a new mask for the S-Box outputs.
    // For simplicity in this implementation, we use a shifted version of the input mask as the new mask.
    // In a truly SCA-resistant hardware design, this M_sbox_out MUST be dynamically generated
    // by a TRNG every clock cycle to ensure the power signature is fully decoupled from any internal state.
    wire [31:0] M_sbox_out = {MR_in[7:0], MR_in[31:8]}; // Pseudo-random re-masking strategy

    // Instantiate 8 masked S-Boxes. Each receives 6-bit masked data, a 6-bit input mask,
    // and produces a 4-bit masked output based on the provided 4-bit output mask (m_out).
    masked_sbox1 sb1 (.d_masked(X_masked[47:42]), .m_in(ME[47:42]), .m_out(M_sbox_out[31:28]), .q_masked(s_out_masked[0]));
    masked_sbox2 sb2 (.d_masked(X_masked[41:36]), .m_in(ME[41:36]), .m_out(M_sbox_out[27:24]), .q_masked(s_out_masked[1]));
    masked_sbox3 sb3 (.d_masked(X_masked[35:30]), .m_in(ME[35:30]), .m_out(M_sbox_out[23:20]), .q_masked(s_out_masked[2]));
    masked_sbox4 sb4 (.d_masked(X_masked[29:24]), .m_in(ME[29:24]), .m_out(M_sbox_out[19:16]), .q_masked(s_out_masked[3]));
    masked_sbox5 sb5 (.d_masked(X_masked[23:18]), .m_in(ME[23:18]), .m_out(M_sbox_out[15:12]), .q_masked(s_out_masked[4]));
    masked_sbox6 sb6 (.d_masked(X_masked[17:12]), .m_in(ME[17:12]), .m_out(M_sbox_out[11:8]),  .q_masked(s_out_masked[5]));
    masked_sbox7 sb7 (.d_masked(X_masked[11:6]),  .m_in(ME[11:6]),  .m_out(M_sbox_out[7:4]),   .q_masked(s_out_masked[6]));
    masked_sbox8 sb8 (.d_masked(X_masked[5:0]),   .m_in(ME[5:0]),   .m_out(M_sbox_out[3:0]),   .q_masked(s_out_masked[7]));

    // Combine the eight 4-bit S-Box outputs into a 32-bit data block.
    wire [31:0] s_combined_masked = {
        s_out_masked[0], s_out_masked[1], s_out_masked[2], s_out_masked[3],
        s_out_masked[4], s_out_masked[5], s_out_masked[6], s_out_masked[7]
    };

    // 4. Permutation
    // Applies the P permutation to the S-Box output data and its corresponding mask. 
    // This is also a linear operation, ensuring the final output data and mask maintain the correct XOR relationship.
    assign F_masked = permute_32(s_combined_masked);
    assign MF_out = permute_32(M_sbox_out);

endmodule
