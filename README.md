<img width="522" height="522" alt="image" src="https://github.com/user-attachments/assets/4d8afc07-6834-41a3-bcf0-94ba75be259e" />

# DDR3 + AXI DMA Data Path for FPGA Accelerator

**Status:** Work in progress — initial Vivado block design  
**Target Board:** Digilent Arty A7-100T  
**FPGA:** Xilinx Artix-7 `XC7A100T-1CSG324`  
**Tool Version:** Vivado 2025.2

## Project Objective

Build a DDR3-to-accelerator data path using AXI DMA burst transfers and a Global Buffer. The intended design will transfer one block of data from DDR3 into the Global Buffer while the accelerator processes another block in a second buffer.

This ping-pong buffering approach aims to overlap data movement and computation, reduce accelerator idle time, and improve sustained throughput.

## Current Design Status

The current work focuses on the initial Vivado IP Integrator design. The memory-controller and DMA memory-mapped path have been created, but the complete system is not yet integrated or hardware-verified.

### IP Blocks

| IP Instance | Purpose | Current Configuration / Status |
|---|---|---|
| `mig_7series_0` | DDR3 memory controller and PHY | Configured for the Arty A7-100T DDR3 interface; physical DDR3 interface exposed |
| `axi_dma_0` | DDR3-to-AXI-Stream data transfers | MM2S enabled; S2MM and Scatter Gather disabled; 128-bit memory-map and stream widths |
| `clk_wiz_0` | Clock generation | Two output clocks requested: 166.667 MHz and 200 MHz |
| `proc_sys_reset_0` | Reset generation | Added; reset wiring requires further verification |
| `util_vector_logic_0` | Reset signal inversion | Configured as a 1-bit NOT operation for the Clocking Wizard reset input |
| `smartconnect_0` | AXI memory interconnect | Connects the DMA memory master to the MIG AXI slave |
| `smartconnect_1` | Intended DMA control interconnect | Control-path integration remains incomplete |

**Not yet integrated:** PicoRV32 processor and Global Buffer implementation.

## System Architecture

### Planned DDR3-to-Accelerator Data Path

```text
          DDR3 SDRAM
        (Arty A7-100T)
                |
                v
        +---------------+
        |  MIG 7 Series |
        +---------------+
                |
                v
        +---------------+
        | AXI           |
        | SmartConnect  |
        +---------------+
                |
                v
        +---------------+
        |    AXI DMA    |
        |     MM2S      |
        +---------------+
                |
                | AXI4-Stream
                v
        +---------------+
        | Global Buffer |
        |   Buffer A/B  |
        +---------------+
                |
                v
        +---------------+
        |  Accelerator  |
        +---------------+
```

### Planned Clocking Architecture

```text
       Arty A7 100 MHz Clock
                  |
                  v
          +---------------+
          | Clocking      |
          | Wizard (MMCM) |
          +---------------+
             |         |
             v         v
       166.667 MHz   200 MHz
             |         |
             v         v
       MIG sys_clk_i  MIG clk_ref_i
```

The clock configuration must be verified against the actual MIG configuration before implementation. The requested Clocking Wizard outputs alone do not establish that the MIG is correctly clocked.

## AXI DMA Configuration

The AXI DMA is configured for the **MM2S (Memory-Mapped to Stream)** path.

| Parameter | Configuration |
|---|---|
| Read Channel (MM2S) | Enabled |
| Write Channel (S2MM) | Disabled |
| Scatter Gather | Disabled |
| Micro DMA | Disabled |
| Memory-Mapped Data Width | 128 bits |
| AXI-Stream Data Width | 128 bits |
| Address Width | 32 bits |
| Buffer Length Width | 14 bits |
| Maximum Burst Size | 4, as currently configured |

The intended transfer is:

```text
DDR3 → MIG → AXI SmartConnect → AXI DMA → AXI4-Stream
```

The stream destination and software-controlled DMA execution still need to be completed.

## DDR3 Address Map

The exported Block Design records the following DDR3 address mapping:

| Parameter | Value |
|---|---|
| Base Address | `0x80000000` |
| Mapped Range | `0x10000000` (256 MiB) |
| Highest Mapped Address | `0x8FFFFFFF` |

The address mapping should be checked again in Vivado's Address Editor after subsequent design changes.

## Clock and Reset Verification

The Clocking Wizard was configured with the following requested outputs:

- `clk_out1`: approximately 166.667 MHz
- `clk_out2`: 200 MHz

These were connected to the MIG's `sys_clk_i` and `clk_ref_i` inputs, respectively.

However, the exported MIG configuration contains clock settings that require review. The MIG clock source, input frequency, clock period, reset connections, and generated constraints must be reconciled before synthesis and hardware testing.

## Planned Double Buffering

The eventual Global Buffer will contain two independently selectable buffers.

```text
                   DDR3
                     |
                     v
                  AXI DMA
                     |
               AXI4-Stream
                     |
              +------+------+
              |             |
              v             v
         +---------+   +---------+
         | Buffer A|   | Buffer B|
         +---------+   +---------+
              |             |
              +------+------+
                     |
                     v
                 Accelerator
```

The intended operation is:

1. DMA fills Buffer A while the accelerator processes Buffer B.
2. After the relevant completion signals, the buffers switch roles.
3. DMA fills Buffer B while the accelerator processes Buffer A.
4. Control logic prevents DMA from overwriting a buffer currently being read by the accelerator.

The final buffer architecture and switching logic remain to be implemented.

## Remaining Work

1. Verify and correct the MIG clock configuration and reset network.
2. Integrate the intended PicoRV32 implementation.
3. Connect a suitable processor bus interface or bridge to the DMA's AXI4-Lite control interface.
4. Connect the DMA AXI-Stream output to a temporary sink for initial testing.
5. Implement the Global Buffer and ping-pong buffering controller.
6. Validate the complete Block Design and run synthesis and implementation.
7. Generate the bitstream and verify MIG initialization on hardware.
8. Demonstrate a known-data DDR3-to-AXI-Stream transfer.
9. Measure transfer latency, effective bandwidth, BRAM usage, and accelerator idle cycles with and without double buffering.

## Verification Checklist

- [x] Initial Vivado IP Integrator design created
- [x] AXI DMA MM2S configured for 128-bit memory-map and stream widths
- [x] DMA memory-mapped interface connected through SmartConnect to the MIG AXI interface
- [x] DDR3 address segment assigned in the exported design
- [ ] MIG clock configuration and reset network fully verified
- [ ] PicoRV32 control path integrated
- [ ] AXI-Stream destination connected
- [ ] Global Buffer implemented
- [ ] Double buffering implemented
- [ ] Known-data DMA transfer demonstrated on hardware
- [ ] Throughput and BRAM usage measured

A previous Vivado validation run reported no errors or critical warnings. This confirms structural validation at that point, not successful operation on hardware. The design remains in progress.

## Repository Contents

The repository should retain the files necessary to reproduce the design, including:

- Vivado project (`.xpr`)
- Block Design source (`.bd`)
- HDL source files
- Board constraints (`.xdc`)
- MIG project preset (`mig.prj`)
- Exported Block Design Tcl script (`dma_ddr3_system_export.tcl`)
- IP inventory text file
- This README

Generated build directories, caches, temporary logs, and simulation outputs can generally be excluded through `.gitignore`.

## References

- [Digilent Arty A7 Reference Manual](https://digilent.com/reference/programmable-logic/arty-a7/reference-manual)
- [Digilent Arty A7-100 Master XDC](https://github.com/Digilent/digilent-xdc/blob/master/Arty-A7-100-Master.xdc)
- [AMD 7 Series Memory Interface Solutions — UG586](https://docs.amd.com/r/en-US/ug586_7Series_MIS)
- [AMD AXI DMA Product Guide — PG021](https://docs.amd.com/r/en-US/pg021_axi_dma)
- [AMD Clocking Wizard Product Guide — PG065](https://docs.amd.com/r/en-US/pg065-clk-wiz)
- [AMD AXI SmartConnect Product Guide — PG247](https://docs.amd.com/r/en-US/pg247-smartconnect)
- [PicoRV32 RTL and Documentation](https://github.com/YosysHQ/picorv32)
