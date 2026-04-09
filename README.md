# RISC-V 6-Stage Pipeline Processor

A fully functional **RV32I** pipeline processor implemented in Verilog, featuring a 6-stage pipeline with complete hazard handling.

![Datapath](riscv_pipeline_datapath.svg)

---

## Architecture

### Pipeline Stages

| Stage | Description |
|-------|-------------|
| **IF** | Instruction Fetch — PC, i_mem |
| **ID** | Instruction Decode — controller, imm_gen, reg_file |
| **EX** | Execute — ALU, forwarding muxes, branch/jump resolution |
| **MEM1** | Memory Access — d_mem write + begin read |
| **MEM2** | Memory Latch — d_mem registered output |
| **WB** | Write Back — MemtoReg mux → reg_file |

### Why 6 Stages?

The `d_mem` module uses **synchronous read** to infer Block RAM (M4K on Cyclone II). This introduces 1-cycle read latency, splitting the conventional MEM stage into MEM1 (address + write) and MEM2 (read data available). This is a deliberate trade-off: Block RAM is far more resource-efficient than implementing memory as registers.

---

## Hazard Handling

### Data Hazards — Forwarding Unit

Three forwarding paths from producer to consumer:

```
ForwardA/B = 01  →  EX_MEM1.alu_res        (1 instruction before EX)
ForwardA/B = 10  →  MEM1_MEM2_result        (2 instructions before EX)
ForwardA/B = 11  →  MEM2_WB_result          (3 instructions before EX)
```

`MEM1_MEM2_result` and `MEM2_WB_result` are multiplexed wires that select between `alu_res` (R/I-type) and `d_mem_res` (load) based on `MemtoReg`.

The register file also includes **internal forwarding** — if WB is writing to a register that ID is reading in the same cycle, the write data is forwarded directly.

### Load-Use Hazard — Stall (1 cycle)

When a load instruction is in EX and the next instruction reads its destination register, the pipeline stalls for **1 cycle**. After the stall, the load result is available via the `ForwardA/B = 10` path.

```
lw  x1, 0(x2)   ← EX stage
add x3, x1, x4  ← ID stage → stall 1 cycle → forward from MEM2
```

### Control Hazards — Flush (2 instructions)

Branch and jump are resolved at **EX stage**. When `PCSrc = 1`, the two instructions already fetched (in IF and ID) are flushed by clearing `IF_ID_buf` and `ID_EX_buf`.

```
beq  x1, x2, label   ← EX: PCSrc computed
[flush]               ← IF/ID instructions discarded
[flush]
target_instruction    ← correct fetch
```

---

## Module Overview

```
Risc_v.v                 — Top-level pipeline
├── PC.v                 — Program counter (with enable for stall)
├── PC_Plus_4.v          — PC+4 adder
├── i_mem.v              — Instruction memory (async read)
├── IF_ID_buf.v          — IF/ID pipeline register
├── controller.v         — Control unit (opcode decode)
├── imm_gen.v            — Immediate generator (I/S/B/U/J formats)
├── reg_file.v           — 32×32 register file (internal forwarding)
├── ID_EX_buf.v          — ID/EX pipeline register
├── ALU_controller.v     — ALU control signals
├── ALU.v                — 32-bit ALU (ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU/LUI)
├── Mux_2.v              — 2-to-1 multiplexer
├── Mux_3.v              — 3-to-1 multiplexer
├── Mux_4.v              — 4-to-1 multiplexer (forwarding)
├── adder.v              — Branch/jump target adder
├── jump_control.v       — PCSrc generation (all 6 branch conditions)
├── EX_MEM1_buf.v        — EX/MEM1 pipeline register
├── d_mem.v              — Data memory (sync read/write → Block RAM)
├── MEM1_MEM2_buf.v      — MEM1/MEM2 pipeline register
├── MEM2_WB_buf.v        — MEM2/WB pipeline register
├── hazard_detection.v   — Load-use stall detection
└── forwarding_unit.v    — 3-path forwarding logic
```

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
- Block RAM inference via synchronous d_mem read

---

## Resource Utilization

Synthesized on **Cyclone II EP2C35F672C6**:

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| Total logic elements | 2,066 | 33,216 | 6% |
| Combinational functions | 2,024 | 33,216 | 6% |
| Dedicated logic registers | 713 | 33,216 | 2% |
| Total registers | 713 | — | — |
| Total pins | 98 | 475 | 21% |
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
- Double EX forwarding (3 consecutive dependent instructions)
- Load-use stall
- All 6 branch conditions
- JAL and JALR

---

## File Structure

```
├── src/
│   ├── Risc_v.v
│   ├── PC.v
│   ├── ...
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
