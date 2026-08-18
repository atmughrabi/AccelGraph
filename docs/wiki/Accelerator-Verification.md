# Accelerator verification

`02_capi_graph/src/capi_utils/accelerator_verification.c` is the AccelGraph CAPI
liveness source of truth. It protects each graph-kernel launch without changing
OpenMP algorithm behavior.

![AccelGraph accelerator verification](https://raw.githubusercontent.com/atmughrabi/AccelGraph/master/docs/fig/accelerator-verification-f01-benchmark-liveness.svg)

## Contract

1. Graph loading and preprocessing complete before the AFU is opened.
2. Each libcxl call has a process watchdog, the MMIO fault handler is
   installed, and setup failures terminate instead of entering a loop with an
   invalid handle.
3. Configuration pulses are re-issued until accepted, AFU status must echo the
   primary configuration, and all status polls are bounded.
4. Running counters must advance within the stall deadline while a graph kernel
   is active.
5. Device errors, stalls, and absolute timeouts terminate with the algorithm
   phase, progress, target vertex count, status, and error register.
6. Completion is acknowledged and drained before the next PageRank iteration,
   BFS frontier step, SPMV pass, or other repeated CU launch.
7. BFS and connected-components convergence loops cannot exceed the graph
   vertex count.
8. Algorithm output remains subject to the existing CPU/reference checks.

Phase deadlines are evaluated between libcxl calls. The call watchdog is the
hard bound while one synchronous libcxl operation is in progress.

## Runtime controls

| Variable | Default | Purpose |
| --- | ---: | --- |
| `ACCELERATOR_START_TIMEOUT_MS` | `10000` | AFU/CU configuration and reset-drain deadline |
| `ACCELERATOR_STALL_TIMEOUT_MS` | `60000` | Maximum time without counter movement |
| `ACCELERATOR_RUN_TIMEOUT_MS` | `1800000` | Absolute kernel deadline |
| `ACCELERATOR_CALL_TIMEOUT_MS` | `30000` | Maximum duration of one libcxl call |
| `ACCELERATOR_POLL_INTERVAL_US` | `1000` | Delay between MMIO polls |

Values must be positive decimal integers. Timeouts are limited to 24 hours,
polling is limited to one second, and the polling interval cannot exceed a
configured timeout. Values are loaded on first accelerator use.

The first 100 polls spin without sleeping; later polls use the configured
interval. Record a non-default interval with benchmark results.

## Local verification

```console
make verify
```

The target exercises configuration parsing, blocked-call watchdog expiry,
mocked libcxl setup/MMIO and completion reset, bounded betweenness-centrality
root selection, integration compilation, a bounded `TEST/graphbrew` smoke run,
and the OpenGraph reference test path.
