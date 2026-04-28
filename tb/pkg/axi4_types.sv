// =============================================================================
// File        : axi4_types.sv
// =============================================================================

`ifndef AXI4_TYPES_SV
`define AXI4_TYPES_SV

// Operation type
typedef enum logic [1:0] {
    AXI_WRITE = 2'd1,
    AXI_READ  = 2'd2
} axi4_op_e;

// AXI4 response codes
typedef enum logic [1:0] {
    AXI_RESP_OKAY   = 2'b00,
    AXI_RESP_SLVERR = 2'b10
} axi4_resp_e;

`endif // AXI4_TYPES_SV
