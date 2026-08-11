\# AMTGC Architecture



\## 1. System Overview



The Adaptive Multi-Junction Traffic Grid Controller (AMTGC) consists of two coordinated traffic junctions, Junction A and Junction B.



The system uses a single clock domain and a modular RTL architecture.



The main modules are:



\- `amtgc\_top`

\- `junction\_controller`

\- `generic\_timer`

\- `ped\_arbiter`



The system also supports:



\- Adaptive traffic-density timing

\- Green-wave coordination

\- Shared pedestrian arbitration

\- Emergency override

\- Runtime reset



\---



\## 2. Top-Level Architecture



```text

&#x20;                        +----------------------+

&#x20;                        |      amtgc\_top       |

&#x20;                        |                      |

&#x20;                        |  Green-Wave Control  |

&#x20;                        |  Emergency Override  |

&#x20;                        +----------+-----------+

&#x20;                                   |

&#x20;             +---------------------+---------------------+

&#x20;             |                                           |

&#x20;             v                                           v

&#x20;    +-------------------+                       +-------------------+

&#x20;    |    Junction A     |                       |    Junction B     |

&#x20;    |                   |                       |                   |

&#x20;    | junction\_controller|                      | junction\_controller|

&#x20;    +---------+---------+                       +---------+---------+

&#x20;              |                                           |

&#x20;              v                                           v

&#x20;       +-------------+                             +-------------+

&#x20;       | generic     |                             | generic     |

&#x20;       | timer A     |                             | timer B     |

&#x20;       +-------------+                             +-------------+



&#x20;                        +----------------------+

&#x20;                        |     ped\_arbiter      |

&#x20;                        |   Round-Robin Logic  |

&#x20;                        +----------------------+

&#x20;                          ^                  ^

&#x20;                          |                  |

&#x20;                     ped\_req\_a          ped\_req\_b

3\. Junction Controller



Both Junction A and Junction B use the same parameterized junction\_controller RTL module.



This demonstrates hardware reuse because the same RTL design can be instantiated with different parameter values.



The controller implements a Moore FSM.



Traffic Sequence

NS\_GREEN

&#x20;   |

&#x20;   v

NS\_YELLOW

&#x20;   |

&#x20;   v

ALL\_RED\_1

&#x20;   |

&#x20;   +------> PED\_PHASE

&#x20;   |          |

&#x20;   |          v

&#x20;   |       EW\_GREEN

&#x20;   |

&#x20;   +------> EW\_GREEN

&#x20;              |

&#x20;              v

&#x20;          EW\_YELLOW

&#x20;              |

&#x20;              v

&#x20;          ALL\_RED\_2

&#x20;              |

&#x20;              v

&#x20;          NS\_GREEN



The pedestrian phase is entered when a pedestrian grant is received at the appropriate transition point.



The all-red phases provide a safety gap between conflicting traffic directions.



4\. Generic Timer



Each junction has an independent instance of the reusable generic\_timer.



The timer receives:



start

count\_target



and produces:



done



The timer is independent of the FSM.



This separation allows the same timer design to be reused for different traffic phases and different junction configurations.



5\. Adaptive Timing



The junction controllers receive traffic-density inputs.



The green-time target is calculated from the traffic density while respecting configured minimum and maximum limits.



The verified adaptive behavior is:



Traffic Density	Green Target

0	3

1	4

2	5

3	6

4	7

5	8

6	8

7	8



The configured limits are:



Minimum green time: 3 cycles

Maximum green time: 8 cycles

Green extension: 1 cycle

6\. Pedestrian Arbitration



Pedestrian requests from both junctions are handled by one shared ped\_arbiter.



The arbiter uses round-robin arbitration.



This prevents Junction A from permanently receiving priority over Junction B.



For repeated simultaneous requests, service alternates between the two junctions.



The final verification tested 120 pedestrian requests and produced:



Pedestrian A grants = 60

Pedestrian B grants = 60



The grants are mutually exclusive.



7\. Green-Wave Coordination



Junction A and Junction B are coordinated through the green-wave mechanism.



Junction A is enabled first.



Junction B is initially held and is enabled after the configured GREEN\_WAVE\_OFFSET.



The green-wave behavior was verified during system-level simulation.



The verification confirmed that Junction B's North-South green begins after the required startup coordination delay.



8\. Emergency Override



A system-wide emergency\_override input is connected to both junction controllers.



When the emergency override is asserted:



Junction A -> ALL RED

Junction B -> ALL RED



Both junctions remain in a safe all-red condition while the override is active.



Emergency release was also verified to resume the system safely.



9\. Clock and Reset



The design uses a single clock domain.



The selected reset strategy is:



Synchronous active-high reset



This provides deterministic initialization of the FSMs, timers, arbitration logic, and coordination logic while keeping state changes synchronized to the system clock.



10\. Module Responsibilities

amtgc\_top.v



Top-level system integration.



Responsibilities:



Instantiate Junction A

Instantiate Junction B

Instantiate generic timers

Instantiate pedestrian arbiter

Coordinate green-wave startup

Distribute emergency override

junction\_controller.v



Parameterized traffic FSM.



Responsibilities:



Traffic phase sequencing

Adaptive timing

Pedestrian phase control

Emergency handling

Timer control

Traffic-light outputs

generic\_timer.v



Reusable timer.



Responsibilities:



Count clock cycles

Compare against target

Generate done

Respond to reset

Support configurable counter width

ped\_arbiter.v



Shared pedestrian arbitration.



Responsibilities:



Receive requests from Junction A and B

Generate grants

Maintain round-robin fairness

Prevent starvation

Ensure mutually exclusive grants

11\. Design Philosophy



The system is intentionally divided into independent modules.



This provides:



Hardware reuse

Easier verification

Clear interfaces

Easier debugging

Parameterized configuration

Better maintainability



The architecture keeps timing, traffic-state control, pedestrian arbitration, and system coordination as separate responsibilities.

