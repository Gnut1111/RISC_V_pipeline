module reg_file(
    input RegWrite, clk,
    input [4:0] RA1, RA2, WA,
    input [31:0] WD,
    output [31:0] RD1, RD2
);
    reg [31:0] regfile [31:0];
    integer j;
    initial begin
        for (j = 0; j < 32; j = j + 1)
            regfile[j] = 32'b0;
    end

    always @(posedge clk) begin
        if(RegWrite && WA != 5'b00000) regfile[WA] <= WD;
    end

    // Internal forwarding — nếu WB đang ghi vào register đang đọc
    // thì trả về WD trực tiếp thay vì giá trị cũ trong regfile
    assign RD1 = (RA1 == 5'b00000)              ? 32'h0 :
                 (RegWrite && WA == RA1)         ? WD    :
                 regfile[RA1];

    assign RD2 = (RA2 == 5'b00000)              ? 32'h0 :
                 (RegWrite && WA == RA2)         ? WD    :
                 regfile[RA2];

endmodule