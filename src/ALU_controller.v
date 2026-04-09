module ALU_controller (
	input [1:0] ALUOp,
	input [2:0] func3,
	input  func7b5, opb5,
	output reg [3:0] ALUControl
);
	wire sub_sra = func7b5 & opb5 ;
	always @(*) begin
		case(ALUOp)
			2'b00: ALUControl = 4'b0000; //add
			2'b01: ALUControl = 4'b0001; //sub 
			2'b10: begin 
				case(func3) 
					3'b000: ALUControl = (sub_sra == 0) ? 4'b0000 : 4'b0001; //add, sub, addi
					3'b001: ALUControl = 4'b0101; //sll
					3'b010: ALUControl = 4'b0110; //slt
					3'b011: ALUControl = 4'b0111; //sltu
					3'b100: ALUControl = 4'b0100; //xor
					3'b101: ALUControl = (func7b5) ? 4'b1001 : 4'b1000 ; //srl, sra
					3'b110: ALUControl = 4'b0011; //or 
					3'b111: ALUControl = 4'b0010; //and
					default: ALUControl = 4'b0000;
				endcase
			end
			2'b11: ALUControl = 4'b1111; //LUI
			default: ALUControl = 4'b0000;
		endcase
	end
endmodule
					
					
				