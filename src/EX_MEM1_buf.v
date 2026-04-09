module EX_MEM1_buf(
    input clk, reset,

    // Control — MEM
    input  mem_read_in, mem_write_in,
    // Control — WB
    input  RegWrite_in,
    input  [1:0] MemtoReg_in,
    
    // Data
    input  [31:0] alu_res_in, RD2_in, PC_plus4_in,
    input  [4:0]  rd_in,
    input  [2:0]  funct3_in,
    
    // Control signals out — MEM
    output reg mem_read_out, mem_write_out,
    // Control signals out — WB
    output reg RegWrite_out,
    output reg [1:0] MemtoReg_out,
    
    // Data out
    output reg [31:0] alu_res_out, RD2_out, PC_plus4_out,
    output reg [4:0]  rd_out,
    output reg [2:0]  funct3_out
);
    always @(posedge clk) begin
        if (reset) begin
            mem_read_out  <= 0; mem_write_out <= 0;
            RegWrite_out  <= 0; MemtoReg_out  <= 2'b00;
            alu_res_out   <= 32'b0; RD2_out      <= 32'b0;
            PC_plus4_out  <= 32'b0;
            rd_out        <= 5'b0; funct3_out   <= 3'b0;
        end else begin
            mem_read_out  <= mem_read_in;  mem_write_out <= mem_write_in;
            RegWrite_out  <= RegWrite_in;  MemtoReg_out  <= MemtoReg_in;
            alu_res_out   <= alu_res_in;   RD2_out       <= RD2_in;
            PC_plus4_out  <= PC_plus4_in;
            rd_out        <= rd_in;        funct3_out    <= funct3_in;
        end
    end
endmodule