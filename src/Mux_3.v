module Mux_3(
    input  [31:0] A, B, C,
    input  [1:0]  ctrl_signal,
    output [31:0] Mux3_res
);
assign Mux3_res = (ctrl_signal == 2'b00) ? A: 
                  (ctrl_signal == 2'b01) ? B:
                  (ctrl_signal == 2'b10) ? C: 32'b0;
endmodule