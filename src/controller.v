
`timescale 1ns/1ps


module controller (
	input [6:0] op,
	output reg Branch, MemRead, MemWrite, Jump, 
			 ALUSrc, RegWrite, JALR, ALUSrcA,
	output reg [1:0] ALUOp, MemtoReg
);
	always @(*) begin
		case(op)
			7'b0110011: begin //R_type
				Branch = 0; MemRead = 0;
				MemWrite = 0; Jump = 0;
				MemtoReg = 2'b00; ALUSrc = 0;
				RegWrite = 1; ALUOp = 2'b10;
				JALR = 0; ALUSrcA = 0;
			end
			7'b0010011: begin //I_type
				Branch = 0; MemRead = 0;
				MemWrite = 0; Jump = 0;
				MemtoReg = 2'b00; ALUSrc = 1;
				RegWrite = 1; ALUOp = 2'b10;
				JALR = 0; ALUSrcA = 0;
			end
			7'b0000011: begin //I_type_load
				Branch = 0; MemRead = 1;
				MemWrite = 0; Jump = 0;
				MemtoReg = 2'b01; ALUSrc = 1;
				RegWrite = 1; ALUOp = 2'b00;
				JALR = 0; ALUSrcA = 0;
			end
			7'b0100011: begin //S_type
				Branch = 0; MemRead = 0;
				MemWrite = 1; Jump = 0;
				MemtoReg = 2'b00; ALUSrc = 1;
				RegWrite = 0; ALUOp = 2'b00;
				JALR = 0; ALUSrcA = 0;
			end
			7'b1100011: begin //B-type
				Branch = 1; MemRead = 0;
				MemWrite = 0; Jump = 0;
				MemtoReg = 2'b00; ALUSrc = 0;
				RegWrite = 0; ALUOp = 2'b01;
				JALR = 0; ALUSrcA = 0;
			end
			7'b0110111: begin //LUI
				Branch = 0; MemRead = 0;
				MemWrite = 0; Jump = 0;
				MemtoReg = 2'b00; ALUSrc = 1;
				RegWrite = 1; ALUOp = 2'b11;
				JALR = 0; ALUSrcA = 0;
			end
			7'b0010111: begin //AUIPC
				Branch = 0; MemRead = 0;
				MemWrite = 0; Jump = 0;
				MemtoReg = 2'b00; ALUSrc = 1;
				RegWrite = 1; ALUOp = 2'b00;
				JALR = 0; ALUSrcA = 1;
			end
			7'b1101111: begin //JAL
				Branch = 0; MemRead = 0;
				MemWrite = 0; Jump = 1;
				MemtoReg = 2'b10; ALUSrc = 1;
				RegWrite = 1; ALUOp = 2'b00;
				JALR = 0; ALUSrcA = 0;
			end
			7'b1100111: begin //JALR
				Branch = 0; MemRead = 0;
				MemWrite = 0; Jump = 1;
				MemtoReg = 2'b10; ALUSrc = 1;
				RegWrite = 1; ALUOp = 2'b00;
				JALR = 1; ALUSrcA = 0;
			end
			default: begin
				Branch   = 0; MemRead  = 0;
				MemWrite = 0; Jump     = 0;
				MemtoReg = 2'b00; ALUSrc = 0;
				RegWrite = 0; ALUOp   = 2'b00;
				JALR = 0; ALUSrcA = 0;
end
		endcase
	end
endmodule
			
			
			
		