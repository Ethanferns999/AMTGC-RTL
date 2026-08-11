\# AMTGC Bug and Debug History



This document records significant implementation and verification issues encountered during AMTGC development and the corresponding fixes.



\---



\## 1. Adaptive Green-Time Verification Failure



\### Symptom



Initial adaptive timing verification failed for several traffic-density values.



Examples included:



```text

Density 1 -> Expected 4, Got 1

Density 2 -> Expected 5, Got 2

Density 4 -> Expected 7, Got 1

Density 5 -> Expected 8, Got 2

Density 7 -> Expected 8, Got 1

Investigation



The adaptive green target was not being correctly maintained for the active green phase.



Fix



The junction controller was updated so that the density-derived green target is captured when the green phase begins and remains stable during the active green phase.



Result



The adaptive timing verification subsequently passed:



Density 0 -> 3

Density 1 -> 4

Density 2 -> 5

Density 3 -> 6

Density 4 -> 7

Density 5 -> 8

Density 6 -> 8

Density 7 -> 8



Minimum and maximum green-time limits were also verified.



2\. Junction B Adaptive Timing Integration Failure

Symptom



During Task 4 integration testing:



Junction B expected target 8, got 3

Investigation



Junction B was not using its density-derived target correctly when entering its active green phase.



Fix



The junction controller integration was corrected so that Junction B independently captures and uses its own adaptive timing target.



Result



The corrected integration test reported:



Junction B high density -> target 8



Task 4 adaptive integration subsequently passed.



3\. Green-Wave Integration Verification Failure

Symptom



An early system integration test failed to detect the expected Junction B green-wave timing.



Investigation



The initial verification environment did not correctly capture the timing relationship between Junction A and Junction B.



Fix



The green-wave startup sequencing and integration verification were adjusted so that Junction B is initially held and then enabled after the configured coordination delay.



Result



The final integration verification confirmed:



Junction B NS\_GREEN begins after startup offset

4\. Emergency Verification Testbench Issue

Symptom



An early Task 5 verification environment repeatedly reported:



Emergency during ALL\_RED\_1 -> all red



many times.



Cause



The testbench phase-search procedure continued executing after the requested phase had already been detected.



This was a verification-testbench control-flow problem rather than a confirmed RTL failure.



Fix



The emergency verification approach was simplified to verify system-level emergency behavior without repeatedly forcing or searching for individual internal phases.



Result



The final verification successfully confirmed:



Emergency -> both junctions all red

Emergency maintains all-red

Emergency released safely

5\. FSM Coverage Verification Issue

Symptom



An early full-system verification run reported that the following phases had not been observed:



EW\_GREEN

EW\_YELLOW

ALL\_RED\_2

Investigation



A dedicated cycle-debug testbench was created to observe Junction A's internal FSM state together with the timer signals.



The debug output demonstrated the complete sequence:



NS\_GREEN

NS\_YELLOW

ALL\_RED\_1

EW\_GREEN

EW\_YELLOW

ALL\_RED\_2

NS\_GREEN

Conclusion



The FSM and timer were functioning correctly. The problem was associated with the verification environment rather than the normal FSM transition logic.



Result



The final full-system verification observed all normal traffic phases.



6\. Git Remote Synchronization Issue

Symptom



A Git push was rejected with:



! \[rejected] main -> main (fetch first)

Cause



The GitHub repository contained commits that were not present in the local repository.



Fix



The local branch was synchronized using:



git pull --rebase origin main



After resolving a documentation add/add conflict, the changes were pushed using:



git push origin main

Result



The local repository and GitHub repository were successfully synchronized.



7\. Final Verification Status



After the debugging and verification iterations, the final Task 5 full-system testbench produced:



Total checks = 24

Total errors = 0



Additional final verification results included:



Pedestrian A grants = 60

Pedestrian B grants = 60

Randomized cycles completed = 500



The final AMTGC verification completed successfully.

