# Hardware Analysis & Kernel Logic
**Focus:** Intel (2 Cores / 2 Threads)

## 1. The Win32PrioritySeparation Optimization
On a 2-core CPU without hyper-threading, thread contention is the primary source of system stutter. By changing `Win32PrioritySeparation` to `26` (Hex), we force the Windows kernel into a strict foreground-priority state with fixed-length, short intervals. 

## 2. DisablePagingExecutive
By default, Windows pages kernel-mode drivers to the disk (pagefile) to save RAM. Setting `DisablePagingExecutive` to `1` forces the OS to keep the core kernel and drivers locked in the physical RAM, eliminating latency spikes associated with disk I/O.
