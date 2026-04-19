`timescale 1ns/1ps
module hazard_detection(
    input        ID_EX_MemRead,
    input  PCSrc, // Tín hiệu này có thể được sử dụng để xác định khi nào cần stall do nhánh
    input  [4:0] ID_EX_rd,

    input  [4:0] IF_ID_rs1,
    input  [4:0] IF_ID_rs2,

    output reg stallF, stallD, flushE, flushD
);

wire lw_stall = ID_EX_MemRead && ((ID_EX_rd == IF_ID_rs1) || (ID_EX_rd == IF_ID_rs2)) && (ID_EX_rd != 5'b0);
always @(*) begin
    stallF = lw_stall; // Stall PC và IF/ID
    stallD = lw_stall; // Stall IF/ID
    flushE = lw_stall || PCSrc; // Flush ID/EX
    flushD = PCSrc; // Flush ID
end

endmodule 