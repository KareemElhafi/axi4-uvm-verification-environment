// =============================================================================
// Interface   : axi4_if
// Description : AXI4 signal bundle with DUT, TB, and monitor modports.
// =============================================================================
interface axi4_if (input logic ACLK);

    logic        ARESETn;

    // Write address channel
    logic [15:0] AWADDR;
    logic [7:0]  AWLEN;
    logic [2:0]  AWSIZE;
    logic        AWVALID;
    logic        AWREADY;

    // Write data channel
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WLAST;
    logic        WREADY;

    // Write response channel
    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;

    // Read address channel
    logic [15:0] ARADDR;
    logic [7:0]  ARLEN;
    logic [2:0]  ARSIZE;
    logic        ARVALID;
    logic        ARREADY;

    // Read data channel
    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RLAST;
    logic        RREADY;

endinterface : axi4_if
