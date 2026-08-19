# Architecture

<p align="center">
  <img src="https://raw.githubusercontent.com/atmughrabi/AccelGraph/master/docs/fig/accelgraph-architecture.png" width="960" alt="AccelGraph accelerator architecture">
</p>

AccelGraph combines the CAPI-Precis AFU-control layer with graph-specific CU
clusters. The host maps graph arrays through the WED, AFU control owns the PSL
protocol, and graph CUs implement vertex-job, edge-job, edge-data, and
algorithm-specific processing.

The shared PSL, MMIO, buffering, credit, tag, response, error, done, and reset
blocks are defined by
[CAPI-Precis architecture](https://github.com/atmughrabi/CAPI-Precis/wiki/Architecture).
This page documents only the graph extension.

## Repository boundaries

| Path | Responsibility |
| --- | --- |
| `00_open_graph` | Pinned CPU/reference graph framework and data structures |
| `01_capi_precis` | Pinned AFU-control, PSLSE, and libcxl integration |
| `02_capi_graph` | Host benchmark, CAPI algorithms, verification, and tests |
| `03_capi_integration/accelerator_rtl/cu_control` | Graph CU clusters and algorithm engines |
| `03_capi_integration/accelerator_rtl/verification` | Graph-specific bind, WED target regressions, and real-bind lint |
| `03_capi_integration/accelerator_sim` | ModelSim graph-CU selection and PSLSE simulation |
| `03_capi_integration/accelerator_synth` | Quartus generation and implementation |

## Data and control path

1. The host loads and preprocesses the graph into the selected structure.
2. The graph WED exposes vertex, edge, inverse-graph, and auxiliary arrays.
3. AFU control manages commands, tags, credits, responses, data, errors, MMIO,
   completion, and reset.
4. CU-cluster arbitration distributes vertex jobs across graph CUs.
5. Graph engines issue edge-job and edge-data requests and write algorithm
   results.
6. Completion counters return through AFU control and are acknowledged by the
   host before the next graph round.

The host and RTL evidence layers are described in
[Accelerator verification](https://github.com/atmughrabi/AccelGraph/wiki/Accelerator-Verification).

## Graph diagram blocks

| Block | Responsibility | Primary RTL |
| --- | --- | --- |
| OpenGraph host/reference | Loads, reorders, and checks graph results on the CPU | `00_open_graph`, `02_capi_graph` |
| Graph WED | Publishes vertex/edge arrays, inverse arrays, weights, and auxiliary algorithm buffers | `*/global_pkg/wed_pkg.sv` |
| CU cluster control | Splits the accelerator into graph-CU and vertex-CU groups | `*/global_cu/cu_control.sv` |
| Vertex job control | Streams vertex work and filters active vertices | `cu_vertex_job_control.sv`, `cu_vertex_job_filter.sv` |
| Graph algorithm arbiter | Distributes vertex work across algorithm CUs and combines completion | `cu_graph_algorithm_arbiter_control.sv` |
| Vertex CU | Executes BFS, PageRank, SPMV, connected-components, or triangle-count kernels | `cu_vertex_*.sv` and algorithm `cu/*.sv` |
| Edge job control | Converts vertex work into edge ranges and read commands | `cu_edge_job_control.sv` |
| Edge data read/extract | Fetches edge/property cache lines and extracts individual values | `cu_edge_data_read_command_control.sv`, `cu_edge_data_read_extract_control.sv` |
| Edge data write | Writes updated vertex/property data through AFU control | `cu_edge_data_write_command_control.sv` |
| Reduction/demux | Combines per-CU counters and routes tagged data | `sum_reduce.sv`, `demux_bus.sv`, `array_struct_type_demux_bus.sv` |
