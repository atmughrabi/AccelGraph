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

The active layout manifest is authoritative:

| Algorithm | Active layout |
| --- | --- |
| BFS | CSR PULL BottomUp |
| PageRank | CSR PULL FloatPoint, FixedPoint, Quantized |
| SPMV | CSR PULL FloatPoint, FixedPoint |
| Connected components | CSR ShiloachVishkin |
| Triangle counting | CSR BinaryIntersection |

PageRank PUSH FloatPoint, FixedPoint, and Quantized remain exact expected
failures until their missing RTL source sets are restored. Other
research-stage source paths are not active accelerator support. CU selection
is determined by data structure, algorithm, direction, and precision in
`05_scripts/choose_algorithm_*.py`.

Current portable real-top evidence limits PageRank PULL, SPMV PULL, and
TriangleCount to `-K1`. ConnectedComponents passes its full topology; the
multi-CU ring blocker for the other layouts is recorded in
[Verification infrastructure](https://github.com/atmughrabi/AccelGraph/wiki/Verification-Infrastructure).

## Common options

| Option | Purpose |
| --- | --- |
| `-f` | Input graph |
| `-z` | Input format: text edge list, binary edge list, or binary CSR |
| `-d` | Graph data structure |
| `-a` | Algorithm |
| `-p` | Pull, push, or hybrid direction |
| `-r` | Root vertex for traversal algorithms |
| `-i` | Iteration count |
| `-n`, `-N`, `-K` | Preprocessing, algorithm, and accelerator-kernel thread/CU counts |
| `-l`, `-L`, `-O` | First, second, and third reorder stages |
| `-C` | Cache-size model |
| `-M` | Cache-mask mode |
| `-t` | Trial count |
| `-e` | Numeric tolerance |
| `-b` | Delta for delta-stepping workloads |
| `-s` | Symmetrize the graph |
| `-w` | Load or generate weights |

Pass custom arguments through the existing Make targets, for example:

```console
make run-openmp ARGS='-f <graph> -z 1 -d 0 -a 0 -p 0 -r 0 -N 8 -t 1'
```

The selected binary's `--help` output is the exact parser reference.

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
