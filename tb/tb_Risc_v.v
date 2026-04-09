`timescale 1ns/1ps

module tb_Risc_v;

    reg  clk, reset;
    wire [31:0] out_mem, out_alu, out_rs2;

    Risc_v dut(
        .clk(clk), .reset(reset),
        .out_mem(out_mem), .out_alu(out_alu), .out_rs2(out_rs2)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ─── Counters ────────────────────────────────────────
    integer pass_count, fail_count, stall_count, flush_count;

    // ─── Task: check register ────────────────────────────
    task check_reg;
        input [4:0]    reg_num;
        input [31:0]   expected;
        input [8*40:1] test_name;
        begin
            if (dut.reg_file.regfile[reg_num] === expected) begin
                $display("  PASS: x%-2d = %08h | %0s",
                    reg_num, expected, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: x%-2d = %08h, expected %08h | %0s",
                    reg_num,
                    dut.reg_file.regfile[reg_num],
                    expected, test_name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ─── Task: check memory ──────────────────────────────
    task check_mem;
        input [31:0]   word_idx;
        input [31:0]   expected;
        input [8*40:1] test_name;
        begin
            if (dut.d_mem.mem[word_idx] === expected) begin
                $display("  PASS: mem[%0d] = %08h | %0s",
                    word_idx, expected, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: mem[%0d] = %08h, expected %08h | %0s",
                    word_idx,
                    dut.d_mem.mem[word_idx],
                    expected, test_name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ─── Main ────────────────────────────────────────────
    integer i;

    initial begin
        $dumpfile("tb_full_test.vcd");
        $dumpvars(0, tb_Risc_v);

        pass_count  = 0;
        fail_count  = 0;
        stall_count = 0;
        flush_count = 0;

        // Reset 2 cycles
        reset = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        reset = 0;
		  
		  $monitor("T=%0t | PC=%08h | instr=%08h | alu=%08h | mem=%08h | rs2=%08h | stall=%b | PCSrc=%b | x11=%08h | x12=%08h ",
        $time,
        dut.pc,
        dut.instr,
        out_alu,
        out_mem,
        out_rs2,
        dut.stall,
        dut.PCSrc,
		  dut.reg_file.regfile[11],
		  dut.reg_file.regfile[12]
    );

        $display("========================================");
        $display("  RV32I Full Instruction Test");
        $display("========================================");

        // 120 cycles: du cho 62 instrs + pipeline fill/drain + hazards
        for (i = 0; i < 120; i = i + 1) begin
            @(posedge clk); #1;
            if (dut.stall) begin
                stall_count = stall_count + 1;
                $display("  >> STALL cycle %0d | PC=%08h", i, dut.pc);
            end
            if (dut.PCSrc) begin
                flush_count = flush_count + 1;
                $display("  >> FLUSH cycle %0d | target=%08h", i, dut.pc_target_jump);
            end
				
        end

        // ================================================
        // SECTION 1: Setup
        // ================================================
        $display("\n--- SECTION 1: Register Setup ---");
        check_reg(4, 32'hffffffff, "addi x4=-1");

        // ================================================
        // SECTION 2: R-type
        // ================================================
        $display("\n--- SECTION 2: R-type ---");
        check_reg(5,  32'd25,         "add  x5=x1+x2=25");
        check_reg(14, 32'd0,          "sltu x14=0 (15>10)");

        // ================================================
        // SECTION 3: I-type ALU
        // ================================================
        $display("\n--- SECTION 3: I-type ALU ---");
        check_reg(15, 32'd22,         "addi  x15=15+7=22");
        check_reg(16, 32'd10,         "andi  x16=15&10=10");
        check_reg(17, 32'd31,         "ori   x17=15|16=31");
        check_reg(18, 32'd0,          "xori  x18=15^15=0");
        check_reg(19, 32'd60,         "slli  x19=15<<2=60");
        check_reg(20, 32'd3,          "srli  x20=15>>2=3");
        check_reg(21, 32'hffffffff,   "srai  x21=-1>>2=-1");
        check_reg(22, 32'd1,          "slti  x22=1 (15<20)");
        check_reg(23, 32'd0,          "sltiu x23=0 (15>10)");

        // ================================================
        // SECTION 4: Load/Store
        // ================================================
        $display("\n--- SECTION 4: Load/Store ---");
        check_mem(50, 32'd25,         "sw  x5 -> mem[50]=25");
        check_mem(51, 32'h0000000f,   "sh  x1 -> mem[51]=15");
        check_mem(52, 32'h00000003,   "sb  x3 -> mem[52]=3");
        check_mem(53, 32'hffffffff,   "sw  x4 -> mem[53]=-1");
        check_reg(26, 32'd25,         "lw  x26=25");
        check_reg(27, 32'd15,         "lhu x27=15 (unsigned)");
        check_reg(28, 32'd3,          "lbu x28=3  (unsigned)");
        check_reg(29, 32'hffffffff,   "lh  x29=-1 (signed)");
        check_reg(30, 32'hffffffff,   "lb  x30=-1 (signed)");

        // ================================================
        // SECTION 5: LUI, AUIPC
        // ================================================
        $display("\n--- SECTION 5: LUI / AUIPC ---");
        check_reg(24, 32'h00001000,   "lui   x24=0x1000");
        // auipc x31 tai PC=0x88, imm=1 -> x31=0x88+0x1000=0x1088
        check_reg(31, 32'h00001088,   "auipc x31=PC+0x1000=0x1088");

        // ================================================
        // SECTION 6: Hazard — Double EX forwarding
        // ================================================
        $display("\n--- SECTION 6: Double EX Forwarding ---");
        // x1 qua 3 addi lien tiep: 1->2->3
        check_reg(1, 32'd3,           "x1=3 (EX->EX fwd x2)");

        // ================================================
        // SECTION 7: Load-use stall
        // ================================================
        $display("\n--- SECTION 7: Load-Use Stall ---");
        check_reg(2, 32'd28,          "x2=3+25=28 (load-use stall)");

        // ================================================
        // SECTION 8: Branch
        // ================================================
        $display("\n--- SECTION 8: Branch ---");
        // BEQ taken
        check_reg(7,  32'd55,         "beq  taken: x7=55 (99 flushed)");
        // BNE not taken
        check_reg(8,  32'd77,         "bne  not taken: x8=77 (runs)");
        // BLT taken
        check_reg(9,  32'd11,         "blt  taken: x9=11 (99 flushed)");
        // BGE taken
        check_reg(10, 32'd22,         "bge  taken: x10=22 (99 flushed)");

        // ================================================
        // SECTION 9: JAL, JALR
        // ================================================
        $display("\n--- SECTION 9: JAL / JALR ---");
        // JAL x11 tai PC=0xe0, x11=0xe4
        check_reg(11, 32'h000000e4,   "jal  x11=PC+4=0xe4");
        // addi x12=33 chay dung
        check_reg(12, 32'd33,         "jal  skip: x12=33 (99 flushed)");
        // JALR x13 tai PC=0xf0, x13=0xf4
        check_reg(13, 32'h000000f4,   "jalr x13=PC+4=0xf4");

        // ================================================
        // Hazard summary
        // ================================================
        $display("\n--- Hazard Summary ---");
        $display("  Stall cycles: %0d (expect 1 — load-use)", stall_count);
        $display("  Flush events: %0d (expect >= 5 — branch+jump+loop)",
            flush_count);

        // ================================================
        // Register dump
        // ================================================
        $display("\n--- Register File Dump ---");
        begin : dump
            integer k;
            for (k = 0; k < 32; k = k + 1)
                $display("  x%-2d = %08h (%0d)",
                    k,
                    dut.reg_file.regfile[k],
                    $signed(dut.reg_file.regfile[k]));
        end

        // ================================================
        // Tổng kết
        // ================================================
        $display("\n========================================");
        $display("  TONG KET: %0d PASS / %0d FAIL",
            pass_count, fail_count);
        if (fail_count == 0)
            $display("  >> TAT CA TEST PASS! Pipeline OK.");
        else
            $display("  >> CO %0d FAIL — kiem tra waveform.", fail_count);
        $display("========================================");

        $finish;
    end

endmodule