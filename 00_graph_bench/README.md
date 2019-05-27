
# Installation [<img src="../02_slides/fig/logo1.png" width="100" align="right" >](#installation-)

## Setting up the source code 

1. Clone Accel-Graph.

  ```
  git clone https://github.com/atmughrabi/AccelGraph.git
  ```

2. Setup the CAPI submodules.

  ```
  git submodule update --init --recursive
  ```

# Running Accel-Graph 

[<img src="../02_slides/fig/openmp_logo.png" height="45" align="right" >](https://www.openmp.org/)

## Initial compilation for the Graph framework with OpenMP 

1. From the root directory go to the graph benchmark directory:
  ```
  cd 00_Graph_Bench/
  ```
2. The default compilation is openmp:
  ```
  make 
  ```
3. From the root directory you can modify the Makefile with the [(parameters)](#accel-graph-options) you need for OpenMP:
  ```
  make run
  ```
  * OR
  ```
  make run-openmp
  ```
[<img src="../02_slides/fig/gem5-aladdin_logo.png" height="45" align="right" >](https://github.com/harvard-acc/gem5-aladdin)

## Initial compilation for the Graph framework with gem5-Aladdin 

* NOTE: You need gem5-aladdin environment setup on your machine.
* Please refer to [(gem5-Aladdin)](https://github.com/harvard-acc/gem5-aladdin), read the papers to understand the big picture `HINT: check their docker folder for an easy setup`.
* It is best to go through some of the integration-test examples that [(Aladdin)](https://github.com/ysshao/aladdin/) provides. So you can understand the process flow of how and why things are proceeding the way they are.

### Running Aladdin 

1. From the root directory go to the graph benchmark directory:
  ```
  cd 00_Graph_Bench/
  ```
2. This will compile Aladdin, then generate a dynamic trace if it doesn't exist and then run Aladdin:
  * The generated dynamic_trace resides in `./00_Graph_bench/aladdin_common/dynamic_traces` 
  * The dynamic trace is labeled with the following `(GRAPH_NAME)_(DATA_STRUCTURES)_(ALGORITHMS)_(PUSH_PULL)_dynamic_trace.gz`, this helps to distinguish between dynamic traces across different runs.
  ```
  make run-aladdin
  ```
3. To generate a dynamic trace without running Aladdin:
  ```
  make run-llvm-tracer # if it never been generated
  ```
  * OR
  ```
  make run-llvm-tracer-force # regenerated even if it exists
  ```

### Running gem5-Aladdin 

* NOTE: You need gem5-aladdin environment setup on your machine.
* AGAIN: Please refer to [(gem5-Aladdin)](https://github.com/harvard-acc/gem5-aladdin), read the papers to understand the big picture `HINT: check their docker folder for an easy setup`.
* gem5-Aladdin provides the possibility to evaluate the performance of shared memory accelerators.

1. From the root directory go to the graph benchmark directory:
  ```
  cd 00_Graph_Bench/
  ```
2. Their are three types of mode runs for gem5-aladding.
  * Running with `openmp` mode on gem5 with the fully parallelized version of the graph algorithm.
  ```
  make run-gem5-openmp
  ```
  * Running with `cpu` mode on gem5 with a single threaded kernel extracted from the graph algorithm (the compute intensive one), this is according to gem5-Aladdin integration-test examples.
  ```
  make run-gem5-cpu
  ```
  * Running with `accel` mode on gem5 with the accelerator active. The performance-power model is derived from the DDDG (Dynamic Data Dependence Graph).
  ```
  make run-gem5-accel
  ```
[<img src="../02_slides/fig/capi_logo.png" height="45" align="right" >](https://openpowerfoundation.org/capi-drives-business-performance/)

## Initial compilation for the Graph framework with CAPI  

* NOTE: You need CAPI environment setup on your machine.
* [CAPI Education Videos](https://developer.ibm.com/linuxonpower/capi/education/)
* We are not supporting CAPI SNAP since our graph processing suite heavily depends on accelerator-cache. SNAP does not support this feature yet. So if you are interested in streaming applications or do not benefit from caches SNAP is a candidate.
* For Deeper understanding of the SNAP framework: https://github.com/open-power/snap
* CAPI and SNAP on IBM developerworks: https://developer.ibm.com/linuxonpower/capi/  
* [IBM Developerworks Forum, tag CAPI_SNAP (to get support)](https://developer.ibm.com/answers/smartspace/capi-snap/index.html)


1. From the root directory go to the graph benchmark directory:
  ```
  cd 00_Graph_Bench/
  ```
2. Run [PSL Simulation Engine](https://github.com/ibm-capi/pslse) (PSLSE) for `simulation` this step is not needed when running on real hardware this just emulates the PSL that resides on your PowerPC machine (CAPI supported) :
  ```
  make run-pslse
  ```
3. Runs a graph algorithm that communicates with the pslse (simulation), or psl (real HW):
  ```
  make run-capi
  ```

## Graph structure (Edge list) 

* If you open the Makefile you will see the convention for graph directories : `BENCHMARKS_DIR/GRAPH_NAME/graph.wbin`.
* `.bin` stands to unweighted edge list, `.wbin` stands for wighted, `In binary format`. (This is only a convention you don't have to use it)
* The reason behind converting the edge-list from text to binary, it is simply takes less space on the drive for large graphs, and easier to use with the `mmap` function.

| Source  | Dest | Weight (Optional) |
| :---: | :---: | :---: |
| 30  | 3  |  1 |
| 3  | 4  |  1 |

* Example: 
* INPUT: (unweighted textual edge-list)
 ```
  ../BENCHMARKS_DIR/GRAPH_NAME/graph

  30    3
  3     4
  25    5
  25    7
  6     3
  4     2
  6     12
  6     8
  6     11
  8     22
  9     27

 ```
* convert to binary format and add random weights, for this example all the weights are `1`.
* `--graph-file-format` is the type of graph you are reading, `--convert-format` is the type of format you are converting to.
* `--stats` is a flag that enables conversion. It used also for collecting stats about the graph (but this feature is on hold for now).
 ```
  make convert
 ```
  * OR
 ```
./bin/accel-graph-openmp  --generate-weights --stats --graph-file-format=0 --convert-format=1 --graph-file=../BENCHMARKS_DIR/GRAPH_NAME/graph 
 ```

* OUTPUT: (weighted binary edge-list)
 ```
  ../BENCHMARKS_DIR/GRAPH_NAME/graph.wbin

1e00 0000 0300 0000 0100 0000 0300 0000
0400 0000 0100 0000 1900 0000 0500 0000
0100 0000 1900 0000 0700 0000 0100 0000
0600 0000 0300 0000 0100 0000 0400 0000
0200 0000 0100 0000 0600 0000 0c00 0000
0100 0000 0600 0000 0800 0000 0100 0000
0600 0000 0b00 0000 0100 0000 0800 0000
1600 0000 0100 0000 0900 0000 1b00 0000
0100 0000 
```

## Accel-Graph Options 

 ```
Usage: accel-graph [OPTION...]
            -f <graph file> -d [data structure] -a [algorithm] -r [root] -n
            [num threads] [-h -c -s -w]
AccelGraph is an open source graph processing framework, it is designed to be a
portable benchmarking suite for various graph processing algorithms.

  -a, --algorithm=[ALGORITHM #]   
                             [0]-BFS, [1]-Page-rank, [2]-SSSP-DeltaStepping,
                             [3]-SSSP-BellmanFord, [4]-DFS
                             [5]-IncrementalAggregation

  -b, --delta=[DELTA:1]      
                             SSSP Delta value [Default:1]

  -c, --convert-format=[TEXT|BIN|CSR:1]
                             [stats flag must be on --stats to write]Serialize
                             graph text format (edge list format) to binary
                             graph file on load example:-f <graph file> -c this
                             is specifically useful if you have Graph CSR/Grid
                             structure and want to save in a binary file format
                             to skip the preprocessing step for future runs.
                             [0]-text edgeList [1]-binary edgeList [2]-graphCSR
                             binary

  -d, --data-structure=[TYPE #]   
                             [0]-CSR, [1]-Grid, [2]-Adj LinkedList, [3]-Adj
                             ArrayList [4-5] same order bitmap frontiers

  -e, --tolerance=[EPSILON:0.0001], --epsilon=[EPSILON:0.0001]
                             Tolerance value of for page rank [default:0.0001]

  -f, --graph-file=<FILE>    
                             Edge list represents the graph binary format to
                             run the algorithm textual format change
                             graph-file-format

  -i, --num-iterations=[# ITERATIONS]
                             Number of iterations for page rank to converge
                             [default:20] SSSP-BellmanFord [default:V-1] 

  -l, --light-reorder=[ORDER:0]   
                             Relabels the graph for better cache performance.
                             [default:0]-no-reordering [1]-page-rank-order
                             [2]-in-degree [3]-out-degree [4]-in/out degree
                             [5]-Rabbit [6]-Epoch-pageRank [7]-Epoch-BFS
                             [8]-LoadFromFile 

  -n, --num-threads=[# THREADS]   
                             Default:max number of threads the system has

  -o, --sort=[RADIX|COUNT]   
                             [0]-radix-src [1]-radix-src-dest [2]-count-src
                             [3]-count-src-dst

  -p, --direction=[PUSH|PULL]   
                             [0-1]-push/pull [2-3]-push/pull fixed point
                             arithmetic [4-6]-same order but using data driven

  -r, --root=[SOURCE|ROOT]   
                             BFS, DFS, SSSP root

  -s, --symmetries           
                             Symmetric graph, create a set of incoming edges

  -t, --num-trials=[# TRIALS]   
                             Number of random trials for each whole run (graph
                             algorithm run) [default:0] 

  -w, --generate-weights     
                             Generate random weights don't load from graph
                             file. Check ->graphConfig.h #define WEIGHTED 1
                             beforehand then recompile using this option

  -x, --stats                
                             Dump a histogram to file based on in-out degree
                             count bins / sorted according to in/out-degree or
                             page-ranks 

  -z, --graph-file-format=[TEXT|BIN|CSR:1]
                             Specify file format to be read, is it textual edge
                             list, or a binary file edge list. This is
                             specifically useful if you have Graph CSR/Grid
                             structure already saved in a binary file format to
                             skip the preprocessing step. [0]-text edgeList
                             [1]-binary edgeList [2]-graphCSR binary

  -?, --help                 Give this help list
      --usage                Give a short usage message
  -V, --version              Print program version

 ```
`Report bugs to <atmughra@ncsu.edu>.`

## Organization Detailed:

```bash
 .
.
├── aladdin_common
│   ├── algorithms_configs
│   │   ├── 0
│   │   │   ├── 1
│   │   │   │   └── 0.cfg
│   ├── cacti_configs
│   │   ├── cacti_cache.cfg
│   │   ├── cacti_lq.cfg
│   │   ├── cacti_sq.cfg
│   │   └── cacti_tlb.cfg
│   ├── dynamic_traces
│   │   └── test_0_1_0_dynamic_trace.gz
│   ├── gem5_configs
│   │   ├── gem5.cfg
│   │   └── run.sh
│   ├── stats_aladdin
│   └── stats_gem5
│       ├── accel
│       │   ├── algorithm.cfg -> ../../algorithms_configs/0/1/0.cfg
│       │   ├── cacti_cache.cfg -> ../../cacti_configs/cacti_cache.cfg
│       │   ├── cacti_lq.cfg -> ../../cacti_configs/cacti_lq.cfg
│       │   ├── cacti_sq.cfg -> ../../cacti_configs/cacti_sq.cfg
│       │   ├── cacti_tlb.cfg -> ../../cacti_configs/cacti_tlb.cfg
│       │   ├── dddg_parse_progress.out
│       │   ├── dynamic_trace.gz -> ../../dynamic_traces/test_0_1_0_dynamic_trace.gz
│       │   ├── out.csv
│       │   ├── outputs
│       │   │   ├── algorithm_cache_stats.txt
│       │   │   ├── algorithm_spad_stats.txt
│       │   │   ├── algorithm_summary
│       │   │   ├── config.ini
│       │   │   ├── config.json
│       │   │   ├── stats.db
│       │   │   └── stats.txt
│       │   └── stdout.gz
│       ├── cpu
│       │   ├── algorithm.cfg -> ../../algorithms_configs/0/1/0.cfg
│       │   ├── cacti_cache.cfg -> ../../cacti_configs/cacti_cache.cfg
│       │   ├── cacti_lq.cfg -> ../../cacti_configs/cacti_lq.cfg
│       │   ├── cacti_sq.cfg -> ../../cacti_configs/cacti_sq.cfg
│       │   ├── cacti_tlb.cfg -> ../../cacti_configs/cacti_tlb.cfg
│       │   ├── dynamic_trace.gz -> ../../dynamic_traces/test_0_1_0_dynamic_trace.gz
│       │   ├── outputs
│       │   │   ├── config.ini
│       │   │   ├── config.json
│       │   │   ├── stats.db
│       │   │   └── stats.txt
│       │   └── stdout.gz
│       └── openmp
├── bin
│   ├── accel-graph-gem5aladdin-gem5-accel
│   ├── accel-graph-gem5aladdin-gem5-cpu
│   └── accel-graph-gem5aladdin-instrumented
├── cmake
│   ├── Findcxl.cmake
│   └── Findsnap.cmake
├── CMakeLists.txt
├── include
│   ├── graphalgorithms
│   │   ├── capi
│   │   │   ├── bellmanFord.h
│   │   │   ├── BFS.h
│   │   │   ├── DFS.h
│   │   │   ├── incrementalAggregation.h
│   │   │   ├── pageRank.h
│   │   │   └── SSSP.h
│   │   ├── gem5aladdin
│   │   │   ├── bellmanFord.h
│   │   │   ├── BFS.h
│   │   │   ├── DFS.h
│   │   │   ├── incrementalAggregation.h
│   │   │   ├── pageRank.h
│   │   │   └── SSSP.h
│   │   └── openmp
│   │       ├── bellmanFord.h
│   │       ├── BFS.h
│   │       ├── DFS.h
│   │       ├── incrementalAggregation.h
│   │       ├── pageRank.h
│   │       └── SSSP.h
│   ├── preprocessing
│   │   ├── countsort.h
│   │   ├── epochReorder.h
│   │   ├── radixsort.h
│   │   ├── reorder.h
│   │   └── sortRun.h
│   ├── structures
│   │   ├── adjArrayList.h
│   │   ├── adjLinkedList.h
│   │   ├── adjMatrix.h
│   │   ├── arrayQueue.h
│   │   ├── arrayStack.h
│   │   ├── bitmap.h
│   │   ├── capienv.h
│   │   ├── dynamicQueue.h
│   │   ├── edgeList.h
│   │   ├── graphAdjArrayList.h
│   │   ├── graphAdjLinkedList.h
│   │   ├── graphCSR.h
│   │   ├── graphGrid.h
│   │   ├── grid.h
│   │   └── vertex.h
│   └── utils
│       ├── bloomFilter.h
│       ├── bloomMultiHash.h
│       ├── bloomStream.h
│       ├── boolean.h
│       ├── cache.h
│       ├── fixedPoint.h
│       ├── graphConfig.h
│       ├── graphRun.h
│       ├── graphStats.h
│       ├── hash.h
│       ├── mt19937.h
│       ├── myMalloc.h
│       ├── quantization.h
│       └── timer.h
├── labelmap
├── Makefile
├── obj
├── README.md
└── src
    ├── CMakeLists.txt
    ├── graphalgorithms
    │   ├── capi
    │   │   ├── bellmanFord.c
    │   │   ├── BFS.c
    │   │   ├── CMakeLists.txt
    │   │   ├── DFS.c
    │   │   ├── incrementalAggregation.c
    │   │   ├── pageRank.c
    │   │   └── SSSP.c
    │   ├── CMakeLists.txt
    │   ├── gem5aladdin
    │   │   ├── bellmanFord.c
    │   │   ├── BFS.c
    │   │   ├── CMakeLists.txt
    │   │   ├── DFS.c
    │   │   ├── incrementalAggregation.c
    │   │   ├── pageRank.c
    │   │   └── SSSP.c
    │   └── openmp
    │       ├── bellmanFord.c
    │       ├── BFS.c
    │       ├── CMakeLists.txt
    │       ├── DFS.c
    │       ├── incrementalAggregation.c
    │       ├── pageRank.c
    │       └── SSSP.c
    ├── main
    │   ├── accel-graph.c
    │   └── CMakeLists.txt
    ├── preprocessing
    │   ├── CMakeLists.txt
    │   ├── countsort.c
    │   ├── epochReorder.c
    │   ├── radixsort.c
    │   ├── reorder.c
    │   └── sortRun.c
    ├── structures
    │   ├── adjArrayList.c
    │   ├── adjLinkedList.c
    │   ├── adjMatrix.c
    │   ├── arrayQueue.c
    │   ├── arrayStack.c
    │   ├── bitmap.c
    │   ├── CMakeLists.txt
    │   ├── dynamicQueue.c
    │   ├── edgeList.c
    │   ├── graphAdjArrayList.c
    │   ├── graphAdjLinkedList.c
    │   ├── graphCSR.c
    │   ├── graphGrid.c
    │   ├── grid.c
    │   └── vertex.c
    ├── tests
    │   ├── CMakeLists.txt
    │   ├── test_afu.c
    │   ├── test_bloomfilter.c
    │   ├── test_bloomStream.c
    │   ├── test_fixedpoint.c
    │   ├── test_graphAdjArray.c
    │   ├── test_graphAdjLinkedList.c
    │   ├── test_graphCSR.c
    │   ├── test_graphGrid.c
    │   ├── test_grid.c
    │   └── test_quantization.c
    └── utils
        ├── bloomFilter.c
        ├── bloomMultiHash.c
        ├── bloomStream.c
        ├── cache.c
        ├── CMakeLists.txt
        ├── graphRun.c
        ├── graphStats.c
        ├── hash.c
        ├── mt19937.c
        ├── myMalloc.c
        ├── quantization.c
        └── timer.c



```

## Tasks TODO:

- [x] Finish preprocessing sort
  - [x] Radix sort
  - [x] Count sort 
- [x] Finish preprocessing Graph-Datastructures
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
  - [x] SSSP  (Dijkstra)
  - [ ] CC    (Connected Components)
  - [ ] BC    (Betweenness Centrality)
  - [ ] TC    (Triangle Counting)
  - [ ] SPMV  (Sparse Matrix-vector Multiplication)
- [x] Finish integration with gem5-Aladdin
- [ ] Finish graph algorithms suite gem5-Aladdin
  - [ ] BFS   (Breadth First Search)
  - [ ] PR    (Page-Rank)
  - [ ] DFS   (Depth First Search)
  - [ ] IA    (Incremental Aggregation)
  - [ ] SSSP  (BellmanFord)
  - [ ] SSSP  (Dijkstra)
  - [ ] CC    (Connected Components)
  - [ ] BC    (Betweenness Centrality)
  - [ ] TC    (Triangle Counting)
  - [ ] SPMV  (Sparse Matrix-vector Multiplication)
- [x] Finish integration with CAPI
- [ ] Finish graph algorithms suite CAPI
  - [ ] BFS   (Breadth First Search)
  - [ ] PR    (Page-Rank)
  - [ ] DFS   (Depth First Search)
  - [ ] IA    (Incremental Aggregation)
  - [ ] SSSP  (BellmanFord)
  - [ ] SSSP  (Dijkstra)
  - [ ] CC    (Connected Components)
  - [ ] BC    (Betweenness Centrality)
  - [ ] TC    (Triangle Counting)
  - [ ] SPMV  (Sparse Matrix-vector Multiplication)
- [ ] Research Ideas
  - [ ] Graph algorithms performance exploration with gem5-Aladdin
  - [ ] Page-Rank quantization
  - [ ] FPGA Frontier prefetcher
- [ ] Support unit testing

[<p align="right"> <img src="../02_slides/fig/logo1.png" width="100" ></p>](#installation-)