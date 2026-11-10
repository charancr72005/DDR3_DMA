# DDR3 DMA-Based Memory System – Arty A7-100T

## 1. Project Overview

This project develops a DDR3-based memory transfer system on the **Digilent Arty A7-100T FPGA** using AMD Xilinx Vivado.

The design uses a PicoRV32 processor to configure and control an AXI DMA engine. The DMA transfers data from external DDR3 memory through an AXI memory-mapped interface and produces an AXI4-Stream output. The design also includes BRAM-based local memory and an additional BRAM test path for validating stream-to-memory transfers.

The longer-term objective is to connect the DMA data path to a Global Buffer and an accelerator architecture, allowing data movement and accelerator computation to overlap.

**Current development status:** Work in progress. Block Design validation has succeeded at earlier stages, but the latest XDC and clock changes still require a fresh synthesis and implementation run. Successful hardware operation and bitstream generation have not yet been confirmed.

---

## 2. Hardware and Development Environment

| Item | Configuration |
|---|---|
| FPGA board | Digilent Arty A7-100T |
| FPGA device | XC7A100T-1CSG324 |
| FPGA family | Artix-7 |
| Vivado version | 2025.2 |
| HDL | Verilog |
| External memory | DDR3L SDRAM |
| DDR3 memory part | MT41K128M16XX-15E |
| Physical DDR3 data width | 16 bits |
| DDR3 capacity | 256 MB |
| Processor | PicoRV32 AXI |
| DMA | AXI DMA, MM2S |
| Main AXI data width | 128 bits |

---

## 3. System Architecture

The design is organized around two AXI memory-mapped interconnect paths.

### 3.1 Processor and control path

The PicoRV32 AXI wrapper acts as the AXI master for processor-side control and local memory access.

Its SmartConnect routes transactions to:

- AXI DMA control interface (`S_AXI_LITE`)
- AXI BRAM Controller (`S_AXI`)

The processor uses local BRAM for program and data storage and accesses the DMA control registers to configure transfers.

### 3.2 DDR3 and DMA data path

The AXI DMA MM2S channel reads data from the MIG DDR3 memory interface.

The memory-side path is:

`AXI DMA M_AXI_MM2S → SmartConnect_0 → MIG S_AXI → DDR3`

The DMA then produces an AXI4-Stream output. This stream is intended to feed the Global Buffer or the additional BRAM test path.

**Important:** AXI SmartConnect is used for AXI memory-mapped transactions. The DMA AXI4-Stream output is a separate interface and is not routed through SmartConnect.

### 3.3 Additional BRAM test path

An additional `axis_to_bram_writer_0` block and `blk_mem_gen_2` BRAM have been added to investigate the complete data path from the DMA stream into on-chip memory.

The exact writer implementation and its stream/BRAM interface configuration must be verified against the current RTL and Block Design before treating this path as functionally tested.

---

## 4. IP Blocks and Their Roles

### 4.1 PicoRV32 AXI Wrapper — `picorv32_axi_wrapper_0`

**Purpose:** Processor-side control of the system.

The wrapper instantiates the `picorv32_axi` core and exposes an AXI master interface.

Main interfaces:

| Interface / Signal | Purpose |
|---|---|
| `M_AXI` | AXI memory-mapped master interface |
| `aclk` | Processor clock |
| `aresetn` | Active-low processor reset |
| `trap` | PicoRV32 trap indication |

The processor communicates with the DMA control registers and local BRAM through `smartconnect_1`.

The processor is not directly connected to DDR3 in the current architecture. DDR3 data movement is intended to be handled by the DMA.

### 4.2 AXI SmartConnect — `smartconnect_1`

**Purpose:** Processor-side AXI interconnect.

Configuration:

- One slave interface: `S00_AXI`
- Two master interfaces: `M00_AXI`, `M01_AXI`

Connections:

| Interface | Connected block |
|---|---|
| `S00_AXI` | PicoRV32 AXI master |
| `M00_AXI` | AXI DMA `S_AXI_LITE` |
| `M01_AXI` | AXI BRAM Controller `S_AXI` |

The SmartConnect handles address routing between the processor and its two AXI-controlled peripherals.

### 4.3 AXI DMA — `axi_dma_0`

**Purpose:** Transfer data from DDR3 memory and produce an AXI4-Stream output.

Current intended configuration:

| Parameter | Setting |
|---|---|
| MM2S | Enabled |
| S2MM | Disabled |
| Scatter Gather | Disabled |
| Micro DMA | Disabled |
| Memory-mapped data width | 128 bits |
| AXI4-Stream data width | 128 bits |
| Address width | 32 bits |
| Buffer length width | 14 bits |
| Maximum burst size | 4 |
| AXI-Lite control interface | Enabled |

Important interfaces:

| Interface | Purpose |
|---|---|
| `M_AXI_MM2S` | Reads data from DDR3 through SmartConnect |
| `M_AXIS_MM2S` | Streams transferred data to downstream logic |
| `S_AXI_LITE` | Processor configuration and control |
| `s_axi_lite_aclk` | DMA control clock |
| `m_axi_mm2s_aclk` | DMA memory-side clock |

The current design enables MM2S only. A write-back path using S2MM is not enabled.

### 4.4 AXI SmartConnect — `smartconnect_0`

**Purpose:** DDR3 memory-side AXI interconnect.

Main connection:

`axi_dma_0/M_AXI_MM2S → smartconnect_0 → mig_7series_0/S_AXI`

This interconnect routes DMA memory-read transactions to the MIG AXI slave interface.

### 4.5 Memory Interface Generator — `mig_7series_0`

**Purpose:** Interface between the FPGA AXI system and the external DDR3 memory.

DDR3 configuration:

| Parameter | Setting |
|---|---|
| Memory type | DDR3 SDRAM |
| Memory part | MT41K128M16XX-15E |
| Physical data width | 16 bits |
| Memory capacity | 256 MB |
| AXI data width | 128 bits |
| Burst length | 8 |
| CAS latency | 5 |
| ECC | Disabled |
| AXI interface | Enabled |

Important interfaces:

| Interface / Port | Purpose |
|---|---|
| `S_AXI` | AXI memory-mapped interface from the DMA path |
| `ddr3_*` | Physical DDR3 interface |
| `sys_clk_i` | MIG system clock input |
| `clk_ref_i` | MIG reference clock input |
| `sys_rst` | MIG reset input |
| `ui_clk` | MIG-generated user-interface clock |
| `ui_clk_sync_rst` | User-interface synchronous reset |
| `init_calib_complete` | DDR3 initialization/calibration status |

The MIG user-interface clock is used as the clock source for the AXI DMA and other logic in the corresponding clock domain.

### 4.6 Clock Wizard — `clk_wiz_0`

**Purpose:** Generate the clocks required by the MIG and the surrounding logic.

Current intended configuration:

| Parameter | Setting |
|---|---|
| Input clock | 100 MHz |
| Primary input source | No buffer |
| `clk_out1` | 160 MHz |
| `clk_out2` | 200 MHz |

Current intended MIG connections:

| MIG port | Clock source |
|---|---|
| `sys_clk_i` | `clk_wiz_0/clk_out1` |
| `clk_ref_i` | `clk_wiz_0/clk_out2` |

The Clock Wizard primary input was changed to **No buffer** to address the duplicate input-buffer placement conflict between the Clock Wizard and MIG.

The generated clock configuration and MIG clock compatibility must be confirmed in the next successful implementation run.

### 4.7 Processor System Reset — `proc_sys_reset_0`

**Purpose:** Generate synchronized reset signals for the system clock domain.

The block provides reset outputs for the processor, AXI interconnects and peripherals.

Relevant outputs include:

- `peripheral_aresetn`
- `interconnect_aresetn`
- `peripheral_reset`

Reset polarity and clock-domain connections must match the corresponding IP requirements.

### 4.8 Utility Vector Logic — `util_vector_logic_0`

**Purpose:** Perform reset polarity conversion where required.

The block is configured as a one-bit inverter in the current design.

Its connection must be checked against the active reset polarity of the Clock Wizard and MIG.

### 4.9 AXI BRAM Controller — `axi_bram_ctrl_0`

**Purpose:** Provide an AXI-accessible interface to local FPGA Block RAM.

Main interface:

| Interface | Purpose |
|---|---|
| `S_AXI` | AXI access from PicoRV32 through `smartconnect_1` |
| `BRAM_PORTA` | Connection to the Block Memory Generator |

The processor accesses local BRAM through this controller.

The configured address window is intended to be 8 KB at base address `0x00000000`. Confirm the controller's data width and actual BRAM depth before relying on this capacity in firmware.

### 4.10 Block Memory Generator — `blk_mem_gen_0`

**Purpose:** Local BRAM connected to the AXI BRAM Controller.

The BRAM is intended to store PicoRV32 program and data.

Its actual width and depth must be checked against the AXI BRAM Controller configuration and the Address Editor mapping.

### 4.11 AXI-Stream to BRAM Writer — `axis_to_bram_writer_0`

**Purpose:** Additional RTL block introduced to test writing incoming AXI-Stream data into BRAM.

The intended input is the DMA AXI4-Stream output. Its BRAM-side interface connects to the additional Block Memory Generator.

The RTL implementation, handshake logic (`TVALID`, `TREADY`, `TLAST`) and BRAM write-control signals must be verified before functional testing.

### 4.12 Additional Block Memory Generator — `blk_mem_gen_2`

**Purpose:** BRAM storage for the additional stream-to-memory test path.

This memory was added to help validate the DMA-to-BRAM data flow independently of the main processor-local BRAM.

---

## 5. Address Map

The current intended address assignments are:

| Peripheral | Base address | Address range |
|---|---:|---:|
| AXI BRAM Controller | `0x00000000` | 8 KB |
| AXI DMA | `0x41E00000` | 64 KB |
| MIG DDR3 | `0x80000000` | 256 MB |

These values should be checked against the latest Vivado Address Editor after IP regeneration or address-map changes.

---

## 6. Clock and Reset Constraints

### 6.1 Board clock

The Arty A7 onboard 100 MHz oscillator is connected to:

- Top-level port: `clk_in1_0`
- Package pin: `E3`
- I/O standard: `LVCMOS33`

### 6.2 Reset input

The current intended reset mapping is:

- Top-level port: `sys_rst_0`
- Package pin: `D9`
- I/O standard: `LVCMOS33`

This is intended to use the Arty A7 BTN0 pin. Verify the reset polarity and the actual implemented pin assignments before hardware testing.

### 6.3 XDC file

The board constraints are maintained in:

`DDR3.srcs/constrs_1/new/arty7.xdc`

Current intended contents:

```tcl
# Arty A7 onboard 100 MHz oscillator
set_property PACKAGE_PIN E3 [get_ports {clk_in1_0}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk_in1_0}]

# Arty A7 BTN0 reset input
set_property PACKAGE_PIN D9 [get_ports {sys_rst_0}]
set_property IOSTANDARD LVCMOS33 [get_ports {sys_rst_0}]
```

Do not put `reset_property` commands in the XDC file. Vivado reports that this command is unsupported in XDC constraints.

The Clock Wizard also generates its own clock constraints. Avoid defining a duplicate `create_clock` on the same input port unless the existing IP constraint is deliberately managed.

---

## 7. Expected Data Flow

The intended transfer sequence is:

1. PicoRV32 executes firmware from local BRAM.
2. PicoRV32 configures the AXI DMA through its AXI-Lite control interface.
3. The DMA reads a data block from the DDR3 address space.
4. DMA memory transactions pass through `smartconnect_0` to the MIG.
5. MIG accesses external DDR3 and returns the requested data.
6. The DMA produces a 128-bit AXI4-Stream output.
7. The stream is directed to the downstream Global Buffer or the additional BRAM test path.
8. The downstream accelerator is intended to consume the data.

The eventual accelerator architecture is intended to support double buffering so that data transfer and computation can overlap.

This complete sequence remains a target for functional verification; it should not be considered proven until DMA transfers and downstream writes are tested.

---

## 8. Build and Verification Status

| Stage | Status |
|---|---|
| Vivado project creation | Completed |
| MIG IP configuration | Configured; clock compatibility to be reverified |
| AXI DMA MM2S configuration | Configured |
| SmartConnect control path | Integrated |
| SmartConnect DDR3 path | Integrated |
| PicoRV32 AXI wrapper | Added |
| Processor-local BRAM path | Integrated; memory depth to be verified |
| Additional stream-to-BRAM test path | Added; functional verification pending |
| Clock Wizard input source changed to No buffer | Configured; implementation verification pending |
| Board clock XDC | Updated for E3 |
| Reset XDC | Updated for D9; implementation verification pending |
| Successful final implementation | Pending |
| Bitstream generation | Pending |
| Hardware DDR3 DMA transfer test | Pending |
| Global Buffer and accelerator integration | Pending |

---

## 9. Important Verification Checklist

Before considering the design complete:

- [ ] Confirm the Clock Wizard output frequencies and MIG clock inputs.
- [