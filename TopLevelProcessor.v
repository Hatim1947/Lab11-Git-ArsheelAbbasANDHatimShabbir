`timescale 1ns / 1ps
//==================================================================
// TopLevelProcessor : modular single-cycle RV32I processor + Basys 3 I/O
//
//   clk (100 MHz) -> clockDivider -> cpu_clk (10 MHz)
//   PC -> instructionMemory -> main_control / immGen / RegisterFile
//   RegisterFile / immGen -> ALU -> dataMemory or memory-mapped I/O
//
//   btnC : memory-mapped RESET button read by the program
//   btnU : processor hardware reset (PC = 0)
//   SIM_FAST = 1 : shortens the 1 s delay (simulation only, keep 0 for FPGA)
//
//   Port names are the same as lab10_top, so lab10's XDC pin mapping is reused.
//==================================================================
module TopLevelProcessor #(
    parameter SIM_FAST = 0
)(
    input         clk,
    input         btnC,
    input         btnU,
    input  [15:0] sw,
    output [15:0] led
);
    //---------------- 10 MHz processor clock ----------------
    wire cpu_clk;
    clockDivider #(.DIV(10), .USE_BUFG(SIM_FAST ? 0 : 1)) u_clkdiv (
        .clk_in (clk),
        .clk_out(cpu_clk)
    );

    //---------------- hardware reset synchroniser ----------------
    reg rst_m = 1'b0, rst_s = 1'b0;
    always @(posedge cpu_clk) begin
        rst_m <= btnU;
        rst_s <= rst_m;
    end

    //---------------- datapath wires ----------------
    wire [31:0] pc, pc_plus4, br_target, jalr_target;
    wire [31:0] pc_br_sel, pc_next, instr, imm;
    wire [31:0] rd1, rd2, alu_a, alu_b, alu_result;
    wire [31:0] mem_rdata, wb_alu_mem, wb_data;
    wire        zero, take_branch, PCSrc;

    //---------------- control wires ----------------
    wire        RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch, Jal, Jalr, Lui;
    wire [1:0]  ALUOp;
    wire [3:0]  ALUCtrl;

    //---------------- fetch ----------------
    ProgramCounter u_pc   (.clk(cpu_clk), .reset(rst_s), .pc_next(pc_next), .pc(pc));
    pcAdder        u_pcp4 (.pc(pc), .pc_plus4(pc_plus4));

    instructionMemory #(.OPERAND_LENGTH(31), .SIM_FAST(SIM_FAST)) u_imem (
        .instAddress(pc),
        .instruction(instr)
    );

    //---------------- decode ----------------
    main_control u_ctrl (
        .opcode  (instr[6:0]),
        .RegWrite(RegWrite), .ALUSrc(ALUSrc), .MemRead(MemRead), .MemWrite(MemWrite),
        .MemtoReg(MemtoReg), .Branch(Branch), .Jal(Jal), .Jalr(Jalr), .Lui(Lui),
        .ALUOp   (ALUOp)
    );

    immGen u_imm (.instr(instr), .imm(imm));

    RegisterFile u_rf (
        .clk(cpu_clk), .rst(rst_s), .WriteEnable(RegWrite),
        .rs1(instr[19:15]), .rs2(instr[24:20]), .rd(instr[11:7]),
        .WriteData(wb_data), .ReadData1(rd1), .ReadData2(rd2)
    );

    //---------------- execute ----------------
    mux2 #(32) u_alua (.d0(rd1), .d1(32'd0), .sel(Lui),    .y(alu_a));   // lui: 0 + imm
    mux2 #(32) u_alub (.d0(rd2), .d1(imm),   .sel(ALUSrc), .y(alu_b));

    alu_control u_aluc (.ALUOp(ALUOp), .funct3(instr[14:12]), .funct7(instr[31:25]),
                        .ALUControl(ALUCtrl));

    ALU u_alu (.A(alu_a), .B(alu_b), .ALUControl(ALUCtrl), .ALUResult(alu_result), .Zero(zero));

    //---------------- next PC ----------------
    branchAdder u_br (.pc(pc), .imm(imm), .target(br_target));

    // beq: take when Zero.  bne: take when !Zero.  (other branch types not supported)
    assign take_branch = Branch & (((instr[14:12] == 3'b000) &  zero) |
                                   ((instr[14:12] == 3'b001) & ~zero));
    assign PCSrc       = take_branch | Jal;

    mux2 #(32) u_pcsrc (.d0(pc_plus4),  .d1(br_target),   .sel(PCSrc), .y(pc_br_sel));
    assign jalr_target = {alu_result[31:1], 1'b0};
    mux2 #(32) u_jalr  (.d0(pc_br_sel), .d1(jalr_target), .sel(Jalr),  .y(pc_next));

    //---------------- memory / I/O ----------------
    wire sel_ram, sel_led, sel_sw, sel_rst;
    addressDecoder u_dec (
        .addr(alu_result),
        .sel_ram(sel_ram), .sel_led(sel_led), .sel_sw(sel_sw), .sel_rst(sel_rst)
    );

    wire [31:0] ramData;
    dataMemory u_dmem (
        .clk(cpu_clk), .memWrite(MemWrite & sel_ram),
        .address(alu_result), .writeData(rd2), .readData(ramData)
    );

    wire [15:0] sw_sync, led_out;
    wire        btn_sync;
    ioInterface u_io (
        .clk(cpu_clk), .sw_in(sw), .btn_in(btnC),
        .ledWrite(MemWrite & sel_led), .ledData(rd2[15:0]),
        .sw_sync(sw_sync), .btn_sync(btn_sync), .led_out(led_out)
    );
    assign led = led_out;

    assign mem_rdata = sel_ram ? ramData :
                       sel_sw  ? {16'd0, sw_sync} :
                       sel_rst ? {31'd0, btn_sync} :
                       sel_led ? {16'd0, led_out} : 32'd0;

    //---------------- write back ----------------
    mux2 #(32) u_memtoreg (.d0(alu_result), .d1(mem_rdata), .sel(MemtoReg),   .y(wb_alu_mem));
    mux2 #(32) u_link     (.d0(wb_alu_mem), .d1(pc_plus4),  .sel(Jal | Jalr), .y(wb_data));
endmodule
