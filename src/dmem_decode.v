
`timescale 1ns/1ps
module dmem_decode (
    input  [31:0] word_data,     // raw word từ SRAM
    input  [2:0]  funct3,        // từ pipeline register
    input  [1:0]  byte_offset,   // addr[1:0] từ pipeline register
    output reg [31:0] rd         // data đã decode
);
    always @(*) begin
        case (funct3)
            3'b010: rd = word_data;  // LW
            3'b000: begin            // LB
                case (byte_offset)
                    2'b00: rd = {{24{word_data[7]}},  word_data[7:0]};
                    2'b01: rd = {{24{word_data[15]}}, word_data[15:8]};
                    2'b10: rd = {{24{word_data[23]}}, word_data[23:16]};
                    2'b11: rd = {{24{word_data[31]}}, word_data[31:24]};
                    default: rd = 32'd0;
                endcase
            end
            3'b001: begin            // LH
                if (!byte_offset[1])
                    rd = {{16{word_data[15]}}, word_data[15:0]};
                else
                    rd = {{16{word_data[31]}}, word_data[31:16]};
            end
            3'b100: begin            // LBU
                case (byte_offset)
                    2'b00: rd = {24'd0, word_data[7:0]};
                    2'b01: rd = {24'd0, word_data[15:8]};
                    2'b10: rd = {24'd0, word_data[23:16]};
                    2'b11: rd = {24'd0, word_data[31:24]};
                    default: rd = 32'd0;
                endcase
            end
            3'b101: begin            // LHU
                if (!byte_offset[1])
                    rd = {16'd0, word_data[15:0]};
                else
                    rd = {16'd0, word_data[31:16]};
            end
            default: rd = word_data;
        endcase
    end
endmodule