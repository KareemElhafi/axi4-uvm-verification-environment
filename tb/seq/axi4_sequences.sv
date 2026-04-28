// =============================================================================
// File        : axi4_sequences.sv
// =============================================================================

`ifndef AXI4_SEQUENCES_SV
`define AXI4_SEQUENCES_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// =============================================================================
// axi4_base_seq — fully randomised read/write transactions
// =============================================================================
class axi4_base_seq extends uvm_sequence #(axi4_transaction);
    `uvm_object_utils(axi4_base_seq)

    int unsigned num_transactions = 200;

    function new(string name = "axi4_base_seq");
        super.new(name);
    endfunction

    task body();
        axi4_sequencer sqr;
        axi4_transaction req;
        bit done;

        if (!$cast(sqr, m_sequencer))
            `uvm_fatal(get_type_name(), "Cannot cast sequencer")

        `uvm_info(get_type_name(),
            $sformatf("Starting — %0d transactions", num_transactions), UVM_LOW)

        repeat (num_transactions) begin
            req = axi4_transaction::type_id::create("req");

            start_item(req);
            if (!req.randomize())
                `uvm_fatal(get_type_name(), "Randomisation failed")
            finish_item(req);

            // FIX #2: wait until monitor has processed this transaction.
            // monitor_done_mb.get() blocks until the monitor calls .put(),
            // which happens only after ap.write() — guaranteeing the
            // scoreboard has seen the result before we start the next item.
            void'(sqr.m_cfg.monitor_done_mb.get());
        end

        `uvm_info(get_type_name(),
            $sformatf("Done — %0d transactions", num_transactions), UVM_LOW)
    endtask

endclass : axi4_base_seq


// =============================================================================
// Writes a burst, then reads the same address with the same length.
// Scoreboard verifies data integrity end-to-end through the AXI protocol.
// =============================================================================
class axi4_wr_rd_seq extends uvm_sequence #(axi4_transaction);
    `uvm_object_utils(axi4_wr_rd_seq)

    int unsigned num_pairs = 100;

    function new(string name = "axi4_wr_rd_seq");
        super.new(name);
    endfunction

    task body();
        axi4_sequencer   sqr;
        axi4_transaction wr_req, rd_req;

        if (!$cast(sqr, m_sequencer))
            `uvm_fatal(get_type_name(), "Cannot cast sequencer")

        `uvm_info(get_type_name(),
            $sformatf("Starting %0d write-read pairs", num_pairs), UVM_LOW)

        repeat (num_pairs) begin

            // -----------------------------------------------------------------
            // Step 1: randomise a VALID write transaction
            // -----------------------------------------------------------------
            wr_req = axi4_transaction::type_id::create("wr_req");
            start_item(wr_req);
            if (!wr_req.randomize() with {
                op          == AXI_WRITE;
                valid_range == 1'b1;        // must be in-range
                len         inside {[8'd0:8'd15]}; // short bursts for speed
            })
                `uvm_fatal(get_type_name(), "Write randomisation failed")
            finish_item(wr_req);
            void'(sqr.m_cfg.monitor_done_mb.get());

            // -----------------------------------------------------------------
            // Step 2: read the same address and burst length
            // -----------------------------------------------------------------
            rd_req = axi4_transaction::type_id::create("rd_req");
            start_item(rd_req);
            // FIX #8: use inline constraints (no rand_mode / constraint_mode)
            if (!rd_req.randomize() with {
                op          == AXI_READ;
                addr        == wr_req.addr;
                len         == wr_req.len;
                size        == wr_req.size;
                valid_range == 1'b1;
            })
                `uvm_fatal(get_type_name(), "Read randomisation failed")
            finish_item(rd_req);
            void'(sqr.m_cfg.monitor_done_mb.get());
        end

        `uvm_info(get_type_name(),
            $sformatf("Done — %0d pairs", num_pairs), UVM_LOW)
    endtask

endclass : axi4_wr_rd_seq


// =============================================================================
// axi4_error_seq — targets boundary/out-of-range SLVERR paths
// =============================================================================
class axi4_error_seq extends uvm_sequence #(axi4_transaction);
    `uvm_object_utils(axi4_error_seq)

    typedef struct {
        logic [15:0] addr;
        logic [7:0]  len;
        axi4_op_e    op;
        string       desc;
    } scenario_t;

    int unsigned reps_per_scenario = 10;

    function new(string name = "axi4_error_seq");
        super.new(name);
    endfunction

    task body();
        axi4_sequencer sqr;
        axi4_transaction req;

        scenario_t scenarios[] = '{
            '{addr:16'h0FFC, len:8'd1,   op:AXI_READ,  desc:"Read at 4KB boundary"},
            '{addr:16'h0FE0, len:8'd7,   op:AXI_WRITE, desc:"Write crosses boundary"},
            '{addr:16'h0FF8, len:8'd2,   op:AXI_READ,  desc:"Read crosses boundary"},
            '{addr:16'hFFFC, len:8'd3,   op:AXI_READ,  desc:"Max addr long burst"},
            '{addr:16'h1000, len:8'd255, op:AXI_WRITE, desc:"Write past memory end"},
            '{addr:16'h0000, len:8'd255, op:AXI_READ,  desc:"Burst exceeds depth"}
        };

        if (!$cast(sqr, m_sequencer))
            `uvm_fatal(get_type_name(), "Cannot cast sequencer")

        `uvm_info(get_type_name(), "Starting error sequence", UVM_LOW)

        foreach (scenarios[i]) begin
            `uvm_info(get_type_name(),
                $sformatf("Scenario[%0d]: %s", i, scenarios[i].desc), UVM_LOW)

            repeat (reps_per_scenario) begin
                req = axi4_transaction::type_id::create("req");
                start_item(req);

                // FIX #8: inline constraints only — no rand_mode/constraint_mode
                if (!req.randomize() with {
                    op   == scenarios[i].op;
                    addr == scenarios[i].addr;
                    len  == scenarios[i].len;
                    size == 3'd2;
                })
                    `uvm_fatal(get_type_name(), "Error scenario randomise failed")

                finish_item(req);
                void'(sqr.m_cfg.monitor_done_mb.get());
            end
        end

        `uvm_info(get_type_name(), "Error sequence done", UVM_LOW)
    endtask

endclass : axi4_error_seq

`endif // AXI4_SEQUENCES_SV
