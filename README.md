[![Build Status](https://travis-ci.com/atmughrabi/AccelGraph.svg?token=L3reAtGHdEVVPvzcVqQ6&branch=master)](https://travis-ci.com/atmughrabi/AccelGraph)
[<p align="center"><img src="./02_slides/fig/logo3.png" width="650" ></p>](#accel-graph-benchmark-suite)

# AccelGraph-CAPI Benchmark Suite

## Graph Processing Framework that supports | OpenMP || CAPI

## Overview

![End-to-End Acceleration](./02_slides/fig/theme.png "AccelGraph-CAPI")

AccelGraph-CAPI is an open source graph processing framework. It is designed as a modular benchmarking suite for graph processing algorithms. It provides an end to end evaluation infrastructure which includes the preprocessing stage of forming the graph structure and the graph algorithm. The OpenMP part of AccelGraph-CAPI has been developed on Ubuntu 18.04, with PowerPC/Intel architecture taken into account.
AccelGraph-CAPI is coded using C giving the researcher full flexibility with modifying data structures and other algorithmic optimizations. Furthermore, this benchmarking suite has been fully integrated with IBM Coherent Accelerator Processor Interface (CAPI), demonstrating the contrast in performance between Shared Memory Accelerators and Parallel Processors.

# Installation

## Dependencies

### OpenMP
1. Judy Arrays
```console
AccelGraph@CAPI:~$ sudo apt-get install libjudy-dev
```
2. OpenMP is already a feature of the compiler, so this step is not necessary.
```console
AccelGraph@CAPI:~$ sudo apt-get install libomp-dev
```

### CAPI
1. Simulation and Synthesis
  * This framework was developed on Ubuntu 18.04 LTS.
  * ModelSim is used for simulation and installed along side Quartus II 18.1.
  * Synthesis requires ALTERA Quartus, starting from release 15.0 of Quartus II should be fine.
  * Nallatech P385-A7 card with the Altera Stratix-V-GX-A7 FPGA is supported.
  * Environment Variable setup, `HOME` and `ALTERAPATH` depend on where you clone the repository and install ModelSim.

```bash
#quartus 18.1 env-variables
export ALTERAPATH="${HOME}/intelFPGA/18.1"
export QUARTUS_INSTALL_DIR="${ALTERAPATH}/quartus"
export LM_LICENSE_FILE="${ALTERAPATH}/licenses/psl_A000_license.dat:${ALTERAPATH}/licenses/common_license.dat"
export QSYS_ROOTDIR="${ALTERAPATH}/quartus/sopc_builder/bin"
export PATH=$PATH:${ALTERAPATH}/quartus/bin
export PATH=$PATH:${ALTERAPATH}/nios2eds/bin

#modelsim env-variables
export PATH=$PATH:${ALTERAPATH}/modelsim_ase/bin

#AccelGraph_CAPI project folder
export CAPI_PROJECT=00_AccelGraph_CAPI

#CAPI framework env variables
export PSLSE_INSTALL_DIR="${HOME}/Documents/github_repos/${CAPI_PROJECT}/01_capi_integration/pslse"
export VPI_USER_H_DIR="${ALTERAPATH}/modelsim_ase/include"
export PSLVER=8
export BIT32=n
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PSLSE_INSTALL_DIR/libcxl:$PSLSE_INSTALL_DIR/afu_driver/src"

#PSLSE env variables
export PSLSE_SERVER_DIR="${HOME}/Documents/github_repos/${CAPI_PROJECT}/01_capi_integration/accelerator_sim/server"
export PSLSE_SERVER_DAT="${PSLSE_SERVER_DIR}/pslse_server.dat"
export SHIM_HOST_DAT="${PSLSE_SERVER_DIR}/shim_host.dat"
export PSLSE_PARMS="${PSLSE_SERVER_DIR}/pslse.parms"
export DEBUG_LOG_PATH="${PSLSE_SERVER_DIR}/debug.log"

```

2. AFU Communication with PSL
  * please check [(OpenGraph)](https://github.com/atmughrabi/OpenGraph).
  * please check [(CAPIPrecis)](https://github.com/atmughrabi/CAPIPrecis).
  * please check [(CAPI User's Manual)](http://www.nallatech.com/wp-content/uploads/IBM_CAPI_Users_Guide_1-2.pdf).

## Setting up the source code

1. Clone AccelGraph-CAPI.
```console
AccelGraph@CAPI:~$ git clone https://github.com/atmughrabi/AccelGraph_CAPI.git
```
2. From the home directory go to the AccelGraph_CAPI directory:
```console
AccelGraph@CAPI:~$ cd AccelGraph_CAPI/
```
3. Setup the CAPI submodules.
```console
AccelGraph@CAPI:~AccelGraph_CAPI$ git submodule update --init --recursive
```

# Running AccelGraph-CAPI

[<img src="./02_slides/fig/openmp_logo.png" height="45" align="right" >](https://www.openmp.org/)

## Initial compilation for the Graph framework with OpenMP

1. (Optional) From the root directory go to the graph benchmark directory:
```console
AccelGraph@CAPI:~AccelGraph_CAPI$ cd 00_graph_bench/
```
2. The default compilation is `openmp` mode:
```console
AccelGraph@CAPI:~AccelGraph_CAPI/00_graph_bench$ make
```
3. From the root directory you can modify the Makefile with the [(parameters)](#accel-graph-options) you need for OpenMP:
```console
AccelGraph@CAPI:~AccelGraph_CAPI/00_graph_bench$ make run
```
* OR
```console
AccelGraph@CAPI:~AccelGraph_CAPI/00_graph_bench$ make run-openmp
```

[<img src="./02_slides/fig/capi_logo.png" height="45" align="right" >](https://openpowerfoundation.org/capi-drives-business-performance/)

## Initial compilation for the Graph framework with Coherent Accelerator Processor Interface (CAPI)

* NOTE: You need CAPI environment setup on your machine (tested on Power8 8247-22L).
* [CAPI Education Videos](https://developer.ibm.com/linuxonpower/capi/education/)
* We are not supporting CAPI-SNAP since our processing suite supports accelerator-cache. SNAP does not support this feature yet. So if you are interested in streaming applications or do not benefit from caches SNAP is also good candidate.
* To check the SNAP framework: https://github.com/open-power/snap.

### Simulation

* NOTE: You need three open terminals, for running vsim, pslse, and the application.

1. (Optional) From the root directory go to benchmark directory:
```console
AccelGraph@CAPI:~AccelGraph_CAPI$ cd 00_graph_bench/
```
2. On terminal 1. Run [ModelSim vsim] for `simulation` this step is not needed when running on real hardware, this just simulates the AFU that resides on your (CAPI supported) FPGA  :
```console
AccelGraph@CAPI:~AccelGraph_CAPI/00_graph_bench$ make run-vsim
```
3. The previous step will execute vsim.tcl script to compile the design, to start the running the simulation just execute the following command at the transcript terminal of ModelSim : `r #recompile design`,`c #run simulation`
```console
ModelSim> r
ModelSim> c
```
4. On Terminal 2. Run [PSL Simulation Engine](https://github.com/ibm-capi/pslse) (PSLSE) for `simulation` this step is not needed when running on real hardware, this just emulates the PSL that resides on your (CAPI supported) IBM-PowerPC machine  :
```console
AccelGraph@CAPI:~AccelGraph_CAPI/00_graph_bench$ make run-pslse
```

##### Option 1: Silent run with no stats output

5. On Terminal 3. Run the algorithm that communicates with the PSLSE (simulation):
```console
AccelGraph@CAPI:~AccelGraph_CAPI/00_graph_bench$ make run-capi-sim
```

##### Option 2: Verbose run with stats output

5.  On Terminal 3. Run the algorithm that communicates with the PSLSE (simulation) printing out stats based on the responses received to the AFU-Control layer:
```console
AccelGraph@CAPI:~AccelGraph_CAPI/00_graph_bench$ make run-capi-sim-verbose
```
6. Example output: please check [(CAPI User's Manual)](http://www.nallatech.com/wp-content/uploads/IBM_CAPI_Users_Guide_1-2.pdf), for each response explanation. The stats are labeled `RESPONSE_COMMANADTYPE_count`.
```
*-----------------------------------------------------*
|                 AFU Stats                          |
 -----------------------------------------------------
| CYCLE_count        : #Cycles                       |
*-----------------------------------------------------*
|                 Responses Stats                    |
 -----------------------------------------------------
| DONE_count               : (#) Commands successful |
 -----------------------------------------------------
| DONE_READ_count          : (#) Reads successful    |
| DONE_WRITE_count         : (#) Writes successful   |
 -----------------------------------------------------
| DONE_RESTART_count       : (#) Bus Restart         |
 -----------------------------------------------------
| DONE_PREFETCH_READ_count : (#) Read Prefetches     |
| DONE_PREFETCH_WRITE_count: (#) Write Prefetches    |
 -----------------------------------------------------
| PAGED_count        : 0                             |
| FLUSHED_count      : 0                             |
| AERROR_count       : 0                             |
| DERROR_count       : 0                             |
| FAILED_count       : 0                             |
| NRES_count         : 0                             |
| NLOCK_count        : 0                             |
*-----------------------------------------------------*

```

### FPGA

#### Synthesize

These steps require ALTERA Quartus synthesis tool, starting from release 15.0 of Quartus II should be fine.

##### Using terminal
1. From the root directory (using terminal)
```console
AccelGraph@CAPI:~AccelGraph_CAPI$ make run-capi-synth
```
2. Check AccelGraph_CAPI.sta.rpt for timing requirements violations

##### Using Quartus GUI
1. From the root directory (using terminal)
```console
AccelGraph@CAPI:~AccelGraph_CAPI$ make run-capi-gui
```
2. Synthesize using Quartus GUI

##### Another way (using terminal)
1. From the root directory go to CAPI integration directory -> AccelGraph_CAPI synthesis folder
```console
AccelGraph@CAPI:~AccelGraph_CAPI$ cd 01_capi_integration/accelerator_synth/
```
2. invoke synthesis from terminal
```console
AccelGraph@CAPI:~AccelGraph_CAPI/01_capi_integration/accelerator_synth$ make
```

##### Another way (using Quartus GUI)
1. From the root directory go to CAPI integration directory -> AccelGraph_CAPI synthesis folder
```console
AccelGraph@CAPI:~AccelGraph_CAPI$ cd 01_capi_integration/accelerator_synth/
```
2. invoke synthesis from terminal
```console
AccelGraph@CAPI:~AccelGraph_CAPI/01_capi_integration/accelerator_synth$ make gui
```

#### Flashing image

1. From the root directory go to CAPI integration directory -> AccelGraph_CAPI binary images:
```console
AccelGraph@CAPI:~AccelGraph_CAPI$ cd 01_capi_integration/accelerator_bin/
```
2. Flash the image to the corresponding `#define DEVICE` you can modify it according to your Power8 system from `00_bench/include/capi_utils/capienv.h`
```console
AccelGraph@CAPI:~AccelGraph_CAPI/01_capi_integration/accelerator_bin$ sudo capi-flash-script accel-graph_GITCOMMIT#_DATETIME.rbf
```

#### Running

1. (Optional) From the root directory go to benchmark directory:
```console
AccelGraph@CAPI:~AccelGraph_CAPI$ cd 00_bench/
```

##### Silent run with no stats output

2. Runs algorithm that communicates with the or PSL (real HW):
```console
AccelGraph@CAPI:~AccelGraph_CAPI/00_bench$ make run-capi-fpga
```

##### Verbose run with stats output

This run outputs different AFU-Control stats based on the responses received from the PSL

2. Runs algorithm that communicates with the or PSL (real HW):
```console
AccelGraph@CAPI:~AccelGraph_CAPI/00_bench$ make run-capi-fpga-verbose
```


# Graph Structure Preprocessing:
AccelGraph-CAPI can handle multiple representations of the graph structure in memory, each has their own theoretical benefits and shortcomings.


# Organization

* `00_graph_bench`
  * `include` - Major function headers
    * `algorithms` - supported Graph algorithms
      * `capi`  - capi integration
        * `BFS.h`   - Breadth First Search
        * `DFS.h`   - Depth First Search
        * `SSSP.h`  - Single Source Shortest Path
        * `bellmanFord.h` - Single Source Shortest Path using Bellman Ford
        * `incrementalAgreggation.h` - Incremental Aggregation for clustering
        * `pageRank.h` - Page Rank Algorithm
        * `SPMV.h` - Sparse Matrix Vector Multiplication
  * `src` - Major function Source files
    * `algorithms` - supported Graph algorithms
      * `capi`  - CAPI integration
        * `BFS.c`   - Breadth First Search
        * `DFS.c`   - Depth First Search
        * `SSSP.c`  - Single Source Shortest Path
        * `bellmanFord.c` - Single Source Shortest Path using Bellman Ford
        * `incrementalAgreggation.c` - Incremental Aggregation for clustering
        * `pageRank.c` - Page Rank Algorithm
        * `SPMV.c` - Sparse Matrix Vector Multiplication

* *`Makefile`* - Global makefile

# Tasks TODO:

- [x] Finish preprocessing sort
  - [x] Radix sort
  - [x] Count sort
  - [ ] Bitonic sort
- [x] Finish preprocessing Graph Data-structures
  - [x] CSR   (Compressed Sparse Row)
  - [x] Grid
  - [x] Adjacency Linked List
  - [x] Adjacency Array List
- [x] Add Light weight reordering
- [ ] Finish graph algorithms suite OpenMP
  - [x] BFS   (Breadth First Search)
  - [x] PR    (Page-Rank)
  - [x] DFS   (Depth First Search)
  - [x] IA    (Incremental Aggregation)
  - [x] SSSP  (BellmanFord)
  - [x] SSSP  (Delta Stepping)
  - [x] SPMV  (Sparse Matrix Vector Multiplication)
  - [x] CC    (Connected Components)
  - [x] TC    (Triangle Counting)
  - [ ] BC    (Betweenness Centrality)
- [x] Finish integration with CAPI Simulation
- [x] Finish integration with CAPI Cache
- [x] Finish Synthesis with CAPI (Meets time requirements)
- [ ] Finish graph algorithms suite CAPI
  - [x] BFS   (Breadth First Search)
  - [x] PR    (Page-Rank)
  - [-] DFS   (Depth First Search) (work in progress)
  - [|] IA    (Incremental Aggregation) (Needs Atomic Operation -> CAPI v2.0)
  - [|] SSSP  (BellmanFord) (Needs Atomic Operation -> CAPI v2.0)
  - [|] SSSP  (Dijkstra) (Needs Atomic Operation -> CAPI v2.0)
  - [x] CC    (Connected Components)
  - [-] TC    (Triangle Counting) (work in progress)
  - [x] SPMV  (Sparse Matrix-vector Multiplication)
  - [-] BC    (Betweenness Centrality) (work in progress)
- [x] Support testing

Report bugs to <atmughra@ncsu.edu>
[<p align="right"> <img src="./02_slides/fig/logo1.png" width="200" ></p>](#accel-graph-benchmark-suite)