// =============================================================================
// File        : axi4_scoreboard.sv
// =============================================================================

`ifndef AXI4_SCOREBOARD_SV
`define AXI4_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi4_scoreboard)

    uvm_analysis_export #(axi4_transaction)   analysis_export;
    uvm_tlm_analysis_fifo #(axi4_transaction) m_fifo;

    // -------------------------------------------------------------------------
    // Golden memory shadow (word-addressed)
    // -------------------------------------------------------------------------
    localparam int unsigned MEM_DEPTH = 1024;
    logic [31:0] golden_mem [0:MEM_DEPTH-1];

    // Statistics
    int unsigned total_wr, total_rd;
    int unsigned pass_wr,  pass_rd;
    int unsigned fail_wr,  fail_rd;
    int unsigned txn_id;
    int unsigned failed_ids[$];

    function new(string name = "axi4_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        foreach (golden_mem[i]) golden_mem[i] = '0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        m_fifo          = new("m_fifo",          this);
    endfunction

    function void connect_phase(uvm_phase phase);
        analysis_export.connect(m_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_transaction tr;
        forever begin
            m_fifo.get(tr);
            txn_id++;
            check_transaction(tr);
        end
    endtask

    // =========================================================================
    function automatic logic [1:0] predict_resp(axi4_transaction tr);
        logic range_err, bnd_err;
        // Range: last word address must be < MEM_DEPTH
        range_err = ((tr.addr >> 2) + tr.len + 1 > MEM_DEPTH);
        // FIX #4: correct byte-span formula
        bnd_err   = (({4'h0, tr.addr[11:0]} +
                      (({8'h0, tr.len} + 9'd1) << tr.size)) > 13'h1000);
        return (range_err || bnd_err) ? 2'b10 : 2'b00;
    endfunction

    // =========================================================================
    task automatic check_transaction(axi4_transaction tr);
        logic [1:0] exp_resp;
        logic       is_error;

        exp_resp = predict_resp(tr);
        is_error = (exp_resp == 2'b10);

        if (tr.op == AXI_WRITE) begin
            total_wr++;
            
             if (!is_error) begin
                for (int i = 0; i <= int'(tr.len); i++)
                    golden_mem[(tr.addr >> 2) + i] = tr.write_data_q[i];
            end
            check_resp(tr, exp_resp, "WRITE", total_wr);
        end else begin
            total_rd++;
            check_read(tr, exp_resp, is_error);
        end
    endtask

    // -------------------------------------------------------------------------
    task automatic check_resp(
        axi4_transaction tr,
        logic [1:0] exp_resp,
        string op_name,
        int unsigned id
    );
        if (tr.actual_resp === exp_resp) begin
            if (tr.op == AXI_WRITE) pass_wr++; else pass_rd++;
            `uvm_info(get_type_name(),
                $sformatf("[PASS][%s #%0d] %s", op_name, id, tr.convert2string()),
                UVM_HIGH)
        end else begin
            if (tr.op == AXI_WRITE) fail_wr++; else fail_rd++;
            failed_ids.push_back(txn_id);
            `uvm_error(get_type_name(),
                $sformatf("[FAIL][%s #%0d] exp_resp=%02b got=%02b | %s",
                          op_name, id, exp_resp, tr.actual_resp, tr.convert2string()))
        end
    endtask

    // -------------------------------------------------------------------------
    task automatic check_read(
        axi4_transaction tr,
        logic [1:0] exp_resp,
        logic is_error
    );
        logic [31:0] exp_data [];
        bit resp_ok, data_ok;

        resp_ok = (tr.actual_resp === exp_resp);
        data_ok = 1'b1;

        if (!is_error) begin
            exp_data = new[tr.len + 1];
            for (int i = 0; i <= int'(tr.len); i++)
                exp_data[i] = golden_mem[(tr.addr >> 2) + i];

            if (tr.actual_rdata_q.size() != exp_data.size()) begin
                data_ok = 1'b0;
                `uvm_error(get_type_name(),
                    $sformatf("[FAIL][RD #%0d] beat count exp=%0d got=%0d",
                              txn_id, exp_data.size(), tr.actual_rdata_q.size()))
            end else begin
                for (int i = 0; i < int'(exp_data.size()); i++) begin
                    if (tr.actual_rdata_q[i] !== exp_data[i]) begin
                        data_ok = 1'b0;
                        `uvm_error(get_type_name(),
                            $sformatf("[FAIL][RD #%0d] beat[%0d] exp=0x%08X got=0x%08X",
                                      txn_id, i, exp_data[i], tr.actual_rdata_q[i]))
                    end
                end
            end
        end

        if (resp_ok && data_ok) begin
            pass_rd++;
            `uvm_info(get_type_name(),
                $sformatf("[PASS][RD  #%0d] %s", txn_id, tr.convert2string()), UVM_HIGH)
        end else begin
            fail_rd++;
            failed_ids.push_back(txn_id);
            if (!resp_ok)
                `uvm_error(get_type_name(),
                    $sformatf("[FAIL][RD  #%0d] resp exp=%02b got=%02b | %s",
                              txn_id, exp_resp, tr.actual_resp, tr.convert2string()))
        end
    endtask

    // =========================================================================
    // Final summary
    // =========================================================================
    function void report_phase(uvm_phase phase);
        int unsigned total = total_wr + total_rd;
        int unsigned pass  = pass_wr  + pass_rd;
        int unsigned fail  = fail_wr  + fail_rd;
        real rate = (total > 0) ? (real'(pass)/real'(total))*100.0 : 0.0;

        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        `uvm_info(get_type_name(), "        SCOREBOARD FINAL REPORT         ", UVM_NONE)
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Total     : %0d", total),        UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("  Writes  : pass=%0d fail=%0d",  pass_wr, fail_wr), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("  Reads   : pass=%0d fail=%0d",  pass_rd, fail_rd), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Pass rate : %0.2f%%", rate),     UVM_NONE)
        if (failed_ids.size() > 0) begin
            string ids = "";
            foreach (failed_ids[j]) ids = {ids, $sformatf(" %0d", failed_ids[j])};
            `uvm_info(get_type_name(), $sformatf("Failed IDs:%s", ids), UVM_NONE)
        end
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        if (fail > 0)
            `uvm_error(get_type_name(), $sformatf("%0d transaction(s) FAILED", fail))
    endfunction

endclass : axi4_scoreboard

`endif // AXI4_SCOREBOARD_SV
