# Stabilization plan

## Scope and acceptance

The current benchmark is stable when host-only checks pass, every CAPI wait is
bounded, back-to-back CU launches observe reset completion, compatibility
comparisons pass, and failures identify the algorithm phase and workload.
Compatibility comparisons are not the merge oracle; active algorithms use the
independent goldens and closure rules in the verification infrastructure.

## Failure model

| Boundary | Previous risk | Control | Acceptance evidence |
| --- | --- | --- | --- |
| Submodules/tooling | Partial checkout or Python 2 command | Recursive checkout and Python 3 entry points | Clean setup and deterministic helper output |
| AFU setup | Null handle check used the pointer address | Correct handle validation and checked attach/map | Missing device fails immediately |
| libcxl call | PSLSE or detach could block inside one synchronous call | Monotonic process watchdog | Deliberately blocked call terminates |
| Configuration | Infinite repeated MMIO writes | Single write plus bounded status poll | Unit state tests and simulator status transition |
| Kernel execution | Infinite busy poll | Running-counter stall and absolute deadlines | Advancing and frozen counter cases |
| Device error | Benchmark continued after error | Failed process with register snapshot | Non-zero exit |
| Iterative algorithms | New CU launch raced completion reset | ACK plus done/status drain | Repeated PageRank/BFS/SPMV launch trace |
| Graph convergence | BFS or connected-components rounds could repeat forever | Vertex-count round ceiling | Non-converging frontier/change signal fails explicitly |
| BC root selection | AccelGraph CAPI copy looped when no vertex exceeded average degree | Bounded scan with non-isolated fallback | Regular and edgeless CAPI cases terminate |
| CI fixture | OpenGraph reference test hardcodes a LAW graph | Add bounded `TEST/graphbrew` smoke execution | Small fixture runs on every verification job |
| Correctness | Completion treated as success | Existing comparison retained as compatibility evidence while strict independent goldens are introduced | Per-algorithm shadow result, intentional-failure sensitivity, then merge-gating golden |
| RTL protocol | Host evidence could not detect internal graph-CU publication or target violations | Bind graph-target-aware monitor to `cached_afu` | Verilator pass/negative tests and ModelSim bind |

## Delivery stages

1. **Host baseline:** run the standalone accelerator verification test and the
   OpenGraph test target.
2. **Compile boundary:** compile the AccelGraph CAPI host against the pinned CAPI
   headers for simulator and hardware modes.
3. **Small-graph simulator:** run supported CAPI algorithms on `TEST/graphbrew`
   and preserve progress/reset evidence.
4. **Repeated launch:** exercise algorithms with multiple CU rounds or
   iterations and confirm no stale completion/status.
5. **Dataset canary:** run one representative graph from each deployed suite.
6. **Scale and stress:** sweep graph size, thread/CU count, direction, and cache
   configuration while checking output.
7. **Release:** record commit, submodule commits, image, graph, command, result
   checksum or comparison, and elapsed time.

## Verification matrix

| Layer | Required checks |
| --- | --- |
| Host unit | Defaults, overrides, invalid values, progress, stall, timeout, completion, device error |
| OpenMP/reference | Existing graph tests and algorithm result checks |
| Simulator | AFU/CU status, progress, error, completion ACK/reset |
| RTL monitor | Configuration acceptance, monotonic progress, WED vertex target, stable completion, ACK/reset |
| FPGA | Same protocol evidence plus image and platform identity |
| Algorithms | BFS, PageRank, SPMV, connected components, triangle count where supported |
| Repetition | Multi-iteration and multi-frontier launches |

## Rollout and rollback

Canary one graph algorithm and image at a time. Increase deadlines only from
measured healthy runs; never disable them. Roll back the host commit, CAPI
submodule commit, and FPGA image as one unit if liveness or output changes.
Retain the first failing diagnostic and the complete benchmark command.

## Accepted submodule residual

The pinned OpenGraph submodule retains its upstream unbounded
betweenness-centrality root selector. This commit does not modify third-party
submodule content; close that residual in OpenGraph and bump the pin separately.
