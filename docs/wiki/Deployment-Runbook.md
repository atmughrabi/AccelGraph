# Deployment runbook

Shared CAPI/PSLSE environment setup, timeout controls, and generic
host/RTL failure meanings are maintained in the
[CAPI-Precis deployment runbook](https://github.com/atmughrabi/CAPI-Precis/wiki/Deployment-Runbook).
This page contains only AccelGraph-specific deployment evidence.

## Before launch

```console
git submodule sync --recursive
git submodule update --init --recursive
sudo apt-get install libjudy-dev verilator
verilator --version  # must report version 5 or newer
make verify
```

Record the graph file, format, algorithm, direction, CU count, FPGA image,
thread counts, and timeout overrides.

## Launch

Use the existing simulator or FPGA target:

```console
make run-capi-sim-verbose2
make run-capi-fpga-verbose2
```

Simulation targets default to 5-minute start/call, 15-minute stall, and 2-hour
run limits. Override the `SIM_ACCELERATOR_*` make variables when measured
ModelSim latency requires different bounds.

Start with a `TEST` graph before moving to GAP, SNAP, LAW, or another large
suite.

## Failure evidence

Preserve the `Accelerator verification failed` line together with the command
line, graph metadata, CU image, AFU/CU status, error register, progress counters,
target vertex count, and simulator `debug.log` when applicable.

| Reason | First check |
| --- | --- |
| `device-error` | WED pointers, graph size, MMIO error decode, selected image |
| `stalled` | Counter movement, frontier/iteration size, PSL response statistics |
| `timeout` | Workload scale, algorithm/direction/image match, measured healthy duration |
| MMIO failure | Device node, permissions, attach state, PSLSE health |

Do not classify an algorithm as correct from liveness alone; compare its result
against the existing reference path.
