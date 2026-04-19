module Risc_v(
    input        clk,
    input         reset,

    output [31:0] alu_out, mem_out, WB_out
);

wire [31:0] pc, pc_next, pc_plus_4, instr;

wire stallF, stallD, flushE, flushD; // Tín hiệu stall và flush từ hazard detection unit

PC pc_inst (
    .clk(clk),
    .reset(reset),
    .enable(!stallF), // Luôn enable để PC có thể cập nhật
    .pc_next(pc_next), 
    .pc(pc)
);

PC_Plus_4 pc_plus_4_inst (
    .PC(pc),
    .PCPlus4(pc_plus_4)
);

wire [31:0] instr_raw;
i_mem i_mem_inst (
    .clk(clk),
    .we(1'b0), // Chỉ đọc từ IMEM
    .cs(~stallF), // Kích hoạt đọc từ IMEM
    .address(pc), // Đọc instruction tại PC+4
    .instr(instr_raw)
);
wire PCSrc;
reg PCSrc_dly;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        PCSrc_dly <= 1'b0;
    end else begin
        // IMEM đồng bộ trả dữ liệu trễ 1 chu kỳ, nên cần kill thêm 1 instr sau redirect
        PCSrc_dly <= PCSrc;
    end
end

reg [31:0] pc_if_dly, pc_plus4_if_dly;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        pc_if_dly <= 32'b0;
        pc_plus4_if_dly <= 32'b0;
    end else if (~stallF) begin
        // Đệm PC/PC+4 1 chu kỳ để đồng bộ với instr_raw từ IMEM đồng bộ
        pc_if_dly <= pc;
        pc_plus4_if_dly <= pc_plus_4;
    end
end

wire [31:0] instr_ifid_in;
assign instr_ifid_in = PCSrc_dly ? 32'h00000013 : instr_raw;

wire [31:0] PC_out_if_id_buf, PC_plus_4_out_if_id_buf;
IF_ID_buf if_id_buf_inst (
    .clk(clk),
    .reset(reset),
    .enable(~stallD), // Stall IF/ID khi cần thiết
    .flush(flushD), // Flush ID khi cần thiết
    .PC_in(pc_if_dly),
    .PC_plus_4_in(pc_plus4_if_dly),
    .instr_in(instr_ifid_in),
    .PC_out(PC_out_if_id_buf),
    .PC_plus_4_out(PC_plus_4_out_if_id_buf),
    .instr_out(instr)
);

wire Branch, MemRead, MemWrite, Jump, ALUSrc, RegWrite, JALR, ALUSrcA;
wire [1:0] ALUOp, MemtoReg;
controller controller_inst (
	.op(instr[6:0]),
	.Branch(Branch),
	.MemRead(MemRead),
	.MemWrite(MemWrite),
	.Jump(Jump),
	.ALUSrc(ALUSrc),
	.RegWrite(RegWrite),
	.JALR(JALR),
	.ALUSrcA(ALUSrcA),
	.ALUOp(ALUOp),
	.MemtoReg(MemtoReg)
);

wire [31:0] imm;
imm_gen imm_gen_inst (
    .op(instr[6:0]),
    .instr(instr[31:7]),
    .imm(imm)
);

wire [31:0] RD1, RD2, WD_WB;

wire RegWrite_out_mem_wb_buf;
wire [4:0] rd_out_mem_wb_buf;
reg_file reg_file_inst (
    .RegWrite(RegWrite_out_mem_wb_buf), // Sử dụng tín hiệu RegWrite đã qua pipeline register
    .clk(clk),
    .reset(reset),
    .RA1(instr[19:15]),
    .RA2(instr[24:20]),
    .WA(rd_out_mem_wb_buf),
    .WD(WD_WB),
    .RD1(RD1),
    .RD2(RD2)
);

wire [4:0] rd_out_ex_mem_buf;

wire Branch_out_id_ex_buf , MemRead_out_id_ex_buf, MemWrite_out_id_ex_buf, Jump_out_id_ex_buf, ALUSrc_out_id_ex_buf, RegWrite_out_id_ex_buf, JALR_out_id_ex_buf, ALUSrcA_out_id_ex_buf;
wire [1:0] ALUOp_out_id_ex_buf, MemtoReg_out_id_ex_buf;
wire [2:0] funct3_out_id_ex_buf;
wire funct7b5_out_id_ex_buf, opb5_out_id_ex_buf;
wire [31:0] RD1_out_id_ex_buf, RD2_out_id_ex_buf, imm_out_id_ex_buf, PC_out_id_ex_buf, PC_plus4_out_id_ex_buf;
wire [4:0] rs1_out_id_ex_buf, rs2_out_id_ex_buf, rd_out_id_ex_buf;
ID_EX_buf id_ex_buf_inst (
    .clk(clk),
    .reset(reset),
    .flush(flushE), // Flush EX khi cần thiết
    
    // Control signals
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

    // Data signals
    .funct3_in(instr[14:12]),
    .funct7b5_in(instr[30]),
    .opb5_in(instr[5]),
    .RD1_in(RD1),
    .RD2_in(RD2),
    .imm_in(imm),
    .PC_in(PC_out_if_id_buf),
    .PC_plus4_in(PC_plus_4_out_if_id_buf),
    .rs1_in(instr[19:15]),
    .rs2_in(instr[24:20]),
    .rd_in(instr[11:7]),

    // Control signals out
    .Branch_out(Branch_out_id_ex_buf),
    .MemRead_out(MemRead_out_id_ex_buf),
    .MemWrite_out(MemWrite_out_id_ex_buf),
    .Jump_out(Jump_out_id_ex_buf),
    .ALUSrc_out(ALUSrc_out_id_ex_buf),
    .RegWrite_out(RegWrite_out_id_ex_buf),
    .JALR_out(JALR_out_id_ex_buf),
    .ALUSrcA_out(ALUSrcA_out_id_ex_buf),
    .ALUOp_out(ALUOp_out_id_ex_buf),
    .MemtoReg_out(MemtoReg_out_id_ex_buf),

    // Data signals out
    .funct3_out(funct3_out_id_ex_buf),
    .funct7b5_out(funct7b5_out_id_ex_buf),
    .opb5_out(opb5_out_id_ex_buf),
    .RD1_out(RD1_out_id_ex_buf),
    .RD2_out(RD2_out_id_ex_buf),
    .imm_out(imm_out_id_ex_buf),
    .PC_out(PC_out_id_ex_buf),
    .PC_plus4_out(PC_plus4_out_id_ex_buf),
    .rs1_out(rs1_out_id_ex_buf),
    .rs2_out(rs2_out_id_ex_buf),
    .rd_out(rd_out_id_ex_buf)
);

wire [1:0] ForwardA, ForwardB;
wire [31:0] SrcA_fwd, SrcB_fwd, SrcA, SrcB, alu_res_out_ex_mem_buf;
Mux_3 ForwardA_Mux (
    .A(RD1_out_id_ex_buf),
    .B(alu_res_out_ex_mem_buf),
    .C(WD_WB),
    .ctrl_signal(ForwardA),
    .Mux3_res(SrcA_fwd)
);
Mux_2 SrcA_Mux (
    .A(SrcA_fwd),
    .B(PC_out_id_ex_buf),
    .ctrl_signal(ALUSrcA_out_id_ex_buf),
    .Mux_res(SrcA)
);


Mux_3 mux_forwardB (
    .A(RD2_out_id_ex_buf),
    .B(alu_res_out_ex_mem_buf),
    .C(WD_WB),
    .ctrl_signal(ForwardB),
    .Mux3_res(SrcB_fwd)
);
Mux_2 SrcB_Mux (
    .A(SrcB_fwd),
    .B(imm_out_id_ex_buf),
    .ctrl_signal(ALUSrc_out_id_ex_buf),
    .Mux_res(SrcB)
);

wire [3:0] ALUControl;
ALU_controller alu_controller_inst (
	.ALUOp(ALUOp_out_id_ex_buf),
	.func3(funct3_out_id_ex_buf),
	.func7b5(funct7b5_out_id_ex_buf),
	.opb5(opb5_out_id_ex_buf),
	.ALUControl(ALUControl)
);

wire [31:0] ALU_res;
wire Zero, slt, sltu;
ALU ALU_inst (
	.A(SrcA),
	.B(SrcB),
	.ALUControl(ALUControl),
	.ALU_res(ALU_res),
	.Zero(Zero),
	.slt(slt),
	.sltu(sltu)
);

wire [31:0] Src_adder;
Mux_2 Src_adder_mux2 (
    .A(PC_out_id_ex_buf),
    .B(SrcA_fwd),
    .ctrl_signal(JALR_out_id_ex_buf),
    .Mux_res(Src_adder)
);

wire [31:0] Res_adder;
adder adder_inst (
	.a(Src_adder),
    .b(imm_out_id_ex_buf),
    .res(Res_adder)
);

jump_control jump_control_inst (
	.Branch(Branch_out_id_ex_buf),
	.Jump(Jump_out_id_ex_buf),
	.func3(funct3_out_id_ex_buf),
	.Zero(Zero),
	.slt(slt),
	.sltu(sltu),
	.PCSrc(PCSrc)
);

Mux_2 PCSrc_mux (
    .A(pc_plus_4),
    .B(Res_adder),
    .ctrl_signal(PCSrc),
    .Mux_res(pc_next)
);

wire mem_read_out_ex_mem_buf, mem_write_out_ex_mem_buf, RegWrite_out_ex_mem_buf;
wire [1:0] MemtoReg_out_ex_mem_buf;
wire [31:0] RD2_out_ex_mem_buf, PC_plus4_out_ex_mem_buf;
wire [2:0] funct3_out_ex_mem_buf;
EX_MEM1_buf ex_mem1_buf_inst (
    .clk(clk), .reset(reset),

    // Control — MEM
    .mem_read_in(MemRead_out_id_ex_buf),
    .mem_write_in(MemWrite_out_id_ex_buf),
    // Control — WB
    .RegWrite_in(RegWrite_out_id_ex_buf),
    .MemtoReg_in(MemtoReg_out_id_ex_buf),

    // Data
    .alu_res_in(ALU_res),
    .RD2_in(SrcB_fwd),
    .PC_plus4_in(PC_plus4_out_id_ex_buf),
    .rd_in(rd_out_id_ex_buf),
    .funct3_in(funct3_out_id_ex_buf),

    // Control signals out — MEM
    .mem_read_out(mem_read_out_ex_mem_buf),
    .mem_write_out(mem_write_out_ex_mem_buf),
    // Control signals out — WB
    .RegWrite_out(RegWrite_out_ex_mem_buf),
    .MemtoReg_out(MemtoReg_out_ex_mem_buf),

    // Data out
    .alu_res_out(alu_res_out_ex_mem_buf),
    .RD2_out(RD2_out_ex_mem_buf),
    .PC_plus4_out(PC_plus4_out_ex_mem_buf),
    .rd_out(rd_out_ex_mem_buf),
    .funct3_out(funct3_out_ex_mem_buf)
);

wire [3:0] wmask;
dmem_wmask_gen dmem_wmask_gen_inst (
    .funct3(funct3_out_ex_mem_buf),
    .byte_offset(alu_res_out_ex_mem_buf[1:0]),
    .mem_write(mem_write_out_ex_mem_buf),
    .wmask(wmask)
);

wire [31:0] rdata;
d_mem d_mem_inst (
    .clk(clk),
    .we(mem_write_out_ex_mem_buf),
    .addr(alu_res_out_ex_mem_buf),
    .wdata(RD2_out_ex_mem_buf),
    .rdata(rdata)
);

wire [31:0] alu_res_out_mem_wb_buf, PC_plus4_out_mem_wb_buf, d_mem_res_out_mem_wb_buf;
wire [1:0] MemtoReg_out_mem_wb_buf;
wire [2:0] funct3_out_mem_wb_buf;
MEM2_WB_buf mem2_wb_buf_inst (
    .clk(clk),
    .reset(reset),
    // Data
    .alu_res_in(alu_res_out_ex_mem_buf),
    .PC_plus4_in(PC_plus4_out_ex_mem_buf),
    .d_mem_res_in(),
    .rd_in(rd_out_ex_mem_buf),
    .funct3_in(funct3_out_ex_mem_buf),
    // Control
    .RegWrite_in(RegWrite_out_ex_mem_buf),
    .MemtoReg_in(MemtoReg_out_ex_mem_buf),
    // Data out
    .alu_res_out(alu_res_out_mem_wb_buf),
    .PC_plus4_out(PC_plus4_out_mem_wb_buf),
    .d_mem_res_out(),
    .rd_out(rd_out_mem_wb_buf),
    .funct3_out(funct3_out_mem_wb_buf),
    // Control out
    .RegWrite_out(RegWrite_out_mem_wb_buf),
    .MemtoReg_out(MemtoReg_out_mem_wb_buf)
);

wire [31:0] rdata_decoded;
dmem_decode dmem_decode_inst (
    .word_data(rdata),     // raw word từ SRAM
    .funct3(funct3_out_mem_wb_buf),        // từ pipeline register
    .byte_offset(alu_res_out_mem_wb_buf[1:0]),   // addr[1:0] từ pipeline register
    .rd(rdata_decoded)         // data đã decode
);

Mux_3 MemtoReg_mux (
    .A(alu_res_out_mem_wb_buf),
    .B(rdata_decoded), // Dữ liệu thô từ SRAM (chưa decode)
    .C(PC_plus4_out_mem_wb_buf),
    .ctrl_signal(MemtoReg_out_mem_wb_buf),
    .Mux3_res(WD_WB)
);


forwarding_unit forwarding_unit_inst (
    .ID_EX_rs1(rs1_out_id_ex_buf),
    .ID_EX_rs2(rs2_out_id_ex_buf),
    .EX_MEM1_RegWrite(RegWrite_out_ex_mem_buf),
    .EX_MEM1_rd(rd_out_ex_mem_buf),

    .MEM2_WB_RegWrite(RegWrite_out_mem_wb_buf),
    .MEM2_WB_rd(rd_out_mem_wb_buf),

    .ForwardA(ForwardA),
    .ForwardB(ForwardB)
);

hazard_detection hazard_detection_inst (
    .ID_EX_MemRead(MemRead_out_id_ex_buf),
    .PCSrc(PCSrc),
    .ID_EX_rd(rd_out_id_ex_buf),
    .IF_ID_rs1(instr[19:15]), // Lấy trực tiếp từ IF/ID vì hazard detection cần thông tin này sớm
    .IF_ID_rs2(instr[24:20]),
    .stallF(stallF),
    .stallD(stallD),
    .flushE(flushE),
    .flushD(flushD)
);
reg [31:0] alu_out_reg, mem_out_reg, WB_out_reg;
always @(posedge clk) begin
    alu_out_reg <= ALU_res;
	 mem_out_reg <= rdata_decoded;
	 WB_out_reg <= WD_WB;
end
assign alu_out = alu_out_reg;
assign mem_out = mem_out_reg;
assign WB_out = WB_out_reg;
endmodule
