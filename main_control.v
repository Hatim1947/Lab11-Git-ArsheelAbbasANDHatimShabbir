`timescale 1ns / 1ps
// Lab 9 main control, extended with JAL, JALR and LUI (used by the Lab 10 program).
module main_control (
    input  wire [6:0] opcode,
    output reg        RegWrite,
    output reg        ALUSrc,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        MemtoReg,
    output reg        Branch,
    output reg        Jal,
    output reg        Jalr,
    output reg        Lui,
    output reg  [1:0] ALUOp
);
    localparam [6:0] OP_RTYPE  = 7'b0110011;
    localparam [6:0] OP_ITYPE  = 7'b0010011;
    localparam [6:0] OP_LOAD   = 7'b0000011;
    localparam [6:0] OP_STORE  = 7'b0100011;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_JALR   = 7'b1100111;
    localparam [6:0] OP_LUI    = 7'b0110111;

    always @(*) begin
        RegWrite = 1'b0; ALUSrc = 1'b0; MemRead = 1'b0; MemWrite = 1'b0;
        MemtoReg = 1'b0; Branch = 1'b0; Jal = 1'b0; Jalr = 1'b0; Lui = 1'b0;
        ALUOp    = 2'b00;
        case (opcode)
            OP_RTYPE:  begin RegWrite = 1'b1; ALUOp = 2'b10; end
            OP_ITYPE:  begin RegWrite = 1'b1; ALUSrc = 1'b1; end
            OP_LOAD:   begin RegWrite = 1'b1; ALUSrc = 1'b1; MemRead = 1'b1; MemtoReg = 1'b1; end
            OP_STORE:  begin ALUSrc = 1'b1; MemWrite = 1'b1; end
            OP_BRANCH: begin Branch = 1'b1; ALUOp = 2'b01; end
            OP_JAL:    begin RegWrite = 1'b1; Jal = 1'b1; end
            OP_JALR:   begin RegWrite = 1'b1; ALUSrc = 1'b1; Jalr = 1'b1; end  // target = rs1 + imm
            OP_LUI:    begin RegWrite = 1'b1; ALUSrc = 1'b1; Lui = 1'b1; end   // 0 + immU
            default: ;
        endcase
    end
endmodule
