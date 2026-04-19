
`timescale 1ns/1ps


module imm_gen(
    input  [6:0]  op,
    input  [31:7] instr,
    output reg [31:0] imm
);
    always @(*) begin
        case(op)
            7'b0010011,
            7'b0000011,
            7'b1100111: // I-type: ADDI, Load, JALR
                imm = {{20{instr[31]}}, instr[31:20]};

            7'b0100011: // S-type: Store
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            7'b1100011: // B-type: Branch
                imm = {{20{instr[31]}}, instr[7], instr[30:25],
                        instr[11:8], 1'b0};

            7'b0110111,
            7'b0010111: // U-type: LUI, AUIPC
                imm = {instr[31:12], 12'h000};

            7'b1101111: // J-type: JAL
                imm = {{12{instr[31]}}, instr[19:12], instr[20],
                        instr[30:21], 1'b0};

            default: imm = 32'b0;
        endcase
    end
endmodule