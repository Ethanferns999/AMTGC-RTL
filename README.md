# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)

## Overview

The **Adaptive Multi-Junction Traffic Grid Controller (AMTGC)** is a parameterized Verilog RTL project developed as part of the **Elevance Skills RTL Design Internship 2026**.

The system models two coordinated 4-way traffic junctions with adaptive traffic control, pedestrian arbitration, emergency override, and green-wave synchronization.

The project demonstrates:

- Parameterized RTL design
- Moore FSM architecture
- Reusable timer modules
- Adaptive traffic-density timing
- Green-wave coordination
- Shared pedestrian arbitration
- Round-robin fairness
- Emergency override
- Hierarchical RTL architecture
- Self-checking verification
- Randomized safety verification

---

## System Architecture

```text
                         +----------------------+
                         |      amtgc_top       |
                         |                      |
                         |  Green-Wave Control  |
                         |  Emergency Override  |
                         +----------+-----------+
                                    |
              +---------------------+---------------------+
              |                                           |
              v                                           v
     +-------------------+                       +-------------------+
     |    Junction A     |                       |    Junction B     |
     | junction_controller|                      | junction_controller|
     +---------+---------+                       +---------+---------+
               |                                           |
               v                                           v
        +-------------+                             +-------------+
        | Generic     |                             | Generic     |
        | Timer A     |                             | Timer B     |
        +-------------+                             +-------------+

                         +----------------------+
                         |     ped_arbiter      |
                         |   Round-Robin Logic  |
                         +----------------------+
Traffic FSM

Each junction uses the same parameterized junction_controller module.

The normal traffic sequence is:

NS_GREEN
    |
    v
NS_YELLOW
    |
    v
ALL_RED_1
    |
    v
EW_GREEN
    |
    v
EW_YELLOW
    |
    v
ALL_RED_2
    |
    v
NS_GREEN

A pedestrian phase can be inserted when a pedestrian grant is received.

The all-red phases provide a safety gap between conflicting traffic directions.

Adaptive Timing

Green time adapts according to the traffic-density input.

Traffic Density	Green Target
0	3
1	4
2	5
3	6
4	7
5	8
6	8
7	8

Configured limits:

Minimum green time: 3 cycles
Maximum green time: 8 cycles
Green extension: 1 cycle
Green-Wave Coordination

Junction A and Junction B operate as a coordinated system.

Junction B is initially held and is enabled after the configured GREEN_WAVE_OFFSET.

The green-wave relationship was verified through system-level simulation.

Pedestrian Arbitration

A shared ped_arbiter handles pedestrian requests from both junctions.

The arbiter uses round-robin arbitration to prevent starvation.

Repeated simultaneous requests alternate service between Junction A and Junction B.

Final verification:

Pedestrian A grants = 60
Pedestrian B grants = 60

The grants are mutually exclusive.

Emergency Override

A system-wide emergency_override input is distributed to both junction controllers.

When asserted, both junctions transition to a safe all-red condition and remain there while the override is active.

The final verification confirmed safe emergency activation, maintenance, and release.

RTL Modules
amtgc_top.v

Top-level integration module.

Responsibilities:

Instantiates Junction A
Instantiates Junction B
Instantiates generic timers
Instantiates pedestrian arbiter
Controls green-wave startup
Distributes emergency override
junction_controller.v

Parameterized Moore FSM.

Responsibilities:

Traffic phase sequencing
Adaptive timing
Pedestrian phase handling
Emergency handling
Timer control
Traffic-light outputs
generic_timer.v

Reusable parameterized timer.

Responsibilities:

Clock-cycle counting
Configurable target
Done indication
Reset handling
ped_arbiter.v

Shared round-robin pedestrian arbiter.

Responsibilities:

Receive requests from both junctions
Generate grants
Prevent starvation
Ensure mutually exclusive grants
Repository Structure
AMTGC-RTL/
|
+-- rtl/
|   +-- amtgc_top.v
|   +-- junction_controller.v
|   +-- generic_timer.v
|   +-- ped_arbiter.v
|
+-- tb/
|   +-- amtgc_top_tb.v
|   +-- generic_timer_tb.v
|   +-- junction_controller_tb.v
|   +-- junction_timer_integration_tb.v
|   +-- ped_arbiter_tb.v
|   +-- junction_adaptive_tb.v
|   +-- amtgc_adaptive_integration_tb.v
|   +-- amtgc_full_verification_tb.v
|
+-- docs/
|   +-- architecture.md
|   +-- verification.md
|   +-- bug-fixes.md
|   +-- waveform_evidence.md
|
+-- report/
|   +-- AMTGC_Final_Report.md
|
+-- images/
+-- logs/
+-- waveforms/
|
+-- assumptions.md
+-- verification_plan.md
+-- daily_log.md
+-- bug_log.md
+-- README.md
Verification

The project uses self-checking Verilog testbenches and was verified using ModelSim Intel FPGA Edition 2020.1.

The final Task 5 full-system verification tested:

Reset behavior
Complete traffic FSM cycle
Adaptive traffic-density timing
Green-wave coordination
Pedestrian fairness
Emergency override
Runtime reset
Randomized safety behavior

Final result:

Total checks = 24
Total errors = 0

Pedestrian A grants = 60
Pedestrian B grants = 60

Randomized cycles completed = 500

ALL TASK 5 VERIFICATION TESTS PASSED
AMTGC full-system verification successful.
FSM Coverage
Phase	Observed
NS_GREEN	Yes
NS_YELLOW	Yes
ALL_RED_1	Yes
EW_GREEN	Yes
EW_YELLOW	Yes
ALL_RED_2	Yes
Simulation
Compile RTL
vlog rtl/*.v
Compile Full-System Testbench
vlog tb/amtgc_full_verification_tb.v
Run Full-System Verification
vsim work.amtgc_full_verification_tb
run -all
Generic Timer Test
vlog rtl/generic_timer.v tb/generic_timer_tb.v
vsim work.generic_timer_tb
run -all
Junction Controller Test
vlog rtl/junction_controller.v rtl/generic_timer.v tb/junction_controller_tb.v
vsim work.junction_controller_tb
run -all
Pedestrian Arbiter Test
vlog rtl/ped_arbiter.v tb/ped_arbiter_tb.v
vsim work.ped_arbiter_tb
run -all
Design Practices

The RTL follows:

Parameterized modules
Hierarchical architecture
Named port connections
Non-blocking assignments for sequential logic
Blocking assignments for combinational logic
Default cases in FSM logic
Explicit reset values
No magic timing constants in FSM logic
Separate timer and FSM responsibilities
Self-checking verification
Documentation

Additional project documentation is available in docs/:

architecture.md — System architecture and module responsibilities
verification.md — Verification methodology and results
bug-fixes.md — Development and debugging history
waveform_evidence.md — Simulation evidence

The final technical report is available in:

report/AMTGC_Final_Report.md
Development Status
Task	Description	Status
Task 1	System Architecture Planning	Complete
Task 2	Parameterized RTL Module Design	Complete
Task 3	System Integration	Complete
Task 4	Adaptive Timing	Complete
Task 5	Full-System Verification	Complete
Task 6	Professional Documentation & Delivery	In Progress
Author

Ethan Fernandes

M.Sc. Electronics

Elevance Skills RTL Design Internship 2026