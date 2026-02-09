# Asynchronous FIFO Design and Verification

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Verilog](https://img.shields.io/badge/Language-Verilog-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen.svg)]()
[![Documentation](https://img.shields.io/badge/Docs-Complete-blue.svg)]()

This project implements a parameterized asynchronous FIFO (First-In-First-Out) buffer for safe clock domain crossing (CDC) in digital designs.

## Features

- **Parameterized Design**: Configurable data width and FIFO depth
- **Gray Code Pointers**: Safe clock domain crossing with minimal metastability risk
- **2-Stage Synchronizers**: CDC protection for pointer synchronization
- **Full/Empty Flags**: Reliable status indicators in respective clock domains
- **Dual-Port RAM**: Independent read and write ports

## Project Structure

```
async_fifo_test/
├── rtl/                    # RTL source files
│   ├── async_fifo.v        # Top-level async FIFO module
│   ├── gray_counter.v      # Gray code counter
│   ├── synchronizer.v      # 2-stage synchronizer
│   └── dual_port_ram.v     # Dual-port RAM
├── tb/                     # Testbench files
│   └── tb_async_fifo.v     # Comprehensive testbench
├── sim/                    # Simulation outputs (generated)
│   ├── async_fifo.vvp      # Compiled simulation
│   └── async_fifo.vcd      # Waveform dump
├── docs/                   # Documentation
│   ├── design_doc.md       # Design documentation
│   ├── verification_report.md  # Verification report
│   └── issues_log.md       # Issues and solutions
├── Makefile                # Build automation
└── README.md               # This file
```

## Requirements

- **iverilog**: Icarus Verilog simulator
- **gtkwave**: Waveform viewer

### Installation on macOS

```bash
brew install icarus-verilog gtkwave
```

### Installation on Linux (Ubuntu/Debian)

```bash
sudo apt-get install iverilog gtkwave
```

## Quick Start

### Compile and Run Simulation

```bash
make all
```

This will compile the RTL and testbench, then run the simulation.

### View Waveforms

```bash
make wave
```

Opens the waveform viewer (gtkwave) with the simulation results.

### Clean Generated Files

```bash
make clean
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make all` | Compile and run simulation (default) |
| `make compile` | Compile RTL and testbench |
| `make sim` | Run simulation |
| `make wave` | Open waveform viewer |
| `make clean` | Remove generated files |
| `make help` | Show help message |

## Design Parameters

The async FIFO can be configured with the following parameters:

```verilog
parameter DATA_WIDTH = 8;    // Data bus width (bits)
parameter ADDR_WIDTH = 4;    // Address width (FIFO depth = 2^ADDR_WIDTH)
```

Default configuration:
- Data width: 8 bits
- FIFO depth: 16 entries (2^4)

## Module Interface

### Ports

**Write Side (wclk domain):**
- `wclk`: Write clock
- `wrst_n`: Write reset (active low)
- `wen`: Write enable
- `wdata[DATA_WIDTH-1:0]`: Write data
- `wfull`: Full flag (output)

**Read Side (rclk domain):**
- `rclk`: Read clock
- `rrst_n`: Read reset (active low)
- `ren`: Read enable
- `rdata[DATA_WIDTH-1:0]`: Read data (output)
- `rempty`: Empty flag (output)

## Test Coverage

The testbench includes the following test scenarios:

1. **Basic Write/Read**: Single write and read operations
2. **Fill/Empty**: Fill FIFO completely and empty it
3. **Continuous Operations**: Simultaneous write and read
4. **Random Operations**: Randomized delays and data patterns
5. **Boundary Conditions**: Write when full, read when empty
6. **Stress Test**: Long-duration random operations

## Verification Features

- **Self-Checking**: Automatic data integrity verification
- **Coverage Monitoring**: Tracks full/empty events
- **Error Reporting**: Detailed error messages with timestamps
- **Statistical Analysis**: Final report with operation counts

## Design Details

### Gray Code Counter

Gray code ensures only one bit changes at a time during pointer increments, reducing metastability risk when crossing clock domains.

### Synchronizer

2-stage flip-flop chain synchronizes Gray code pointers between clock domains, providing proper CDC handling.

### Full/Empty Logic

- **Full**: Write pointer catches up to read pointer (with MSB inversion check)
- **Empty**: Read pointer equals write pointer

## Performance

- **Latency**: 2-3 clock cycles (due to synchronizer stages)
- **Throughput**: One word per clock cycle (when not full/empty)
- **Clock Ratio**: Supports arbitrary clock frequency ratios

## Documentation

Detailed documentation is available in the `docs/` directory:

- [Design Documentation](docs/design_doc.md)
- [Verification Report](docs/verification_report.md)
- [Issues and Solutions](docs/issues_log.md)

## License

This is an educational project for learning digital design and verification.

## References

- Clifford E. Cummings, "Simulation and Synthesis Techniques for Asynchronous FIFO Design"
- Clock Domain Crossing (CDC) Design & Verification Techniques
