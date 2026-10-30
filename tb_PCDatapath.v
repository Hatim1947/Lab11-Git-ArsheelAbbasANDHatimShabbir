`timescale 1ns/1ps
module tb_PCDatapath;
    reg clk = 0, reset = 1, PCSrc = 0;
    reg [31:0] instr = 0;
    wire [31:0] pc, pc_plus4, imm, br_target, pc_next;
    integer errors = 0;

    ProgramCounter u_pc (.clk(clk), .reset(reset), .pc_next(pc_next), .pc(pc));
    pcAdder        u_p4 (.pc(pc), .pc_plus4(pc_plus4));
    immGen         u_im (.instr(instr), .imm(imm));
    branchAdder    u_br (.pc(pc), .imm(imm), .target(br_target));
    mux2 #(32)     u_mx (.d0(pc_plus4), .d1(br_target), .sel(PCSrc), .y(pc_next));

    always #5 clk = ~clk;

    task check(input [31:0] got, input [31:0] exp);
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("FAIL t=%0t got=%h exp=%h", $time, got, exp);
            end else
                $display("PASS t=%0t val=%h", $time, got);
        end
    endtask

    initial begin
        $dumpfile("tb_PCDatapath.vcd");
        $dumpvars(0, tb_PCDatapath);

        // reset
        @(negedge clk); @(negedge clk);
        reset = 0; PCSrc = 0;
        #1 check(pc, 32'd0);

        // sequential, PCSrc = 0
        @(posedge clk); #1 check(pc, 32'd4);
        @(posedge clk); #1 check(pc, 32'd8);
        @(posedge clk); #1 check(pc, 32'd12);

        // forward branch: beq x1,x2,+8 at pc=12 -> 20
        @(negedge clk);
        instr = 32'h00208463; PCSrc = 1;
        #1 check(imm, 32'd4);
        #1 check(br_target, 32'd20);
        @(posedge clk); #1 check(pc, 32'd20);

        // backward branch: beq x1,x2,-8 at pc=20 -> 12
        @(negedge clk);
        instr = 32'hFE208CE3; PCSrc = 1;
        #1 check(imm, 32'hFFFFFFFC);
        #1 check(br_target, 32'd12);
        @(posedge clk); #1 check(pc, 32'd12);

        // back to sequential
        @(negedge clk); PCSrc = 0;
        @(posedge clk); #1 check(pc, 32'd16);

        // immGen: I, S, S negative
        PCSrc = 0;
        instr = 32'hFFF00093; #1 check(imm, 32'hFFFFFFFF);   // addi x1,x0,-1
        instr = 32'h00500093; #1 check(imm, 32'd5);          // addi x1,x0,5
        instr = 32'h0020A423; #1 check(imm, 32'd8);          // sw x2,8(x1)
        instr = 32'hFE20AE23; #1 check(imm, 32'hFFFFFFFC);   // sw x2,-4(x1)
        // extras used by the Lab 10 program
        instr = 32'h002622B7; #1 check(imm, 32'h00262000);   // lui t0,0x262
        instr = 32'h008000EF; #1 check(imm, 32'd4);          // jal ra,+8   (halved)
        instr = 32'hFE5FF06F; #1 check(imm, 32'hFFFFFFF2);   // jal x0,-28  (halved)

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
