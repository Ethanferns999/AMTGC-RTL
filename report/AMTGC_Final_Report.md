\# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)



\## Final Technical Report



\*\*Author:\*\* Ethan Fernandes  

\*\*Program:\*\* M.Sc. Electronics  

\*\*Internship:\*\* Elevance Skills RTL Design Internship 2026  

\*\*Technology:\*\* Verilog RTL  

\*\*Simulation:\*\* ModelSim Intel FPGA Edition 2020.1



\---



\# 1. Introduction



The Adaptive Multi-Junction Traffic Grid Controller (AMTGC) is a digital traffic-control system designed to coordinate two 4-way traffic junctions.



The project was developed as a modular and parameterized RTL design rather than as two independent traffic-light controllers.



The system incorporates:



\- Two coordinated traffic junctions

\- Moore FSM-based traffic control

\- Generic reusable timers

\- Adaptive traffic-density timing

\- Green-wave synchronization

\- Shared pedestrian arbitration

\- Round-robin fairness

\- Emergency override

\- Runtime reset handling

\- Self-checking verification



The primary objective was to demonstrate practical RTL design, modular hardware architecture, parameterization, integration, and verification.



\---



\# 2. System Requirements



The AMTGC system was designed to satisfy the following functional requirements:



1\. Control two independent 4-way traffic junctions.

2\. Maintain safe traffic-light sequencing.

3\. Include an all-red interval between conflicting traffic directions.

4\. Use reusable parameterized RTL modules.

5\. Adapt green time according to traffic density.

6\. Coordinate Junction A and Junction B using a green-wave mechanism.

7\. Handle pedestrian requests through a shared arbiter.

8\. Prevent pedestrian starvation.

9\. Provide a system-wide emergency override.

10\. Return to a valid state following reset or emergency release.

11\. Verify the complete system using self-checking simulation.



\---



\# 3. System Architecture



The design uses a hierarchical architecture consisting of four major RTL modules:



```text

&#x20;                        +----------------------+

&#x20;                        |      amtgc\_top       |

&#x20;                        |                      |

&#x20;                        | Green-Wave Control   |

&#x20;                        | Emergency Override   |

&#x20;                        +----------+-----------+

&#x20;                                   |

&#x20;             +---------------------+---------------------+

&#x20;             |                                           |

&#x20;             v                                           v

&#x20;    +-------------------+                       +-------------------+

&#x20;    |    Junction A     |                       |    Junction B     |

&#x20;    | junction\_controller|                      | junction\_controller|

&#x20;    +---------+---------+                       +---------+---------+

&#x20;              |                                           |

&#x20;              v                                           v

&#x20;       +-------------+                             +-------------+

&#x20;       | Generic     |                             | Generic     |

&#x20;       | Timer A     |                             | Timer B     |

&#x20;       +-------------+                             +-------------+



&#x20;                        +----------------------+

&#x20;                        |     ped\_arbiter      |

&#x20;                        |   Round-Robin Logic  |

&#x20;                        +----------------------+



The architecture separates state control, timing, arbitration, and system coordination.



4\. RTL Module Design

4.1 Junction Controller



The junction\_controller is a parameterized Moore finite-state machine.



The same RTL module is instantiated for both Junction A and Junction B.



The normal traffic sequence is:



NS\_GREEN

&#x20;   ->

NS\_YELLOW

&#x20;   ->

ALL\_RED\_1

&#x20;   ->

EW\_GREEN

&#x20;   ->

EW\_YELLOW

&#x20;   ->

ALL\_RED\_2

&#x20;   ->

NS\_GREEN



A pedestrian phase can be inserted when an appropriate pedestrian grant is received.



The all-red states provide a safety interval between conflicting traffic directions.



4.2 Generic Timer



The generic\_timer is an independent reusable timer module.



The timer accepts:



Clock

Reset

Start

Count target



and generates a done signal when the configured target is reached.



The timer is intentionally separated from the FSM so that timing functionality is not duplicated inside the traffic controller.



4.3 Pedestrian Arbiter



The ped\_arbiter receives pedestrian requests from both junctions.



A round-robin arbitration policy is used.



For repeated simultaneous requests, service alternates between Junction A and Junction B.



This prevents one junction from receiving permanent priority.



The final verification produced:



Pedestrian A grants = 60

Pedestrian B grants = 60



for 120 tested pedestrian requests.



4.4 Top-Level Controller



The amtgc\_top module integrates the complete system.



It instantiates:



Two junction\_controller modules

Two generic\_timer modules

One ped\_arbiter



It also implements:



Green-wave startup coordination

Emergency override distribution

Junction enable control



Named port connections are used throughout the hierarchy.



5\. Parameterization



The design uses parameters rather than hardcoded timing values.



Examples include:



COUNTER\_WIDTH

GREEN\_TIME

YELLOW\_TIME

RED\_TIME

PED\_TIME

MIN\_GREEN\_TIME

MAX\_GREEN\_TIME

GREEN\_EXTENSION

GREEN\_WAVE\_OFFSET



Junction A and Junction B can therefore use different timing configurations without modifying the underlying RTL.



This demonstrates genuine hardware reusability.



6\. Adaptive Traffic Timing



Traffic density is represented using a 3-bit input.



The verified mapping is:



Density	Green Target

0	3

1	4

2	5

3	6

4	7

5	8

6	8

7	8



The design enforces:



Minimum green = 3 cycles

Maximum green = 8 cycles



The active green target remains stable during the current green phase.



7\. Green-Wave Coordination



The two junctions are coordinated through a configurable green-wave offset.



Junction A is enabled first.



Junction B is initially held and is subsequently enabled after the configured coordination delay.



System-level simulation verified:



Junction B NS\_GREEN begins after startup offset



This demonstrates that the green-wave relationship is implemented in RTL and verified through simulation.



8\. Emergency Handling



The system contains a single emergency\_override input.



When asserted, both junction controllers transition to a safe all-red condition.



The all-red condition is maintained while the emergency override remains active.



After the override is released, the system resumes from a valid traffic state.



Final verification confirmed:



Emergency -> both junctions all red

Emergency maintains all-red

Emergency released safely

9\. Clock and Reset Strategy



The system uses a single clock domain.



The selected reset strategy is:



Synchronous active-high reset



The reset initializes the system to deterministic states.



For normal startup:



Junction A -> NS\_GREEN

Junction B -> held all-red / green-wave startup condition



Runtime reset was also verified during active operation.



10\. Verification Methodology



Verification was performed progressively.



Module-Level Verification



The following modules were tested independently:



Generic timer

Junction controller

Pedestrian arbiter

Integration Verification



The following system-level relationships were tested:



Controller + timer

Two-junction integration

Green-wave coordination

Adaptive timing

Pedestrian arbitration

Emergency override

Full-System Verification



A dedicated full-system self-checking testbench was developed for Task 5.



The final verification included:



Reset verification

Complete FSM coverage

Pedestrian fairness

Adaptive density combinations

Green-wave verification

Emergency override

Runtime reset

Randomized verification

11\. Final Verification Results



The final Task 5 verification completed successfully.



===============================================

TASK 5 VERIFICATION SUMMARY

===============================================



Total checks = 24

Total errors = 0



Pedestrian A grants = 60

Pedestrian B grants = 60



Randomized cycles completed = 500



===============================================

ALL TASK 5 VERIFICATION TESTS PASSED

AMTGC full-system verification successful.

===============================================

FSM Coverage



The final simulation observed:



NS\_GREEN

NS\_YELLOW

ALL\_RED\_1

EW\_GREEN

EW\_YELLOW

ALL\_RED\_2



The complete normal traffic cycle returned to NS\_GREEN.



12\. Verification Challenges and Debugging



Several issues were encountered during development.



Adaptive Timing



Initial adaptive tests showed incorrect targets for several density values.



The issue was traced to how the adaptive target was captured and maintained during the active green phase.



The controller was corrected and the complete density range was subsequently verified.



Junction B Adaptive Timing



An integration test initially reported:



Junction B expected target 8, got 3



The Junction B adaptive target handling was corrected.



The final integration test confirmed that high-density Junction B traffic correctly produces a green target of 8.



FSM Coverage



Early full-system verification did not observe all traffic phases.



A dedicated cycle-debug testbench was used to inspect:



FSM state

Timer target

Timer start

Timer done

Traffic-light outputs



The debug simulation confirmed the complete FSM cycle.



The final verification environment then successfully observed all normal traffic phases.



Emergency Verification



Early emergency tests exposed issues in the phase-search logic of the verification environment.



The testbench methodology was improved and the final system-level emergency tests passed.



13\. Design Decisions

Modular Architecture



Separate modules were used instead of combining the entire system into one RTL block.



This improves:



Reusability

Debugging

Verification

Maintainability

Shared Pedestrian Arbiter



A shared arbiter was selected instead of separate pedestrian controllers.



This provides a single point of arbitration and allows requests from both junctions to be handled fairly.



Round-Robin Arbitration



Round-robin arbitration was selected because fixed priority could starve one junction under repeated simultaneous requests.



Separate Timer Module



Timing functionality was kept independent from the FSM.



This avoids duplicated counter logic and makes the timer reusable.



Single Clock Domain



A single clock domain simplifies synchronization and verification.



Synchronous Reset



A synchronous active-high reset provides deterministic initialization while keeping state transitions aligned with the system clock.



14\. Verification Lessons



The project demonstrated the importance of verifying not only individual modules but also their interactions.



Important lessons included:



A module can pass standalone testing while integration can still fail.

Parameterization must be verified by changing parameters and observing behavior.

Testbench control flow can introduce false failures.

Debug instrumentation is valuable when investigating FSM/timer interactions.

Safety properties should be checked continuously rather than only at selected states.

Randomized testing provides additional confidence beyond directed tests.

15\. Repository Organization



The final repository is organized as:



AMTGC-RTL/

|

+-- rtl/

|   +-- amtgc\_top.v

|   +-- junction\_controller.v

|   +-- generic\_timer.v

|   +-- ped\_arbiter.v

|

+-- tb/

|   +-- generic\_timer\_tb.v

|   +-- junction\_controller\_tb.v

|   +-- junction\_timer\_integration\_tb.v

|   +-- ped\_arbiter\_tb.v

|   +-- amtgc\_top\_tb.v

|   +-- junction\_adaptive\_tb.v

|   +-- amtgc\_adaptive\_integration\_tb.v

|   +-- amtgc\_full\_verification\_tb.v

|

+-- docs/

|   +-- architecture.md

|   +-- verification.md

|   +-- bug-fixes.md

|   +-- waveform\_evidence.md

|

+-- report/

|   +-- AMTGC\_Final\_Report.md

|

+-- images/

+-- logs/

+-- waveforms/

|

+-- README.md

+-- assumptions.md

+-- verification\_plan.md

+-- daily\_log.md

+-- bug\_log.md

16\. Conclusion



The AMTGC project successfully progressed from system architecture planning through RTL implementation, system integration, adaptive timing, and full-system verification.



The final verified system demonstrates:



Parameterized RTL

Reusable hardware modules

Moore FSM traffic control

Adaptive timing

Green-wave coordination

Fair pedestrian arbitration

Emergency safety handling

Hierarchical system integration

Self-checking verification

Randomized simulation



The final Task 5 verification completed with:



24 checks

0 errors

500 randomized cycles

120 pedestrian requests

60 grants for Junction A

60 grants for Junction B



The project provides a complete example of a modular RTL design and verification workflow from architecture through system-level validation.

