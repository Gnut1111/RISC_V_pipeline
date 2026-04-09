module i_mem(
	input [31:0] address,
	output [31:0] instr
);
	reg [31:0] mem [511:0];
	initial $readmemh("program.hex", mem);
	assign instr = mem[address[31:2]];
endmodule 