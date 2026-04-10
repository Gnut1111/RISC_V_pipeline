module ALU (
	input [31:0] A,B,
	input [3:0] ALUControl,
	output reg [31:0] ALU_res,
	output Zero, slt, sltu
);
	wire [31:0] Sum,Temp;
	assign Temp = (ALUControl[0]) ? ~B : B; 
	assign Sum = A + Temp + ALUControl[0];
	assign slt = (A[31] == B[31]) ? (A < B) : A[31];
	assign sltu = A < B;
	assign Zero = (Sum == 0); 
 always @(*) begin 
	case(ALUControl) 
			4'b0000: ALU_res = Sum; //sum
			4'b0001: ALU_res = Sum; //sub
			4'b0010: ALU_res = A & B;
			4'b0011: ALU_res = A | B;
			4'b0100: ALU_res = A ^ B;
			
			4'b0101: ALU_res = (A << B[4:0]); //sll
			4'b0110: ALU_res = {31'b0, slt}; //slt
			4'b0111: ALU_res = {31'b0, sltu}; //sltu
			4'b1000: ALU_res = (A >> B[4:0]); //srl
			4'b1001: ALU_res = ($signed(A) >>> B[4:0]); //sra
			4'b1111: ALU_res = B; //lui
			default: ALU_res = 32'b00000000;
	endcase
	end
endmodule
			
