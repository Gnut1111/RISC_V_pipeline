
`timescale 1ns/1ps

module forwarding_unit(
    input [4:0] ID_EX_rs1, ID_EX_rs2,

    input        EX_MEM1_RegWrite,
    input [4:0]  EX_MEM1_rd,

    input        MEM2_WB_RegWrite,
    input [4:0]  MEM2_WB_rd,

    output reg [1:0] ForwardA, ForwardB
);
    always @(*) begin
        // ForwardA
        if (EX_MEM1_RegWrite && EX_MEM1_rd != 0 &&
            EX_MEM1_rd == ID_EX_rs1)
            ForwardA = 2'b01;
        else if (MEM2_WB_RegWrite && MEM2_WB_rd != 0 &&
                 MEM2_WB_rd == ID_EX_rs1)
            ForwardA = 2'b10;  
        else
            ForwardA = 2'b00;

        // ForwardB
        if (EX_MEM1_RegWrite && EX_MEM1_rd != 0 &&
            EX_MEM1_rd == ID_EX_rs2)
            ForwardB = 2'b01;
        else if (MEM2_WB_RegWrite && MEM2_WB_rd != 0 &&
                 MEM2_WB_rd == ID_EX_rs2)
            ForwardB = 2'b10;  
        else
            ForwardB = 2'b00;
    end
endmodule