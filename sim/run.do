# =============================================================================
# File   : run.do
# Tool   : QuestaSim / ModelSim
# Usage  :
#   vsim -do sim/run.do
#   vsim -do sim/run.do +UVM_TESTNAME=<test_name>
# =============================================================================

quietly set ROOT [file normalize [file dirname [info script]]/..]
quietly set RTL  $ROOT/rtl
quietly set TB   $ROOT/tb

# Clean previous sim
if {[catch {quit -sim}]} {}
if {[file exists work]} { vdel -all }
vlib work
vmap work work

# -----------------------------------------------------------------------------
# Compile RTL
# -----------------------------------------------------------------------------
vlog -sv -timescale "1ns/1ps" +cover=bcstf \
    $RTL/axi4_memory.sv \
    $RTL/axi4.sv

# -----------------------------------------------------------------------------
# Compile TB (order matters)
# -----------------------------------------------------------------------------
vlog -sv -timescale "1ns/1ps" +cover=bcstf \
    +incdir+$TB/pkg \
    +incdir+$TB/agent \
    +incdir+$TB/env \
    +incdir+$TB/seq \
    +incdir+$TB/test \
    $TB/pkg/axi4_types.sv \
    $TB/agent/axi4_if.sv \
    $TB/pkg/axi4_pkg.sv \
    $TB/env/axi4_assertions.sv \
    $TB/test/tb_top.sv

# -----------------------------------------------------------------------------
# Run Simulation
# -----------------------------------------------------------------------------
vsim -coverage \
     -assertdebug \
     +UVM_VERBOSITY=UVM_LOW \
     work.tb_top

run -all

# -----------------------------------------------------------------------------
# Coverage Reports
# -----------------------------------------------------------------------------
coverage report -assert   -file sim/rpt_assertions.txt
coverage report -cvg      -file sim/rpt_functional_cov.txt
coverage report -code bcstf -file sim/rpt_code_cov.txt

echo "=== Simulation complete ==="