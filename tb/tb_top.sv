// =============================================================================
// File        : tb_top.sv
// =============================================================================

`timescale 1ns/1ps

`include "axi4_if.sv"
`include "axi4_pkg.sv"
`include "axi4_assertions.sv"
`include "uvm_macros.svh"

import uvm_pkg::*;
import axi4_pkg::*;

module tb_top;

    // -------------------------------------------------------------------------
    // Clock: 10 ns period (100 MHz)
    // -------------------------------------------------------------------------
    logic ACLK;
    initial ACLK = 1'b0;
    always #5ns ACLK = ~ACLK;

    // -------------------------------------------------------------------------
    // Interface
    // -------------------------------------------------------------------------
    axi4_if vif (.ACLK(ACLK));

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    axi4 #(
        .DATA_WIDTH   (32),
        .ADDR_WIDTH   (16),
        .MEMORY_DEPTH (1024)
    ) u_dut (
        .ACLK    (vif.ACLK),
        .ARESETn (vif.ARESETn),
        .AWADDR  (vif.AWADDR),  .AWLEN  (vif.AWLEN),
        .AWSIZE  (vif.AWSIZE),  .AWVALID(vif.AWVALID),
        .AWREADY (vif.AWREADY),
        .WDATA   (vif.WDATA),   .WVALID (vif.WVALID),
        .WLAST   (vif.WLAST),   .WREADY (vif.WREADY),
        .BRESP   (vif.BRESP),   .BVALID (vif.BVALID),
        .BREADY  (vif.BREADY),
        .ARADDR  (vif.ARADDR),  .ARLEN  (vif.ARLEN),
        .ARSIZE  (vif.ARSIZE),  .ARVALID(vif.ARVALID),
        .ARREADY (vif.ARREADY),
        .RDATA   (vif.RDATA),   .RRESP  (vif.RRESP),
        .RVALID  (vif.RVALID),  .RLAST  (vif.RLAST),
        .RREADY  (vif.RREADY)
    );

    // -------------------------------------------------------------------------
    // Assertion module (structural bind, read-only)
    // -------------------------------------------------------------------------
    axi4_assertions u_assert (.vif(vif));

    // -------------------------------------------------------------------------
    // UVM startup
    // -------------------------------------------------------------------------
    initial begin
        uvm_config_db #(virtual axi4_if)::set(null, "*", "vif", vif);
        run_test();
    end

    // -------------------------------------------------------------------------
    // Global simulation watchdog
    // -------------------------------------------------------------------------
    initial begin
        #(10ns * 10_000_000);
        `uvm_fatal("TIMEOUT", "Global simulation timeout — possible deadlock")
    end

endmodule : tb_top
