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

The root wrapper supplies AccelGraph's graph-simulation directory and pinned
CAPI-Precis checkout to the canonical environment harness:

```console
./tools/capi-env --mode host check
./tools/capi-env --mode sim check
./tools/capi-env --mode sim -- make run-vsim
./tools/capi-env --mode sim -- make run-pslse
./tools/capi-env --mode sim -- make run-capi-sim-verbose2
./tools/capi-env --mode fpga -- make run-capi-fpga-verbose2
```

Use `./tools/capi-env --mode sim shell` for a temporary configured shell. Exit
the shell to discard the environment. The wrapper never edits or relies on
`.bashrc`; mode behavior, custom Intel FPGA paths, and printed exports are
defined by the
[CAPI-Precis environment harness](https://github.com/atmughrabi/CAPI-Precis/wiki/Environment-Harness).
In simulation mode, `CAPI_DEVICE` must select the AFU configured in
`03_capi_integration/accelerator_sim/server/shim_host.dat`.

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
