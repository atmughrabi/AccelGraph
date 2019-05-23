

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
# INTEGRATION_DIR		= openmp
# INTEGRATION_DIR		= capi
INTEGRATION_DIR		= gem5aladdin
DYNAMIC_DIR		  	= dynamictraces

#contains the tests use make run-test to compile what in this directory
TEST_DIR		  	= tests

#contains the main for the graph processing framework
MAIN_DIR		  	= main

##############################################
#      ACCEL GRAPH COMPILATION VARIABLES     #
##############################################

SRC_FILES_UTIL		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/*.c) 
SRC_FILES_ALGO		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/*.c) 
SRC_FILES_PREPRO	=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/*.c) 
SRC_FILES_STRUCT	=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/*.c)
SRC_FILES_MAIN		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/*.c)
SRC_FILES_TEST		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/*.c)

OBJ_FILES_UTIL 		= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%.o,$(SRC_FILES_UTIL)) 
OBJ_FILES_ALGO 		= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/%.o,$(SRC_FILES_ALGO)) 
OBJ_FILES_PREPRO 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%.o,$(SRC_FILES_PREPRO)) 
OBJ_FILES_STRUCT 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%.o,$(SRC_FILES_STRUCT)) 
OBJ_FILES_MAIN  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/%.o,$(SRC_FILES_MAIN)) 
OBJ_FILES_TEST  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/%.o,$(SRC_FILES_TEST)) 

##################################################
##################################################

##################################################
#      LLVM TRACER COMPILATION VARIABLES         #
##################################################

LLVM_VERSION = $(shell clang --version | grep -o -m 1 "[0-9\.]\+" | head -n 1)

LLVM_OBJ_FILES_UTIL 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%-opt.llvm,$(SRC_FILES_UTIL)) 
LLVM_OBJ_FILES_ALGO 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/%-opt.llvm,$(SRC_FILES_ALGO)) 
LLVM_OBJ_FILES_PREPRO 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%-opt.llvm,$(SRC_FILES_PREPRO)) 
LLVM_OBJ_FILES_STRUCT 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%-opt.llvm,$(SRC_FILES_STRUCT)) 
LLVM_OBJ_FILES_MAIN  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/%-opt.llvm,$(SRC_FILES_MAIN)) 
LLVM_OBJ_FILES_TEST  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/%-opt.llvm,$(SRC_FILES_TEST)) 

TRACER = $(TRACER_HOME)/lib/full_trace.so
LOGGER = $(TRACER_HOME)/lib/trace_logger.llvm
GET_LABELED_STMTS = $(TRACER_HOME)/bin/get-labeled-stmts

KERNELS = pageRankPullGraphCSRKernel

export WORKLOAD  = $(KERNELS)

LLVM_LIBS = -lm -lz -lpthread 

LLVM_INC	=	-I$(ALADDIN_HOME)	\
		   		-I$(COMMON_DIR)		\
		   		-I$(ALADDIN_HOME)/gem5 \
				-I$(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)   \
				-I$(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR) 	\
				-I$(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)   \
				-I$(APP_DIR)/$(INC_DIR)/$(UTIL_DIR) 

ALL_SRCS = 	$(SRC_FILES_UTIL)   \
			$(SRC_FILES_ALGO)   \
			$(SRC_FILES_PREPRO)	\
			$(SRC_FILES_STRUCT)	\
			$(SRC_FILES_MAIN)

LLVMFLAGS = -static -g -O1 -S -fno-slp-vectorize -fno-vectorize -fno-unroll-loops -fno-inline -fno-builtin -emit-llvm 

##################################################
##################################################



# compilers
# CPP               = c++
# CC				= clang
CC				  = gcc 

INC = 	-I$(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)   \
		-I$(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR) 	\
		-I$(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)   \
		-I$(APP_DIR)/$(INC_DIR)/$(UTIL_DIR) 


# flags
CFLAGS   =  -O3 -Wall -m64 -fopenmp -g 
LIBS = -lm


#########################################################
#       		 ACCEL GRAPH GENERATION    				#
#########################################################

.PHONY: all
all : directories $(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR)
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> AccelGraph: $(word 2,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: test
test : directories $(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> TEST: $(word 2,$^)"
	@echo " ****************************************************************************** \n"

.PHONY: directories
directories :  directories-$(INTEGRATION_DIR)
	@mkdir -p $(APP_DIR)/$(BIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)

.PHONY: directories-$(INTEGRATION_DIR)
directories-$(INTEGRATION_DIR) :
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)

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

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/%.c
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

.PHONY: clean
clean: clean-trace
	@rm -fr $(APP_DIR)/$(OBJ_DIR)
	@rm -fr $(APP_DIR)/$(BIN_DIR)
	@rm -fr $(APP_DIR)/$(BUILD_DIR)/*

##################################################
##################################################

#########################################################
#       		 LLVM TRACER GENERATION    				#
#########################################################

.PHONY: directories-instrumented
directories-instrumented:
	@mkdir -p $(APP_DIR)/$(DYNAMIC_DIR)

# Generate the source code labelmap
$(APP_DIR)/labelmap: $(ALL_SRCS)
	$(GET_LABELED_STMTS) $(ALL_SRCS) -- -I$(LLVM_HOME)/lib/clang/$(LLVM_VERSION)/include $(LLVM_INC) 

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/full.llvm: $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP)-opt.llvm $(LLVM_OBJ_FILES_UTIL) $(LLVM_OBJ_FILES_ALGO) $(LLVM_OBJ_FILES_PREPRO) $(LLVM_OBJ_FILES_STRUCT)
	llvm-link -o $@ $^ $(LOGGER)

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/full.s: $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/full.llvm
	llc -O0 -disable-fp-elim -filetype=asm -o $@ $<

./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR)-instrumented: $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/full.s
	$(CXX) -static -O0 -fno-inline -o $@ $< $(LLVM_LIBS) -fopenmp

$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP)-opt.llvm : $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/$(GAPP).c $(APP_DIR)/labelmap
	clang 	 $(LLVMFLAGS) $(LLVM_INC) -o $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/$*.llvm $<
	opt 	-S -load=$(TRACER) -fulltrace -labelmapwriter $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/$*.llvm -o $@ 

$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%-opt.llvm : $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c $(APP_DIR)/labelmap
	clang 	 $(LLVMFLAGS) $(LLVM_INC) -o $(APP_DIR)/$(OBJ_DIR)//$(UTIL_DIR)/$*.llvm $<
	opt 	-S -load=$(TRACER) -fulltrace -labelmapwriter $(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/$*.llvm -o $@

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/%-opt.llvm : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/%.c $(APP_DIR)/labelmap
	clang 	 $(LLVMFLAGS) $(LLVM_INC) -o $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/$*.llvm $<
	opt 	-S -load=$(TRACER) -fulltrace -labelmapwriter $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/$(INTEGRATION_DIR)/$*.llvm -o $@

$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%-opt.llvm : $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c $(APP_DIR)/labelmap
	clang 	 $(LLVMFLAGS) $(LLVM_INC) -o $(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/$*.llvm $<
	opt 	-S -load=$(TRACER) -fulltrace -labelmapwriter $(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/$*.llvm -o $@

$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%-opt.llvm : $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c $(APP_DIR)/labelmap
	clang 	 $(LLVMFLAGS) $(LLVM_INC) -o $(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/$*.llvm $<
	opt 	-S -load=$(TRACER) -fulltrace -labelmapwriter $(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/$*.llvm -o $@

.PHONY: clean-trace
clean-trace:
	@rm -f dynamic_trace.gz
	@rm -f labelmap
##################################################
##################################################

#########################################################
#       		 ACCEL GRAPH ARGUMENTS    				#
#########################################################

#small test graphs
# GRAPH_NAME = test.txt
# GRAPH_NAME = Rabbit

# synthetic graphs
# GRAPH_NAME = RMAT20
# GRAPH_NAME = RMAT22

# real world large graphs binary format
# GRAPH_NAME = orkut
# GRAPH_NAME = gplus
# GRAPH_NAME = sk-2005
# GRAPH_NAME = twitter
# GRAPH_NAME = livejournal
# GRAPH_NAME = USA-Road
# GRAPH_NAME = enwiki-2013
# GRAPH_NAME = arabic-2005


# real world small graphs binary format
GRAPH_NAME = com-youtube
# GRAPH_NAME = p2p-Gnutella31
# GRAPH_NAME = web-BerkStan
# GRAPH_NAME = web-Google
# GRAPH_NAME = wiki-Talk

FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_NAME)/graph.wbin

#GRAPH RUN
SORT_TYPE 		= 0
REORDER 		= 0
DATA_STRUCTURES = 0
ALGORITHMS 		= 1

ROOT 			= 0
PUSH_PULL 		= 0
TOLERANCE 		= 1e-9
DELTA 			= 800

NUM_THREADS  	= 8
NUM_ITERATIONS 	= 20
NUM_TRIALS 		= 10

FILE_FORMAT 	= 1
CONVERT_FORMAT 	= 1

#STATS COLLECTION VARIABLES
BIN_SIZE = 512
INOUT_STATS = 2

ARGS = -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PUSH_PULL) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)

##############################################
#         ACCEL GRAPH TOP LEVEL RULES        #
##############################################

.PHONY: run
run: all
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR)  -f $(FILE_BIN) $(ARGS)

.PHONY: convert
convert: all
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR) -x -c $(CONVERT_FORMAT) -f $(FILE_BIN) -z $(FILE_FORMAT)

.PHONY: stats
stats: all
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR) -x -f $(FILE_BIN) -n $(NUM_THREADS) -i $(BIN_SIZE) -o $(SORT_TYPE) -l $(REORDER) -p $(INOUT_STATS)

.PHONY: debug
debug: all	
	gdb ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR)

.PHONY: debug-memory
debug-memory: all	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR) -f $(FILE_BIN) $(ARGS)
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
	valgrind --tool=cachegrind ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR) -f $(FILE_BIN) $(ARGS)
.PHONY: cache-perf
cache-perf: all
	sudo perf stat -d ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR) -f $(FILE_BIN) $(ARGS)

############################################
#      LLVM TRACER  TOP LEVEL RULES        #
############################################



trace-binary: directories directories-instrumented ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR)-instrumented
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE"
	@echo " * ---> AccelGraph: $(word 2,$^)"
	@echo " ******************************************************************************  \n"


dma-trace-binary:
	$(MAKE) -C . DMA_MODE=1 trace-binary

run-trace: trace-binary
	@cd $(APP_DIR)/$(DYNAMIC_DIR) &&\
	../$(APP_DIR)/$(BIN_DIR)/$(GAPP)-$(INTEGRATION_DIR)-instrumented -f ../$(FILE_BIN) $(ARGS) &&\
	@mv $(APP_DIR)/$(DYNAMIC_DIR)/dynamic_trace.gz $(APP_DIR)/$(DYNAMIC_DIR)/dynamic_trace.gz 


