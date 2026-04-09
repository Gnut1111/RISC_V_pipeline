module IF_ID_buf(
    input clk, reset, enable, flush,
    input  [31:0] PC_in, PC_plus_4_in, instr_in,
    output reg [31:0] PC_out, PC_plus_4_out, instr_out
);
    always @(posedge clk) begin
        if (reset || flush) begin
            PC_out      <= 32'b0;
            PC_plus_4_out <= 32'b0;
            instr_out   <= 32'b0;
        end else if (enable) begin
            PC_out      <= PC_in;
            PC_plus_4_out <= PC_plus_4_in;
            instr_out   <= instr_in;
        end
    end
endmodule
