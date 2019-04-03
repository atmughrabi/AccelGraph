

# globals
  GAPP               = main
#   GAPP_TEST          = test_quantization
  GAPP_TEST          = test_bloomfilter
# GAPP_TEST               = fixedpoint
# GAPP_TEST               = graphCSR
# GAPP_TEST               = graphGrid
# GAPP_TEST               = graphAdjLinkedList
# GAPP_TEST               = graphAdjArray
# GAPP_TEST               = grid

# dirs Root app 
APP_DIR           = .
BENCHMARKS_DIR    = ../../01_GraphDatasets
SNIPER_DIR		  = ../../sniper

#dir root/managed_folders
SRC_DIR           = src
OBJ_DIR			  = obj
INC_DIR			  = include
BIN_DIR			  = bin

#if you want to compile from cmake you need this directory
#cd build
#cmake ..
BUILD_DIR		  = build

# relative directories used for managing src/obj files
STRUCT_DIR		  = structures
PREPRO_DIR		  = preprocessing
ALGO_DIR		  = graphalgorithms
UTIL_DIR		  = utils

#contains the tests use make run-test to compile what in this directory
TEST_DIR		  = tests

#contains the main for the graph processing framework
MAIN_DIR		  = main


SRC_FILES_UTIL		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/*.c) 
SRC_FILES_ALGO		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/*.c) 
SRC_FILES_PREPRO	=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/*.c) 
SRC_FILES_STRUCT	=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/*.c)
SRC_FILES_MAIN		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/*.c)
SRC_FILES_TEST		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/*.c)

OBJ_FILES_UTIL 		= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%.o,$(SRC_FILES_UTIL)) 
OBJ_FILES_ALGO 		= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/%.o,$(SRC_FILES_ALGO)) 
OBJ_FILES_PREPRO 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%.o,$(SRC_FILES_PREPRO)) 
OBJ_FILES_STRUCT 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%.o,$(SRC_FILES_STRUCT)) 
OBJ_FILES_MAIN  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/%.o,$(SRC_FILES_MAIN)) 
OBJ_FILES_TEST  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/%.o,$(SRC_FILES_TEST)) 
# compilers
# CPP               = c++
# CC				= clang
CC				  = gcc 

INC = 	-I$(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)   \
		-I$(APP_DIR)/$(INC_DIR)/$(ALGO_DIR) 	\
		-I$(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)   \
		-I$(APP_DIR)/$(INC_DIR)/$(UTIL_DIR)  	\
		-I$(SNIPER_DIR)/include

# flags
CFLAGS   = -O3 -Wall -m64 -fopenmp -g

.PHONY: all
all : directories $(APP_DIR)/$(BIN_DIR)/$(GAPP)

.PHONY: test
test : directories $(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)

.PHONY: directories
directories :
	@mkdir -p $(APP_DIR)/$(BIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)

$(APP_DIR)/$(BIN_DIR)/$(GAPP) : $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^

$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST) : $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(GAPP_TEST).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^

$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP).o : $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/$(GAPP).c
	@$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(GAPP_TEST).o : $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(GAPP_TEST).c 
	@$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c
	@$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/%.c
	@$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c
	@$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c
	@$(CC) $(CFLAGS) $(INC) -c -o $@ $<




.PHONY: clean
clean:
	@rm -fr $(APP_DIR)/$(OBJ_DIR)
	@rm -fr $(APP_DIR)/$(BIN_DIR)
	@rm -fr $(APP_DIR)/$(BUILD_DIR)/*



# Usage: ./main -f <graph file> -d [data structure] -a [algorithm] -r [root] -n [num threads] [-h -c -s -w]
#   -h [Help] 
#   -a [algorithm] : [0]-BFS, [1]-Pagerank, [2]-SSSP-DeltaStepping, [3]-SSSP-BellmanFord, [4]-DFS [5]-IncrementalAggregation
#   -d [data structure] : [0]-CSR, [1]-Grid, [2]-Adj LinkedList, [3]-Adj ArrayList [4-5] same order bitmap frontiers
#   -r [root]: BFS, DFS, SSSP root
#   -p [algorithm direction] [0-1]-push/pull [2-3]-push/pull fixed point arithmetic [4-5]-push/pull fixed point arithmetic [6-8]-same order but using data driven 
#   -o [sorting algorithm] [0]-radix-src [1]-radix-src-dest [2]-count-src [3]-count-src-dst.
#   -n [num threads] default:max number of threads the system has
#   -i [num iterations] number of iterations for pagerank to converge [default:20] SSSP-BellmanFord [default:V-1] 
#   -t [num trials] number of random trials for each whole run [default:0]
#   -e [epsilon/tolerance] tolerance value of for page rank [default:0.0001]
#   -l [mode] lightweight reordering [default:0]-no-reordering [1]-pagerank-order [2]-in-degree [3]-out-degree [4]-in/out degree [5]-Rabbit  
#   -c: read text format convert to bin file on load example:-f <graph file> -c
#   -w: Weight generate random or load from file graph check graphConfig.h #define WEIGHTED 1 beforehand then recompile with using this option
#   -s: Symmetric graph, if not given set of incoming edges will be created 
#   -b: SSSP Delta value [Default:1]  


# FILE_BIN = $(BENCHMARKS_DIR)/RMAT/RMAT26
# FILE_BIN = $(BENCHMARKS_DIR)/RMAT/RMAT19
# FILE_BIN = $(BENCHMARKS_DIR)/RMAT/RMAT20
# FILE_BIN = $(BENCHMARKS_DIR)/RMAT/RMAT21
# FILE_BIN = $(BENCHMARKS_DIR)/RMAT/RMAT22

FILE_BIN = $(BENCHMARKS_DIR)/RMAT/RMAT22.wbin
ROOT = 690969
# ROOT = 2169295
# ROOT = 502357
# ROOT = 3009230
# ROOT = 0


#app command line arguments
# FILE_BIN = "../01_GraphDatasets/twitter/twitter_rv.net.bin8"
# FILE_BIN = "../01_GraphDatasets/Rabbit/test.txt.bin"
# ROOT = 428333 #max out labelless
# ROOT = 813286 #max in  labelless
# REORDER = 0

# ROOT = 19144663 #max out label
# ROOT = 3 #max in  label
# reorder = 1

# ROOT = 5576448 #max out label
# ROOT = 0 #max in  label


# ROOT = 0 #max out label
# ROOT = 2 #max in  label
# REORDER = 3

# ROOT = 0 #max out label
# ROOT = 2 #max in  label
# REORDER = 4


# FILE_BIN = "$(BENCHMARKS_DIR)/test/test.txt.wbin"
# ROOT  = 6
# ROOT  = 19

# FILE_BIN =  $(BENCHMARKS_DIR)/facebook/facebook_combined.txt.wbin
# ROOT = 107
# ROOT = 3120
# FILE_BIN = "../01_GraphDatasets/wiki-vote/wiki-Vote.txt.bin"
# ROOT = 428333
DATA_STRUCTURES = 0
ALGORITHMS = 1
NUM_THREADS  = 8
NUM_ITERATIONS = 100
NUM_TRIALS = 0
TOLERANCE = 1e-6
SORT_TYPE = 0
PUSH_PULL = 4
DELTA = 800
REORDER = 0
# DELTA = 400
# DELTA = 1

.PHONY: convert
convert: all
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -c -w -f $(FILE_BIN)

.PHONY: run
run: all
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -f $(FILE_BIN) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PUSH_PULL) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)

.PHONY: debug
debug: all	
	gdb ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)

.PHONY: debug-memory
debug-memory: main	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -f $(FILE_BIN) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS)

.PHONY: run-test
run-test: test
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST) 

.PHONY: debug-test
debug-test: test	
	gdb ./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)

.PHONY: debug-memory-test
debug-memory-test: test	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)

.PHONY: sniper
sniper: all	
	./$(SNIPER_DIR)/run-sniper --roi  -ccacheonly -gperf_model/branch_predictor/type=none -ggeneral/enable_icache_modeling=false -c ./$(SNIPER_DIR)/config/base.cfg -- $(APP_DIR)/$(BIN_DIR)/$(GAPP) -f $(FILE_BIN) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PUSH_PULL) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)

.PHONY: sst
sst: all
	$(APP_DIR)/$(BIN_DIR)/$(GAPP) -f $(FILE_BIN) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PUSH_PULL) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)

.PHONY: pin
pin: all	
	 ../../../pin-3.7/pin  -t ../../../pin-3.7/source/tools/SimpleExamples/obj-intel64/pinatrace.so -- $(APP_DIR)/$(BIN_DIR)/$(GAPP) -f $(FILE_BIN) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PUSH_PULL) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)
