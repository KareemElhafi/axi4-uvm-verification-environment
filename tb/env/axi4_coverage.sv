// =============================================================================
// File        : axi4_coverage.sv
// =============================================================================

`ifndef AXI4_COVERAGE_SV
`define AXI4_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_coverage extends uvm_component;
    `uvm_component_utils(axi4_coverage)

    uvm_analysis_export #(axi4_transaction)   analysis_export;
    uvm_tlm_analysis_fifo #(axi4_transaction) m_fifo;

    axi4_transaction tr;

    // =========================================================================
    // Covergroup
    // =========================================================================
    covergroup axi4_cg;

        // Operation type
        cp_op: coverpoint tr.op {
            bins write_op = {AXI_WRITE};
            bins read_op  = {AXI_READ};
        }

        // Burst length — corners + buckets
        cp_len: coverpoint tr.len {
            bins corner_0   = {8'd0};
            bins corner_1   = {8'd1};
            bins corner_127 = {8'd127};
            bins corner_128 = {8'd128};
            bins corner_254 = {8'd254};
            bins corner_255 = {8'd255};
            bins short      = {[8'd2   : 8'd15]};
            bins medium     = {[8'd16  : 8'd63]};
            bins long_burst = {[8'd64  : 8'd126]};
            bins xl_burst   = {[8'd129 : 8'd253]};
        }

        // Address regions
        cp_addr: coverpoint tr.addr {
            bins page_0      = {[16'd0    : 16'd1023]};
            bins page_1      = {[16'd1024 : 16'd4095]};
            bins upper       = {[16'd4096 : 16'hFFFF]};
            bins corner_0    = {16'd0};
            bins corner_4k   = {16'd4096};
            bins corner_max  = {16'hFFFC};
        }

        // Memory access validity
        cp_range: coverpoint ((tr.addr >> 2) + tr.len + 1 <= 1024) {
            bins valid   = {1'b1};
            bins invalid = {1'b0};
        }

        cp_resp: coverpoint tr.actual_resp {
            bins okay   = {2'b00};
            bins slverr = {2'b10};
        }

        cp_wdata: coverpoint tr.write_data_q[0]
                             iff (tr.op == AXI_WRITE && tr.write_data_q.size() > 0) {
            bins zero        = {32'd0};
            bins all_ones    = {32'hFFFF_FFFF};
            bins alternating = {32'hAAAA_AAAA, 32'h5555_5555};
            bins dead_beef   = {32'hDEAD_BEEF};
            bins lo_range    = {[32'd1       : 32'd32767]};
            bins mid_range   = {[32'd32768   : 32'd1048575]};
            bins hi_range    = {[32'd1048576 : 32'hFFFFFFFE]};
        }

        // Handshake delays
        cp_aw_dly: coverpoint tr.aw_valid_delay { bins all[] = {[0:7]}; }
        cp_w_dly:  coverpoint tr.w_valid_delay  { bins all[] = {[0:7]}; }
        cp_b_dly:  coverpoint tr.b_ready_delay  { bins all[] = {[0:7]}; }
        cp_ar_dly: coverpoint tr.ar_valid_delay { bins all[] = {[0:7]}; }
        cp_r_dly:  coverpoint tr.r_ready_delay  { bins all[] = {[0:7]}; }

        // --- Cross coverage ---

        // Op × validity — 4 meaningful bins (2×2)
        cx_op_range: cross cp_op, cp_range;

        // Op × response — should see OKAY and SLVERR on both read and write
        cx_op_resp: cross cp_op, cp_resp;

        cx_op_len: cross cp_op, cp_len {
            // Unreachable: read with xl_burst in upper address will always SLVERR
            ignore_bins rd_xl_oob =
                binsof(cp_op.read_op) && binsof(cp_len.xl_burst);
        }

        // Addr page × len — exclude physically impossible valid-range combos
        cx_addr_len: cross cp_addr, cp_len {
            // upper addresses + long/xl bursts always exceed memory depth
            ignore_bins upper_long =
                binsof(cp_addr.upper) && binsof(cp_len.long_burst);
            ignore_bins upper_xl =
                binsof(cp_addr.upper) && binsof(cp_len.xl_burst);
            ignore_bins max_long =
                binsof(cp_addr.corner_max) && binsof(cp_len.long_burst);
            ignore_bins max_xl =
                binsof(cp_addr.corner_max) && binsof(cp_len.xl_burst);
        }

    endgroup : axi4_cg

    function new(string name = "axi4_coverage", uvm_component parent = null);
        super.new(name, parent);
        axi4_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        m_fifo          = new("m_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        analysis_export.connect(m_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            m_fifo.get(tr);
            axi4_cg.sample();
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
            $sformatf("Functional coverage = %0.2f%%", axi4_cg.get_coverage()),
            UVM_NONE)
    endfunction

endclass : axi4_coverage

`endif // AXI4_COVERAGE_SV
