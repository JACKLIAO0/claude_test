#===============================================================================
# Makefile for Async FIFO Simulation
#===============================================================================

# Directories
RTL_DIR = rtl
TB_DIR  = tb
SIM_DIR = sim

# Source files
RTL_SRCS = $(RTL_DIR)/dual_port_ram.v \
           $(RTL_DIR)/gray_counter.v \
           $(RTL_DIR)/synchronizer.v \
           $(RTL_DIR)/async_fifo.v

TB_SRCS = $(TB_DIR)/tb_async_fifo_simple.v

# Simulation outputs
VVP_FILE = $(SIM_DIR)/async_fifo.vvp
VCD_FILE = $(SIM_DIR)/async_fifo.vcd

# Tools
IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

# Flags
IVERILOG_FLAGS = -g2012 -Wall

#===============================================================================
# Targets
#===============================================================================

.PHONY: all compile sim wave clean help

# Default target
all: compile sim

# Compile RTL and testbench
compile: $(VVP_FILE)

$(VVP_FILE): $(RTL_SRCS) $(TB_SRCS)
	@echo "=========================================="
	@echo "Compiling RTL and Testbench..."
	@echo "=========================================="
	@mkdir -p $(SIM_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(VVP_FILE) $(RTL_SRCS) $(TB_SRCS)
	@echo "Compilation successful!"
	@echo ""

# Run simulation
sim: $(VVP_FILE)
	@echo "=========================================="
	@echo "Running Simulation..."
	@echo "=========================================="
	cd $(SIM_DIR) && $(VVP) async_fifo.vvp
	@echo ""
	@echo "Simulation completed!"
	@echo "Waveform saved to: $(VCD_FILE)"
	@echo ""

# Open waveform viewer
wave: $(VCD_FILE)
	@echo "Opening waveform viewer..."
	$(GTKWAVE) $(VCD_FILE) &

# Clean generated files
clean:
	@echo "Cleaning up..."
	rm -rf $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd
	@echo "Clean complete!"

# Help
help:
	@echo "Available targets:"
	@echo "  make all      - Compile and run simulation (default)"
	@echo "  make compile  - Compile RTL and testbench"
	@echo "  make sim      - Run simulation"
	@echo "  make wave     - Open waveform viewer"
	@echo "  make clean    - Remove generated files"
	@echo "  make help     - Show this help message"
