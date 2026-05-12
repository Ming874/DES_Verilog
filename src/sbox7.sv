// Module: Masked S-Box 7

// This module implements the masked S-Box functionality using combinatorial logic.
// By integrating masking at the gate level, it prevents the generation of unmasked sensitive signals within the FPGA.

module masked_sbox7 (
    input [5:0] d_masked, // Input: 6-bit masked data (D' = D ^ m_in)
    input [5:0] m_in,     // Input: 6-bit input mask
    input [3:0] m_out,    // Input: Expected 4-bit output mask (for re-masking)
    output [3:0] q_masked // Output: 4-bit data protected by the new mask (Q' = Q ^ m_out)
);

    // Decode the internal true values to build the truth table. The synthesizer will merge this operation with the case statement.
    wire [5:0] d = d_masked ^ m_in;
    reg [3:0] q_base;
    always @(*) begin
        case (d)
            6'd0: q_base = 4'd4;
            6'd1: q_base = 4'd13;
            6'd2: q_base = 4'd11;
            6'd3: q_base = 4'd0;
            6'd4: q_base = 4'd2;
            6'd5: q_base = 4'd11;
            6'd6: q_base = 4'd14;
            6'd7: q_base = 4'd7;
            6'd8: q_base = 4'd15;
            6'd9: q_base = 4'd4;
            6'd10: q_base = 4'd0;

            6'd11: q_base = 4'd9;
            6'd12: q_base = 4'd8;
            6'd13: q_base = 4'd1;
            6'd14: q_base = 4'd13;
            6'd15: q_base = 4'd10;
            6'd16: q_base = 4'd3;
            6'd17: q_base = 4'd14;
            6'd18: q_base = 4'd12;
            6'd19: q_base = 4'd3;
            6'd20: q_base = 4'd9;
            
            6'd21: q_base = 4'd5;
            6'd22: q_base = 4'd7;
            6'd23: q_base = 4'd12;
            6'd24: q_base = 4'd5;
            6'd25: q_base = 4'd2;
            6'd26: q_base = 4'd10;
            6'd27: q_base = 4'd15;
            6'd28: q_base = 4'd6;
            6'd29: q_base = 4'd8;
            6'd30: q_base = 4'd1;
            
            6'd31: q_base = 4'd6;
            6'd32: q_base = 4'd1;
            6'd33: q_base = 4'd6;
            6'd34: q_base = 4'd4;
            6'd35: q_base = 4'd11;
            6'd36: q_base = 4'd11;
            6'd37: q_base = 4'd13;
            6'd38: q_base = 4'd13;
            6'd39: q_base = 4'd8;
            6'd40: q_base = 4'd12;
            
            6'd41: q_base = 4'd1;
            6'd42: q_base = 4'd3;
            6'd43: q_base = 4'd4;
            6'd44: q_base = 4'd7;
            6'd45: q_base = 4'd10;
            6'd46: q_base = 4'd14;
            6'd47: q_base = 4'd7;
            6'd48: q_base = 4'd10;
            6'd49: q_base = 4'd9;
            6'd50: q_base = 4'd15;
            
            6'd51: q_base = 4'd5;
            6'd52: q_base = 4'd6;
            6'd53: q_base = 4'd0;
            6'd54: q_base = 4'd8;
            6'd55: q_base = 4'd15;
            6'd56: q_base = 4'd0;
            6'd57: q_base = 4'd14;
            6'd58: q_base = 4'd5;
            6'd59: q_base = 4'd2;
            6'd60: q_base = 4'd9;
            
            6'd61: q_base = 4'd3;
            6'd62: q_base = 4'd2;
            6'd63: q_base = 4'd12;
        endcase
    end
    assign q_masked = q_base ^ m_out;
endmodule
