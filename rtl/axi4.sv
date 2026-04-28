// =============================================================================
// Module      : axi4
// Description : AXI4-compliant memory-mapped slave.
//
// FIX #4 — Boundary formula corrected to (AWLEN+1)*(1<<AWSIZE).
//           Boundary/range checks evaluated at address-accept time using
//           REGISTERED copies of address/len/size (captured_*), so they
//           remain correct after the master removes AW/AR channel signals.
// =============================================================================
`timescale 1ns/1ps

module axi4 #(
    parameter int unsigned DATA_WIDTH   = 32,
    parameter int unsigned ADDR_WIDTH   = 16,
    parameter int unsigned MEMORY_DEPTH = 1024
)(
    input  logic                    ACLK,
    input  logic                    ARESETn,

    // Write address channel
    input  logic [ADDR_WIDTH-1:0]   AWADDR,
    input  logic [7:0]              AWLEN,
    input  logic [2:0]              AWSIZE,
    input  logic                    AWVALID,
    output logic                    AWREADY,

    // Write data channel
    input  logic [DATA_WIDTH-1:0]   WDATA,
    input  logic                    WVALID,
    input  logic                    WLAST,
    output logic                    WREADY,

    // Write response channel
    output logic [1:0]              BRESP,
    output logic                    BVALID,
    input  logic                    BREADY,

    // Read address channel
    input  logic [ADDR_WIDTH-1:0]   ARADDR,
    input  logic [7:0]              ARLEN,
    input  logic [2:0]              ARSIZE,
    input  logic                    ARVALID,
    output logic                    ARREADY,

    // Read data channel
    output logic [DATA_WIDTH-1:0]   RDATA,
    output logic [1:0]              RRESP,
    output logic                    RVALID,
    output logic                    RLAST,
    input  logic                    RREADY
);

    localparam int unsigned MEM_AW = $clog2(MEMORY_DEPTH);

    // -------------------------------------------------------------------------
    // Internal memory bus
    // -------------------------------------------------------------------------
    logic                  mem_en, mem_we;
    logic [MEM_AW-1:0]     mem_addr;
    logic [DATA_WIDTH-1:0] mem_wdata, mem_rdata;

    // -------------------------------------------------------------------------
    // Burst tracking (registered at AW/AR handshake)
    // -------------------------------------------------------------------------
    logic [ADDR_WIDTH-1:0] write_addr,      read_addr;
    logic [7:0]            write_burst_cnt, read_burst_cnt;
    logic [2:0]            write_size,      read_size;

    logic [ADDR_WIDTH-1:0] write_addr_incr, read_addr_incr;
    assign write_addr_incr = ADDR_WIDTH'(1) << write_size;
    assign read_addr_incr  = ADDR_WIDTH'(1) << read_size;

    // -------------------------------------------------------------------------
    // FIX #4: Combinational helpers — evaluated at address-channel time.
    // Formula: byte_span = (LEN+1) * (1<<SIZE)
    // Boundary cross when: addr_offset + byte_span > 4096
    // -------------------------------------------------------------------------
    logic aw_boundary_cross, ar_boundary_cross;
    logic aw_addr_valid,     ar_addr_valid;

    assign aw_boundary_cross =
        (({4'h0, AWADDR[11:0]} + (({8'h0, AWLEN} + 9'd1) << AWSIZE)) > 13'h1000);
    assign ar_boundary_cross =
        (({4'h0, ARADDR[11:0]} + (({8'h0, ARLEN} + 9'd1) << ARSIZE)) > 13'h1000);
    assign aw_addr_valid = ((AWADDR >> 2) < ADDR_WIDTH'(MEMORY_DEPTH));
    assign ar_addr_valid = ((ARADDR >> 2) < ADDR_WIDTH'(MEMORY_DEPTH));

    // Captured at handshake so they remain valid through the burst
    logic cap_wr_boundary, cap_rd_boundary;
    logic cap_wr_valid,    cap_rd_valid;

    // -------------------------------------------------------------------------
    // Memory instance
    // -------------------------------------------------------------------------
    axi4_memory #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (MEM_AW),
        .DEPTH      (MEMORY_DEPTH)
    ) u_mem (
        .clk      (ACLK),   .rst_n    (ARESETn),
        .mem_en   (mem_en), .mem_we   (mem_we),
        .mem_addr (mem_addr),.mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata)
    );

    // =========================================================================
    // Write FSM
    // =========================================================================
    typedef enum logic [1:0] {W_IDLE=0, W_ADDR=1, W_DATA=2, W_RESP=3} wstate_e;
    wstate_e write_state;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWREADY <= 1'b1; WREADY <= 1'b0; BVALID <= 1'b0; BRESP <= 2'b00;
            write_state <= W_IDLE;
            write_addr <= '0; write_burst_cnt <= '0; write_size <= '0;
            cap_wr_boundary <= 1'b0; cap_wr_valid <= 1'b0;
            mem_en <= 1'b0; mem_we <= 1'b0; mem_addr <= '0; mem_wdata <= '0;
        end else begin
            mem_en <= 1'b0;
            mem_we <= 1'b0;

            case (write_state)
                W_IDLE: begin
                    AWREADY <= 1'b1; WREADY <= 1'b0; BVALID <= 1'b0;
                    if (AWVALID && AWREADY) begin
                        write_addr      <= AWADDR;
                        write_burst_cnt <= AWLEN;
                        write_size      <= AWSIZE;
                        cap_wr_boundary <= aw_boundary_cross;
                        cap_wr_valid    <= aw_addr_valid;
                        AWREADY         <= 1'b0;
                        write_state     <= W_ADDR;
                    end
                end
                W_ADDR: begin
                    WREADY      <= 1'b1;
                    write_state <= W_DATA;
                end
                W_DATA: begin
                    if (WVALID && WREADY) begin
                        if (cap_wr_valid && !cap_wr_boundary) begin
                            mem_en    <= 1'b1;
                            mem_we    <= 1'b1;
                            mem_addr  <= MEM_AW'(write_addr >> 2);
                            mem_wdata <= WDATA;
                        end
                        if (WLAST || write_burst_cnt == 8'd0) begin
                            WREADY  <= 1'b0;
                            BRESP   <= (cap_wr_valid && !cap_wr_boundary) ? 2'b00 : 2'b10;
                            BVALID  <= 1'b1;
                            write_state <= W_RESP;
                        end else begin
                            write_addr      <= write_addr + write_addr_incr;
                            write_burst_cnt <= write_burst_cnt - 8'd1;
                        end
                    end
                end
                W_RESP: begin
                    if (BREADY && BVALID) begin
                        BVALID      <= 1'b0;
                        BRESP       <= 2'b00;
                        write_state <= W_IDLE;
                    end
                end
                default: write_state <= W_IDLE;
            endcase
        end
    end

    // =========================================================================
    // Read FSM  (R_FETCH absorbs 1-cycle memory latency)
    // =========================================================================
    typedef enum logic [1:0] {R_IDLE=0, R_FETCH=1, R_DATA=2} rstate_e;
    rstate_e read_state;

    logic [1:0] rresp_reg;
    logic       rlast_reg;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARREADY <= 1'b1; RVALID <= 1'b0; RDATA <= '0;
            RRESP <= 2'b00; RLAST <= 1'b0;
            read_state <= R_IDLE;
            read_addr <= '0; read_burst_cnt <= '0; read_size <= '0;
            cap_rd_boundary <= 1'b0; cap_rd_valid <= 1'b0;
            rresp_reg <= 2'b00; rlast_reg <= 1'b0;
        end else begin
            case (read_state)
                R_IDLE: begin
                    ARREADY <= 1'b1; RVALID <= 1'b0; RLAST <= 1'b0;
                    if (ARVALID && ARREADY) begin
                        read_addr       <= ARADDR;
                        read_burst_cnt  <= ARLEN;
                        read_size       <= ARSIZE;
                        cap_rd_boundary <= ar_boundary_cross;
                        cap_rd_valid    <= ar_addr_valid;
                        ARREADY         <= 1'b0;
                        read_state      <= R_FETCH;
                    end
                end
                R_FETCH: begin
                    if (cap_rd_valid && !cap_rd_boundary) begin
                        mem_en   <= 1'b1;
                        mem_we   <= 1'b0;
                        mem_addr <= MEM_AW'(read_addr >> 2);
                        rresp_reg <= 2'b00;
                    end else begin
                        rresp_reg <= 2'b10;
                    end
                    rlast_reg  <= (read_burst_cnt == 8'd0);
                    read_state <= R_DATA;
                end
                R_DATA: begin
                    if (!RVALID) begin
                        RDATA  <= (rresp_reg == 2'b00) ? mem_rdata : '0;
                        RRESP  <= rresp_reg;
                        RLAST  <= rlast_reg;
                        RVALID <= 1'b1;
                    end
                    if (RVALID && RREADY) begin
                        RVALID <= 1'b0;
                        if (read_burst_cnt > 8'd0) begin
                            read_addr      <= read_addr + read_addr_incr;
                            read_burst_cnt <= read_burst_cnt - 8'd1;
                            read_state     <= R_FETCH;
                        end else begin
                            RLAST      <= 1'b0;
                            read_state <= R_IDLE;
                        end
                    end
                end
                default: read_state <= R_IDLE;
            endcase
        end
    end

endmodule : axi4
