\# AMTGC Verification Report



\## 1. Verification Overview



The Adaptive Multi-Junction Traffic Grid Controller (AMTGC) was verified using self-checking Verilog testbenches in ModelSim Intel FPGA Edition 2020.1.



Verification was performed at multiple levels:



\- Generic timer verification

\- Junction controller verification

\- Pedestrian arbiter verification

\- Timer/controller integration

\- AMTGC system integration

\- Adaptive timing integration

\- Full-system verification



\---



\## 2. Module-Level Verification



\### Generic Timer



The generic timer was verified with multiple parameter values.



The tests verified:



\- Timer reset

\- Timer start

\- Configurable target count

\- Done signal generation

\- One-cycle start behavior

\- Reset while counting

\- Zero-target behavior



\### Junction Controller



The junction controller testbench verified:



\- Reset behavior

\- NS\_GREEN

\- NS\_YELLOW

\- ALL\_RED\_1

\- PED\_PHASE

\- EW\_GREEN

\- EW\_YELLOW

\- ALL\_RED\_2

\- Timer targets

\- Pedestrian requests

\- Reset during operation

\- Safety gaps between conflicting directions



\### Pedestrian Arbiter



The pedestrian arbiter was verified using round-robin arbitration.



The testbench verified:



\- Reset behavior

\- No requests

\- A-only request

\- B-only request

\- Simultaneous requests

\- Alternating grants

\- Mutually exclusive grants

\- Grant clearing



The result confirmed that neither junction is permanently prioritized.



\---



\## 3. System Integration Verification



The AMTGC integration testbench verified both junctions operating together.



The following functions were tested:



\- Junction A operation

\- Junction B operation

\- Green-wave coordination

\- Pedestrian arbitration

\- Simultaneous pedestrian requests

\- Emergency override

\- Emergency all-red behavior

\- Safe recovery after emergency

\- Traffic-light safety



The integration test completed successfully.



\---



\## 4. Adaptive Timing Verification



Traffic-density inputs were tested to verify adaptive green timing.



The verified relationship was:



| Traffic Density | Green Target |

|------------------|--------------|

| 0 | 3 |

| 1 | 4 |

| 2 | 5 |

| 3 | 6 |

| 4 | 7 |

| 5 | 8 |

| 6 | 8 |

| 7 | 8 |



The minimum green limit was verified as:



```text

3 cycles



The maximum green limit was verified as:



8 cycles



Density changes during an active green phase were also tested to ensure that the active target remains stable.



5\. Green-Wave Verification



The green-wave mechanism was verified at system level.



Junction B is initially held before normal operation.



After the configured coordination delay, Junction B's North-South green phase begins.



The integration test confirmed:



Junction B NS\_GREEN begins after startup offset



This demonstrates that the green-wave relationship is implemented in RTL and verified through simulation.



6\. Pedestrian Fairness Verification



The final verification environment tested 120 simultaneous pedestrian requests.



Results:



Pedestrian A grants = 60

Pedestrian B grants = 60



The verification confirmed:



Junction A receives pedestrian service

Junction B receives pedestrian service

Neither junction is starved

Grants are mutually exclusive



The equal 60/60 distribution demonstrates the expected round-robin behavior for repeated simultaneous requests.



7\. Emergency Override Verification



The system-wide emergency override was tested.



The verification confirmed:



Emergency override can be asserted during normal operation.

Both junctions transition to an all-red condition.

Both junctions remain all-red while emergency override remains active.

The system resumes safely after emergency release.



Final verification output included:



Emergency -> both junctions all red

Emergency maintains all-red

Emergency released safely

8\. Runtime Reset Verification



Reset was asserted during active system operation.



The system correctly returned Junction A to its defined initial traffic state:



Reset during operation -> NS\_GREEN



This verifies deterministic recovery from a runtime reset.



9\. FSM Phase Coverage



The final full-system verification observed the complete normal traffic cycle:



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



Observed phases:



FSM Phase	Observed

NS\_GREEN	Yes

NS\_YELLOW	Yes

ALL\_RED\_1	Yes

PED\_PHASE	Not required for the normal cycle

EW\_GREEN	Yes

EW\_YELLOW	Yes

ALL\_RED\_2	Yes



The complete traffic FSM cycle was successfully observed.



10\. Randomized Verification



The final testbench executed:



500 randomized cycles



During randomized operation, the testbench checked:



Conflicting green outputs

Simultaneous pedestrian grants

General traffic-light safety



The randomized verification completed successfully without reported safety failures.



11\. Final Task 5 Verification Result



The final full-system verification produced:



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

