module Mux_2(
	input [31:0] A,B,
	input ctrl_signal,
	output [31:0] Mux_res
);

assign Mux_res = (ctrl_signal) ? B : A;
endmodule 