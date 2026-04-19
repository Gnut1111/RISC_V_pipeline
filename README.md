# RISC-V 5-Stage Pipeline Processor

A fully functional **RV32I** pipeline processor implemented in Verilog, featuring a 5-stage pipeline with complete hazard handling.

---

## Architecture

### Pipeline Stages

| Stage | Description |
|-------|-------------|
| **IF** | Instruction Fetch — PC, i_mem (synchronous read, 1-cycle latency) |
| **ID** | Instruction Decode — controller, imm_gen, reg_file |
| **EX** | Execute — ALU, forwarding muxes, branch/jump resolution |
| **MEM** | Memory Access — d_mem write + begin read (EX/MEM1 register → MEM2/WB register) |
| **WB** | Write Back — dmem_decode, MemtoReg mux → reg_file |

Pipeline registers: `IF_ID_buf` → `ID_EX_buf` → `EX_MEM1_buf` → `MEM2_WB_buf` (4 registers, 5 stages).

### Synchronous Memory and Latency Handling

Both `i_mem` and `d_mem` use **synchronous read** to infer Block RAM (M4K on Cyclone II). This is more resource-efficient than register-based memory, but introduces 1-cycle read latency that must be accounted for:

- **i_mem**: PC and PC+4 are delayed 1 cycle (`pc_if_dly`, `pc_plus4_if_dly`) before entering `IF_ID_buf`, so they stay aligned with the instruction word that i_mem outputs.
- **d_mem**: The MEM stage spans two clock cycles internally — `EX_MEM1_buf` holds the address and drives the synchronous read; `MEM2_WB_buf` captures the result one cycle later. There is no explicit MEM2 pipeline register between them; the d_mem synchronous read latency is absorbed transparently between these two existing registers.

---

## Hazard Handling

### Data Hazards — Forwarding Unit

Two forwarding paths from producer to consumer:

```
ForwardA/B = 01  →  alu_res_out_ex_mem_buf    (1 instruction before EX, from EX/MEM1 register)
ForwardA/B = 10  →  WD_WB                      (from MEM2/WB register, after MemtoReg mux)
```

`WD_WB` is the output of the MemtoReg mux in WB stage — it selects between `alu_res` (R/I-type), `rdata_decoded` (load), and `PC_plus4` (JAL/JALR) based on `MemtoReg[1:0]`.

The register file also includes **internal forwarding** — if WB is writing to a register that ID is reading in the same cycle, the write data is forwarded directly.

### Load-Use Hazard — Stall (1 cycle)

When a load instruction is in EX and the next instruction reads its destination register, the pipeline stalls for **1 cycle**. After the stall, the load result is available via the `ForwardA/B = 10` path (through `WD_WB` in WB stage).

```
lw  x1, 0(x2)   ← EX stage (MemRead = 1)
add x3, x1, x4  ← ID stage → stall 1 cycle → forward from WB (WD_WB)
```

The `hazard_detection` unit asserts `stallF`, `stallD`, and `flushE` simultaneously during a load-use stall.

### Control Hazards — Flush (3 instructions)

Branch and jump are resolved at **EX stage**. When `PCSrc = 1`, the pipeline must discard 3 instructions:

- **Cycle 0**: `PCSrc` asserts → `flushD` kills the IF/ID register (ID-stage instruction)
- **Cycle 0**: `flushE` kills the ID/EX register (EX-stage bubble)
- **Cycle 1**: `PCSrc_dly` asserts → `instr_ifid_in` is overridden with NOP (`32'h00000013`)

The extra NOP insertion (`PCSrc_dly`) is necessary because `i_mem` uses synchronous read — even after the PC is redirected, one more stale instruction word emerges from i_mem on the next clock edge.

```
beq  x1, x2, label   ← EX: PCSrc computed, flushD/flushE asserted
[NOP injected]        ← i_mem sync latency — PCSrc_dly kills this
[flushed]             ← IF/ID flushed by flushD
target_instruction    ← correct fetch arrives
```

The hazard detection unit also drives `flushD` based on `PCSrc` to handle branch/jump flush alongside load-use stall.

---

## Module Overview

```
Risc_v.v                 — Top-level pipeline
├── PC.v                 — Program counter (with enable for stall)
├── PC_Plus_4.v          — PC+4 adder
├── i_mem.v              — Instruction memory (sync read, 1-cycle latency)
├── IF_ID_buf.v          — IF/ID pipeline register (with enable + flush)
├── controller.v         — Control unit (opcode decode)
├── imm_gen.v            — Immediate generator (I/S/B/U/J formats)
├── reg_file.v           — 32×32 register file (internal forwarding)
├── ID_EX_buf.v          — ID/EX pipeline register (with flush)
├── ALU_controller.v     — ALU control signals
├── ALU.v                — 32-bit ALU (ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU/LUI)
├── Mux_2.v              — 2-to-1 multiplexer
├── Mux_3.v              — 3-to-1 multiplexer
├── adder.v              — Branch/jump target adder
├── jump_control.v       — PCSrc generation (all 6 branch conditions)
├── EX_MEM1_buf.v        — EX/MEM1 pipeline register
├── dmem_wmask_gen.v     — Write mask generator (byte/half/word from funct3 + addr[1:0])
├── d_mem.v              — Data memory (sync read/write → Block RAM)
├── MEM2_WB_buf.v        — MEM2/WB pipeline register
├── dmem_decode.v        — Load data decoder (LW/LH/LHU/LB/LBU from funct3 + addr[1:0])
├── hazard_detection.v   — Load-use stall + branch flush detection
└── forwarding_unit.v    — 2-path forwarding logic
```

> **Note:** The module names `EX_MEM1_buf` and `MEM2_WB_buf` reflect the synchronous d_mem read latency absorbed within the MEM stage, but there is no separate MEM2 pipeline stage. The design is a standard 5-stage pipeline.

---

## Top-Level Ports

```verilog
module Risc_v(
    input        clk,
    input        reset,
    output [31:0] alu_out,   // Registered ALU result (from EX stage)
    output [31:0] mem_out,   // Registered decoded load data (from MEM2 stage)
    output [31:0] WB_out     // Registered write-back data (WD_WB, from WB stage)
);
```

All three outputs are registered on the rising edge of `clk` for observation purposes (testbench / debug).

---

## Key Implementation Details

### Synchronous i_mem Alignment

Because `i_mem` has 1-cycle read latency, the PC and PC+4 values must be delayed to stay aligned with the instruction word at the IF/ID register input:

```verilog
always @(posedge clk) begin
    if (~stallF) begin
        pc_if_dly       <= pc;
        pc_plus4_if_dly <= pc_plus_4;
    end
end
```

The IF/ID register receives `pc_if_dly` / `pc_plus4_if_dly` and the raw instruction word from i_mem on the same cycle.

### PCSrc Delay for NOP Injection

```verilog
always @(posedge clk) begin
    PCSrc_dly <= PCSrc;
end
assign instr_ifid_in = PCSrc_dly ? 32'h00000013 : instr_raw;
```

This forces a NOP into the IF/ID register the cycle after a branch/jump redirects the PC, compensating for the extra instruction that i_mem has already fetched.

### DMEM Write Mask

Sub-word stores (SB, SH) are handled by `dmem_wmask_gen`, which generates a 4-bit byte-enable mask from `funct3` and `addr[1:0]`. The write data (`RD2`) is stored pre-shifted, aligned to the correct byte lane.

### DMEM Load Decode

Load data is decoded in `dmem_decode` at the WB stage, using `funct3` and `addr[1:0]` propagated through the pipeline registers. This keeps the decode logic out of the critical memory read path.

### MemtoReg Encoding

`MemtoReg` is a 2-bit signal selecting among three write-back sources:

| `MemtoReg` | WD_WB source |
|------------|--------------|
| `00` | `alu_res` (R/I-type) |
| `01` | `rdata_decoded` (load) |
| `10` | `PC_plus4` (JAL/JALR) |

### JALR Target Address

For JALR, the branch adder input is muxed to `SrcA_fwd` (forwarded rs1) rather than PC:

```verilog
Mux_2 Src_adder_mux2 (
    .A(PC_out_id_ex_buf),
    .B(SrcA_fwd),
    .ctrl_signal(JALR_out_id_ex_buf),
    .Mux_res(Src_adder)
);
```

The adder computes `SrcA_fwd + imm`, and `jump_control` sets `PCSrc = 1` for both JAL and JALR.

---

## Instruction Support

Full **RV32I** base integer instruction set:

| Type | Instructions |
|------|-------------|
| R-type | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU |
| I-type | ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU |
| Load | LW, LH, LHU, LB, LBU |
| Store | SW, SH, SB |
| Branch | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| Jump | JAL, JALR |
| Upper | LUI, AUIPC |

---

## Timing

Tested on **Altera DE2 (Cyclone II EP2C35F672C6)**, timing model: Final:

| Metric | Value |
|--------|-------|
| Target clock | 50 MHz (20 ns) |
| Achieved Fmax | **~72 MHz** |
| Critical path | EX stage (forwarding → ALU → PCSrc) |

Key optimizations applied:
- `Zero` signal computed directly from `Sum` (parallel with ALU output mux)
- Forwarding unit conditions computed as parallel wires before priority select
- Block RAM inference via synchronous i_mem and d_mem reads

---

## Resource Utilization

Synthesized on **Cyclone II EP2C35F672C6**:

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| Total logic elements | 2,066 | 33,216 | 6% |
| Combinational functions | 2,024 | 33,216 | 6% |
| Dedicated logic registers | 713 | 33,216 | 2% |
| Total registers | 713 | — | — |
| Total memory bits | 34,816 | 483,840 | 7% |
| Embedded Multiplier 9-bit | 0 | 70 | 0% |
| PLLs | 0 | 4 | 0% |

The design is extremely lightweight — only **6% logic utilization** on Cyclone II, leaving ample room for peripherals, cache, or RV32M/RV32F extensions. The 7% memory usage corresponds to the synchronous Block RAM (M4K) inferred for `d_mem` and `i_mem`.

---

## Simulation

Run with ModelSim:

```bash
# Compile all modules
vlog *.v

# Run simulation
vsim -t 1ps tb_Risc_v
run -all
```

The testbench (`tb_Risc_v.v`) runs the full RV32I test program (`full_test.hex`) and verifies:
- All R-type and I-type ALU operations
- All load/store widths (byte, half, word, signed/unsigned)
- LUI and AUIPC
- EX forwarding (consecutive dependent instructions)
- Load-use stall (1-cycle stall + forward from WB)
- All 6 branch conditions
- JAL and JALR

---

## File Structure

```
├── src/
│   ├── Risc_v.v
│   ├── PC.v
│   ├── PC_Plus_4.v
│   ├── i_mem.v
│   ├── IF_ID_buf.v
│   ├── controller.v
│   ├── imm_gen.v
│   ├── reg_file.v
│   ├── ID_EX_buf.v
│   ├── ALU_controller.v
│   ├── ALU.v
│   ├── Mux_2.v
│   ├── Mux_3.v
│   ├── adder.v
│   ├── jump_control.v
│   ├── EX_MEM1_buf.v
│   ├── dmem_wmask_gen.v
│   ├── d_mem.v
│   ├── MEM2_WB_buf.v
│   ├── dmem_decode.v
│   ├── hazard_detection.v
│   └── forwarding_unit.v
├── sim/
│   ├── tb_Risc_v.v
│   └── program.hex
├── constraints/
│   └── tm.sdc
├── riscv_pipeline_datapath.svg
└── README.md
```

---

## References

- Patterson & Hennessy, *Computer Organization and Design RISC-V Edition*
- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
- Altera DE2 Board Reference Manual
