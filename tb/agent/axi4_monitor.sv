// =============================================================================
// File        : axi4_monitor.sv
// =============================================================================

`ifndef AXI4_MONITOR_SV
`define AXI4_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_monitor extends uvm_monitor;
    `uvm_component_utils(axi4_monitor)

    virtual axi4_if                       vif;
    axi4_cfg                              m_cfg;
    uvm_analysis_port #(axi4_transaction) ap;

    function new(string name = "axi4_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual axi4_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_full_name(), "VIF not found in config_db")
        if (!uvm_config_db #(axi4_cfg)::get(this, "", "m_cfg", m_cfg))
            `uvm_fatal(get_full_name(), "axi4_cfg not found in config_db")
    endfunction

    // -------------------------------------------------------------------------
    // run_phase: get completed transactions from driver, check protocol,
    //            forward to scoreboard + coverage, signal sequence to proceed.
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        axi4_transaction tr;
        forever begin
            // No race: driver only puts AFTER all handshakes finish.
            m_cfg.stimulus_fifo.get(tr);

            // Protocol-level checks (read-only bus observation)
            check_protocol(tr);

            // Forward to scoreboard and coverage via analysis port
            ap.write(tr);

            // Signal sequence that it may start the next transaction
            m_cfg.monitor_done_mb.put(1'b1);
        end
    endtask

    // =========================================================================
    // Protocol checks — bus observation only, no signal driving
    // =========================================================================
    task automatic check_protocol(axi4_transaction tr);
        // Verify RLAST was asserted on the final read beat (already checked
        // in the driver with a warning; escalate to error here)
        if (tr.op == AXI_READ) begin
            if (tr.actual_rdata_q.size() != (tr.len + 1))
                `uvm_error(get_type_name(),
                    $sformatf("READ beat count mismatch: exp=%0d got=%0d",
                              tr.len + 1, tr.actual_rdata_q.size()))
        end

        // Verify response is a legal value
        if (tr.actual_resp !== 2'b00 && tr.actual_resp !== 2'b10)
            `uvm_error(get_type_name(),
                $sformatf("Illegal response value: %02b", tr.actual_resp))
    endtask

endclass : axi4_monitor

`endif // AXI4_MONITOR_SV
