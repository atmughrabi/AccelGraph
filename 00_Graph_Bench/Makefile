

# globals
  GAPP               = accel-graph
#   GAPP_TEST          = test_quantization
  GAPP_TEST          = test_bloomfilter
# GAPP_TEST          = test_bloomStream
# GAPP_TEST               = fixedpoint
# GAPP_TEST               = graphCSR
# GAPP_TEST               = graphGrid
# GAPP_TEST               = graphAdjLinkedList
# GAPP_TEST               = graphAdjArray
# GAPP_TEST               = grid

# dirs Root app 
APP_DIR           	= .
BENCHMARKS_DIR    	= ../../01_GraphDatasets

#dir root/managed_folders
SRC_DIR           	= src
OBJ_DIR			  	= obj
INC_DIR			  	= include
BIN_DIR			  	= bin

#if you want to compile from cmake you need this directory
#cd build
#cmake ..
BUILD_DIR		  	= build

# relative directories used for managing src/obj files
STRUCT_DIR		  	= structures
PREPRO_DIR		  	= preprocessing
ALGO_DIR		  	= graphalgorithms
UTIL_DIR		  	= utils

# Integration Directory you can chose gem5aladdin / openmp / capi
INTEGRATION_DIR		= openmp

#contains the tests use make run-test to compile what in this directory
TEST_DIR		  	= tests

#contains the main for the graph processing framework
MAIN_DIR		  	= main


SRC_FILES_UTIL		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/*.c) 
SRC_FILES_ALGO		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(INTEGRATION_DIR)/$(ALGO_DIR)/*.c) 
SRC_FILES_PREPRO	=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/*.c) 
SRC_FILES_STRUCT	=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/*.c)
SRC_FILES_MAIN		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/*.c)
SRC_FILES_TEST		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/*.c)

OBJ_FILES_UTIL 		= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%.o,$(SRC_FILES_UTIL)) 
OBJ_FILES_ALGO 		= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(INTEGRATION_DIR)/$(ALGO_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(INTEGRATION_DIR)/$(ALGO_DIR)/%.o,$(SRC_FILES_ALGO)) 
OBJ_FILES_PREPRO 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%.o,$(SRC_FILES_PREPRO)) 
OBJ_FILES_STRUCT 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%.o,$(SRC_FILES_STRUCT)) 
OBJ_FILES_MAIN  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/%.o,$(SRC_FILES_MAIN)) 
OBJ_FILES_TEST  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/%.o,$(SRC_FILES_TEST)) 
# compilers
# CPP               = c++
# CC				= clang
CC				  = gcc 

INC = 	-I$(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)   \
		-I$(APP_DIR)/$(INC_DIR)/$(INTEGRATION_DIR)/$(ALGO_DIR) 	\
		-I$(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)   \
		-I$(APP_DIR)/$(INC_DIR)/$(UTIL_DIR)  	
		

# flags
CFLAGS   =  -O3 -Wall -m64 -fopenmp -g 
LIBS = -lm

.PHONY: all
all : directories $(APP_DIR)/$(BIN_DIR)/$(GAPP)
	@echo "\n ***************************************************************** "
	@echo " *   DONE!! NOTHING ELSE TO COMPILE ---> ACCELGraph: $(word 2,$^)    *"
	@echo " ***************************************************************** \n"

.PHONY: test
test : directories $(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)
	@echo "\n ***************************************************************** "
	@echo " *   DONE!! NOTHING ELSE TO COMPILE ---> TEST: $(word 2,$^)     *"
	@echo " ***************************************************************** \n"

.PHONY: directories
directories :
	@mkdir -p $(APP_DIR)/$(BIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(INTEGRATION_DIR)/$(ALGO_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)

$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR) : $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^  $(LIBS)
	
$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST) : $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(GAPP_TEST).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^  $(LIBS)

$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP).o : $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/$(GAPP).c
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(GAPP_TEST).o : $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(GAPP_TEST).c 
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(INTEGRATION_DIR)/$(ALGO_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(INTEGRATION_DIR)/$(ALGO_DIR)/%.c
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

.PHONY: clean
clean:
	@rm -fr $(APP_DIR)/$(OBJ_DIR)
	@rm -fr $(APP_DIR)/$(BIN_DIR)
	@rm -fr $(APP_DIR)/$(BUILD_DIR)/*


# Usage: main_argp [OPTION...]
#             -f <graph file> -d [data structure] -a [algorithm] -r [root] -n
#             [num threads] [-h -c -s -w]
# AccelGraph is an open source graph processing framework, it is designed to be a
# portable benchmarking suite for various graph processing algorithms.

#   -a, --algorithm=[ALGORITHM #]   
#                              [0]-BFS, [1]-Page-rank, [2]-SSSP-DeltaStepping,
#                              [3]-SSSP-BellmanFord, [4]-DFS
#                              [5]-IncrementalAggregation
#   -b, --delta=[DELTA:1]      
#                              SSSP Delta value [Default:1]
#   -c, --convert-format=[TEXT|BIN|CSR:1]
                             
#                              [stats flag must be on --stats to write]Serialize
#                              graph text format (edge list format) to binary
#                              graph file on load example:-f <graph file> -c this
#                              is specifically useful if you have Graph CSR/Grid
#                              structure and want to save in a binary file format
#                              to skip the preprocessing step for future runs.
#                              [0]-text edgeList [1]-binary edgeList [2]-graphCSR
#                              binary
#   -d, --data-structure=[TYPE #]   
#                              [0]-CSR, [1]-Grid, [2]-Adj LinkedList, [3]-Adj
#                              ArrayList [4-5] same order bitmap frontiers
#   -e, --tolerance=[EPSILON:0.0001],                              --epsilon=[EPSILON:0.0001]
                             
#                              Tolerance value of for page rank [default:0.0001]

#   -f, --graph-file=<FILE>    
#                              Edge list represents the graph binary format to
#                              run the algorithm textual format change
#                              graph-file-format
#   -i, --num-iterations=[# ITERATIONS]
                             
#                              Number of iterations for page rank to converge
#                              [default:20] SSSP-BellmanFord [default:V-1] 
#   -l, --light-reorder=[ORDER:0]   
#                              Relabels the graph for better cache performance.
#                              [default:0]-no-reordering [1]-page-rank-order
#                              [2]-in-degree [3]-out-degree [4]-in/out degree
#                              [5]-Rabbit [6]-Epoch-pageRank [7]-Epoch-BFS
#                              [8]-LoadFromFile 
#   -n, --num-threads=[# THREADS]   
#                              Default:max number of threads the system has
#   -o, --sort=[RADIX|COUNT]   
#                              [0]-radix-src [1]-radix-src-dest [2]-count-src
#                              [3]-count-src-dst
#   -p, --direction=[PUSH|PULL]   
#                              [0-1]-push/pull [2-3]-push/pull fixed point
#                              arithmetic [4-6]-same order but using data driven
#   -r, --root=[SOURCE|ROOT]   
#                              BFS, DFS, SSSP root
#   -s, --symmetries           
#                              Symmetric graph, create a set of incoming edges
#   -t, --num-trials=[# TRIALS]   
#                              Number of random trials for each whole run (graph
#                              algorithm run) [default:0] 
#   -w, --generate-weights     
#                              Generate random weights don't load from graph
#                              file. Check ->graphConfig.h #define WEIGHTED 1
#                              beforehand then recompile using this option
#   -x, --stats                
#                              Dump a histogram to file based on in-out degree
#                              count bins / sorted according to in/out-degree or
#                              page-ranks 
#   -z, --graph-file-format=[TEXT|BIN|CSR:1]
                             
#                              Specify file format to be read, is it textual edge
#                              list, or a binary file edge list. This is
#                              specifically useful if you have Graph CSR/Grid
#                              structure already saved in a binary file format to
#                              skip the preprocessing step. [0]-text edgeList
#                              [1]-binary edgeList [2]-graphCSR binary
#   -?, --help                 Give this help list
#       --usage                Give a short usage message
#   -V, --version              Print program version

# Report bugs to <atmughra@ncsu.edu>.


#small test graphs
# FILE_BIN = $(BENCHMARKS_DIR)/test/test.txt.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/Rabbit/graph.wbin

# synthetic graphs
# FILE_BIN = $(BENCHMARKS_DIR)/RMAT/RMAT20.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/RMAT/RMAT22.wbin.csr

# real world large graphs binary format
# FILE_BIN = $(BENCHMARKS_DIR)/orkut/graph.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/gplus/graph.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/sk-2005/graph.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/twitter/graph.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/livejournal/graph.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/USA-Road/graph.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/arabic-2005/graph.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/enwiki-2013/graph.wbin


# real world small graphs binary format

FILE_BIN = $(BENCHMARKS_DIR)/Aladdin-graphs/com-youtube.ungraph.trunc.wbin  
# FILE_BIN = $(BENCHMARKS_DIR)/Aladdin-graphs/p2p-Gnutella31.trunc.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/Aladdin-graphs/web-BerkStan.trunc.wbin 
# FILE_BIN = $(BENCHMARKS_DIR)/Aladdin-graphs/web-Google.trunc.wbin
# FILE_BIN = $(BENCHMARKS_DIR)/Aladdin-graphs/wiki-Talk.trunc.wbin

#GRAPH RUN
SORT_TYPE 		= 0
REORDER 		= 0
DATA_STRUCTURES = 0
ALGORITHMS 		= 0

ROOT 			= 0
PUSH_PULL 		= 0
TOLERANCE 		= 1e-9
DELTA 			= 800

NUM_THREADS  	= 8
NUM_ITERATIONS 	= 20
NUM_TRIALS 		= 0

FILE_FORMAT 	= 1
CONVERT_FORMAT 	= 1

#STATS COLLECTION VARIABLES
BIN_SIZE = 512
INOUT_STATS = 2

.PHONY: convert
convert: all
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -x -c $(CONVERT_FORMAT) -f $(FILE_BIN) -z $(FILE_FORMAT)

.PHONY: stats
stats: all
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -x -f $(FILE_BIN) -n $(NUM_THREADS) -i $(BIN_SIZE) -o $(SORT_TYPE) -l $(REORDER) -p $(INOUT_STATS)

.PHONY: run
run: all
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -f $(FILE_BIN) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PUSH_PULL) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)

.PHONY: debug
debug: all	
	gdb ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)

.PHONY: debug-memory
debug-memory: all	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -f $(FILE_BIN) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PUSH_PULL) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)

# test files 

.PHONY: run-test
run-test: test
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST) 

.PHONY: debug-test
debug-test: test	
	gdb ./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)

.PHONY: debug-memory-test
debug-memory-test: test	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)


# cache performance

.PHONY: cachegrind-perf
cachegrind-perf: all
	valgrind --tool=cachegrind ./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -w -f $(FILE_BIN) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PUSH_PULL) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)

.PHONY: cache-perf
cache-perf: all
	sudo perf stat -d ./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -w -f $(FILE_BIN) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PUSH_PULL) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)
