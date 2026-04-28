// =============================================================================
// File        : axi4_cfg.sv
// =============================================================================

`ifndef AXI4_CFG_SV
`define AXI4_CFG_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// Forward declaration — full class defined in axi4_transaction.sv
typedef class axi4_transaction;

class axi4_cfg extends uvm_object;
    `uvm_object_utils(axi4_cfg)

    // -------------------------------------------------------------------------
    // Driver puts completed transactions; monitor gets them.
    // Bounded to 1 so the driver naturally back-pressures the sequence.
    // -------------------------------------------------------------------------
    uvm_tlm_fifo #(axi4_transaction) stimulus_fifo;

    // -------------------------------------------------------------------------
    // Sequence waits on this before starting the next item, guaranteeing
    // the scoreboard has seen the response before new stimulus begins.
    // -------------------------------------------------------------------------
    mailbox #(bit) monitor_done_mb;

    // Configurable timeout in clock cycles
    int unsigned handshake_timeout = 200;

    function new(string name = "axi4_cfg");
        super.new(name);
        stimulus_fifo   = new("stimulus_fifo", 1);
        monitor_done_mb = new(1);
    endfunction

endclass : axi4_cfg

`endif // AXI4_CFG_SV
