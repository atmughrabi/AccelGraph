# AccelGraph verification extension

The shared host watchdog, AFU/CU configuration, progress, error,
completion-publication, acknowledgement, and reset-clear contract is owned by
[CAPI-Precis accelerator verification](https://github.com/atmughrabi/CAPI-Precis/wiki/Accelerator-Verification).

AccelGraph consumes that monitor through the pinned `01_capi_precis` submodule
and adds graph-specific binding, tests, and host convergence guards.

![AccelGraph accelerator verification](https://raw.githubusercontent.com/atmughrabi/AccelGraph/master/docs/fig/accelerator-verification-f01-benchmark-liveness.svg)

## Graph-specific RTL verification

The RTL monitor checks:

- graph progress never exceeding the WED vertex target;
- graph completion matching `WED.num_vertices`;
- the generic monitor against BFS, PageRank, SPMV, connected-components, and
  triangle-count WED layouts.

ModelSim compiles and binds the monitor automatically through
`03_capi_integration/accelerator_sim/sim/vsim.tcl`. The verification wave group
is defined in `watch_accelerator_verification.do`; a violated RTL contract
terminates simulation with `$fatal`.

For first-platform bring-up, add `+VERIF_FATAL=0` to the `vsim` command to
retain failure counters and wave evidence without stopping at the first
violation.

## Graph-specific host guards

- graph loading and preprocessing complete before AFU setup;
- device errors and stalls include the target vertex count in diagnostics;
- completion is drained before every iterative graph round;
- BFS and connected-components rounds cannot exceed the vertex count;
- betweenness-centrality root selection is bounded;
- results remain subject to CPU/reference comparison.

## Intermittent-hang triage

| Symptom | Evidence to inspect |
| --- | --- |
| No CU progress | RTL `stall_age`, running counters, WED target, selected CU image |
| Progress exceeds target | WED/bitstream mismatch or duplicated vertex work |
| Completion never publishes | `cu_done`, `completion_valid`, `reset_done`, final counters |
| Next round never starts | completion ACK and `CU_STATUS` reset-clear witness |
| Host blocks inside libcxl | CAPI-Precis call-watchdog diagnostic |

## Local verification

```console
make rtl-verification
make verify
```

`make rtl-verification` validates the Phase 0 pin/layout manifests and
elaborates the real `cached_afu`, AFU-control, and graph `cu_control` RTL for
all eight active layouts without the compatibility CU stub. Implicit nets and
pin mismatches fail the gate; portable lint blackboxes only the two generated
Quartus floating-point IP boundaries. It then runs positive and negative
protocol tests with Verilator. `make verify` includes that RTL evidence
alongside host watchdog, graphbrew smoke, and OpenGraph checks. Local
verification skips the RTL stage when Verilator 5 is unavailable; GitHub
Actions sets `RTL_VERIFICATION_REQUIRED=1`.
