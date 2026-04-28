// =============================================================================
// File        : axi4_agent.sv
// Description : AXI4 UVM agent — active by default.
//               Monitor is passive (read-only); driver owns all handshakes.
// =============================================================================

`ifndef AXI4_AGENT_SV
`define AXI4_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_agent extends uvm_agent;
    `uvm_component_utils(axi4_agent)

    axi4_sequencer sqr;
    axi4_driver    drv;
    axi4_monitor   mon;

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "axi4_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(uvm_active_passive_enum)::get(
                this, "", "is_active", is_active))
            `uvm_info(get_type_name(), "is_active not set — default UVM_ACTIVE", UVM_LOW)

        mon = axi4_monitor::type_id::create("mon", this);

        if (is_active == UVM_ACTIVE) begin
            sqr = axi4_sequencer::type_id::create("sqr", this);
            drv = axi4_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if (is_active == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass : axi4_agent

`endif // AXI4_AGENT_SV
