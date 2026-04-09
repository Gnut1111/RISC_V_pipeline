module MEM2_WB_buf(
    input clk, reset,

    // Data
    input  [31:0] alu_res_in, PC_plus4_in, d_mem_res_in,
    input  [4:0]  rd_in,
    // Control
    input  RegWrite_in,
    input  [1:0] MemtoReg_in,

    // Data out
    output reg [31:0] alu_res_out, PC_plus4_out, d_mem_res_out,
    output reg [4:0]  rd_out,
    // Control out
    output reg RegWrite_out,
    output reg [1:0] MemtoReg_out
);
    always @(posedge clk) begin
        if (reset) begin
            alu_res_out  <= 32'b0;
            PC_plus4_out <= 32'b0;
            d_mem_res_out <= 32'b0;
            rd_out       <= 5'b0;
            RegWrite_out <= 0;
            MemtoReg_out <= 2'b00;
        end else begin
            alu_res_out  <= alu_res_in;
            PC_plus4_out <= PC_plus4_in;
            d_mem_res_out <= d_mem_res_in;
            rd_out       <= rd_in;
            RegWrite_out <= RegWrite_in;
            MemtoReg_out <= MemtoReg_in;
        end
    end
endmodule