Introduction
This project documents the systematic optimization of Windows 10/11, pro. The goal was to achieve a low-thread count and ultra-low RAM idle states for high-performance tactical for gaming and AI evaluation workloads.

Technical Methodology
OS Stripping: Used NTLite and AtlasOS methodologies to remove non-essential telemetry and UWP bloat.

Kernel Tuning: Implemented registry-level modifications to prioritize foreground tasks and reduce system interrupts (ISR).

Resource Management: Disabled non-vital I/O services to free up clock cycles for CPU-bound tasks.

---------------------------
Results & Performance Data

Metric               |	Stock Windows       |    	Optimized State
Idle RAM Usage       |   	~3.2 GB           |      	~0.9 GB
Process Count	       |      180+            |        	< 60
Latency (DPC)        |   	> 500µs	          |        < 50µs
