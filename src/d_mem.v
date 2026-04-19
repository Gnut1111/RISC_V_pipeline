`timescale 1ns/1ps

module d_mem (
    input clk, we,
    input [31:0] addr, wdata,
    output reg [31:0] rdata
);
    reg [31:0] mem [0:1023]; // 1024 words of 32 bits each

    always @(posedge clk) begin
        if (we) begin
            mem[addr[11:2]] <= wdata; // word-aligned access
        end
        else 
            rdata <= mem[addr[11:2]]; // read data (combinational)
    end
endmodule