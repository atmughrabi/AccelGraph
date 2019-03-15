# globals
  GAPP               = main
  GAPP_TEST          = test_quantization
# GAPP_TEST               = fixedpoint
# GAPP_TEST               = graphCSR
# GAPP_TEST               = graphGrid
# GAPP_TEST               = graphAdjLinkedList
# GAPP_TEST               = graphAdjArray
# GAPP_TEST               = grid

# dirs
APP_DIR           = .
SRC_DIR           = src
OBJ_DIR			  = obj
INC_DIR			  = include
STRUCT_DIR		  = structures
PREPRO_DIR		  = preprocessing
ALGO_DIR		  = graphalgorithms
TEST_DIR		  = tests
BIN_DIR			  = bin
MAIN_DIR		  = main
UTIL_DIR		  = utils
BUILD_DIR		  = build

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
		-I$(APP_DIR)/$(INC_DIR)/$(UTIL_DIR)

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
#   -p [algorithm direction] [0-1]-push/pull [2-3]-push/pull fixed point arithmetic [4-6]-same order but using data driven
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


# fnameb = "../01_GraphDatasets/RMAT/RMAT-26"
# fnameb = "../01_GraphDatasets/RMAT/RMAT19"
# fnameb = "../01_GraphDatasets/RMAT/RMAT20"
# fnameb = "../01_GraphDatasets/RMAT/RMAT21"
# fnameb = "../01_GraphDatasets/RMAT/RMAT22"

fnameb = "../../01_GraphDatasets/RMAT/RMAT22.wbin"
root = 690969
# root = 2169295
# root = 502357
# root = 3009230
# root = 0
#app command line arguments
# fnameb = "../01_GraphDatasets/twitter/twitter_rv.net.bin8"
# fnameb = "../01_GraphDatasets/Rabbit/test.txt.bin"
# root = 428333 #max out labelless
# root = 813286 #max in  labelless
# reorder = 0

# root = 19144663 #max out label
# root = 3 #max in  label
# reorder = 1

# root = 5576448 #max out label
# root = 0 #max in  label
reorder = 0

# root = 0 #max out label
# root = 2 #max in  label
# reorder = 3

# root = 0 #max out label
# root = 2 #max in  label
# reorder = 4


# fnameb = "../01_GraphDatasets/test/test.txt.wbin"
# root  = 6
# # root  = 19

# fnameb = "../01_GraphDatasets/facebook/facebook_combined.txt.wbin"
# root = 107
# root = 3120
# fnameb = "../01_GraphDatasets/wiki-vote/wiki-Vote.txt.bin"
# root = 428333
datastructure = 0
algorithm = 1
numThreads  = 8
iterations = 100
trials = 0
tolerance = 1e-6
sort = 0
pushpull = 3
delta = 800
# delta = 400
# delta = 1

.PHONY: convert
convert: all
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -c -w -f $(fnameb)

.PHONY: run
run: all
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -f $(fnameb) -d $(datastructure) -a $(algorithm) -r $(root) -n $(numThreads) -i $(iterations) -o $(sort) -p $(pushpull) -t $(trials) -e $(tolerance) -l $(reorder) -b $(delta)

.PHONY: debug
debug: all	
	gdb ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)

.PHONY: debug-memory
debug-memory: main	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(GAPP) -f $(fnameb) -d $(datastructure) -a $(algorithm) -r $(root) -n $(numThreads) -i $(iterations)

.PHONY: run-test
run-test: test
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST) 

.PHONY: debug-test
debug-test: test	
	gdb ./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)

.PHONY: debug-memory-test
debug-memory-test: test	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)