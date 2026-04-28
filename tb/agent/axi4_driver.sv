// =============================================================================
// File        : axi4_driver.sv
// =============================================================================

`ifndef AXI4_DRIVER_SV
`define AXI4_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_driver extends uvm_driver #(axi4_transaction);
    `uvm_component_utils(axi4_driver)

    virtual axi4_if vif;
    axi4_cfg        m_cfg;

    function new(string name = "axi4_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual axi4_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_full_name(), "VIF not found in config_db")
        if (!uvm_config_db #(axi4_cfg)::get(this, "", "m_cfg", m_cfg))
            `uvm_fatal(get_full_name(), "axi4_cfg not found in config_db")
    endfunction

    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        axi4_transaction req;
        apply_reset();
        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask

    // =========================================================================
    // Reset
    // =========================================================================
    task automatic apply_reset();
        vif.ARESETn <= 1'b0;
        clear_master_signals();
        repeat (5) @(posedge vif.ACLK);
        @(negedge vif.ACLK);
        vif.ARESETn <= 1'b1;
        repeat (2) @(posedge vif.ACLK);
    endtask

    task automatic clear_master_signals();
        vif.AWVALID <= 1'b0; vif.AWADDR <= '0;
        vif.AWLEN   <= '0;   vif.AWSIZE <= '0;
        vif.WVALID  <= 1'b0; vif.WDATA  <= '0; vif.WLAST <= 1'b0;
        vif.BREADY  <= 1'b0;
        vif.ARVALID <= 1'b0; vif.ARADDR <= '0;
        vif.ARLEN   <= '0;   vif.ARSIZE <= '0;
        vif.RREADY  <= 1'b0;
    endtask

    // =========================================================================
    // Top-level dispatch
    // =========================================================================
    task automatic drive_transaction(axi4_transaction req);
        axi4_transaction tr_done;

        // Clone so monitor gets an immutable snapshot
        $cast(tr_done, req.clone());
        tr_done.actual_rdata_q = new[0];
        tr_done.actual_resp    = '0;

        if (req.op == AXI_WRITE)
            drive_write(req, tr_done);
        else
            drive_read(req, tr_done);


        // stimulus_fifo is bounded to 1 — this call blocks if the monitor has
        // not yet consumed the previous entry, providing natural back-pressure.
        m_cfg.stimulus_fifo.put(tr_done);
    endtask

    // =========================================================================
    // Write transaction: AW → W → B (all three channels, fully in driver)
    // =========================================================================
    task automatic drive_write(
        input  axi4_transaction req,
        inout  axi4_transaction tr_done
    );
        // --- Write address phase ---
        repeat (req.aw_valid_delay) @(negedge vif.ACLK);
        @(negedge vif.ACLK);
        vif.AWADDR  <= req.addr;
        vif.AWLEN   <= req.len;
        vif.AWSIZE  <= req.size;
        vif.AWVALID <= 1'b1;
        wait_handshake(vif.AWREADY, "AWREADY");
        @(negedge vif.ACLK);
        vif.AWVALID <= 1'b0;

        // --- Write data phase ---
        repeat (req.w_valid_delay) @(negedge vif.ACLK);
        // FIX #6: iterate over transaction's write_data_q directly
        for (int i = 0; i <= req.len; i++) begin
            @(negedge vif.ACLK);
            vif.WDATA  <= req.write_data_q[i];
            vif.WVALID <= 1'b1;
            vif.WLAST  <= (i == int'(req.len));
            wait_handshake(vif.WREADY, "WREADY");
            @(negedge vif.ACLK);
            vif.WVALID <= 1'b0;
            vif.WLAST  <= 1'b0;
            if (i < int'(req.len))
                repeat ($urandom_range(0, req.w_valid_delay)) @(negedge vif.ACLK);
        end

        // --- Write response phase (FIX #1: BREADY driven HERE, not in monitor) ---
        repeat (req.b_ready_delay) @(negedge vif.ACLK);
        @(negedge vif.ACLK);
        vif.BREADY <= 1'b1;
        wait_handshake(vif.BVALID, "BVALID");
        // Sample BRESP at the posedge where both BVALID && BREADY are high
        @(posedge vif.ACLK);
        while (!(vif.BVALID && vif.BREADY)) @(posedge vif.ACLK);
        tr_done.actual_resp = vif.BRESP;
        @(negedge vif.ACLK);
        vif.BREADY <= 1'b0;
    endtask

    // =========================================================================
    // Read transaction: AR → R (driver owns RREADY, collects data)
    // =========================================================================
    task automatic drive_read(
        input  axi4_transaction req,
        inout  axi4_transaction tr_done
    );
        tr_done.actual_rdata_q = new[req.len + 1];

        // --- Read address phase ---
        repeat (req.ar_valid_delay) @(negedge vif.ACLK);
        @(negedge vif.ACLK);
        vif.ARADDR  <= req.addr;
        vif.ARLEN   <= req.len;
        vif.ARSIZE  <= req.size;
        vif.ARVALID <= 1'b1;
        wait_handshake(vif.ARREADY, "ARREADY");
        @(negedge vif.ACLK);
        vif.ARVALID <= 1'b0;

        // --- Read data phase (FIX #1: RREADY driven HERE, not in monitor) ---
        vif.RREADY <= 1'b1;
        for (int i = 0; i <= int'(req.len); i++) begin
            if (req.r_ready_delay > 0) begin
                vif.RREADY <= 1'b0;
                repeat (req.r_ready_delay) @(negedge vif.ACLK);
                @(negedge vif.ACLK);
                vif.RREADY <= 1'b1;
            end
            wait_handshake(vif.RVALID, "RVALID");
            // Sample at posedge where handshake completes
            @(posedge vif.ACLK);
            while (!(vif.RVALID && vif.RREADY)) @(posedge vif.ACLK);
            tr_done.actual_rdata_q[i] = vif.RDATA;
            tr_done.actual_resp       = vif.RRESP;
            if (i == int'(req.len) && !vif.RLAST)
                `uvm_warning(get_type_name(),
                    $sformatf("RLAST not asserted on final beat %0d", i))
            @(negedge vif.ACLK);
        end
        vif.RREADY <= 1'b0;
    endtask

    // =========================================================================
    // Handshake helper with configurable timeout
    // =========================================================================
    task automatic wait_handshake(input logic sig, input string sig_name);
        int unsigned cnt = 0;
        @(negedge vif.ACLK);
        while (!sig) begin
            @(negedge vif.ACLK);
            if (++cnt >= m_cfg.handshake_timeout)
                `uvm_fatal(get_type_name(),
                    $sformatf("Timeout(%0d) waiting for %s",
                              m_cfg.handshake_timeout, sig_name))
        end
    endtask

endclass : axi4_driver

`endif // AXI4_DRIVER_SV