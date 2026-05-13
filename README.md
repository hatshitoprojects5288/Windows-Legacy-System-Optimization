Introduction
-
This project documents the systematic optimization of Windows 10/11, pro. The goal was to achieve a low-thread count and ultra-low RAM idle states for high-performance tactical for gaming and AI evaluation workloads.

Technical Methodology
OS Stripping: Used NTLite and AtlasOS methodologies to remove non-essential telemetry and UWP bloat.

Kernel Tuning: Implemented registry-level modifications to prioritize foreground tasks and reduce system interrupts (ISR).

Resource Management: Disabled non-vital I/O services to free up clock cycles for CPU-bound tasks.

------------------------
1. The Performance Benchmarks
   -
|System Specifications|                  |
| :----| :-------------------------------|
| **CPU:** | Dual core proccesor             |
| **RAM:** |2GB DDR3|                        |
| **Windows 10 Pro (22H2) / Windows 11 Pro** |

------------------------
Results & Performance Delta
-
| Metric              |	    Stock Windows               |    Optimized Windows    |
| :-----------------  | :------------------------------ |  :--------------------  |
|**Idle RAM Usage**       |  	~3.2 GB                       |   	~0.9 GB - 1.1 GB    |
|**Process Count**	      |      200+                       |      	< 60              |     
|**Latency (DPC)**        |      600µs - 1200µs             |        < 60µs           |
|**Handle Count**         |       60,000+                   |     18,000 - 22,000     |

------------------------

2. Core Optimization Pillars
   -

***I. Kernel & Interrupt Optimization***

Interrupt Moderation: Adjusted NIC and GPU interrupt settings to ensure deterministic CPU cycles for foreground applications.

Timer Resolution: Forced a stable 0.5ms global timer resolution to reduce input lag and micro-stuttering in high-load scenarios.

DPC Mitigation: Identified and disabled legacy drivers (e.g., Floppy, Print Spooler, unnecessary HID) that cause interrupt spikes.

***II. System Service Hardening***

Telemetry Stripping: Complete removal of DiagTrack and related data-collection services to recover CPU cycles and bandwidth.

UWP Management: Systematic removal of non-essential Universal Windows Platform apps and the background "broker" processes they spawn.

Service Manualization: Converted "Automatic" services into "Manual" or "Disabled" to ensure the OS only consumes resources when explicitly requested.

***III. Registry-Level Tuning***

I/O Prioritization: 'Modified Win32PrioritySeparation for optimized foreground responsiveness.'

Memory Management: Tweaked LargeSystemCache and DisablePagingExecutive settings for users with 8GB+ RAM to force kernel-mode code into RAM instead of the pagefile.

3. Safety & Disclaimer
   -
***Warning:*** These optimizations involve deep-level modifications to the Windows Registry and System Services. It is designed for advanced users and legacy hardware where resource overhead is a critical bottleneck. Always create a System Restore Point before applying these configurations.





