// =============================================================================
// File        : axi4_sequencer.sv
// Description : Standard UVM sequencer parameterised on axi4_transaction.
//               Holds m_cfg so sequences can access handshake_timeout and
//               monitor_done_mb without going to config_db themselves.
// =============================================================================

`ifndef AXI4_SEQUENCER_SV
`define AXI4_SEQUENCER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_sequencer extends uvm_sequencer #(axi4_transaction);
    `uvm_component_utils(axi4_sequencer)

    axi4_cfg m_cfg;

    function new(string name = "axi4_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(axi4_cfg)::get(this, "", "m_cfg", m_cfg))
            `uvm_fatal(get_full_name(), "axi4_cfg not found in config_db")
    endfunction

endclass : axi4_sequencer

`endif // AXI4_SEQUENCER_SV
