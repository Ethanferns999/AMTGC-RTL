# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)

## Overview

The **Adaptive Multi-Junction Traffic Grid Controller (AMTGC)** is a parameterized Verilog RTL project developed as part of the **Elevance Skills RTL Design Internship 2026**.

The system models two coordinated 4-way traffic junctions, Junction A and Junction B, operating as a single adaptive traffic-control system.

The design demonstrates:

- Parameterized RTL design
- Moore finite-state-machine architecture
- Reusable timer modules
- Adaptive traffic-density timing
- Green-wave coordination
- Shared pedestrian arbitration
- Round-robin fairness
- System-wide emergency override
- Hierarchical RTL architecture
- Self-checking verification
- Randomized safety verification

The project is designed to demonstrate practical RTL design and verification methodology suitable for semiconductor and digital-design development environments.

---

## System Architecture

The AMTGC consists of the following major modules:

```text
                    +----------------------+
                    |      amtgc_top       |
                    |   System Controller  |
                    +----------+-----------+
                               |
              +----------------+----------------+
              |                                 |
              v                                 v
     +-------------------+             +-------------------+
     |   Junction A      |             |   Junction B      |
     | junction_controller|            | junction_controller|
     +---------+---------+             +---------+---------+
               |                                 |
               v                                 v
        +-------------+                   +-------------+
        | Generic     |                   | Generic     |
        | Timer A     |                   | Timer B     |
        +-------------+                   +-------------+

                    +----------------------+
                    |    ped_arbiter       |
                    |  Round-Robin Arbiter |
                    +----------------------+
Junction Controller

Each junction uses the same reusable junction_controller RTL module.

The controller implements the traffic sequence:

NS_GREEN
    |
    v
NS_YELLOW
    |
    v
ALL_RED_1
    |
    +----> PED_PHASE (when granted)
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

The all-red phases provide a safety interval between conflicting traffic directions.

Main Features
1. Parameterized Traffic Timing

Green, yellow, red, and pedestrian timing values are configurable through module parameters.

Adaptive green timing is controlled using traffic-density information.

The implemented green-time limits are:

Minimum green time = 3 cycles
Maximum green time = 8 cycles
Green extension    = 1 cycle

Example adaptive behavior:

Traffic Density	Green Target
0	3
1	4
2	5
3	6
4	7
5	8
6	8
7	8
2. Green-Wave Coordination

Junction A and Junction B do not operate independently.

A configurable GREEN_WAVE_OFFSET controls the startup relationship between the two junctions.

Junction B is initially held before entering normal operation and subsequently begins its North-South green phase within the configured coordination window.

The green-wave relationship was verified during system-level simulation.

3. Shared Pedestrian Arbitration

A single ped_arbiter module handles pedestrian requests from both junctions.

The arbiter uses a round-robin policy to prevent starvation.

For simultaneous requests:

First request  -> Junction A
Next request   -> Junction B
Next request   -> Junction A
Next request   -> Junction B
...

Verification demonstrated:

Pedestrian A grants = 60
Pedestrian B grants = 60

for 120 simultaneous pedestrian requests.

The two grants are mutually exclusive.

4. Emergency Override

A system-wide emergency_override input is provided.

When asserted, both junctions transition to an all-red condition and remain there while the override is active.

Emergency behavior was verified during system-level simulation.

RTL Modules
amtgc_top.v

Top-level integration module.

Responsibilities:

Instantiates Junction A
Instantiates Junction B
Instantiates generic timers
Instantiates pedestrian arbiter
Controls green-wave enable sequencing
Distributes emergency override
Connects traffic-density inputs
junction_controller.v

Parameterized Moore FSM used by both traffic junctions.

Responsibilities:

Traffic phase sequencing
Adaptive green timing
Pedestrian phase handling
Emergency handling
Timer control
Traffic-light outputs
generic_timer.v

Reusable parameterized timer module.

Responsibilities:

Start-controlled counting
Configurable counter width
Configurable target count
Done indication
Reset handling
ped_arbiter.v

Shared pedestrian arbitration module.

Responsibilities:

Accept requests from Junction A and B
Generate mutually exclusive grants
Implement round-robin arbitration
Prevent starvation
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
|   +-- junction_controller_tb.v
|   +-- generic_timer_tb.v
|   +-- junction_timer_integration_tb.v
|   +-- ped_arbiter_tb.v
|   +-- junction_adaptive_tb.v
|   +-- amtgc_adaptive_integration_tb.v
|   +-- amtgc_full_verification_tb.v
|
+-- docs/
+-- images/
+-- logs/
+-- report/
+-- waveforms/
|
+-- assumptions.md
+-- bug_log.md
+-- daily_log.md
+-- verification_plan.md
+-- README.md
Verification

The project uses self-checking Verilog testbenches.

Verification was performed at multiple levels:

Module-Level Verification
Generic timer
Junction controller
Pedestrian arbiter
Integration Verification
Junction controller + timer
Complete AMTGC top-level system
Adaptive timing integration
Full-System Verification

The final Task 5 verification environment tested:

Reset behavior
Complete traffic FSM cycle
Adaptive traffic-density timing
Green-wave coordination
Pedestrian fairness
Emergency override
Runtime reset
Randomized safety behavior

Final verification result:

Total checks = 24
Total errors = 0

Pedestrian A grants = 60
Pedestrian B grants = 60

Randomized cycles completed = 500

ALL TASK 5 VERIFICATION TESTS PASSED
AMTGC full-system verification successful.
FSM Coverage
NS_GREEN   = observed
NS_YELLOW  = observed
ALL_RED_1  = observed
EW_GREEN   = observed
EW_YELLOW  = observed
ALL_RED_2  = observed
Simulation Environment

The design was verified using ModelSim Intel FPGA Edition 2020.1.

Compile RTL

From the project directory:

vlog rtl/*.v
Compile Testbench

Example:

vlog tb/amtgc_full_verification_tb.v
Run Full-System Verification
vsim work.amtgc_full_verification_tb
run -all
Run Individual Tests

Generic timer:

vlog rtl/generic_timer.v tb/generic_timer_tb.v
vsim work.generic_timer_tb
run -all

Junction controller:

vlog rtl/junction_controller.v rtl/generic_timer.v tb/junction_controller_tb.v
vsim work.junction_controller_tb
run -all

Pedestrian arbiter:

vlog rtl/ped_arbiter.v tb/ped_arbiter_tb.v
vsim work.ped_arbiter_tb
run -all
Design Practices

The RTL follows these design practices:

Parameterized modules
Reusable hardware blocks
Hierarchical architecture
Named port connections
Non-blocking assignments for sequential logic
Blocking assignments for combinational logic
Default cases in FSM logic
Explicit reset behavior
No magic timing constants inside FSM logic
Separate timer and FSM responsibilities
Self-checking verification
Development Tasks
Task	Description	Status
Task 1	System Architecture Planning	Complete
Task 2	Parameterized RTL Module Design	Complete
Task 3	System Integration	Complete
Task 4	Adaptive Timing	Complete
Task 5	Full System Verification	Complete
Task 6	Professional Documentation & Delivery	In Progress
Author

Ethan Fernandes

M.Sc. Electronics

Elevance Skills RTL Design Internship 2026
