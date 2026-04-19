
`timescale 1ns/1ps


module dmem_wmask_gen (
    input  [2:0]  funct3,
    input  [1:0]  byte_offset,  // addr[1:0]
    input         mem_write,
    output reg [3:0] wmask
);
    always @(*) begin
        if (!mem_write) begin
            wmask = 4'b0000;  // không ghi
        end else begin
            case (funct3[1:0])
                // SW — ghi cả 4 bytes
                2'b10: wmask = 4'b1111;

                // SH — ghi 2 bytes
                2'b01: begin
                    if (!byte_offset[1])
                        wmask = 4'b0011;  // byte 0,1
                    else
                        wmask = 4'b1100;  // byte 2,3
                end

                // SB — ghi 1 byte
                2'b00: begin
                    case (byte_offset)
                        2'b00: wmask = 4'b0001;  // byte 0
                        2'b01: wmask = 4'b0010;  // byte 1
                        2'b10: wmask = 4'b0100;  // byte 2
                        2'b11: wmask = 4'b1000;  // byte 3
                        default: wmask = 4'b0000;
                    endcase
                end

                default: wmask = 4'b1111;
            endcase
        end
    end
endmodule