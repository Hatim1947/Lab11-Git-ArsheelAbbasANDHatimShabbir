`timescale 1ns / 1ps
// 2-to-1 mux: sel = 0 -> d0, sel = 1 -> d1
module mux2 #(parameter WIDTH = 32)(
    input  [WIDTH-1:0] d0,
    input  [WIDTH-1:0] d1,
    input              sel,
    output [WIDTH-1:0] y
);
    assign y = sel ? d1 : d0;
endmodule
