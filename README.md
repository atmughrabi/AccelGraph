[![verification](https://github.com/atmughrabi/AccelGraph/actions/workflows/verification.yml/badge.svg)](https://github.com/atmughrabi/AccelGraph/actions/workflows/verification.yml)

<p align="center">
  <img src="./06_slides/fig/logo.svg" width="180" alt="AccelGraph logo">
</p>

# AccelGraph

AccelGraph is a graph-processing benchmark for OpenMP and CAPI. It combines
graph loading and preprocessing, CPU reference implementations, coherent FPGA
compute units, benchmark orchestration, and result reporting in one
reproducible flow.

<p align="center">
  <img src="./docs/fig/accelgraph-architecture.svg" width="960" alt="AccelGraph host and FPGA accelerator architecture">
</p>

## Scope

AccelGraph owns:

- graph loading, conversion, preprocessing, and OpenMP reference execution;
- graph WEDs, CSR and inverse-CSR arrays, and CAPI host launch code;
- vertex, edge-job, edge-data, writeback, cluster, and algorithm RTL;
- graph fixtures, independent algorithm goldens, scoreboards, backpressure,
  and coverage.

The pinned [`01_capi_precis`](https://github.com/atmughrabi/CAPI-Precis)
submodule owns the shared libcxl, PSL, AFU-control, and generic protocol
contract. AccelGraph extends that contract rather than copying it.

## Active accelerator layouts

Eight active layouts cover BFS, PageRank PULL, SPMV PULL, connected
components, and triangle counting. The
[Benchmark guide](https://github.com/atmughrabi/AccelGraph/wiki/Benchmark-Guide)
and `layouts.json` own the exact direction and precision table. Three PageRank
PUSH layouts remain exact expected failures until their missing RTL source
sets are restored; research-stage host sources are not equivalent to an active
accelerator layout.

At this checkpoint, PageRank PULL, SPMV PULL, and TriangleCount real-top
integration is limited to `-K1`; their multi-CU ring test remains open.
ConnectedComponents completes with its full topology. The exact limitation is
recorded in
[Verification infrastructure](https://github.com/atmughrabi/AccelGraph/wiki/Verification-Infrastructure).

## Quick start

```console
git clone https://github.com/atmughrabi/AccelGraph.git
cd AccelGraph
git submodule sync --recursive
git submodule update --init --recursive
sudo apt-get install build-essential libjudy-dev tcl verilator
make verify
```

Verilator 5 or newer is required for portable RTL verification. ModelSim and
Quartus are needed only for licensed simulation and implementation.

Run the default OpenMP benchmark:

```console
make
make run-openmp
```

Algorithm, graph, direction, precision, reorder, cache, and thread settings are
documented in the
[Benchmark guide](https://github.com/atmughrabi/AccelGraph/wiki/Benchmark-Guide).

## CAPI execution

The root `tools/capi-env` wrapper delegates to the pinned CAPI-Precis harness
while supplying AccelGraph's project and simulation roots. It does not modify
shell profiles.

```console
./tools/capi-env --mode host check
./tools/capi-env --mode sim --intel-fpga "$HOME/intelFPGA/18.1" check
./tools/capi-env --mode sim -- make run-vsim
./tools/capi-env --mode sim -- make run-pslse
./tools/capi-env --mode sim -- make run-capi-sim-verbose2
./tools/capi-env --mode fpga -- make run-capi-fpga-verbose2
```

Start with a small graph from `04_test_graphs/TEST`. The
[deployment runbook](https://github.com/atmughrabi/AccelGraph/wiki/Deployment-Runbook)
owns launch sequencing, timeout overrides, and hang evidence.

## Verification

| Command | Evidence |
| --- | --- |
| `make verify` | Host, benchmark, submodule, manifest, real-RTL, and graph-family gates |
| `make rtl-manifest-verification` | Exact CAPI pin, active/XFAIL layouts, source order, inventory, and ownership |
| `make rtl-real-elaboration` | Real graph `cu_control` elaboration across every active layout |
| `make rtl-unit-verification` | Canonical owners currently promoted into the coverage plan |
| `make rtl-unit-engines` | Resume the paused vertex/edge/cluster/scheduler suite |
| `make rtl-unit-algorithms` | Run kernel and shell goldens, mutations, and exact census |
| `make rtl-integration-graph` | Resume the paused eight-layout real-top suite |
| `make accelerator-verification` | Graph-aware host timeout, progress, completion, and reset behavior |

Liveness and algorithm correctness are separate requirements. Completion alone
does not establish a correct graph result.

## Repository layout

| Path | Responsibility |
| --- | --- |
| `00_open_graph` | Pinned OpenGraph CPU/reference framework |
| `01_capi_precis` | Pinned CAPI-Precis host/AFU protocol |
| `02_capi_graph` | Graph host runtime, algorithms, benchmark tests, and results |
| `03_capi_integration/accelerator_rtl` | Synthesizable graph RTL |
| `03_capi_integration/accelerator_verification` | Graph host, unit, integration, manifest, and simulation evidence |
| `04_test_graphs` | Versioned graph inputs and verification fixtures |
| `05_scripts` | Algorithm and layout selection helpers |
| `06_slides` | Historical presentations and brand assets |
| `docs` | Maintained documentation and wiki source |
| `tools` | Thin CAPI environment wrapper and tests |

Exact directory naming and compatibility rules are maintained in
[Repository structure](https://github.com/atmughrabi/AccelGraph/wiki/Repository-Structure).

## Documentation

| Topic | Canonical page |
| --- | --- |
| Host, CAPI, cluster, and graph-engine boundaries | [Architecture](https://github.com/atmughrabi/AccelGraph/wiki/Architecture) |
| Workloads, layouts, options, and report evidence | [Benchmark guide](https://github.com/atmughrabi/AccelGraph/wiki/Benchmark-Guide) |
| Graph-specific timeout and lifecycle checks | [Accelerator verification](https://github.com/atmughrabi/AccelGraph/wiki/Accelerator-Verification) |
| Launch and intermittent-hang triage | [Deployment runbook](https://github.com/atmughrabi/AccelGraph/wiki/Deployment-Runbook) |
| Module tests, goldens, backpressure, and coverage | [Verification infrastructure](https://github.com/atmughrabi/AccelGraph/wiki/Verification-Infrastructure) |
| Acceptance and rollout | [Stabilization plan](https://github.com/atmughrabi/AccelGraph/wiki/Stabilization-Plan) |

`docs/wiki` is the editable source of truth; the GitHub wiki is its published
mirror. Start at [`docs/README.md`](docs/README.md) when editing documentation.

## Platform

The retained hardware flow targets IBM Power8 CAPI with a Nallatech P385-A7
FPGA card, ModelSim, PSLSE, and Quartus II 18.1. Portable host and Verilator
verification do not require the licensed tools.

## Contact

Report defects to <atmughra@ncsu.edu>.
