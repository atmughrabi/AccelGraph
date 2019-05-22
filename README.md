# AccelGraph
## Graph Processing Framework With OpenMP/CAPI-Verilog/Gem5-Aladdin

AFU framework for Graph Processing algorithms with OpenMP/Shared Memory Accelerator CAPI

## Overview

![End-to-End Acceleration](./02_slides/fig/fig-4.png "AccelGraph")

AccelGraph is an open source Graph processing framework, it is designed to be a portable benchmarking suite for various graph processing algorithms. Graph processing usually involves preprocessing step that builds the graph structure, and the graph algorithm. both steps can be evaluated using this framework. The OpenMP part of AccelGraph has been tested on Ubuntu 18.04 with PowerPC/Intel architecture taken into account. It is coded using C giving the researcher full flexibility with modifying data structures and other algorithmic optimizations. Furthermore this benchmarking tool has been fully integrated with IBM Coherent Accelerator Processor Interface (CAPI), demonstrating the contrast in performance between shared memory FPGAs with parallel processors.

## Organization

* `00_Graph_OpenMP`
  * `include` - System Verilog architectures
    * `graphalgorithms` - \Implemented Graph algorithm
      * `BFS.h` - Breadth First Search
      * `DFS.h` - Depth First Search
      * `SSSP.h` - Single Source Shortest Path
      * `bellmanFord.h` - Single Source Shortest Path using Bellman Ford
      * `incrementalAgreggation.h` - Incremental Aggregation for clustering
      * `pageRank.h` - Page Rank Algorithm
    * `preprocessing` - preprocessing graph structure [Presentation](./02_slides/preprocessing_Graphs_countsort.pdf)
      * `countsort.h` - sort edge list using count sort
      * `radixsort.h` - sort edge list using radix sort
      * `reorder.h` - cluster reorder the graph for better cache locality
      * `sortRun.h` - chose which sorting algorithm to use
    * `structures` - structures that hold the graph in memory [Presentation](./02_slides/Graph_DataStructures.pdf)
      * `graphAdjArrayList.h` - graph using adjacency list array with arrays
      * `graphAdjLinkeList.h` - graph using adjacency list array with linked lists
      * `graphCSR.h` - graph using compressed sparse matrix
      * `graphGrid.h` - graph using Grid

* *`Makefile`* - Global makefile

## Details

### Graph Algorithms Supported Implementations

### Initial compilation for the Graph frame work with OpenMP

1. From the root directory you can modify the Makefile with the parameters you need
  ```bash
  make 
  make run
  ```

2. Run the algorithm with the data structure and other settings you need
  ```
Usage: main_argp [OPTION...]
            -f <graph file> -d [data structure] -a [algorithm] -r [root] -n
            [num threads] [-h -c -s -w]
AccelGraph is an open source graph processing framework, it is designed to be a
portable benchmarking suite for various graph processing algorithms.

  -a, --algorithm=[ALGORITHM #]   [0]-BFS, [1]-Pagerank,
                             [2]-SSSP-DeltaStepping, [3]-SSSP-BellmanFord,
                             [4]-DFS [5]-IncrementalAggregation
  -b, --delta=[DELTA:1]       SSSP Delta value [Default:1]
  -c, --convert-bin          read graph text format convert to bin graph file
                             on load example:-f <graph file> -c
  -d, --data-structure=[TYPE #]   [0]-CSR, [1]-Grid, [2]-Adj LinkedList,
                             [3]-Adj ArrayList [4-5] same order bitmap
                             frontiers
  -e,                        --tolerance=[EPSILON:0.0001], --epsilon=[EPSILON:0.0001]
                             tolerance value of for page rank [default:0.0001]

  -f, --graph-file=<FILE>    edge list represents the graph binary format to
                             run the algorithm textual format with -convert
                             option
  -i, --num-iterations=[# ITERATIONS]
                             number of iterations for pagerank to converge
                             [default:20] SSSP-BellmanFord [default:V-1] 
  -l, --light-reorder=[ORDER:0]   Relabels the graph for better cache
                             performance. [default:0]-no-reordering
                             [1]-pagerank-order [2]-in-degree [3]-out-degree
                             [4]-in/out degree [5]-Rabbit [6]-Epoch-pageRank
                             [7]-Epoch-BFS [8]-LoadFromFile 
  -n, --num-threads=[# THREADS]   default:max number of threads the system has
  -o, --sort=[RADIX|COUNT]   [0]-radix-src [1]-radix-src-dest [2]-count-src
                             [3]-count-src-dst
  -p, --direction=[PUSH|PULL]   [0-1]-push/pull [2-3]-push/pull fixed point
                             arithmetic [4-6]-same order but using data driven
  -r, --root=[SOURCE|ROOT]   BFS, DFS, SSSP root
  -s, --symmetrise           Symmetric graph, create a set of incoming edges
  -t, --num-trials=[# TRIALS]   number of random trials for each whole run
                             (graph algorithm run) [default:0] 
  -w, --generate-weights     generate random weights don't load from graph
                             file. Check ->graphConfig.h #define WEIGHTED 1
                             beforehand then recompile using this option
  -x, --stats                dump a histogram to file based on in-out degree
                             count bins / sorted according to in/out-degree or
                             pageranks 
  -?, --help                 Give this help list
      --usage                Give a short usage message
  -V, --version              Print program version

Mandatory or optional arguments to long options are also mandatory or optional
for any corresponding short options.

Report bugs to <atmughra@ncsu.edu>.

```

### CAPI SNAP

* For Deeper understanding of the SNAP framework: https://github.com/open-power/snap
* CAPI and SNAP on IBM developerworks: https://developer.ibm.com/linuxonpower/capi/  
* [IBM Developerworks Forum, tag CAPI_SNAP (to get support)](https://developer.ibm.com/answers/smartspace/capi-snap/index.html)
* [Education Videos](https://developer.ibm.com/linuxonpower/capi/education/)
