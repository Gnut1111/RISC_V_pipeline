module PC (
 input clk, reset, enable,
 input [31:0] pc_next,
 output reg [31:0] pc
 );
 always @(posedge clk) begin 
	if(reset) pc <= 32'h00000000;
	else if(enable) pc <= pc_next;
end
endmodule 
 