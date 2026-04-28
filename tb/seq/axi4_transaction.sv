// =============================================================================
// File        : axi4_transaction.sv
// =============================================================================

`ifndef AXI4_TRANSACTION_SV
`define AXI4_TRANSACTION_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_transaction extends uvm_sequence_item;
    `uvm_object_utils_begin(axi4_transaction)
        `uvm_field_enum      (axi4_op_e, op,            UVM_DEFAULT)
        `uvm_field_int       (addr,                     UVM_DEFAULT)
        `uvm_field_int       (len,                      UVM_DEFAULT)
        `uvm_field_int       (size,                     UVM_DEFAULT)
        `uvm_field_queue_int (write_data_q,             UVM_DEFAULT)
        `uvm_field_queue_int (actual_rdata_q,           UVM_DEFAULT | UVM_NOPRINT)
        `uvm_field_int       (actual_resp,              UVM_DEFAULT | UVM_NOPRINT)
        `uvm_field_int       (aw_valid_delay,           UVM_DEFAULT)
        `uvm_field_int       (w_valid_delay,            UVM_DEFAULT)
        `uvm_field_int       (b_ready_delay,            UVM_DEFAULT)
        `uvm_field_int       (ar_valid_delay,           UVM_DEFAULT)
        `uvm_field_int       (r_ready_delay,            UVM_DEFAULT)
    `uvm_object_utils_end

    // -------------------------------------------------------------------------
    // Randomisable stimulus fields
    // -------------------------------------------------------------------------
    rand axi4_op_e    op;
    rand logic [15:0] addr;
    rand logic [7:0]  len;
    rand logic [2:0]  size;

    rand logic [31:0] write_data_q [];

    // Collected by monitor (non-rand)
    logic [31:0] actual_rdata_q [];
    logic [1:0]  actual_resp;

    // Handshake delays
    rand logic [2:0] aw_valid_delay;
    rand logic [2:0] w_valid_delay;
    rand logic [2:0] b_ready_delay;
    rand logic [2:0] ar_valid_delay;
    rand logic [2:0] r_ready_delay;

    // Internal distribution controls
    rand bit       valid_range;
    rand bit [1:0] data_mode;
    rand bit       addr_corner;
    rand bit       len_corner;

    // -------------------------------------------------------------------------
    // Constraints
    // -------------------------------------------------------------------------

    constraint c_op   { op dist { AXI_WRITE := 50, AXI_READ := 50 }; }
    constraint c_size { size == 3'd2; }
    constraint c_align{ addr[1:0] == 2'b00; }

    constraint c_data_size {
        write_data_q.size() == (len + 1);
    }

    // 50/50 valid vs. error transactions
    constraint c_valid_range {
        valid_range dist { 1'b1 := 50, 1'b0 := 50 };
        if (valid_range)
            (addr >> 2) + len + 1 <= 1024;
        else
            (addr >> 2) + len + 1 >  1024;
    }

    // Handshake delays
    constraint c_delays {
        aw_valid_delay inside {[0:7]};
        w_valid_delay  inside {[0:7]};
        b_ready_delay  inside {[0:7]};
        ar_valid_delay inside {[0:7]};
        r_ready_delay  inside {[0:7]};
    }

    // Burst length: 80% random, 20% corners
    constraint c_len_mode { len_corner dist { 1'b0:=80, 1'b1:=20 }; }
    constraint c_len {
        if (len_corner)
            len inside {8'd0,8'd1,8'd127,8'd128,8'd254,8'd255};
        else
            len inside {[8'd0:8'd63]};  // keep tests fast
    }

    // Address: 90% random, 10% corners
    constraint c_addr_mode { addr_corner dist { 1'b0:=90, 1'b1:=10 }; }
    constraint c_addr {
        if (addr_corner)
            addr inside {16'd0,16'd1024,16'd2048,16'd4092,16'hFFFC};
        else
            addr inside {[16'd0:16'hFFFF]};
        addr[1:0] == 2'b00;
    }

    // Data distribution across full 32-bit range
    constraint c_data_mode { data_mode dist {2'd0:=30,2'd1:=30,2'd2:=30,2'd3:=10}; }
    constraint c_data {
        foreach (write_data_q[i]) begin
            if (data_mode == 2'd0)
                write_data_q[i] inside {[32'd0        : 32'd32767]};
            else if (data_mode == 2'd1)
                write_data_q[i] inside {[32'd32768     : 32'd1048575]};
            else if (data_mode == 2'd2)
                write_data_q[i] inside {[32'd1048576   : 32'hFFFFFFFE]};
            else
                write_data_q[i] inside {32'd0, 32'd1, 32'hFFFFFFFF,
                                        32'hAAAAAAAA, 32'h55555555,
                                        32'hDEADBEEF, 32'h12345678};
        end
    }

    // -------------------------------------------------------------------------
    function new(string name = "axi4_transaction");
        super.new(name);
        write_data_q  = new[0];
        actual_rdata_q = new[0];
        actual_resp    = '0;
    endfunction

    function string convert2string();
        return $sformatf(
            "op=%-5s addr=0x%04X len=%0d size=%0d valid=%0b resp=%02b | dly(AW=%0d W=%0d B=%0d AR=%0d R=%0d)",
            op.name(), addr, len, size, valid_range, actual_resp,
            aw_valid_delay, w_valid_delay, b_ready_delay,
            ar_valid_delay, r_ready_delay);
    endfunction

endclass : axi4_transaction

`endif // AXI4_TRANSACTION_SV
