# Graph verification infrastructure

## Ownership boundary

AccelGraph verifies only the graph layer. The pinned
[CAPI-Precis verification infrastructure](https://github.com/atmughrabi/CAPI-Precis/wiki/Verification-Infrastructure)
owns libcxl, PSL, MMIO, command, response, data, credit, tag, error,
completion, reset, and generic AFU-control behavior.

AccelGraph owns:

- graph package and C/SystemVerilog WED contracts;
- routing, reduction, vertex, edge, cluster, and scheduler engines;
- BFS, PageRank, SPMV, connected-components, and triangle-count kernels;
- real graph `cu_control` integration across every active layout;
- graph fixtures, independent goldens, scoreboards, mutations, and coverage.

Shared infrastructure changes land in CAPI-Precis first. AccelGraph then updates
the exact `01_capi_precis` pin and regenerates its inventory and ownership
matrix.

## Layout denominator

| Algorithm | Active layout |
| --- | --- |
| BFS | CSR PULL BottomUp |
| PageRank | CSR PULL FloatPoint, FixedPoint, Quantized |
| SPMV | CSR PULL FloatPoint, FixedPoint |
| Connected components | CSR ShiloachVishkin |
| Triangle counting | CSR BinaryIntersection |

The three PageRank PUSH precision layouts are exact expected failures. Each is
locked to its missing source list and normalized failure signature; an
unexpected pass or changed failure fails the manifest gate.

The exact CAPI pin, package order, topology, vendor-IP boundary, and active or
expected-failure status are recorded in
`03_capi_integration/accelerator_verification/rtl/manifests/layouts.json`.

## Current closure

| Area | Status | Evidence |
| --- | --- | --- |
| Package contracts, routing, reduction | Closed | 8 layouts, 48 declaration contexts, 19 hashes, 1,631,876 checks, 2,277/2,277 bins, 43/43 mutations |
| Vertex/edge/cluster/scheduler engines | Rerun paused | Last complete pass: 72 contexts, 8/8 mutations, all owner families closed; final full rerun after downstream-`alfull` grant gating was paused |
| Algorithm kernels and shells | Closed | 16/16 contexts, 28/28 mutations, zero coverage failures, exact census |
| Real graph top | Rerun paused | Last complete pass: 8/8 layouts, 3/3 mutations, zero coverage gaps, 100% reachable line/branch/toggle; final post-`alfull` rerun passed BFS before being paused |
| Multi-CU integration | Open blocker | ConnectedComponents passes full topology; PageRank PULL, SPMV PULL, and TriangleCount are limited to `-K1` after failing the 24-vertex ring with multiple CUs |
| PageRank PUSH | Expected failure | Three manifests locked to the current seven-file source gap |
| Licensed ModelSim/Quartus/hardware | Release evidence | Not represented as a portable pass |

An area becomes closed only when its runner emits the exact `OWNERS:` set
expected by the canonical plan. A filtered run, missing context, stale
coverage denominator, surviving mutation, or known blocker suppresses that
claim.

The paused checkpoint preserves the last complete pre-`alfull` evidence and
the directed BFS post-change pass. It does not claim that the interrupted full
reruns completed.

## Canonical layout

```text
03_capi_integration/accelerator_verification/
  host/                        graph host/runtime contract tests
  sim/                         verification wave configuration
  rtl/
    manifests/                 layouts, inventory, coverage plan, module matrix
    models/                    vendor-IP verification boundaries
    scripts/                   pin, source, topology, and ownership validators
    unit/
      common/                  package contracts, routing, reduction
      engines/                 vertex, edge, cluster, scheduler
      algorithms/              kernels, shells, fixtures, precision models
    integration/               real graph `cu_control` layout suites
```

Synthesizable design remains under `accelerator_rtl`. Verification sources do
not live in Quartus-selected production directories.

## Evidence contract

Every graph family supplies:

1. **Architecture context**: exact layout, package set, topology, CAPI pin, and
   source hashes.
2. **Protocol assertions**: legal requests, ownership, counters, reset, and
   bounded progress.
3. **Transaction scoreboards**: vertex jobs, edge ranges, property reads,
   writes, tags, and completion conservation.
4. **Independent goldens**: algorithm results derived without production RTL
   or permissive benchmark comparison code.
5. **Deterministic backpressure**: named schedules with bounded stalls and
   eventual release.
6. **Functional and structural coverage**: exact reachable denominator for
   every material layout context.
7. **Diagnostic mutations**: representative ownership, address, extraction,
   arithmetic, writeback, and completion defects must be detected.

Liveness and algorithm correctness are separate claims. Reaching `cu_done`
without matching the independent result is a failure.

## Graph backpressure

The graph layer adds five domains:

| Domain | Path |
| --- | --- |
| `graph.vertex_job` | Vertex fetch, filter, and dispatch |
| `graph.edge_job` | CSR range generation |
| `graph.edge_read` | Edge/property command and extraction |
| `graph.write` | Result command and data path |
| `graph.kernel` | Algorithm consumer and completion |

Required portable integration evidence includes:

- an all-ready baseline;
- every domain stalled independently;
- all 32 graph-domain stall masks with eventual release;
- near-full request and result queues;
- cacheline-half and tagged-response reordering;
- repeat launch and reset during active work.

The scoreboard proves that unstalled domains continue to progress and that no
vertex, edge, update, command, tag, or completion is lost or duplicated.
Permanent stalls are used only when a named timeout or reset is the expected
result.

Cross-layer release testing combines graph masks with CAPI command, credit,
response, read-data, write-buffer, ACK, MMIO, job, and reset profiles. Those
campaigns extend, but never replace, deterministic graph P0 cases.

## Fixtures and goldens

The portable fixture set covers:

- empty and single-vertex graphs;
- directed chains, stars, cycles, and disconnected components;
- duplicate edges and self-loops;
- one triangle, shared-edge triangles, and K4;
- weighted toy matrices;
- PageRank dangling/sink behavior.

Golden policies are explicit:

- **BFS:** exact reachability/distance and a legal predecessor parent;
- **PageRank float:** fixed iteration, initialization, sink, rounding, NaN/Inf,
  and absolute/relative tolerance policy;
- **PageRank fixed/quantized:** bit-exact scale, rounding, and overflow policy;
- **SPMV:** exact row/value result with explicit fixed/float arithmetic;
- **Connected components:** compare canonical partitions, not representative
  label identity;
- **Triangle count:** exact per-vertex intersection count and documented total
  normalization.

The existing OpenGraph comparator remains compatibility evidence; it is not
the merge oracle.

## Exact ownership

The normative files are:

- `rtl/manifests/layouts.json`
- `rtl/manifests/rtl-inventory.json`
- `rtl/manifests/coverage-plan.json`
- `rtl/manifests/module-test-matrix.json`
- `rtl/unit/common/scenarios.json`
- `rtl/unit/engines/engine_scenarios.json`
- `rtl/unit/algorithms/suites.json`
- `rtl/integration/suites.json`

Every active production module and package contract has exactly one family
owner. Every distinct source hash runs in each materially different package or
topology context. Wildcard source discovery, stale plan/inventory hashes,
unclassified RTL, duplicate owners, missing contexts, and dirty CAPI pins fail
the gate.

Common-looking files are not deduplicated until source identity and all
applicable family suites prove replacement safety.

## Coverage policy

Closure requires 100% of reachable:

- statements and branches;
- FSM states and transitions where applicable;
- functional bins and assertion goals;
- control toggles;
- mapped layout/module contexts.

Tool-generated, parameter-constant, or structurally unreachable points are
recorded by exact source, scope, signal or branch, metric, and reason.
Exercising a declared unreachable point fails the census.

A waiver must include reason, owner, issue, metric, affected items, approval,
and expiry. Missing data, denominator drift, stale exclusions, or an expired
waiver fails closure.

## Commands

```console
make rtl-manifest-verification
make rtl-real-elaboration
make rtl-unit-common
make rtl-unit-engines
make rtl-unit-algorithms
make rtl-integration-graph
make rtl-unit-verification
make rtl-verification
make verify
```

The three explicit engine/algorithm/integration targets resume the paused long
runs. `make rtl-unit-verification` executes only owners promoted to
`implemented` in the canonical plan. `make verify` combines those promoted
owners with the exact CAPI pin, host watchdogs, benchmark checks, and the small
GraphBrew smoke run. GitHub Actions sets `RTL_VERIFICATION_REQUIRED=1`.

## Release boundary

Portable closure covers the eight active layouts. A release additionally
records:

- AccelGraph, OpenGraph, and CAPI-Precis commits;
- graph file/hash, format, algorithm, direction, precision, reorder, cache,
  thread, and CU settings;
- ModelSim/Quartus versions and ordered manifest hashes;
- FPGA image and platform identity;
- result hash or independent comparison and elapsed time;
- the first failure diagnostic and trace when a gate fails.

PageRank PUSH remains unsupported until all three precision layouts elaborate
with real RTL and pass the same unit, integration, golden, and coverage gates.
