// =============================================================================
// File        : axi4_pkg.sv
// =============================================================================

`ifndef AXI4_PKG_SV
`define AXI4_PKG_SV

package axi4_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // ---- 1. Shared types (enums)
    `include "axi4_types.sv"

    // ---- 2. Configuration object
    `include "axi4_cfg.sv"

    // ---- 3. Transaction 
    `include "axi4_transaction.sv"

    // ---- 4. Sequencer
    `include "axi4_sequencer.sv"

    // ---- 5. Sequences
    `include "axi4_sequences.sv"

    // ---- 6. Driver
    `include "axi4_driver.sv"

    // ---- 7. Monitor
    `include "axi4_monitor.sv"

    // ---- 8. Agent
    `include "axi4_agent.sv"

    // ---- 9. Scoreboard
    `include "axi4_scoreboard.sv"

    // ---- 10. Coverage
    `include "axi4_coverage.sv"

    // ---- 11. Environment
    `include "axi4_env.sv"

    // ---- 12. Tests
    `include "axi4_tests.sv"

endpackage : axi4_pkg

`endif // AXI4_PKG_SV
