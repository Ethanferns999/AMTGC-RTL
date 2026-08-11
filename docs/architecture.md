# AMTGC Architecture

## 1. System Overview

The Adaptive Multi-Junction Traffic Grid Controller (AMTGC) consists of two coordinated traffic junctions controlled from a single clock domain.

The system contains:

- Junction A controller
- Junction B controller
- Generic timer for each junction
- Shared pedestrian arbiter
- Green-wave coordination logic
- System-wide emergency override

## 2. Top-Level Architecture

```text
                         +----------------------+
                         |      amtgc_top       |
                         |                      |
                         |  Green-Wave Control  |
                         |  Emergency Override  |
                         +----------+-----------+
                                    |
              +---------------------+---------------------+
              |                                           |
              v                                           v
     +-------------------+                       +-------------------+
     |    Junction A     |                       |    Junction B     |
     |                   |                       |                   |
     | junction_controller|                      | junction_controller|
     +---------+---------+                       +---------+---------+
               |                                           |
               v                                           v
        +-------------+                             +-------------+
        | generic     |                             | generic     |
        | timer A     |                             | timer B     |
        +-------------+                             +-------------+

                         +----------------------+
                         |     ped_arbiter      |
                         |   Round-Robin Logic  |
                         +----------------------+
                           ^                  ^
                           |                  |
                      ped_req_a          ped_req_b
