// top.v - Top module wrapper cho sky130_sram_2kbyte_1rw1r_32x512_8

`timescale 1ns/1ps


module imem_wrapper (
    input wire clk0,
    input wire clk1,
    
    // Port 0: Read/Write
    input wire csb0,          // active low
    input wire web0,          // active low (0 = write, 1 = read)
    input wire [3:0] wmask0,
    input wire [8:0] addr0,
    input wire [31:0] din0,
    output wire [31:0] dout0,
    
    // Port 1: Read only
    input wire csb1,          // active low
    input wire [8:0] addr1,
    output wire [31:0] dout1
);

`ifdef USE_POWER_PINS
    wire vccd1 = 1'b1;
    wire vssd1 = 1'b0;
`endif

    sky130_sram_2kbyte_1rw1r_32x512_8 u_sram (
`ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
`endif
        // Port 0 - RW
        .clk0   (clk0),
        .csb0   (csb0),
        .web0   (web0),
        .wmask0 (wmask0),
        .addr0  (addr0),
        .din0   (din0),
        .dout0  (dout0),
        
        // Port 1 - Read only
        .clk1   (clk1),
        .csb1   (csb1),
        .addr1  (addr1),
        .dout1  (dout1)
    );

endmodule