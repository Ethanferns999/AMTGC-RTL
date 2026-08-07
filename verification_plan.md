# Verification Plan

## Objective

Verify that the Adaptive Multi-Junction Traffic Grid Controller operates correctly under normal operation and corner-case scenarios.

## Planned Test Cases

| Test ID | Scenario |
|----------|----------|
| T1 | System reset |
| T2 | Normal traffic sequence |
| T3 | North-South to Yellow transition |
| T4 | East-West to Yellow transition |
| T5 | Pedestrian request at Junction A |
| T6 | Pedestrian request at Junction B |
| T7 | Simultaneous pedestrian requests |
| T8 | Starvation prevention |
| T9 | Emergency during NS Green |
| T10 | Emergency during EW Green |
| T11 | Emergency during Pedestrian phase |
| T12 | Green-wave synchronization |
| T13 | Parameter variation |
| T14 | Reset during operation |
| T15 | Recovery after emergency |

Verification will include directed testing, waveform analysis, corner-case testing, and self-checking testbenches where applicable.
