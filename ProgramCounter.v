`timescale 1ns / 1ps
// Stores the PC. Updates on every positive clock edge. Synchronous reset to 0.
module ProgramCounter (
    input             clk,
    input             reset,
    input      [31:0] pc_next,
    output reg [31:0] pc
);
    initial pc = 32'd0;
    always @(posedge clk) begin
        if (reset) pc <= 32'd0;
        else       pc <= pc_next;
    end
endmodule
