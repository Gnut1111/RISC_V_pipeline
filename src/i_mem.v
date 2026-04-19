
`timescale 1ns/1ps

module i_mem(
	input clk, we, cs,
	input [31:0] address, 
	output reg [31:0] instr
);

	reg [31:0] mem [511:0];
	initial $readmemh("program.hex", mem);
	always @(posedge clk) begin
	  if(cs) begin	
		if (we) mem[address[8:2]] <= instr; // word-aligned
		else instr <= mem[address[8:2]];
	  end 
	end

endmodule 