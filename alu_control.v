`timescale 1ns / 1ps
//==============================================================================
// alu_control.v
//==============================================================================
module alu_control (
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] ALUControl
);

    localparam [3:0] ALU_AND = 4'b0000;
    localparam [3:0] ALU_OR  = 4'b0001;
    localparam [3:0] ALU_ADD = 4'b0010;
    localparam [3:0] ALU_SLL = 4'b0011;
    localparam [3:0] ALU_SRL = 4'b0100;
    localparam [3:0] ALU_XOR = 4'b0101;
    localparam [3:0] ALU_SUB = 4'b0110;

    always @(*) begin
        ALUControl = ALU_ADD;                 // safe default
        case (ALUOp)
            2'b00:   ALUControl = ALU_ADD;    // LW/LH/LB/SW/SH/SB/ADDI
            2'b01:   ALUControl = ALU_SUB;    // BEQ
            2'b10: begin                      // R-type
                case (funct3)
                    3'b000:  ALUControl = funct7[5] ? ALU_SUB : ALU_ADD;
                    3'b001:  ALUControl = ALU_SLL;
                    3'b100:  ALUControl = ALU_XOR;
                    3'b101:  ALUControl = ALU_SRL;
                    3'b110:  ALUControl = ALU_OR;
                    3'b111:  ALUControl = ALU_AND;
                    default: ALUControl = ALU_ADD;  // funct3 not supported
                endcase
            end
            default: ALUControl = ALU_ADD;    // 2'b11 unused
        endcase
    end

endmodule
