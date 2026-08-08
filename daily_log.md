# Daily Development Log

---

## Day 1

Date: 07 August 2026

### Objectives

- Understand project requirements
- Plan complete architecture
- Identify RTL modules
- Define interfaces
- Select reset strategy
- Create verification plan
- Initialize GitHub repository

### Work Completed

- Studied internship requirements
- Designed top-level architecture
- Identified reusable RTL modules
- Selected Moore FSM architecture
- Chose synchronous active-high reset
- Chose single clock domain
- Planned green-wave coordination
- Planned pedestrian arbitration using round-robin
- Created repository structure
- Initialized Git repository
- Connected project to GitHub

### Challenges

- Understanding overall system architecture before RTL implementation.

## Day 2

Date: 08 August 2026

### Objectives

- Implement parameterized RTL modules
- Verify the generic timer
- Implement the junction controller FSM
- Verify controller behavior
- Integrate the timer with the controller

### Work Completed

- Implemented reusable parameterized generic timer
- Verified timer reset, counting, zero-target, restart, and reset-during-counting behavior
- Tested timer with multiple counter-width configurations
- Implemented parameterized Moore FSM junction controller
- Added seven traffic phases and pedestrian phase handling
- Added parameterized timing for all phases
- Created self-checking controller testbench
- Integrated generic timer with junction controller
- Verified complete traffic sequence and pedestrian operation
- Verified integration using ModelSim waveforms

### Challenges

- Understanding FSM state transitions and timer handshake timing.

### Next Steps

- Document Task 2 results and commit changes to GitHub.
- Begin Task 3.
- Begin Task 2.
- Design the Generic Timer module.
