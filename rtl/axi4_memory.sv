// =============================================================================
// Module      : axi4_memory
// Description : Synchronous single-port RAM, 1024 x 32-bit.
//               Clean registered read with 1-cycle latency.
// =============================================================================
`timescale 1ns/1ps

module axi4_memory #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned ADDR_WIDTH = 10,
    parameter int unsigned DEPTH      = 1024
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    mem_en,
    input  logic                    mem_we,
    input  logic [ADDR_WIDTH-1:0]   mem_addr,
    input  logic [DATA_WIDTH-1:0]   mem_wdata,
    output logic [DATA_WIDTH-1:0]   mem_rdata
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    initial begin
        for (int i = 0; i < DEPTH; i++) mem[i] = '0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_rdata <= '0;
        end else if (mem_en) begin
            if (mem_we)
                mem[mem_addr] <= mem_wdata;
            else
                mem_rdata <= mem[mem_addr];
        end
    end

endmodule : axi4_memory
