# Async FIFO - Quick Start Guide

## Installation

```bash
# Install tools (macOS)
brew install icarus-verilog gtkwave

# Or on Linux (Ubuntu/Debian)
sudo apt-get install iverilog gtkwave
```

## Run Simulation

```bash
# Compile and simulate
make all

# Or step by step
make compile    # Compile RTL and testbench
make sim        # Run simulation
```

## View Waveforms

```bash
make wave       # Opens GTKWave
```

## Expected Output

```
=== Async FIFO Test ===

[Test 1] Basic Write/Read
[165000] WRITE: 0xa5
[372000] READ: 0xa5 (OK)
[Test 1] Complete

[Test 2] Fill and Drain
...
[Test 2] Complete

[Test 3] Burst Operations
...
[Test 3] Complete

=== FINAL REPORT ===
Writes: 33, Reads: 33, Errors: 0
TEST PASSED!
```

## Project Files

```
rtl/                    # RTL source code
  async_fifo.v          # Main FIFO module
  gray_counter.v        # Gray code counter
  synchronizer.v        # CDC synchronizer
  dual_port_ram.v       # Memory

tb/                     # Testbenches
  tb_async_fifo_simple.v # Working testbench

sim/                    # Generated outputs
  async_fifo.vcd        # Waveform file
  async_fifo.vvp        # Compiled simulation

docs/                   # Documentation
  design_doc.md         # Design details
  verification_report.md # Test results
  issues_log.md         # Debugging notes
```

## Key Parameters

```verilog
parameter DATA_WIDTH = 8;    // Data bus width
parameter ADDR_WIDTH = 4;    // Address width (depth = 2^4 = 16)
```

## Module Interface

```verilog
// Write side
input  wclk           // Write clock
input  wrst_n         // Write reset (active low)
input  wen            // Write enable
input  [7:0] wdata    // Write data
output wfull          // Full flag

// Read side
input  rclk           // Read clock
input  rrst_n         // Read reset (active low)
input  ren            // Read enable
output [7:0] rdata    // Read data
output rempty         // Empty flag
```

## Usage Notes

1. **Wait for synchronization**: After writes, wait 2-3 read clocks before reading
2. **Check flags**: Only write when `!wfull`, only read when `!rempty`
3. **Independent clocks**: Write and read clocks can be completely asynchronous
4. **Data latency**: Data appears 2-3 cycles after write (due to CDC sync)

## Troubleshooting

### Simulation fails to run
```bash
# Check iverilog is installed
iverilog -v

# Clean and rebuild
rm -rf sim/*
make all
```

### Waveform won't open
```bash
# Check gtkwave is installed
gtkwave --version

# Manually open waveform
gtkwave sim/async_fifo.vcd &
```

### Compilation errors
- Ensure all RTL files are present in `rtl/`
- Check for syntax errors in Verilog files
- Verify iverilog supports Verilog-2012 (`-g2012` flag)

## Next Steps

1. Read `README.md` for overview
2. Check `docs/design_doc.md` for technical details
3. Review `docs/verification_report.md` for test results
4. See `PROJECT_SUMMARY.md` for complete project status

## Support

For issues or questions:
- Check `docs/issues_log.md` for common problems
- Review waveforms in GTKWave
- Consult design documentation

---

**Status**: ✅ Fully functional and tested
**Last Updated**: 2026-02-09
