# Graph verification infrastructure roadmap

## Ownership boundary

AccelGraph does not duplicate generic AFU-control verification.

[CAPI-Precis verification infrastructure](https://github.com/atmughrabi/CAPI-Precis/wiki/Verification-Infrastructure)
owns:

- PSL job, MMIO, command, response, data, credit, tag, and reset BFMs;
- generic AFU-control assertions and scoreboards;
- the canonical `accelerator_verification` monitor;
- deterministic scheduling, transaction journals, coverage/result formats, and
  failure artifacts.

AccelGraph owns the graph layer:

- graph WED/CSR adapters;
- vertex, edge-job, edge-data, reduction, demux, and graph-CU tests;
- graph-specific backpressure schedules and scoreboards;
- independent graph-algorithm golden models;
- algorithm/topology elaboration manifests;
- tiny-graph integration suites and reference-result policy.

Shared infrastructure changes land and pass in CAPI-Precis first. AccelGraph
then updates its submodule pin and adds graph adapters in the same commit.

### Cross-repository phase dependencies

| AccelGraph phase | Required CAPI-Precis evidence |
| --- | --- |
| Phase 0 baseline/manifests | Published manifest API pin `803a17a...` and passing CAPI G0/G1 portable gates |
| Phase 1 oracle/ABI | Published CAPI package/WED contract tests |
| Phase 2 shared infrastructure | Published verification API/schema v1, locked runner/BFMs/scheduler/artifact schemas, passing downstream compatibility job |
| Phase 3/4 unit work | CAPI utility/protocol P0 units and portable assertion/scoreboard API |
| Phase 6 cross-engine | CAPI named backpressure profiles, pairwise array schema, replay/journal v1 |
| Phase 7 full system | Exact CAPI pin that passed CAPI integration, compatibility, and replay gates |

## Current baseline

| Area | Current evidence | Missing evidence |
| --- | --- | --- |
| Host runtime | CAPI watchdog/fake-libcxl tests, convergence guards, bounded BC root selection | Independent graph-result oracle and strict mismatch policy |
| RTL lifecycle | Canonical CAPI monitor plus graph WED target bind | Unit assertions and scoreboards for graph engines |
| Real bind | Real `cached_afu + AFU control + graph cu_control` elaboration for all 8 active layouts; implicit nets/pin mismatches rejected | PageRank PUSH closure and licensed floating-point IP elaboration |
| Benchmark smoke | Bounded BFS `graphbrew` run and broad OpenGraph comparison | Deterministic expected outputs for every supported algorithm |
| Simulation | PSLSE/ModelSim graph selection and verification wave group | Reusable graph stimulus, memory model, backpressure, coverage, and replay |
| CI | Host, monitor, exact pin/layout/inventory gate, 8-layout real-CU elaboration, graphbrew, and reference checks | Per-module tests, coverage gates, failure artifacts |

### Phase 0 manifest gate

The executable baseline in `verification/rtl` now provides:

- the exact CAPI-Precis manifest API pin `803a17a...`;
- 8 active ordered ModelSim/Quartus manifests with package-derived topology;
- 3 PageRank PUSH expected-failure manifests, each locked to the same 7
  missing paths and source-resolution signature;
- an inventory of all 118 graph RTL files: 93 module files, 22 package files,
  68 distinct module hashes, and 3 verification files;
- exact ModelSim Tcl, Quartus Tcl, and synthesis Make source-set comparison;
- synthesis-directory naming derived from the hardcoded CU topology rather
  than host thread count;
- real portable elaboration of every active graph CU, with only generated
  Quartus floating-point IP boundaries blackboxed.

```console
make rtl-manifest-verification
make rtl-real-elaboration
```

G0 and portable G1 are active merge gates. Licensed ModelSim/Quartus
analysis/elaboration remains required release evidence.

### Inventory

- 93 graph RTL implementations.
- 30 distinct module-name families.
- 22 package files.
- 63 implementations in 12 shared-named CU-cluster families.
- 30 algorithm-specific implementations in 18 families.
- 11 intended layout/precision builds:
  - BFS PULL BottomUp
  - PageRank PULL FloatPoint, FixedPoint, Quantized
  - PageRank PUSH FloatPoint, FixedPoint, Quantized
  - SPMV PULL FloatPoint, FixedPoint
  - ConnectedComponents ShiloachVishkin
  - TriangleCount BinaryIntersection

Common-looking files are mostly copies with variant drift. Only deduplicate
after module tests and equivalence checks prove identical behavior.

G0 uses an exhaustive path-level inventory. The current denominator is 93
implementations containing 68 distinct source hashes. Every graph RTL file receives
status `active`, `quarantined`, `generated/external`, or `removed`, plus build
membership, source hash, verification family, and evidence. Every distinct
source hash among the 93 implementations must execute the applicable family
suite or be mapped to a tested implementation by approved equivalence evidence.
Unclassified RTL fails G0.

Allowed equivalence evidence is limited to:

1. normalized source identity after comment/whitespace/preprocessor
   normalization; or
2. execution of the full applicable family suite on that distinct hash.

No unpinned behavioral/formal-equivalence claim substitutes for a test.

## Verification contract

Every graph test must provide:

1. **Architecture manifest** - exact packages, modules, parameters, topology,
   and CAPI-Precis pin.
2. **Graph fixture hash** - immutable input graph and configuration.
3. **Independent golden result** - not the current permissive OpenGraph
   comparator.
4. **Transaction scoreboard** - vertex jobs, edge ranges, edge/property reads,
   writes, and completion counts.
5. **Backpressure schedule** - named deterministic profile or replayable seed.
6. **Assertions and functional coverage** - local and cross-engine.
7. **Failure bundle** - first failure, memory diff, recent transactions,
   counters, seed/profile, command, and waveform.

Liveness and algorithm correctness are separate claims. Both are required.
Golden code must not call production OpenGraph, AccelGraph, or DUT
preprocessing/arithmetic functions. Immutable type declarations may be shared;
algorithms and layout calculations may not.

## Shared graph testbench services

AccelGraph adds graph adapters on top of CAPI-Precis services:

| Service | Responsibility |
| --- | --- |
| CSR/WED builder | Builds directed/inverse CSR, weights, labels, auxiliary buffers, and the exact 128-byte WED image |
| Graph memory adapter | Maps graph arrays onto the shared byte-addressable CAPI memory model |
| Vertex-job source/scoreboard | Predicts vertex work, filtering, ownership, and completion |
| Edge-job scoreboard | Predicts edge ranges from CSR offsets/degrees |
| Edge-data scoreboard | Matches cache-line requests and extracted edge/property elements |
| Graph-write scoreboard | Applies legal property updates and validates address/mask/data |
| CU topology model | Tracks graph-CU/vertex-CU enable, routing, grants, and completion reduction |
| Algorithm golden library | BFS, PageRank, SPMV, connected-components, and triangle-count references |
| Precision policy | Exact integer/fixed/quantized checks and explicit float tolerance/rounding |
| Fixture registry | Tiny motifs, graph hash, directedness, weights, expected results, and legal roots |
| Architecture runner | Isolated package/work library per layout/precision build |

## Backpressure model

Graph integration adds five namespaced graph domains to the CAPI channel
scheduler:

- `graph.vertex_job`: vertex-fetch/job production
- `graph.edge_job`: edge-job generation
- `graph.edge_read`: edge/property read path
- `graph.write`: result write path
- `graph.kernel`: algorithm-kernel consumer

### Required profiles

1. All-ready baseline.
2. Each domain stalled independently.
3. Every pairwise graph stall combination as a named subset of the full mask
   matrix.
4. All 32 graph-domain stall masks with eventual release.
5. Near-full oscillation on request and result queues.
6. Long bounded pauses at cache-line and partition boundaries.
7. Response/tag reordering while unrelated engines continue.
8. Seeded random bursts using CAPI-Precis's canonical PRNG.
9. Reset during vertex, edge-job, edge-data, write, done publication, and
   acknowledgement phases.

The scoreboard must continue to make progress in unstalled domains and must
prove no job, edge, update, tag, or completion is duplicated or dropped.

### Cross-repository combination policy

| Tier | Combination rule |
| --- | --- |
| Graph unit | Each graph domain independently and relevant local combinations |
| Graph integration P0 | All 32 graph masks under CAPI all-ready baseline |
| Cross-layer P1 | Pairwise covering array crossing every graph domain with `capi.command`, each `capi.credit.*` class, `capi.response`, `capi.read_data`, `capi.write_buffer`, `capi.ack`, and `capi.reset` |
| Risk triples | Graph edge-read + CAPI response reorder + credit starvation; graph write + buffer stalls + ACK delay; vertex-job + reset + MMIO delay |
| Nightly | Seeded random overlays across all CAPI and graph domains |
| Timeout tests | Selected permanent stalls with explicit expected watchdog/RTL timeout |

Every bounded stall declares maximum duration and eventual release. Permanent
stalls are legal only in tests whose expected result is a named timeout or
reset termination.

The cross-layer array also includes `capi.mmio` and `capi.job`. It is stored as
a version-controlled artifact with factors, levels, generator/version, seed,
case count, regeneration command, and SHA-256.

## Golden graph library

### Fixture set

| Fixture | Required properties |
| --- | --- |
| Empty graph | Zero vertices/edges; host must reject or define explicit no-op behavior |
| Single vertex | Isolated vertex and zero-edge completion |
| Directed chain | Maximum BFS depth, PageRank flow, SPMV ordering |
| Star | High-degree center, frontier expansion/contraction |
| Directed cycle | PageRank conservation and strongly connected component |
| Disconnected components | Reachability and component partitioning |
| Self-loop | Explicit self-loop policy |
| Duplicate edge | Explicit duplicate-edge preprocessing policy |
| One triangle | Smallest positive triangle result |
| Shared-edge triangles | Per-vertex versus normalized total counting |
| K4 | Dense intersection and known triangle count |
| Weighted toy matrix | SPMV values, fixed-point rounding, overflow boundaries |
| Dangling/sink graph | PageRank sink and isolated-vertex policy |

Each fixture stores source edges, canonical CSR, inverse CSR where required,
WED image, expected memory updates, and algorithm results.

The oracle consumes the source edge list independently from the CSR/WED adapter.
Hand-authored fixtures validate serialized CSR/WED bytes. Nontrivial random
fixtures use a second independent implementation or differential library in
addition to the primary golden.

### Golden policies

- **BFS:** exact distance/reachability; parent may vary but must be a legal
  predecessor at distance minus one.
- **PageRank float:** explicit iteration count, damping, sink policy, and
  initialization, update ordering, atomic/conflict policy, accumulation order,
  termination, NaN/Inf handling, and absolute/relative tolerance; report every
  mismatch.
- **PageRank fixed/quantized:** exact scale, rounding, saturation/wrap policy,
  quantization points, update/conflict policy, and bit-exact result.
- **SPMV:** initialization, row/update ordering, accumulation order, exact
  integer/fixed result, overflow policy, and explicit float/NaN/Inf policy.
- **Connected components:** canonicalize labels to partitions before
  comparison; never compare raw representative IDs.
- **Triangle count:** exact per-vertex counts and documented normalization for
  total triangles.

Arithmetic and preprocessing policy is a versioned specification authored
independently of RTL: scale, rounding, saturation/wrap, accumulation order,
conflict/atomicity, initialization, sink handling, convergence, and
serialization. A spec/RTL mismatch is triaged as a defect; the golden is never
silently changed to match RTL.

PageRank float tolerances derive from a documented error bound and cannot be
widened without a waiver. Every tolerance suite includes a sensitivity case
perturbed just beyond the allowed bound.

The current OpenGraph comparator cannot serve as the merge oracle because it
suppresses or resets some mismatches. Keep it as compatibility evidence only.
Algorithm suites enter shadow mode first, compare golden versus compatibility
results, then become merge-gating individually after intentional wrong-result
tests prove sensitivity.

## Common module test matrix

### Job/data plumbing

| Verification unit | Module families | Priority | Required scenarios |
| --- | --- | --- | --- |
| Struct demux | `array_struct_type_demux_bus` | P0 | Every destination, invalid ID, simultaneous traffic, hold under stall |
| Scalar demux | `demux_bus` | P0 | Every destination, width 1/non-power-of-two/default |
| Reduction | `sum_reduce` | P0 | Zero/all inputs, changing inputs, configured widths, pipeline latency, monotonic aggregate |
| Vertex job | `cu_vertex_job_control` | P0 | Zero/one/high degree, final partial cache line, forward/inverse CSR, address/size/ABT |
| Vertex filter | `cu_vertex_job_filter` | P0 | Active/inactive vertices, filtered count, all/none/alternating filters |
| Edge job | `cu_edge_job_control` | P0 | Zero/one/large degree, cache-line crossings, exact edge ranges |
| Edge read command | `cu_edge_data_read_command_control` | P0 | Offsets, alignment, command sizes, CU IDs, backpressure |
| Edge read extract | `cu_edge_data_read_extract_control` | P0 | Both cache-line halves, boundary elements, tag/CU routing, reordered halves |
| Edge write command | `cu_edge_data_write_command_control` | P0 | Masks, same-line updates, address/data coupling, write stalls |

### Cluster and top-level control

| Verification unit | Module families | Priority | Required scenarios |
| --- | --- | --- | --- |
| Vertex-cluster arbiter | `cu_vertex_cluster_arbiter_control` | P0 | One-hot grants, fairness, simultaneous requests, disabled CUs |
| Vertex-cluster control | `cu_vertex_cluster_control` | P0/P1 | Routing, reset, per-CU counters, completion reduction |
| Algorithm arbiter | `cu_graph_algorithm_arbiter_control` and algorithm-specific arbiter controls | P0 | Work ownership, no duplicate/drop, completion aggregation |
| CU top | every `cu_control` | P0 | WED/config latching, engine enable, counter monotonicity, done once, reset, repeated launch |

## Algorithm test matrix

### BFS

| DUT | Tests |
| --- | --- |
| `cu_vertex_bfs` | Parent/distance update, inactive vertex, already visited, frontier transition |
| `cu_vertex_bfs_arbiter_control` | Work distribution, no duplicate vertex ownership, counter reduction |
| BottomUp `cu_update_kernel_control` | Neighbor scan, early match, no match, work-list read/write |
| Integration | Chain, star, disconnected graph, self-loop/duplicate policy; exact distances and legal parents |

### PageRank PULL

| DUT | Tests |
| --- | --- |
| `cu_vertex_pagerank` | Degree normalization, sink handling, property read/write |
| `cu_vertex_pagerank_arbiter_control` | Distribution and reduction |
| `cu_graph_algorithm_control` | Edge accumulation and vertex update ordering |
| `cu_sum_kernel_control` | Float, fixed, and quantized accumulation/rounding |
| Integration | One-step and multi-step cycle, sink, isolated vertex, weighted/unweighted modes |

### PageRank PUSH

| DUT | Tests |
| --- | --- |
| `cu_cacheline_stream` | Cache-line sequencing and backpressure |
| `cu_edge_data_read_control` | Forward CSR property reads |
| `cu_edge_data_control` | Edge traversal and routing |
| `cu_edge_data_write_control` | Update write ordering and conflicts |
| PUSH vertex/arbiter/control/sum kernels | Flat-interface and two-config-word behavior, all precisions |

PageRank PUSH is a P0 flow-closure item: the current simulation script expects a
missing PUSH `wed_pkg.sv` and compiles PULL-oriented module lists. Do not claim
PUSH coverage until its manifest, WED type, module list, and real CU elaboration
are corrected.

### SPMV

| DUT | Tests |
| --- | --- |
| `cu_vertex_spmv` | Row accumulation and result write |
| `cu_vertex_spmv_arbiter_control` | Row ownership and completion |
| Float/Fixed sum kernels | Rounding, sign, zero row, overflow boundary |
| Integration | Zero matrix, identity-like matrix, weighted toy matrix |

### Connected components

| DUT | Tests |
| --- | --- |
| `cu_vertex_connectedComponents` | Hook/update behavior and stable component |
| Arbiter/control | Work distribution and convergence counters |
| ShiloachVishkin `cu_update_kernel_control` | Parent update and compression |
| Integration | Isolated vertices, chain, cycle, multiple components; canonical partition comparison |

### Triangle count

| DUT | Tests |
| --- | --- |
| `cu_vertex_triangleCount` | Neighbor-list intersection and per-vertex count |
| Arbiter/control | Work distribution and count reduction |
| Binary kernel | Sorted-list binary/intersection edge cases |
| Integration | No triangle, one triangle, shared-edge triangles, K4; exact normalized total |

The file
`cu_TriangleCount/CSR/BinaryIntersection/Binary/cu/cu_update_kernel_control.sv`
currently declares `cu_sum_kernel_control`. Resolve the filename/module-name
contract in the P0 manifest phase.

## Architecture elaboration matrix

All builds use isolated work directories because packages and module names
collide.

| Layout | Precision variants | Current topology | Required gate |
| --- | --- | ---: | --- |
| BFS CSR PULL | BottomUp | 4 x 4 = 16 | Real CU elaboration and unit/integration pass |
| PageRank CSR PULL | Float, Fixed, Quantized | 5 x 4 = 20 | Three real elaborations and precision goldens |
| PageRank CSR PUSH | Float, Fixed, Quantized | 1 x 4 = 4 | Flow closure, WED fix, six common/PUSH unit gates |
| SPMV CSR PULL | Float, Fixed | 5 x 4 = 20 | Two real elaborations and result goldens |
| CC CSR | ShiloachVishkin | 4 x 4 = 16 | Real elaboration and partition golden |
| TC CSR | BinaryIntersection | 4 x 4 = 16 | Real elaboration and exact count golden |

All 11 layout/precision builds must elaborate with the real graph CU hierarchy,
not `cached_afu_bind_cu_stub`.

The existing `cu_count` simulation argument is currently reported but does not
change hardcoded package topology. Manifest/image names must not claim a
different count until this is corrected.

## Toolchain and backend contract

AccelGraph inherits the pinned toolchain, portable SystemVerilog subset,
dependency/license registry, artifact whitelist, and required-versus-optional
gate policy from CAPI-Precis.

Graph-specific requirements:

| Tool/backend | Graph role | Gate |
| --- | --- | --- |
| Verilator exact CI pin | Real layout elaboration, common units, graph units, scoreboards | Required PR; >= 5.050 for coverage jobs |
| Python locked environment | Independent graph goldens, fixture/CSR/WED generation, schema validation | Required PR |
| ModelSim/Questa | 4-state graph integration, CAPI BFMs, covergroups, wave evidence | Required release; selected nightly |
| PSLSE | End-to-end graph/CAPI compatibility | Required release; selected nightly |
| Quartus | Analysis/elaboration for all manifests and representative fits | Required release |

Licensed gates use self-hosted runners. Missing required licenses/runners block
the release; they never become a passing skip. Vendor IP, license files,
restricted datasets, encrypted libraries, and proprietary binaries are not
uploaded.

## CI tiers and measurable closure

| Tier | Scope | Runtime target | Sharding | Retention |
| --- | --- | ---: | --- | ---: |
| PR-fast | Manifests, ABI, changed common/algorithm units, tiny fixture smoke | <= 20 min | Layout/unit | 14 days on failure |
| PR-full | All P0 common units, gated algorithm units, 8 currently closable real layouts, all graph masks under CAPI all-ready | <= 90 min | Layout/algorithm | 30 days on failure |
| Nightly | P0+P1, CAPI↔graph pairwise covering array, fixed/random seeds, repeated launches | <= 8 h | Layout/profile/seed | 30 days |
| Release | 11/11 layouts after PUSH closure, licensed backends, source-set equivalence, coverage closure, representative fits | Scheduled | Backend/layout | Release lifetime |
| P2 campaign | Long random/parameter/topology campaigns | Budgeted | Seed/layout | Campaign lifetime |

Before Phase 5, an interim release may cover only the 8/11 non-PUSH layouts
when all three PUSH manifests retain exact expected-failure signatures, PUSH is
documented unsupported, and linked defects remain open. After Phase 5, every
release requires 11/11.

Initial budget model:

- PR-full graph masks: 8 closable layouts x 32 masks = 256 cases, compile once
  per layout, target <= 10 seconds per case, at least 8 shards.
- P0 common/algorithm units are sharded separately; unchanged units may reuse a
  content-addressed compile cache but may not skip tests.
- Nightly cross-layer covering array runs on a rotating representative layout
  set: BFS, one PageRank PULL precision, one SPMV precision, CC, and TC each
  night; all precision/layout combinations complete within a seven-night
  rotation.
- Phase 1 records measured compile/case runtimes and fails planning review if
  stated budgets cannot cover the required denominator.

### Coverage policy

- 100% of version-controlled mandatory functional bins.
- 100% of mandatory cross bins for graph fixture, algorithm, precision, degree
  class, cache-line boundary, engine stall profile, CAPI response class, and
  reset phase.
- Zero unexpected assertions and scoreboard mismatches.
- P0 unit floors on a coverage-capable backend: statement >= 90%, branch >=
  85%, toggle >= 80%. FSM state/transition coverage is 100% for legal states
  and mandatory transitions.
- A nondecreasing ratchet raises each floor when the measured baseline is
  higher.
- Waivers are version-controlled with owner, issue, reason, affected evidence,
  approval, and expiry.
- Missing required coverage data fails the tier.

| Metric | Backend | Earliest required tier |
| --- | --- | --- |
| Assertions | Pinned Verilator | PR-fast |
| Portable functional-bin counters | Pinned Verilator | PR-full |
| Statement/branch/toggle | Verilator >= 5.050 or pinned Questa | Nightly |
| FSM state/transition | Pinned coverage-capable backend | Nightly |
| Cross coverage / covergroups | Pinned Questa unless portable implementation exists | Release |

## Shared schema and replay contract

AccelGraph consumes the versioned CAPI-Precis build-manifest, replay,
transaction-journal, result, and failure-bundle schemas.

Graph extensions add:

- graph fixture schema/version and source-edge-list SHA-256;
- directed/weighted/preprocessing policy;
- CSR/inverse-CSR/WED SHA-256;
- algorithm and precision policy version;
- root, iterations, tolerance, damping, delta, and reorder configuration;
- graph topology/layout manifest hash;
- expected result and memory-image hashes.

Replay verifies the exact CAPI verification API/schema version, CAPI submodule
commit, graph manifest, fixture, PRNG/profile version, tool identity, and
clock/reset parameters. It refuses mismatched inputs rather than replaying a
different build.

## Target folder structure

Keep production RTL and public entry points in place while verification is
introduced:

```text
docs/
  assets/
  archive/slides/
  verification/
  wiki/

02_capi_graph/
  verification/
    host/
      common/
      unit/
      integration/
      e2e/

03_capi_integration/
  accelerator_rtl/
    verification/
      graph/
        common/
        assertions/
        unit/common/
        unit/algorithms/
        integration/
        manifests/
        regress/

04_test_graphs/
  verification/
    fixtures/
    golden/
    manifests/
```

### Compatibility rules

- Consume generic BFMs/models/assertions from the pinned CAPI-Precis submodule.
- Never copy the generic monitor or shared BFM sources.
- Consume the CAPI monitor through its versioned
  `verification/manifests/monitor.f`, not a literal private source path.
- Keep `make verify`, `make rtl-verification`, `make run-vsim`, `make run-pslse`,
  and Quartus targets.
- Convert current scripts into thin wrappers only after new manifests pass from
  repository root and legacy working directories.
- Keep each layout in an isolated library/build directory.
- Do not change production RTL paths during the first verification phases.
- Never add verification, assertion, bind, injector, or testbench files beneath
  Quartus-globbed `global_cu`, `global_pkg`, precision `cu`, or precision `pkg`
  directories.
- CI compares the complete ordered ModelSim/Quartus source set for all 11
  manifests before and after every migration phase.
- Archive slides only after searching Make/Tcl/Quartus and external links.
- Keep unique `2015_CAPI.pdf`; link to pinned OpenGraph copies for duplicated
  graph slides.
- Publish `docs/wiki` to the GitHub wiki before merging README/sidebar links to
  new pages.
- CI compares normalized SHA-256 content for every `docs/wiki/*.md` page against
  the wiki repository and rejects missing pages or redirects to wiki home.
- A merge-triggered publisher mirrors `docs/wiki` to `AccelGraph.wiki.git`.
  Pull requests validate source only; post-merge validates the published hash.
- Wiki editing is restricted to collaborators; direct wiki edits are
  overwritten and must be backported to `docs/wiki`.
- Page existence uses `raw.githubusercontent.com/wiki/...` or a wiki clone;
  following an HTML redirect to wiki home is not a valid page check.
- Keep compatibility stubs for moved repository documents for at least one
  release.

## Phased delivery

### Phase 0 - baseline, pins, manifests

**Status:** 8 active layouts and 3 exact PageRank PUSH expected failures are
implemented; licensed ModelSim/Quartus closure remains pending.

- Require clean recursive checkout with CAPI-Precis
  `803a17a8b5896673526f28b0c32183e0628b59a2` as the baseline pin.
- Record exact package/module/topology manifests for all 11 builds.
- Add source-set comparison for ModelSim and Quartus.
- Add real graph-CU elaboration; remove stub-only confidence.
- Close 8/11 builds in Phase 0. Record the three PageRank PUSH precision
  manifests as quarantined expected failures with linked defects. Each records
  tool/version, compile phase, normalized error pattern, and missing-file list
  including the absent `cu_PageRank/CSR/PUSH/global_pkg/wed_pkg.sv`.

**Gate:** 8/11 non-PUSH layouts compile in isolation; all three PUSH manifests
fail with their exact expected signatures. A different failure or unexpected
pass (XPASS) fails the gate; exclusions are explicit.

### Phase 1 - strict oracle and ABI

- Build independent tiny-graph golden library.
- Add C/SV WED size, offset, endian, and pointer-field tests.
- Stop using permissive comparator results as merge evidence.
- Gate BFS, PageRank, SPMV, CC, and TC goldens.

**Gate:** intentional wrong outputs fail every algorithm suite.

### Phase 2 - shared graph infrastructure

- Consume a future published CAPI-Precis pin containing a named verification
  API/schema version, runner, BFMs, scheduler, journal, result schema, and
  artifact writer.
- Add CSR/WED builder, graph memory adapter, graph transaction types, and
  fixture registry.

**Gate:** the exact CAPI pin passes its own P0 self-tests; AccelGraph records the
API/schema version; one intentional graph failure produces a complete replay
bundle.

### Phase 3 - common graph units

- Demux/reduction, vertex job/filter, edge job/read/extract/write, cluster
  arbitration, and CU top tests.

**Gate:** P0 unit matrix passes every named backpressure profile; mandatory bins
are complete.

### Phase 4 - algorithm units

- BFS, PageRank PULL, SPMV, CC, and TC units and tiny-graph integration.
- Fix TriangleCount module naming contract.

**Gate:** every algorithm matches its independent golden model.

### Phase 5 - PageRank PUSH closure

- Add/correct PUSH WED package, module manifest, compile flow, config-word
  policy, and all three precision suites.

**Gate:** three PUSH builds elaborate with real RTL and pass unit/integration
goldens, promoting architecture closure from 8/11 to 11/11.

### Phase 6 - cross-engine backpressure

- Run all 32 `V/J/R/W/K` masks, deterministic pauses, fixed seeds
  `{13, 52, 1024, 27491095, 37491095, 1461247482}`, repeated launches, and
  nightly random seeds.

**Gate:** no lost/duplicated work or leaked state; journal replay is stable.

### Phase 7 - full-system compatibility

- Run actual `cached_afu + graph cu_control` with CAPI-Precis BFMs.
- Update to the exact CAPI pin that passed the corresponding integration and
  replay gates.
- Validate ModelSim/PSLSE, Quartus analysis/elaboration, and representative
  fits.

**Gate:** existing public targets remain compatible and source manifests match.

### Phase 8 - structure cleanup

- Consolidate only proven-identical common RTL.
- Canonicalize duplicate fixtures.
- Move active docs/assets and archive slides.
- Retain compatibility wrappers for one release.

Legacy and wrapper entry points run in dual mode during that release. Any G7/G8
failure reverts the wrapper/migration commit before further cleanup.

## Release gates

| Gate | Requirement |
| --- | --- |
| G0 pin/manifest | Published baseline CAPI pin, 8 active manifests, 3 quarantined PUSH manifests |
| G1 compile | 8/11 real layouts initially; 11/11 after Phase 5, without stubs or implicit nets |
| G2 oracle/ABI | Strict goldens and C/SV WED contract pass |
| G3 unit | Every P0 common and algorithm module test passes |
| G4 integration | Tiny graph suites pass all deterministic backpressure masks |
| G5 coverage | Required bins complete; exclusions reviewed |
| G6 reproducibility | Seed/profile/manifest reproduces journal and failure bundle |
| G7 compatibility | Existing Make, ModelSim, PSLSE, and Quartus entry points remain valid |
| G8 migration | Links validate, artifacts are ignored, worktree stays clean |

## Known P0 decisions

- Close PageRank PUSH package/module/source-list gaps before counting it as
  supported verification coverage.
- Replace permissive OpenGraph comparator behavior with strict independent
  goldens.
- Test WED layout as an ABI shared by C and every SystemVerilog variant.
- Do not deduplicate shared-looking RTL until unit and equivalence evidence
  exists.
- Do not let requested CU count differ from hardcoded topology or image naming.
- Treat synthesis binaries/reports as implementation evidence, not correctness
  goldens.
