# AXI4 UVM Verification Environment



## 📌 Overview



This project implements a **complete UVM-based verification environment** for an **AXI4 Memory-Mapped Slave** design.

It verifies fundamental AXI4 read and write transactions with a focus on correctness, protocol compliance, and coverage.






---



## 🎯 Objectives



* Verify AXI4 **READ / WRITE operations**

* Ensure **protocol compliance** using assertions

* Achieve high **functional and code coverage**

* Build a **scalable UVM environment**

* Apply **constrained random verification**

* Validate design behavior under **normal and corner cases**



---



## 🏗️ Project Structure



```

axi4-uvm-verification-environment
│
├── rtl/                     # DUT (AXI4 Slave + Memory)
│   ├── axi4.sv
│   └── axi4_memory.sv
│
├── tb/
│   ├── agent/              # Driver, Monitor, Sequencer, Interface
│   │   ├── axi4_agent.sv
│   │   ├── axi4_driver.sv
│   │   ├── axi4_if.sv
│   │   ├── axi4_monitor.sv
│   │   └── axi4_sequencer.sv
│   │
│   ├── env/                # Environment, Scoreboard, Coverage, Config, Assertions
│   │   ├── axi4_assertions.sv
│   │   ├── axi4_cfg.sv
│   │   ├── axi4_coverage.sv
│   │   ├── axi4_env.sv
│   │   └── axi4_scoreboard.sv
│   │
│   ├── pkg/                # Package \& shared types
│   │   ├── axi4_pkg.sv
│   │   └── axi4_types.sv
│   │
│   ├── seq/                # Transactions \& Sequences
│   │   ├── axi4_sequences.sv
│   │   └── axi4_transaction.sv
│   │
│   ├── test/               # UVM Tests
│   │   ├── axi4_tests.sv
│   │    
│   ├── tb_top.sv
│
├── sim/                    # Simulation scripts
│   ├── run.do
│   └── Makefile
│
└── README.md

```



---



## ⚙️ Verification Architecture



The environment follows standard **UVM hierarchy**:



**Agent**



* Driver → drives transactions to DUT

* Monitor → observes DUT activity (passive)

* Sequencer → controls stimulus flow



**Environment**



* Scoreboard → checks expected vs actual behavior

* Coverage → tracks verification completeness

* Assertions → enforce AXI protocol rules



**Sequences**



* Generate constrained-random and directed transactions



**Tests**



* Configure and run the environment



---



## 🔍 Key Features



* ✅ Constrained-random AXI4 transactions

* ✅ Protocol checking using SystemVerilog Assertions (SVA)

* ✅ Functional coverage collection

* ✅ Modular and reusable UVM components

* ✅ Clean separation between stimulus, checking, and DUT

* ✅ Scalable structure for future extensions



---



## ▶️ Running Simulation



### Using QuestaSim / ModelSim (.do file)



```bash

vsim -do sim/run.do

```



### Using Makefile



```bash

cd sim

make run

```



---



## 📊 Coverage



The environment supports:



* Functional Coverage (covergroups)

* Assertion Coverage

* Code Coverage (bcstf)



Reports are generated automatically in the `sim/` directory.



---



## 🚀 Future Improvements



* Add burst transaction verification

* Implement advanced sequences (WR→RD data integrity)

* Add passive agent support

* Introduce multi-seed regression

* Extend coverage model (data patterns, corner cases)



---



## 🧠 Skills Demonstrated



* UVM Architecture \& Components

* AXI4 Protocol Understanding

* Constrained Random Verification

* SystemVerilog Assertions (SVA)

* Functional Coverage

* Debugging \& Verification Strategy



---




## 👤 Author



**Kareem S. Elhafi**

Digital IC Design \& Verification Enthusiast






