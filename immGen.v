`timescale 1ns / 1ps
// Immediate generator (RV32I)
//   I-type (addi, lw, jalr) : imm[11:0]  sign-extended
//   S-type (sw)             : imm[11:0]  sign-extended
//   B-type (beq, bne)       : imm[12:1]  sign-extended   (no trailing 0, branchAdder shifts)
//   J-type (jal)            : imm[20:1]  sign-extended   (no trailing 0, branchAdder shifts)
//   U-type (lui)            : imm[31:12] << 12
// I, S and B are what the lab asks for. J and U are needed because the
// Lab 10 program uses jal and lui.
module immGen (
    input      [31:0] instr,
    output reg [31:0] imm
);
    always @(*) begin
        case (instr[6:0])
            7'b0010011,                         // OP-IMM (addi)
            7'b0000011,                         // LOAD   (lw)
            7'b1100111:                         // JALR
                imm = {{20{instr[31]}}, instr[31:20]};
            7'b0100011:                         // STORE  (sw)
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            7'b1100011:                         // BRANCH (beq, bne)
                imm = {{20{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8]};
            7'b1101111:                         // JAL
                imm = {{12{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21]};
            7'b0110111:                         // LUI
                imm = {instr[31:12], 12'b0};
            default: imm = 32'd0;
        endcase
    end
endmodule
