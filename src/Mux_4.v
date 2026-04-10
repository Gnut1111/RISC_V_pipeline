module Mux_4(
    input  [31:0] A, B, C, D,
    input  [1:0]  ctrl_signal,
    output [31:0] Mux4_res
);
    assign Mux4_res = (ctrl_signal == 2'b00) ? A :
                      (ctrl_signal == 2'b01) ? B :
                      (ctrl_signal == 2'b10) ? C : D;
endmodule