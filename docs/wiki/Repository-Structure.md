# Repository structure

## Rules

1. Preserve the OpenGraph and CAPI-Precis submodule boundaries.
2. Graph host/algorithm code stays in `02_capi_graph`.
3. Synthesizable graph RTL stays in `03_capi_integration/accelerator_rtl`.
4. Graph accelerator verification lives in
   `03_capi_integration/accelerator_verification`.
5. Generic CAPI BFMs, monitor, schemas, and protocol scoreboards are consumed
   from the exact CAPI-Precis pin and never copied.
6. Test graphs are immutable fixtures; generated results and coverage databases
   are ignored artifacts.
7. A move must preserve Make, ModelSim, Quartus, CI, documentation, and
   submodule-pin behavior.

## Naming convention

- Numbered repository roots use two digits and snake case.
- Integration roles use `accelerator_<role>`:
  `accelerator_rtl`, `accelerator_sim`, `accelerator_synth`,
  `accelerator_bin`, and `accelerator_verification`.
- Pinned dependencies retain their repository names in prose and their exact
  snake-case submodule paths (`00_open_graph`, `01_capi_precis`) in commands.
- Verification suite folders are functional nouns: `common`, `engines`,
  `algorithms`, and `integration`.

## Owned roots

| Path | Responsibility |
| --- | --- |
| `00_open_graph` | Pinned CPU/reference graph framework |
| `01_capi_precis` | Pinned shared CAPI host/AFU contract |
| `02_capi_graph` | Graph host runtime, CAPI algorithms, benchmark tests |
| `03_capi_integration` | Graph RTL, simulator, synthesis, binaries, verification |
| `04_test_graphs` | Versioned input fixtures; future golden/fixture registry |
| `05_scripts` | Algorithm/layout selection and benchmark helpers |
| `06_slides` | Historical presentations and brand source assets |
| `docs` | Maintained documentation and published-wiki source |
| `tools` | Thin CAPI environment wrapper and tests |

## Integration layout

```text
03_capi_integration/
  accelerator_rtl/              synthesizable graph RTL only
  accelerator_sim/              graph ModelSim execution flow
  accelerator_synth/            graph Quartus execution flow
  accelerator_bin/              released implementation outputs
  accelerator_verification/
    host/                        graph libcxl/watchdog contract tests
    sim/                         verification wave configuration
    rtl/
      manifests/                 layouts, inventory, coverage, module matrix
      scripts/                   pin/source/topology/real-CU validators
      models/                    vendor-IP verification boundaries only
      unit/
        common/                  packages, routing, and reduction
        engines/                 vertex, edge, cluster, and scheduler engines
        algorithms/              BFS, PageRank, SPMV, CC, triangle kernels
      integration/               real graph `cu_control` layout suites
```

Planned directories are added with their first executable test; empty
scaffolding is not committed.

## Migration order

| Stage | Work | Gate |
| --- | --- | --- |
| S0 | Consolidate existing verification | Complete: 8 active layouts and 3 exact XFAILs pass |
| S1 | Implement shared graph utility/engine families | Exact module matrix remains 78/78 across all active contexts |
| S2 | Implement independent algorithm goldens | Every intentional result corruption fails |
| S3 | Implement cross-engine backpressure | All 32 graph masks plus CAPI risk pairs pass |
| S4 | Close PageRank PUSH | 11/11 real layouts elaborate and pass goldens |
| S5 | Delegate legacy execution flows | Ordered ModelSim/Quartus sources remain identical |
| S6 | Archive unreferenced slides/assets | Link audit, release notes, clean worktree |

Common-looking RTL is not deduplicated until every distinct source hash has
unit evidence and the replacement passes all layout contexts.

## Structure gate

A structural change is complete only when:

- `make verify`, `make rtl-manifest-verification`, and
  `make rtl-real-elaboration` pass;
- every active graph production module and package contract has exactly one
  test owner;
- the CAPI pin is exact, clean, and passes its self-gate;
- ModelSim and Quartus resolve the reviewed layout manifest;
- documentation links and wiki mirrors match;
- no generated or duplicate source appears in `git status`.
