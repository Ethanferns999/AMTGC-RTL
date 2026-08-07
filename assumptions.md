# Assumptions

## System Assumptions

- The entire system operates in a single clock domain.
- A synchronous active-high reset is used throughout the design.
- The system consists of two coordinated 4-way traffic junctions.
- Only one pedestrian request per junction is considered at a time.
- Emergency override has the highest priority over all other operations.
- Junction B follows Junction A through a configurable green-wave delay.
- Round-robin arbitration is used to prevent pedestrian starvation.
- Adaptive traffic timing will be implemented using configurable parameters.
- Traffic density is sampled at the beginning of each green phase.
