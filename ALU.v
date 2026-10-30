`timescale 1ns / 1ps
// ALU. Opcodes are the ones produced by Lab 9's alu_control.
// (The Lab 6 ALU used a different numbering: ADD=0000, SUB=0001, ... so it
//  cannot be dropped in next to alu_control unchanged.)
module ALU (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  ALUControl,
    output reg  [31:0] ALUResult,
    output wire        Zero
);
    localparam [3:0] ALU_AND = 4'b0000,
                     ALU_OR  = 4'b0001,
                     ALU_ADD = 4'b0010,
                     ALU_SLL = 4'b0011,
                     ALU_SRL = 4'b0100,
                     ALU_XOR = 4'b0101,
                     ALU_SUB = 4'b0110;

    always @(*) begin
        case (ALUControl)
            ALU_AND: ALUResult = A & B;
            ALU_OR:  ALUResult = A | B;
            ALU_ADD: ALUResult = A + B;
            ALU_SLL: ALUResult = A << B[4:0];
            ALU_SRL: ALUResult = A >> B[4:0];
            ALU_XOR: ALUResult = A ^ B;
            ALU_SUB: ALUResult = A - B;
            default: ALUResult = 32'b0;
        endcase
    end
    assign Zero = (ALUResult == 32'b0);
endmodule
