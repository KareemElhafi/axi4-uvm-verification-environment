// =============================================================================
// File        : axi4_assertions.sv
// =============================================================================

`ifndef AXI4_ASSERTIONS_SV
`define AXI4_ASSERTIONS_SV

module axi4_assertions (axi4_if vif);

    // =========================================================================
    // These remain valid through the burst even after the master removes the
    // channel signals, so B-channel and R-channel properties are correct.
    // =========================================================================
    logic [15:0] lat_awaddr;
    logic [7:0]  lat_awlen;
    logic [2:0]  lat_awsize;
    logic [15:0] lat_araddr;
    logic [7:0]  lat_arlen;
    logic [2:0]  lat_arsize;

    always_ff @(posedge vif.ACLK or negedge vif.ARESETn) begin
        if (!vif.ARESETn) begin
            lat_awaddr <= '0; lat_awlen <= '0; lat_awsize <= '0;
            lat_araddr <= '0; lat_arlen <= '0; lat_arsize <= '0;
        end else begin
            if (vif.AWVALID && vif.AWREADY) begin
                lat_awaddr <= vif.AWADDR;
                lat_awlen  <= vif.AWLEN;
                lat_awsize <= vif.AWSIZE;
            end
            if (vif.ARVALID && vif.ARREADY) begin
                lat_araddr <= vif.ARADDR;
                lat_arlen  <= vif.ARLEN;
                lat_arsize <= vif.ARSIZE;
            end
        end
    end

    // =========================================================================
    // Use $fell(ARESETn) |=> to check the registered output ONE CYCLE AFTER
    // the reset pulse asserts.  The original !ARESETn |-> was checking
    // combinatorially during an async reset pulse — unreliable.
    // =========================================================================

    property p_reset_awready;
        @(posedge vif.ACLK) $fell(vif.ARESETn) |=> vif.AWREADY == 1'b1;
    endproperty
    A_RESET_AWREADY: assert property (p_reset_awready)
        else $error("AWREADY not 1 one cycle after reset");
    C_RESET_AWREADY: cover property (p_reset_awready);

    property p_reset_wready;
        @(posedge vif.ACLK) $fell(vif.ARESETn) |=> vif.WREADY == 1'b0;
    endproperty
    A_RESET_WREADY: assert property (p_reset_wready)
        else $error("WREADY not 0 one cycle after reset");
    C_RESET_WREADY: cover property (p_reset_wready);

    property p_reset_bvalid;
        @(posedge vif.ACLK) $fell(vif.ARESETn) |=> vif.BVALID == 1'b0;
    endproperty
    A_RESET_BVALID: assert property (p_reset_bvalid)
        else $error("BVALID not 0 one cycle after reset");
    C_RESET_BVALID: cover property (p_reset_bvalid);

    property p_reset_arready;
        @(posedge vif.ACLK) $fell(vif.ARESETn) |=> vif.ARREADY == 1'b1;
    endproperty
    A_RESET_ARREADY: assert property (p_reset_arready)
        else $error("ARREADY not 1 one cycle after reset");
    C_RESET_ARREADY: cover property (p_reset_arready);

    property p_reset_rvalid;
        @(posedge vif.ACLK) $fell(vif.ARESETn) |=> vif.RVALID == 1'b0;
    endproperty
    A_RESET_RVALID: assert property (p_reset_rvalid)
        else $error("RVALID not 0 one cycle after reset");
    C_RESET_RVALID: cover property (p_reset_rvalid);

    property p_reset_rlast;
        @(posedge vif.ACLK) $fell(vif.ARESETn) |=> vif.RLAST == 1'b0;
    endproperty
    A_RESET_RLAST: assert property (p_reset_rlast)
        else $error("RLAST not 0 one cycle after reset");
    C_RESET_RLAST: cover property (p_reset_rlast);

    // =========================================================================
    // WRITE ADDRESS CHANNEL (AW)
    // =========================================================================

    property p_awready_deassert;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.AWVALID && vif.AWREADY) |=> !vif.AWREADY;
    endproperty
    A_AWREADY_DEASSERT: assert property (p_awready_deassert)
        else $error("AWREADY did not deassert after AW handshake");
    C_AWREADY_DEASSERT: cover property (p_awready_deassert);

    property p_awaddr_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.AWVALID && !vif.AWREADY) |=> $stable(vif.AWADDR);
    endproperty
    A_AWADDR_STABLE: assert property (p_awaddr_stable)
        else $error("AWADDR changed while AWVALID && !AWREADY");
    C_AWADDR_STABLE: cover property (p_awaddr_stable);

    property p_awlen_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.AWVALID && !vif.AWREADY) |=> $stable(vif.AWLEN);
    endproperty
    A_AWLEN_STABLE: assert property (p_awlen_stable)
        else $error("AWLEN changed while AWVALID && !AWREADY");
    C_AWLEN_STABLE: cover property (p_awlen_stable);

    property p_awsize_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.AWVALID && !vif.AWREADY) |=> $stable(vif.AWSIZE);
    endproperty
    A_AWSIZE_STABLE: assert property (p_awsize_stable)
        else $error("AWSIZE changed while AWVALID && !AWREADY");
    C_AWSIZE_STABLE: cover property (p_awsize_stable);

    // =========================================================================
    // WRITE DATA CHANNEL (W)
    // =========================================================================

    property p_wdata_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.WVALID && !vif.WREADY) |=> $stable(vif.WDATA);
    endproperty
    A_WDATA_STABLE: assert property (p_wdata_stable)
        else $error("WDATA changed while WVALID && !WREADY");
    C_WDATA_STABLE: cover property (p_wdata_stable);

    property p_wready_deassert_after_wlast;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.WVALID && vif.WREADY && vif.WLAST) |=> !vif.WREADY;
    endproperty
    A_WREADY_AFTER_WLAST: assert property (p_wready_deassert_after_wlast)
        else $error("WREADY did not deassert after WLAST handshake");
    C_WREADY_AFTER_WLAST: cover property (p_wready_deassert_after_wlast);

    // =========================================================================
    // WRITE RESPONSE CHANNEL (B)
    // =========================================================================

    property p_bvalid_after_wlast;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.WVALID && vif.WREADY && vif.WLAST) |=> vif.BVALID;
    endproperty
    A_BVALID_AFTER_WLAST: assert property (p_bvalid_after_wlast)
        else $error("BVALID not asserted cycle after WLAST handshake");
    C_BVALID_AFTER_WLAST: cover property (p_bvalid_after_wlast);


    property p_bvalid_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.BVALID && !vif.BREADY) |=> vif.BVALID;
    endproperty
    A_BVALID_STABLE: assert property (p_bvalid_stable)
        else $error("BVALID deasserted before BREADY");
    C_BVALID_STABLE: cover property (p_bvalid_stable);

    property p_bresp_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.BVALID && !vif.BREADY) |=> $stable(vif.BRESP);
    endproperty
    A_BRESP_STABLE: assert property (p_bresp_stable)
        else $error("BRESP changed while BVALID && !BREADY");
    C_BRESP_STABLE: cover property (p_bresp_stable);

    property p_bvalid_deassert;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.BVALID && vif.BREADY) |=> !vif.BVALID;
    endproperty
    A_BVALID_DEASSERT: assert property (p_bvalid_deassert)
        else $error("BVALID did not deassert after B handshake");
    C_BVALID_DEASSERT: cover property (p_bvalid_deassert);

    property p_bresp_legal;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        vif.BVALID |-> vif.BRESP inside {2'b00, 2'b10};
    endproperty
    A_BRESP_LEGAL: assert property (p_bresp_legal)
        else $error("Illegal BRESP: %02b", vif.BRESP);
    C_BRESP_LEGAL: cover property (p_bresp_legal);

    property p_write_boundary_slverr;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.BVALID &&
         (({4'h0, lat_awaddr[11:0]} +
           (({8'h0, lat_awlen} + 9'd1) << lat_awsize)) > 13'h1000))
        |-> vif.BRESP == 2'b10;
    endproperty
    A_WRITE_BOUNDARY_SLVERR: assert property (p_write_boundary_slverr)
        else $error("4KB boundary cross must produce SLVERR on write");
    C_WRITE_BOUNDARY_SLVERR: cover property (p_write_boundary_slverr);

    property p_write_range_slverr;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.BVALID && ((lat_awaddr >> 2) + lat_awlen + 1 > 16'd1024))
        |-> vif.BRESP == 2'b10;
    endproperty
    A_WRITE_RANGE_SLVERR: assert property (p_write_range_slverr)
        else $error("Out-of-range write must produce SLVERR");
    C_WRITE_RANGE_SLVERR: cover property (p_write_range_slverr);

    // =========================================================================
    // READ ADDRESS CHANNEL (AR)
    // =========================================================================

    property p_arready_deassert;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.ARVALID && vif.ARREADY) |=> !vif.ARREADY;
    endproperty
    A_ARREADY_DEASSERT: assert property (p_arready_deassert)
        else $error("ARREADY did not deassert after AR handshake");
    C_ARREADY_DEASSERT: cover property (p_arready_deassert);

    property p_araddr_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.ARVALID && !vif.ARREADY) |=> $stable(vif.ARADDR);
    endproperty
    A_ARADDR_STABLE: assert property (p_araddr_stable)
        else $error("ARADDR changed while ARVALID && !ARREADY");
    C_ARADDR_STABLE: cover property (p_araddr_stable);

    property p_arlen_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.ARVALID && !vif.ARREADY) |=> $stable(vif.ARLEN);
    endproperty
    A_ARLEN_STABLE: assert property (p_arlen_stable)
        else $error("ARLEN changed while ARVALID && !ARREADY");
    C_ARLEN_STABLE: cover property (p_arlen_stable);

    property p_arsize_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.ARVALID && !vif.ARREADY) |=> $stable(vif.ARSIZE);
    endproperty
    A_ARSIZE_STABLE: assert property (p_arsize_stable)
        else $error("ARSIZE changed while ARVALID && !ARREADY");
    C_ARSIZE_STABLE: cover property (p_arsize_stable);

    // =========================================================================
    // READ DATA CHANNEL (R)
    // =========================================================================

    property p_rvalid_after_araddr;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.ARVALID && vif.ARREADY) |-> ##[1:5] vif.RVALID;
    endproperty
    A_RVALID_AFTER_ARADDR: assert property (p_rvalid_after_araddr)
        else $error("RVALID not asserted within 5 cycles of AR handshake");
    C_RVALID_AFTER_ARADDR: cover property (p_rvalid_after_araddr);

    property p_rvalid_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.RVALID && !vif.RREADY) |=> vif.RVALID;
    endproperty
    A_RVALID_STABLE: assert property (p_rvalid_stable)
        else $error("RVALID deasserted before RREADY");
    C_RVALID_STABLE: cover property (p_rvalid_stable);

    property p_rdata_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.RVALID && !vif.RREADY) |=> $stable(vif.RDATA);
    endproperty
    A_RDATA_STABLE: assert property (p_rdata_stable)
        else $error("RDATA changed while RVALID && !RREADY");
    C_RDATA_STABLE: cover property (p_rdata_stable);

    property p_rresp_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.RVALID && !vif.RREADY) |=> $stable(vif.RRESP);
    endproperty
    A_RRESP_STABLE: assert property (p_rresp_stable)
        else $error("RRESP changed while RVALID && !RREADY");
    C_RRESP_STABLE: cover property (p_rresp_stable);

    property p_rlast_stable;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.RVALID && !vif.RREADY) |=> $stable(vif.RLAST);
    endproperty
    A_RLAST_STABLE: assert property (p_rlast_stable)
        else $error("RLAST changed while RVALID && !RREADY");
    C_RLAST_STABLE: cover property (p_rlast_stable);

    property p_rresp_legal;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        vif.RVALID |-> vif.RRESP inside {2'b00, 2'b10};
    endproperty
    A_RRESP_LEGAL: assert property (p_rresp_legal)
        else $error("Illegal RRESP: %02b", vif.RRESP);
    C_RRESP_LEGAL: cover property (p_rresp_legal);

    property p_read_boundary_slverr;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.RVALID &&
         (({4'h0, lat_araddr[11:0]} +
           (({8'h0, lat_arlen} + 9'd1) << lat_arsize)) > 13'h1000))
        |-> vif.RRESP == 2'b10;
    endproperty
    A_READ_BOUNDARY_SLVERR: assert property (p_read_boundary_slverr)
        else $error("4KB boundary cross must produce SLVERR on read");
    C_READ_BOUNDARY_SLVERR: cover property (p_read_boundary_slverr);

    property p_read_range_slverr;
        @(posedge vif.ACLK) disable iff (!vif.ARESETn)
        (vif.RVALID && ((lat_araddr >> 2) + lat_arlen + 1 > 16'd1024))
        |-> vif.RRESP == 2'b10;
    endproperty
    A_READ_RANGE_SLVERR: assert property (p_read_range_slverr)
        else $error("Out-of-range read must produce SLVERR");
    C_READ_RANGE_SLVERR: cover property (p_read_range_slverr);

endmodule : axi4_assertions
`endif // AXI4_ASSERTIONS_SV
