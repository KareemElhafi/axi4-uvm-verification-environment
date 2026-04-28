# =============================================================================
# AXI4 UVM Verification Makefile
# Targets: run | clean
# =============================================================================

VLOG = vlog -sv -timescale "1ns/1ps" +cover=bcstf
VSIM = vsim -coverage -assertdebug -batch +UVM_VERBOSITY=UVM_LOW

RTL = ../rtl
TB  = ../tb

INCDIRS = \
    +incdir+$(TB)/pkg \
    +incdir+$(TB)/agent \
    +incdir+$(TB)/env \
    +incdir+$(TB)/seq \
    +incdir+$(TB)/test

RTL_FILES = \
    $(RTL)/axi4_memory.sv \
    $(RTL)/axi4.sv

TB_FILES = \
    $(TB)/pkg/axi4_types.sv \
    $(TB)/agent/axi4_if.sv \
    $(TB)/pkg/axi4_pkg.sv \
    $(TB)/env/axi4_assertions.sv \
    $(TB)/test/tb_top.sv

.PHONY: run clean

# -----------------------------------------------------------------------------
# Compile + Run
# -----------------------------------------------------------------------------
run:
	@if [ -d work ]; then vdel -all; fi
	vlib work && vmap work work
	$(VLOG) $(RTL_FILES)
	$(VLOG) $(INCDIRS) $(TB_FILES)
	$(VSIM) -do "run -all; quit -f" work.tb_top \
	        | tee sim.log
	@echo "=== Simulation done ==="

# -----------------------------------------------------------------------------
# Clean
# -----------------------------------------------------------------------------
clean:
	rm -rf work transcript *.log *.wlf rpt_*.txt
	@echo "Clean done."