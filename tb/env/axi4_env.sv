// =============================================================================
// File        : axi4_env.sv
// Description : Top-level UVM environment.
//               Instantiates agent, scoreboard, and coverage collector.
//               Wires monitor analysis port to both scoreboard and coverage.
// =============================================================================

`ifndef AXI4_ENV_SV
`define AXI4_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_env extends uvm_env;
    `uvm_component_utils(axi4_env)

    axi4_agent      agt;
    axi4_scoreboard scb;
    axi4_coverage   cov;
    axi4_cfg        m_cfg;

    function new(string name = "axi4_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(axi4_cfg)::get(this, "", "m_cfg", m_cfg))
            `uvm_fatal(get_full_name(), "axi4_cfg not found in config_db")

        // Propagate cfg to all children via wildcard path
        uvm_config_db #(axi4_cfg)::set(this, "*", "m_cfg", m_cfg);

        agt = axi4_agent::type_id::create("agt", this);
        scb = axi4_scoreboard::type_id::create("scb", this);
        cov = axi4_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        // Monitor analysis port fans out to scoreboard and coverage
        agt.mon.ap.connect(scb.analysis_export);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction

endclass : axi4_env

`endif // AXI4_ENV_SV
