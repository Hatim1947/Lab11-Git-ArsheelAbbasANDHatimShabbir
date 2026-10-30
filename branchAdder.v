`timescale 1ns / 1ps
// PC + (sign-extended immediate << 1)
// immGen delivers B/J immediates WITHOUT the implicit zero bit, so the
// single "<< 1" lives here (the "Shift left 1" box in the lab diagram).
module branchAdder (
    input  [31:0] pc,
    input  [31:0] imm,
    output [31:0] target
);
    assign target = pc + (imm << 1);
endmodule
