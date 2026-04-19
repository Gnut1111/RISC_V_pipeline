
`timescale 1ns/1ps


module dmem_wrapper (
    input         clk,
    input         we,
    input         re,
    input  [3:0]  wmask,
    input  [9:0]  addr,
    input  [31:0] wdata,
    output [31:0] rdata
);
    wire [7:0] dout0, dout1, dout2, dout3;

    sky130_sram_1kbyte_1rw1r_8x1024_8 dmem_b0 (
        .clk0(clk), .csb0(~(we|re)), .web0(~we),
        .wmask0(wmask[0]), .addr0(addr),
        .din0(wdata[7:0]), .dout0(dout0),
        .clk1(clk), .csb1(1'b1), .addr1(10'b0), .dout1()
    );
    sky130_sram_1kbyte_1rw1r_8x1024_8 dmem_b1 (
        .clk0(clk), .csb0(~(we|re)), .web0(~we),
        .wmask0(wmask[1]), .addr0(addr),
        .din0(wdata[15:8]), .dout0(dout1),
        .clk1(clk), .csb1(1'b1), .addr1(10'b0), .dout1()
    );
    sky130_sram_1kbyte_1rw1r_8x1024_8 dmem_b2 (
        .clk0(clk), .csb0(~(we|re)), .web0(~we),
        .wmask0(wmask[2]), .addr0(addr),
        .din0(wdata[23:16]), .dout0(dout2),
        .clk1(clk), .csb1(1'b1), .addr1(10'b0), .dout1()
    );
    sky130_sram_1kbyte_1rw1r_8x1024_8 dmem_b3 (
        .clk0(clk), .csb0(~(we|re)), .web0(~we),
        .wmask0(wmask[3]), .addr0(addr),
        .din0(wdata[31:24]), .dout0(dout3),
        .clk1(clk), .csb1(1'b1), .addr1(10'b0), .dout1()
    );

    assign rdata = {dout3, dout2, dout1, dout0};
endmodule