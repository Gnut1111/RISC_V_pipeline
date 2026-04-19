
`timescale 1ns/1ps


module ID_EX_buf(
    input clk, reset, flush,
    
    // Control signals
    input  Branch_in, MemRead_in, MemWrite_in, Jump_in,
           ALUSrc_in, RegWrite_in, JALR_in, ALUSrcA_in,
    input  [1:0] ALUOp_in, MemtoReg_in,
    
    // Data signals
    input  [2:0]  funct3_in,
    input         funct7b5_in, opb5_in,
    input  [31:0] RD1_in, RD2_in, imm_in, PC_in, PC_plus4_in,
    input  [4:0]  rs1_in, rs2_in, rd_in,   // ← bạn thiếu 3 cái này
    
    // Control signals out
    output reg Branch_out, MemRead_out, MemWrite_out, Jump_out,
               ALUSrc_out, RegWrite_out, JALR_out, ALUSrcA_out,
    output reg [1:0] ALUOp_out, MemtoReg_out,
    
    // Data signals out
    output reg [2:0]  funct3_out,
    output reg        funct7b5_out, opb5_out,
    output reg [31:0] RD1_out, RD2_out, imm_out, PC_out, PC_plus4_out,
    output reg [4:0]  rs1_out, rs2_out, rd_out  // ← bạn thiếu 3 cái này
);
    always @(posedge clk) begin
        if (reset || flush) begin
            // Clear control
            Branch_out   <= 0; MemRead_out  <= 0;
            MemWrite_out <= 0; Jump_out     <= 0;
            ALUSrc_out   <= 0; RegWrite_out <= 0;
            JALR_out     <= 0; ALUSrcA_out  <= 0;
            ALUOp_out    <= 2'b00; MemtoReg_out <= 2'b00;
            // Clear data
            funct3_out   <= 3'b0;
            funct7b5_out <= 0; opb5_out <= 0;
            RD1_out      <= 32'b0; RD2_out     <= 32'b0;
            imm_out      <= 32'b0; PC_out      <= 32'b0;
            PC_plus4_out <= 32'b0;
            rs1_out      <= 5'b0; rs2_out <= 5'b0; rd_out <= 5'b0;
        end else begin
            // Pass control
            Branch_out   <= Branch_in;   MemRead_out  <= MemRead_in;
            MemWrite_out <= MemWrite_in; Jump_out     <= Jump_in;
            ALUSrc_out   <= ALUSrc_in;   RegWrite_out <= RegWrite_in;
            JALR_out     <= JALR_in;     ALUSrcA_out  <= ALUSrcA_in;
            ALUOp_out    <= ALUOp_in;    MemtoReg_out <= MemtoReg_in;
            // Pass data
            funct3_out   <= funct3_in;
            funct7b5_out <= funct7b5_in; opb5_out <= opb5_in;
            RD1_out      <= RD1_in;      RD2_out     <= RD2_in;
            imm_out      <= imm_in;      PC_out      <= PC_in;
            PC_plus4_out <= PC_plus4_in;
            rs1_out      <= rs1_in; rs2_out <= rs2_in; rd_out <= rd_in;
        end
    end
endmodule