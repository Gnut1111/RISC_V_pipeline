
`timescale 1ns/1ps


module jump_control(
	input Branch, Jump,
	input [2:0] func3,
	input Zero, slt, sltu,
	output PCSrc
);
	reg type_branch;
	always @(*) begin 
		case(func3) 
			3'b000: type_branch = Zero; //beq
			3'b001: type_branch = ~Zero; //bne
			3'b100: type_branch = slt; //blt
			3'b101: type_branch = ~slt | Zero; //bge
			3'b110: type_branch = sltu; //bltu
			3'b111: type_branch = ~sltu | Zero; //bgeu
			default: type_branch = 0;
		endcase
	end 
	assign PCSrc = (Branch & type_branch) | Jump;
endmodule
