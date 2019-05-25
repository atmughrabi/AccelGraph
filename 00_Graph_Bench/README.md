
# Accel-Graph Graph Benchmark Suite
<!-- ![Accel-Graph logo](./02_slides/fig/logo.png "Accel-Graph logo") -->
## Graph Processing Framework With | OpenMP || CAPI/SystemVerilog || gem5-Aladdin |

OpenMP/AFU framework for graph Processing algorithms with | OpenMP || CAPI-SystemVerilog || gem5-Aladdin |

## Installation ##

### Setting up the source code ###

1. Clone Accel-Graph.

  ```
  git clone https://github.com/atmughrabi/AccelGraph.git
  ```

2. Setup the CAPI submodules.

  ```
  git submodule update --init --recursive
  ```

## Running Accel-Graph ##

### Initial compilation for the Graph framework with OpenMP

1. From the root directory go to the graph benchmark directory:
  ```
  cd 00_Graph_Bench/
  ```
2. The default compilation is openmp:
  ```
  make 
  ```
3. From the root directory you can modify the Makefile with the parameters you need for OpenMP:
  ```
  make run
  ```
  OR
  ```
  make run-openmp
  ```

### Graph structure (Edge list)

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

* Example: convert to binary format convert and add random weights, for this one all the wights were 1.
* `--graph-file-format` is the type of graph you are reading, `--convert-format` is the type of format you are converting to.
* `--stats` is a flag that enables conversion. It used also for collecting stats about the graph (but this feature is on hold for now).
 ```
  make convert
 ```
* Or
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

### Accel-Graph Options

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
Report bugs to <atmughra@ncsu.edu>.

### Initial compilation for the Graph framework with gem5-aladdin

* NOTE: You need gem5-aladdin environment setup on your machine.
* Please refer to [(gem5-aladdin)](https://github.com/harvard-acc/gem5-aladdin)

1. From the root directory go to the graph benchmark directory:
  ```
  cd 00_Graph_Bench/
  ```
2. The default compilation is openmp change it from Makefile or:
  ```
  make INTEGRATION_DIR=gem5aladdin
  ```
3. From the root directory you can modify the Makefile with the parameters you need for OpenMP:
  ```
  make run INTEGRATION_DIR=gem5aladdin
  ```

### Initial compilation for the Graph framework with CAPI

* NOTE: You need CAPI environment setup on your machine.
* For Deeper understanding of the SNAP framework: https://github.com/open-power/snap
* CAPI and SNAP on IBM developerworks: https://developer.ibm.com/linuxonpower/capi/  
* [IBM Developerworks Forum, tag CAPI_SNAP (to get support)](https://developer.ibm.com/answers/smartspace/capi-snap/index.html)
* [Education Videos](https://developer.ibm.com/linuxonpower/capi/education/)

1. From the root directory go to the graph benchmark directory:
  ```
  cd 00_Graph_Bench/
  ```
2. The default compilation is openmp change it from Makefile or:
  ```
  make INTEGRATION_DIR=capi
  ```
3. From the root directory you can modify the Makefile with the parameters you need for OpenMP:
  ```
  make run INTEGRATION_DIR=capi
  ```

## Organization

* `00_Graph_Bench`
  * `include` - Major function headers 
    * `graphalgorithms` - supported Graph algorithms
      * `openmp`  - OpenMP integration
        * `BFS.h`   - Breadth First Search
        * `DFS.h`   - Depth First Search
        * `SSSP.h`  - Single Source Shortest Path
        * `bellmanFord.h` - Single Source Shortest Path using Bellman Ford
        * `incrementalAgreggation.h` - Incremental Aggregation for clustering
        * `pageRank.h` - Page Rank Algorithm
      * `gem5aladdin`- gem5-aladdin integration
      * `capi` - CAPI integration
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
  * `src` - Major function Source files
    * `graphalgorithms` - supported Graph algorithms
      * `openmp`  - OpenMP integration
        * `BFS.c`   - Breadth First Search
        * `DFS.c`   - Depth First Search
        * `SSSP.c`  - Single Source Shortest Path
        * `bellmanFord.c` - Single Source Shortest Path using Bellman Ford
        * `incrementalAgreggation.c` - Incremental Aggregation for clustering
        * `pageRank.c` - Page Rank Algorithm
      * `gem5aladdin`- gem5-aladdin integration
      * `capi` - CAPI integration
    * `preprocessing` - preprocessing graph structure [Presentation](./02_slides/preprocessing_Graphs_countsort.pdf)
      * `countsort.c` - sort edge list using count sort
      * `radixsort.c` - sort edge list using radix sort
      * `reorder.c` - cluster reorder the graph for better cache locality
      * `sortRun.c` - chose which sorting algorithm to use
    * `structures` - structures that hold the graph in memory [Presentation](./02_slides/Graph_DataStructures.pdf)
      * `graphAdjArrayList.c` - graph using adjacency list array with arrays
      * `graphAdjLinkeList.c` - graph using adjacency list array with linked lists
      * `graphCSR.c` - graph using compressed sparse matrix
      * `graphGrid.c` - graph using Grid

* *`Makefile`* - Global makefile

<p align="right">
<img src="./02_slides/fig/logo1.png" width="200" >
</p>