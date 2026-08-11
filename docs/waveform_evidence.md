\# AMTGC Simulation and Waveform Evidence



\## 1. Purpose



This document records the simulation evidence used during AMTGC verification.



The waveform evidence is intended to demonstrate the behavior of the major system functions at simulation level.



\---



\## 2. Simulation Environment



The AMTGC RTL was simulated using:



\- ModelSim Intel FPGA Edition 2020.1

\- Verilog RTL

\- Self-checking Verilog testbenches



\---



\## 3. Traffic FSM Evidence



The Junction Controller was verified through the complete normal traffic sequence:



```text

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



The cycle-debug simulation confirmed the following state progression:



STATE\_A = 0  -> NS\_GREEN

STATE\_A = 1  -> NS\_YELLOW

STATE\_A = 2  -> ALL\_RED\_1

STATE\_A = 4  -> EW\_GREEN

STATE\_A = 5  -> EW\_YELLOW

STATE\_A = 6  -> ALL\_RED\_2

STATE\_A = 0  -> NS\_GREEN



This demonstrates that the controller does not transition directly between conflicting green phases.



4\. Adaptive Timing Evidence



Traffic-density timing was verified using the adaptive timing testbench.



Verified targets:



Density	Green Target

0	3

1	4

2	5

3	6

4	7

5	8

6	8

7	8



The simulation also verified that the active green target remains stable while the green phase is running.



5\. Green-Wave Evidence



The AMTGC integration simulation verified the green-wave relationship between Junction A and Junction B.



The testbench detected Junction B entering NS\_GREEN after the configured startup coordination delay.



Result:



Junction B NS\_GREEN begins after startup offset



This confirms that the green-wave behavior is implemented and verified through simulation.



6\. Pedestrian Arbitration Evidence



The pedestrian arbiter was verified using repeated simultaneous requests.



The final full-system verification produced:



Pedestrian A grants = 60

Pedestrian B grants = 60



for 120 tested pedestrian requests.



The simulation verified:



Both junctions receive grants.

Neither junction is starved.

Grants are mutually exclusive.

Round-robin fairness is maintained.

7\. Emergency Override Evidence



The full-system verification tested the system-wide emergency override.



The simulation confirmed:



Emergency -> both junctions all red

Emergency maintains all-red

Emergency released safely



This demonstrates that the emergency input forces the system into a safe traffic state and that normal operation can resume after the override is released.



8\. Runtime Reset Evidence



Reset was asserted during active system operation.



The simulation confirmed:



Reset during operation -> NS\_GREEN



This demonstrates deterministic recovery to the defined initial traffic state.



9\. Randomized Simulation Evidence



The final verification environment executed:



500 randomized cycles



The randomized simulation checked traffic-light safety and pedestrian grant exclusivity.



No randomized safety failures were reported.



10\. Final Simulation Result



The final full-system verification completed successfully:



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

