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


---

## Day 2

Date: 08 August 2026

### Objectives

- Complete Task 2 RTL implementation
- Develop and verify reusable RTL modules
- Integrate junction controller with generic timer
- Implement pedestrian arbitration
- Begin Task 3 system integration

### Work Completed

- Implemented parameterized `generic_timer`
- Implemented Moore FSM-based `junction_controller`
- Added configurable GREEN, YELLOW, RED and PED timing parameters
- Verified timer behavior across multiple parameter widths
- Verified zero-count behavior and one-cycle `done` pulse
- Verified reset during timer operation
- Verified timer restart behavior
- Verified complete junction traffic-light sequence
- Verified pedestrian phase handling
- Implemented `ped_arbiter` using round-robin arbitration
- Verified fair pedestrian grants and starvation prevention
- Implemented `amtgc_top`
- Integrated two junction controllers and independent timers
- Integrated shared pedestrian arbiter
- Implemented green-wave coordination
- Implemented system-wide emergency override
- Created system-level integration testbench

### Verification Results

- Generic timer tests: PASS
- Junction controller tests: PASS
- Junction + timer integration tests: PASS
- Pedestrian arbiter tests: PASS
- AMTGC system integration tests: PASS
- Green-wave offset verified in simulation
- Repeated simultaneous pedestrian requests verified
- Emergency all-red behavior verified
- Emergency recovery verified
- No conflicting green signals observed

### Challenges

- Correctly coordinating the green-wave startup delay between Junction A and Junction B.
- Handling emergency recovery without creating an unsafe traffic state.
- Ensuring pedestrian arbitration remains fair under repeated simultaneous requests.
- Debugging testbench timing assumptions during integration verification.

### Final Result

Task 2 RTL development and verification completed successfully.

Task 3 system integration and verification completed successfully.

### Next Steps

- Commit and push completed Task 2 and Task 3 work to GitHub.
- Review repository structure and documentation.
- Mark Task 3 complete.
- Begin next project task.
- Begin Task 2.
- Design the Generic Timer module.


Daily Log — Day 4

Date: 10 August 2026

Work Completed
Implemented adaptive traffic-density-based green timing.
Added configurable minimum/maximum green-time limits.
Integrated adaptive timing with both junctions.
Verified density-based timing for all density levels.
Verified green-wave, pedestrian arbitration, emergency override, and traffic-light safety.
Verification
All adaptive timing tests passed.
All Task 4 integration tests passed.
