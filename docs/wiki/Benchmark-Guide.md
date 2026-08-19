# Benchmark guide

## Repository boundaries

| Path | Responsibility |
| --- | --- |
| `00_open_graph` | Pinned OpenGraph CPU/reference framework and graph structures |
| `01_capi_precis` | Pinned CAPI-Precis AFU-control dependency |
| `02_capi_graph` | AccelGraph host entry point, CAPI algorithms, tests, MMIO runtime |
| `03_capi_integration` | Graph compute-unit RTL, simulator design, synthesis, images |
| `04_test_graphs` | Small and suite-specific benchmark inputs |
| `05_scripts` | CU selection and version helpers |
| `06_slides` | Original papers, diagrams, and current brand assets |

## Execution stages

1. Parse graph, algorithm, direction, threading, reorder, cache, and CAPI
   options.
2. Load or convert the edge list and construct the selected graph structure.
3. Run preprocessing and optional relabeling.
4. Select the OpenMP or CAPI implementation.
5. For CAPI, map graph arrays into the WED and launch one or more CU rounds.
6. Record timing and algorithm statistics.
7. Compare results through the existing reference or report path.

## CAPI coverage

The repository contains CAPI paths for BFS, PageRank, SPMV, connected
components, and triangle counting. Some source files also contain incomplete or
research-stage paths; the README task matrix remains authoritative for support
status. CU selection is determined by data structure, algorithm, direction, and
precision in `05_scripts/choose_algorithm_*.py`.

## Evidence for a benchmark result

A reportable CAPI result needs all of the following:

- exact graph file and format;
- algorithm, direction, precision, reorder, cache, thread, and CU settings;
- host, submodule, and FPGA image revisions;
- bounded accelerator completion with no error register;
- completion reset before any next round;
- result match or algorithm-specific correctness evidence;
- elapsed time and trial count.

See [accelerator verification](https://github.com/atmughrabi/AccelGraph/wiki/Accelerator-Verification)
for liveness and the
[deployment runbook](https://github.com/atmughrabi/AccelGraph/wiki/Deployment-Runbook)
for operational evidence.
