// =============================================================================
// File        : axi4_tests.sv
// =============================================================================

`ifndef AXI4_TESTS_SV
`define AXI4_TESTS_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// =============================================================================
// Base test — cfg + env setup only; not run directly
// =============================================================================
class axi4_base_test extends uvm_test;
    `uvm_component_utils(axi4_base_test)

    axi4_env m_env;
    axi4_cfg m_cfg;

    function new(string name = "axi4_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_cfg = axi4_cfg::type_id::create("m_cfg");

        // Make cfg available to all components under this test
        uvm_config_db #(axi4_cfg)::set(this, "*", "m_cfg", m_cfg);

        // Set agent to active mode
        uvm_config_db #(uvm_active_passive_enum)::set(
            this, "m_env.agt", "is_active", UVM_ACTIVE);

        m_env = axi4_env::type_id::create("m_env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

endclass : axi4_base_test


// =============================================================================
// Randomised test — fully random reads and writes
// =============================================================================
class axi4_rand_test extends axi4_base_test;
    `uvm_component_utils(axi4_rand_test)

    axi4_base_seq m_seq;

    function new(string name = "axi4_rand_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_seq = axi4_base_seq::type_id::create("m_seq");
        m_seq.num_transactions = 200;
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this, "axi4_rand_test running");
        `uvm_info(get_type_name(), "Starting axi4_rand_test", UVM_LOW)
        m_seq.start(m_env.agt.sqr);
        `uvm_info(get_type_name(), "axi4_rand_test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass : axi4_rand_test


// =============================================================================
// Write-then-read test — data integrity end-to-end
// =============================================================================
class axi4_wr_rd_test extends axi4_base_test;
    `uvm_component_utils(axi4_wr_rd_test)

    axi4_wr_rd_seq m_seq;

    function new(string name = "axi4_wr_rd_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_seq = axi4_wr_rd_seq::type_id::create("m_seq");
        m_seq.num_pairs = 100;
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this, "axi4_wr_rd_test running");
        `uvm_info(get_type_name(), "Starting axi4_wr_rd_test", UVM_LOW)
        m_seq.start(m_env.agt.sqr);
        `uvm_info(get_type_name(), "axi4_wr_rd_test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass : axi4_wr_rd_test


// =============================================================================
// Error test — SLVERR boundary and range paths
// =============================================================================
class axi4_error_test extends axi4_base_test;
    `uvm_component_utils(axi4_error_test)

    axi4_error_seq m_seq;

    function new(string name = "axi4_error_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_seq = axi4_error_seq::type_id::create("m_seq");
        m_seq.reps_per_scenario = 10;
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this, "axi4_error_test running");
        `uvm_info(get_type_name(), "Starting axi4_error_test", UVM_LOW)
        m_seq.start(m_env.agt.sqr);
        `uvm_info(get_type_name(), "axi4_error_test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass : axi4_error_test

`endif // AXI4_TESTS_SV
