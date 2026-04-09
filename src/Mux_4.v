module Mux_4(
    input  [31:0] A, B, C, D,
    input  [1:0]  ctrl_signal,
    output [31:0] Mux4_res
);
    wire [31:0] mux_low, mux_high;
    
    assign mux_low  = ctrl_signal[0] ? B : A;
    assign mux_high = ctrl_signal[0] ? D : C;
	 
    assign Mux4_res = ctrl_signal[1] ? mux_high : mux_low;
endmodule