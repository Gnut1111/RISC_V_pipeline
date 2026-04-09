module Risc_v(
    input clk, reset,
    output [31:0] out_mem, out_alu, out_rs2
);

// ====================== IF Stage ======================
    wire [31:0] pc_next, pc, pcplus4, instr;
    wire PCSrc, stall;

    PC PC(
        .clk(clk),
        .reset(reset),
        .enable(~stall),
        .pc_next(pc_next),
        .pc(pc)
    );

    PC_Plus_4 plus_4(
        .PC(pc),
        .PCPlus4(pcplus4)
    );

    i_mem i_mem(
        .address(pc),
        .instr(instr)
    );

// ====================== IF/ID Buffer ======================
    wire [31:0] PC_out_IF, PC_plus4_out_IF, instr_out_IF;

    IF_ID_buf IF_ID(
        .clk(clk),
        .reset(reset),
        .enable(~stall),
        .flush(PCSrc),
        .PC_in(pc),
        .PC_plus_4_in(pcplus4),
        .instr_in(instr),
        .PC_out(PC_out_IF),
        .PC_plus_4_out(PC_plus4_out_IF),
        .instr_out(instr_out_IF)
    );

// ====================== ID Stage ======================
    wire Branch, MemRead, MemWrite, Jump,
         ALUSrc, RegWrite, JALR, ALUSrcA;
    wire [1:0] ALUOp, MemtoReg;

    controller control(
        .op(instr_out_IF[6:0]),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Jump(Jump),
        .ALUSrc(ALUSrc),
        .ALUSrcA(ALUSrcA),
        .RegWrite(RegWrite),
        .JALR(JALR),
        .ALUOp(ALUOp),
        .MemtoReg(MemtoReg)
    );

    wire [31:0] imm;
    imm_gen imm_gen(
        .op(instr_out_IF[6:0]),
        .instr(instr_out_IF[31:7]),
        .imm(imm)
    );

    wire [31:0] write_data_regfile;
    wire [4:0]  rd_out_WB;
    wire        RegWrite_out_WB;

    wire [31:0] RD1, RD2;
    reg_file reg_file(
        .clk(clk),
        .RegWrite(RegWrite_out_WB),
        .RA1(instr_out_IF[19:15]),
        .RA2(instr_out_IF[24:20]),
        .WA(rd_out_WB),
        .WD(write_data_regfile),
        .RD1(RD1),
        .RD2(RD2)
    );

// ====================== ID/EX Buffer ======================
    wire Branch_out_ID, MemRead_out_ID, MemWrite_out_ID, Jump_out_ID,
         ALUSrc_out_ID, RegWrite_out_ID, JALR_out_ID, ALUSrcA_out_ID;
    wire [1:0] ALUOp_out_ID, MemtoReg_out_ID;
    wire [2:0] funct3_out_ID;
    wire       funct7b5_out_ID, opb5_out_ID;
    wire [31:0] RD1_out_ID, RD2_out_ID, imm_out_ID, PC_out_ID, PC_plus4_out_ID;
    wire [4:0]  rs1_out_ID, rs2_out_ID, rd_out_ID;

    ID_EX_buf ID_EX(
        .clk(clk),
        .reset(reset),
        .enable(~stall),
        .flush(PCSrc | stall),
        // Control in
        .Branch_in(Branch),
        .MemRead_in(MemRead),
        .MemWrite_in(MemWrite),
        .Jump_in(Jump),
        .ALUSrc_in(ALUSrc),
        .RegWrite_in(RegWrite),
        .JALR_in(JALR),
        .ALUSrcA_in(ALUSrcA),
        .ALUOp_in(ALUOp),
        .MemtoReg_in(MemtoReg),
        // Data in
        .funct3_in(instr_out_IF[14:12]),
        .funct7b5_in(instr_out_IF[30]),
        .opb5_in(instr_out_IF[5]),
        .RD1_in(RD1),
        .RD2_in(RD2),
        .imm_in(imm),
        .PC_in(PC_out_IF),
        .PC_plus4_in(PC_plus4_out_IF),
        .rs1_in(instr_out_IF[19:15]),
        .rs2_in(instr_out_IF[24:20]),
        .rd_in(instr_out_IF[11:7]),
        // Control out
        .Branch_out(Branch_out_ID),
        .MemRead_out(MemRead_out_ID),
        .MemWrite_out(MemWrite_out_ID),
        .Jump_out(Jump_out_ID),
        .ALUSrc_out(ALUSrc_out_ID),
        .RegWrite_out(RegWrite_out_ID),
        .JALR_out(JALR_out_ID),
        .ALUSrcA_out(ALUSrcA_out_ID),
        .ALUOp_out(ALUOp_out_ID),
        .MemtoReg_out(MemtoReg_out_ID),
        // Data out
        .funct3_out(funct3_out_ID),
        .funct7b5_out(funct7b5_out_ID),
        .opb5_out(opb5_out_ID),
        .RD1_out(RD1_out_ID),
        .RD2_out(RD2_out_ID),
        .imm_out(imm_out_ID),
        .PC_out(PC_out_ID),
        .PC_plus4_out(PC_plus4_out_ID),
        .rs1_out(rs1_out_ID),
        .rs2_out(rs2_out_ID),
        .rd_out(rd_out_ID)
    );

// ====================== EX Stage ======================

    wire [1:0] ForwardA, ForwardB;
	 wire [1:0]  MemtoReg_out_MEM1;
	 wire [31:0] d_mem_res;
	 
    wire [31:0] alu_res_out_EX;

    wire [31:0] alu_res_out_MEM1;
	 
	 wire [31:0] alu_res_out_WB, PC_plus4_out_WB, d_mem_res_out_WB;
    wire [1:0]  MemtoReg_out_WB;
	 
	 wire [31:0] MEM1_MEM2_result =(MemtoReg_out_MEM1 == 2'b01) ? d_mem_res : alu_res_out_MEM1;
	 wire [31:0] MEM2_WB_result = (MemtoReg_out_WB == 2'b01) ? d_mem_res_out_WB : alu_res_out_WB;

    wire [31:0] SrcA_fwd;
    Mux_4 mux_forwardA(
    .A(RD1_out_ID),
    .B(alu_res_out_EX),
    .C(MEM1_MEM2_result),
    .D(MEM2_WB_result),    
    .ctrl_signal(ForwardA),
    .Mux4_res(SrcA_fwd)
);


    wire [31:0] SrcA;
    Mux_2 mux_srcALU_A(
        .A(SrcA_fwd),          
        .B(PC_out_ID),         
        .ctrl_signal(ALUSrcA_out_ID),
        .Mux_res(SrcA)
    );

    wire [31:0] SrcB_fwd;
    Mux_4 mux_forwardB(
    .A(RD2_out_ID),
    .B(alu_res_out_EX),
    .C(MEM1_MEM2_result),
    .D(MEM2_WB_result),    
    .ctrl_signal(ForwardB),
    .Mux4_res(SrcB_fwd)
);

    wire [31:0] SrcB;
    Mux_2 mux_srcALU_B(
        .A(SrcB_fwd),          
        .B(imm_out_ID),        
        .ctrl_signal(ALUSrc_out_ID),
        .Mux_res(SrcB)
    );

    wire [3:0] ALU_Control;
    ALU_controller alu_ctrl(
        .ALUOp(ALUOp_out_ID),
        .func3(funct3_out_ID),
        .func7b5(funct7b5_out_ID),
        .opb5(opb5_out_ID),
        .ALUControl(ALU_Control)
    );

    wire [31:0] alu_res;
    wire zero_signal, slt_signal, sltu_signal;
    ALU alu(
        .A(SrcA),
        .B(SrcB),
        .ALUControl(ALU_Control),
        .ALU_res(alu_res),
        .Zero(zero_signal),
        .slt(slt_signal),
        .sltu(sltu_signal)
    );

    wire [31:0] Src_add_pc;
    Mux_2 mux_j_type(
        .A(PC_out_ID),         
        .B(SrcA_fwd),          
        .ctrl_signal(JALR_out_ID),
        .Mux_res(Src_add_pc)
    );

    wire [31:0] pc_target;
    adder add(
        .a(Src_add_pc),
        .b(imm_out_ID),
        .res(pc_target)
    );

    wire [31:0] pc_target_jump = JALR_out_ID ? {pc_target[31:1], 1'b0} : pc_target;

    jump_control jump_control(
        .Branch(Branch_out_ID),
        .Jump(Jump_out_ID),
        .func3(funct3_out_ID),
        .Zero(zero_signal),
        .slt(slt_signal),
        .sltu(sltu_signal),
        .PCSrc(PCSrc)
    );

    Mux_2 mux_pc_target(
        .A(pcplus4),
        .B(pc_target_jump),
        .ctrl_signal(PCSrc),
        .Mux_res(pc_next)
    );

// ====================== EX/MEM1 Buffer ======================
    wire mem_read_out_EX, mem_write_out_EX;
    wire RegWrite_out_EX;
    wire [1:0] MemtoReg_out_EX;
    wire [31:0] RD2_out_EX, PC_plus4_out_EX;
    wire [4:0]  rd_out_EX;
    wire [2:0]  funct3_out_EX;

    EX_MEM1_buf EX_MEM1(
        .clk(clk),
        .reset(reset),
        .mem_read_in(MemRead_out_ID),
        .mem_write_in(MemWrite_out_ID),
        .RegWrite_in(RegWrite_out_ID),
        .MemtoReg_in(MemtoReg_out_ID),
        .alu_res_in(alu_res),
        .RD2_in(RD2_out_ID),
        .PC_plus4_in(PC_plus4_out_ID),
        .rd_in(rd_out_ID),
        .funct3_in(funct3_out_ID),
        .mem_read_out(mem_read_out_EX),
        .mem_write_out(mem_write_out_EX),
        .RegWrite_out(RegWrite_out_EX),
        .MemtoReg_out(MemtoReg_out_EX),
        .alu_res_out(alu_res_out_EX),
        .RD2_out(RD2_out_EX),
        .PC_plus4_out(PC_plus4_out_EX),
        .rd_out(rd_out_EX),
        .funct3_out(funct3_out_EX)
    );

// ====================== MEM1 Stage ======================
    d_mem d_mem(
        .clk(clk),
        .mem_read(mem_read_out_EX),
        .mem_write(mem_write_out_EX),
        .funct3(funct3_out_EX),
        .addr(alu_res_out_EX),
        .wd(RD2_out_EX),
        .rd(d_mem_res)
    );

// ====================== MEM1/MEM2 Buffer ======================
    wire [31:0] PC_plus4_out_MEM1;
    wire [4:0]  rd_out_MEM1;
    wire        RegWrite_out_MEM1;

    MEM1_MEM2_buf MEM1_MEM2(
        .clk(clk),
        .reset(reset),
        .alu_res_in(alu_res_out_EX),
        .PC_plus4_in(PC_plus4_out_EX),
        .rd_in(rd_out_EX),
        .RegWrite_in(RegWrite_out_EX),
        .MemtoReg_in(MemtoReg_out_EX),
        .alu_res_out(alu_res_out_MEM1),
        .PC_plus4_out(PC_plus4_out_MEM1),
        .rd_out(rd_out_MEM1),
        .RegWrite_out(RegWrite_out_MEM1),
        .MemtoReg_out(MemtoReg_out_MEM1)
    );

// ====================== MEM2/WB Buffer ======================

    MEM2_WB_buf MEM2_WB(
        .clk(clk),
        .reset(reset),
        .alu_res_in(alu_res_out_MEM1),
        .PC_plus4_in(PC_plus4_out_MEM1),
        .d_mem_res_in(d_mem_res),
        .rd_in(rd_out_MEM1),
        .RegWrite_in(RegWrite_out_MEM1),
        .MemtoReg_in(MemtoReg_out_MEM1),
        .alu_res_out(alu_res_out_WB),
        .PC_plus4_out(PC_plus4_out_WB),
        .d_mem_res_out(d_mem_res_out_WB),
        .rd_out(rd_out_WB),
        .RegWrite_out(RegWrite_out_WB),
        .MemtoReg_out(MemtoReg_out_WB)
    );

// ====================== WB Stage ======================
    Mux_3 mux_mem_to_reg(
        .A(alu_res_out_WB),
        .B(d_mem_res_out_WB),
        .C(PC_plus4_out_WB),
        .ctrl_signal(MemtoReg_out_WB),
        .Mux3_res(write_data_regfile)
    );

// ====================== Hazard Detection ======================
    hazard_detection hazard(
        .ID_EX_MemRead(MemRead_out_ID),
        .ID_EX_rd(rd_out_ID),
        .IF_ID_rs1(instr_out_IF[19:15]),
        .IF_ID_rs2(instr_out_IF[24:20]),
        .stall(stall)
    );

// ====================== Forwarding Unit ======================
    forwarding_unit fwd(
    .ID_EX_rs1(rs1_out_ID),
    .ID_EX_rs2(rs2_out_ID),
    .EX_MEM1_RegWrite(RegWrite_out_EX),
    .EX_MEM1_rd(rd_out_EX),
    .MEM1_MEM2_RegWrite(RegWrite_out_MEM1),
    .MEM1_MEM2_rd(rd_out_MEM1),
    .MEM2_WB_RegWrite(RegWrite_out_WB),    
    .MEM2_WB_rd(rd_out_WB),              
    .ForwardA(ForwardA),
    .ForwardB(ForwardB)
);


    assign out_mem = d_mem_res_out_WB;
    assign out_alu = alu_res_out_WB;
    assign out_rs2 = RD2_out_ID;

endmodule