

#########################################################
#       		 GENERAL DIRECTOIRES   	    			#
#########################################################
# globals binaary /bin/accel-graph name doesn't need to match main/accel-graph.c
  GAPP               = accel-graph

# test name needs to match the file name test/test_accel-graph.c
  GAPP_TEST          = test_accel-graph
#   GAPP_TEST          = test_afu


# dirs Root app 
APP_DIR           	= .
SCRIPT_DIR          = ../04_scripts
BENCHMARKS_DIR    	= ../../01_GraphDatasets
BENCHMARKS_DIR    	= ../03_test_graphs

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


# Folders needed when using gem5-aladdin
ALADDIN_COMMON_DIR			= aladdin_common
ALADDIN_CACTI_DIR			= cacti_configs
ALADDIN_GEM5_DIR			= gem5_configs
ALADDIN_ALGO_DIR			= algorithms_configs
DYNAMIC_TRACES_DIR		  	= dynamic_traces
ALADDIN_STATS_DIR		  	= stats_aladdin
GEM5_STATS_DIR		  		= stats_gem5

# Folders needed when using CAPI


#contains the tests use make run-test to compile what in this directory
TEST_DIR		  	= tests

#contains the main for the graph processing framework
MAIN_DIR		  	= main

##################################################
##################################################

#########################################################
#       		 ACCEL RUN GRAPH ARGUMENTS    			#
#########################################################

#small test graphs
# GRAPH_NAME = test
# GRAPH_NAME = Rabbit
#  GRAPH_NAME = v51_e1021
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
# GRAPH_NAME = com-youtube
GRAPH_NAME = p2p-Gnutella31
# GRAPH_NAME = web-BerkStan
# GRAPH_NAME = web-Google
# GRAPH_NAME = wiki-Talk

#UNWEIGHTED
# FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_NAME)/graph.bin

#WEIGHTED
FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_NAME)/graph.wbin



#GRAPH RUN
SORT_TYPE 		= 0
REORDER 		= 0
DATA_STRUCTURES = 0
ALGORITHMS 		= 1

ROOT 			= 43608
PULL_PUSH 		= 5
TOLERANCE 		= 1e-8
DELTA 			= 800

NUM_THREADS  	= 1
# NUM_THREADS  	= $(shell grep -c ^processor /proc/cpuinfo)
NUM_ITERATIONS 	= 100
NUM_TRIALS 		= 1

FILE_FORMAT 	= 1
CONVERT_FORMAT 	= 1

#STATS COLLECTION VARIABLES
BIN_SIZE = 512
INOUT_STATS = 2

ARGS = -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)

##################################################
##################################################
#these variables only affect the signature not used in the make file

UNROLLING = 1
PIPELINE = 0

#each diffrenert run would store the output to different folder based on these parameters
BENCHMARK_SIGNATURE = $(GRAPH_NAME)_$(DATA_STRUCTURES)_$(ALGORITHMS)_$(PULL_PUSH)_$(UNROLLING)_$(PIPELINE)


##################################################
##################################################

##############################################
#      ACCEL GRAPH COMPILATION VARIABLES     #
##############################################


#each implementation is contained in a separate folder. when you compile for openmp for example the files in openmp folder gets included
SRC_FILES_ALGO_OPENMP		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/openmp/*.c)

SRC_FILES_UTIL		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/*.c) 
SRC_FILES_PREPRO	=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/*.c) 
SRC_FILES_STRUCT	=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/*.c)
SRC_FILES_MAIN		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/*.c)
SRC_FILES_TEST		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/*.c)

#create object file rules for the final binary target
OBJ_FILES_ALGO_OPENMP 		= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/openmp/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/openmp/%.o,$(SRC_FILES_ALGO_OPENMP)) 

OBJ_FILES_UTIL 		= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%.o,$(SRC_FILES_UTIL)) 
OBJ_FILES_PREPRO 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%.o,$(SRC_FILES_PREPRO)) 
OBJ_FILES_STRUCT 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%.o,$(SRC_FILES_STRUCT)) 
OBJ_FILES_MAIN  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/%.o,$(SRC_FILES_MAIN)) 
OBJ_FILES_TEST  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/%.o,$(SRC_FILES_TEST)) 

CC				  = gcc 

OPENMP_INC = 	-I$(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)   \
				-I$(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/openmp 	\
				-I$(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)   \
				-I$(APP_DIR)/$(INC_DIR)/$(UTIL_DIR) 


# flags
CFLAGS   =  -O3 -Wall -m64 -fopenmp -g 
LFLAGS = -lm -lJudy


# TEST PASS OR FAIL
PASS = \033[92mPASS\033[0m
FAIL = \033[91mFAIL\033[0m

##################################################
##################################################

##############################################
#      CAPI  GRAPH COMPILATION VARIABLES     #
##############################################

PSLSE_DIR         = ../01_capi_integration/pslse
LIBCXL_DIR        = ../01_capi_integration/libcxl
CAPI_UTILS_DIR    = ../01_capi_integration/capi-utils
CAPI_ACCEL		  = ../01_capi_integration/accelerator
CAPI_COMMON		  = ../01_capi_integration/capi_common

CAPI_SIM		  = $(CAPI_COMMON)/sim
CAPI_SERVER		  = $(CAPI_COMMON)/server

PSLSE_COMMON_DIR  = $(PSLSE_DIR)/common
PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl

SRC_FILES_ALGO_CAPI			=  $(wildcard $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/capi/*.c) 
OBJ_FILES_ALGO_CAPI 		=  $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/capi/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/capi/%.o,$(SRC_FILES_ALGO_CAPI))

CAPI_LINKFLAGS = -lrt -lpthread 
CAPI_INC = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) 

##################################################
##################################################

##################################################
#      LLVM TRACER COMPILATION VARIABLES         #
##################################################

SRC_FILES_ALGO_ALADDIN		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/gem5aladdin/*.c) 

LLVM_VERSION = $(shell clang --version | grep -o -m 1 "[0-9\.]\+" | head -n 1)

LLVM_OBJ_FILES_UTIL 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%-opt.llvm,$(SRC_FILES_UTIL)) 
LLVM_OBJ_FILES_ALGO 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/gem5aladdin/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/%-opt.llvm,$(SRC_FILES_ALGO_ALADDIN)) 
LLVM_OBJ_FILES_PREPRO 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%-opt.llvm,$(SRC_FILES_PREPRO)) 
LLVM_OBJ_FILES_STRUCT 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%-opt.llvm,$(SRC_FILES_STRUCT)) 
LLVM_OBJ_FILES_MAIN  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/%-opt.llvm,$(SRC_FILES_MAIN)) 
LLVM_OBJ_FILES_TEST  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/%-opt.llvm,$(SRC_FILES_TEST)) 

TRACER = $(TRACER_HOME)/lib/full_trace.so
LOGGER = $(TRACER_HOME)/lib/trace_logger.llvm
GET_LABELED_STMTS = $(TRACER_HOME)/bin/get-labeled-stmts

export WORKLOAD=$(shell python $(SCRIPT_DIR)/choose_workload.py $(DATA_STRUCTURES) $(ALGORITHMS) $(PULL_PUSH))
# export WORKLOAD=pageRankPushGraphCSRKernelAladdin

LLVM_LIBS = -lm -lz -lpthread 

LLVM_INC	=	-I$(ALADDIN_HOME)	\
				-I$(ALADDIN_HOME)/common \
		   		-I$(ALADDIN_HOME)/gem5 \
				-I$(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)   \
				-I$(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/gem5aladdin 	\
				-I$(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)   \
				-I$(APP_DIR)/$(INC_DIR)/$(UTIL_DIR) \
				-I$(GEM5_DIR)/include \
				-I$(GEM5_DIR)/include/gem5 \
				-I$(GEM5_DIR)/util/m5

ALL_SRCS_GEM5ALADDIN = 	$(SRC_FILES_UTIL)   \
						$(SRC_FILES_ALGO_ALADDIN)   \
						$(SRC_FILES_PREPRO)	\
						$(SRC_FILES_STRUCT)	\
						$(SRC_FILES_MAIN)

LLVMFLAGS = -static -g -O1 -S -fno-slp-vectorize -fno-vectorize -fno-unroll-loops -fno-inline -fno-builtin -emit-llvm 

##################################################
##################################################

##################################################
#    		 GEM5 COMPILATION VARIABLES         #
##################################################

GEM5_SRCS = aladdin_sys_connection.cpp aladdin_sys_constants.cpp dma_interface.c
GEM5_FULL_SRCS = $(GEM5_SRCS:%=$(ALADDIN_HOME)/gem5/%)

GEM5_TEMP_OBJ = $(patsubst $(ALADDIN_HOME)/gem5/%.c,$(ALADDIN_HOME)/gem5/%.o,$(GEM5_FULL_SRCS)) 
GEM5_FULL_OBJ = $(patsubst $(ALADDIN_HOME)/gem5/%.cpp,$(ALADDIN_HOME)/gem5/%.o,$(GEM5_TEMP_OBJ)) 

OBJ_FILES_ALGO_ALADDIN 		= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/gem5aladdin/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/%.o,$(SRC_FILES_ALGO_ALADDIN)) 

OBJ_FILES_ALGO_ALADDIN_CPU 		= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/gem5aladdin/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/%-cpu.o,$(SRC_FILES_ALGO_ALADDIN)) 
OBJ_FILES_ALGO_ALADDIN_ACCEL 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/gem5aladdin/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/%-accel.o,$(SRC_FILES_ALGO_ALADDIN)) 
OBJ_FILES_ALGO_ALADDIN_CACHE 	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/gem5aladdin/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/%-cache.o,$(SRC_FILES_ALGO_ALADDIN)) 

OBJ_FILES_UTIL_ALADDIN  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%-gem5aladdin.o,$(SRC_FILES_UTIL)) 
OBJ_FILES_PREPRO_ALADDIN  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%-gem5aladdin.o,$(SRC_FILES_PREPRO)) 
OBJ_FILES_STRUCT_ALADDIN  	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%-gem5aladdin.o,$(SRC_FILES_STRUCT)) 
OBJ_FILES_MAIN_ALADDIN   	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/%-gem5aladdin.o,$(SRC_FILES_MAIN)) 
OBJ_FILES_TEST_ALADDIN   	= $(patsubst $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/%-gem5aladdin.o,$(SRC_FILES_TEST)) 

# Common Make targets for simulating MachSuite in gem5.
#
# ALADDIN_HOME needs to be defined as an environment variable.
# The gem5 dependencies are listed as .cpp files for compatibility with gem5.
# To compile them with C code, we need to explicitly use gcc.



ALADDIN_CFLAGS = $(CFLAGS) -Wno-unused-label -DDMA_INTERFACE_V3
# -mno-sse
GEM5_CFLAGS = -static -O3 \
              -msse -mfpmath=sse \
              -fno-exceptions 
            
GEM5_DIR = $(ALADDIN_HOME)/../..

GEM5_INC = $(LLVM_INC)


GEM5_ARGS	= --outdir=./outputs \
			  --stats-db-file=stats.db \
			  $(GEM5_DIR)/configs/aladdin/aladdin_se.py \
			  --num-cpus=1 \
			  --mem-size=8GB \
			  --mem-type=DDR3_1600_8x8  \
			  --sys-clock=1GHz \
			  --cpu-type=DerivO3CPU \
			  --caches \
			  --cacheline_size=128 \
			  --accel_cfg_file=../../../$(ALADDIN_GEM5_DIR)/gem5.cfg

GEM5_ARGS_DEBUG = 	--debug-flags=HybridDatapath,Aladdin \
					 $(GEM5_ARGS) 


##################################################
##################################################

#########################################################
#       		 ACCEL GRAPH GENERATION    				#
#########################################################

.PHONY: graph-openmp
graph-openmp : directories directories-openmp $(APP_DIR)/$(BIN_DIR)/$(GAPP)-openmp
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> AccelGraph: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: test-openmp
test-openmp : directories directories-openmp $(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)-openmp
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> TEST: ./$(word 3,$^)"
	@echo " ****************************************************************************** \n"

.PHONY: directories
directories : 
	@mkdir -p $(APP_DIR)/$(BIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)

.PHONY: directories-openmp
directories-openmp :
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/openmp

$(APP_DIR)/$(BIN_DIR)/$(GAPP)-openmp : $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO_OPENMP) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^  $(LFLAGS)
	
$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)-openmp : $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(GAPP_TEST).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO_OPENMP) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^  $(LFLAGS)

$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP).o : $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/accel-graph.c
	$(CC) $(CFLAGS) $(OPENMP_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(GAPP_TEST).o : $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(GAPP_TEST).c 
	$(CC) $(CFLAGS) $(OPENMP_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c
	$(CC) $(CFLAGS) $(OPENMP_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/openmp/%.o : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/openmp/%.c
	$(CC) $(CFLAGS) $(OPENMP_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c
	$(CC) $(CFLAGS) $(OPENMP_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c
	$(CC) $(CFLAGS) $(OPENMP_INC) -c -o $@ $<

.PHONY: clean
clean: clean-trace clean-gem5
	@rm -fr $(APP_DIR)/$(OBJ_DIR)
	@rm -fr $(APP_DIR)/$(BIN_DIR)

clean-all: clean-trace clean-gem5 clean-sim clean-pslse
	@rm -fr $(APP_DIR)/$(OBJ_DIR)
	@rm -fr $(APP_DIR)/$(BIN_DIR)

.PHONY: clean-obj
clean-obj:
	@rm -fr $(APP_DIR)/$(OBJ_DIR)/*
	@rm -fr $(APP_DIR)/$(BIN_DIR)/*
	@rm -f labelmap

##################################################
##################################################

#########################################################
#       		 CAPI GRAPH GENERATION    				#
#########################################################

.PHONY: clean-pslse
clean-pslse:
	@cd $(PSLSE_DIR)/afu_driver/src && make clean
	@cd $(PSLSE_DIR)/pslse && make clean
	@cd $(PSLSE_LIBCXL_DIR) && make clean

.PHONY: graph-capi
graph-capi : directories directories-capi $(APP_DIR)/$(BIN_DIR)/$(GAPP)-capi
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> AccelGraph: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: test-capi
test-capi : directories directories-capi $(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)-capi
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> TEST: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: directories-capi
directories-capi :
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/capi

$(PSLSE_DIR)/afu_driver/src/libdpi.so:
	@cd $(PSLSE_DIR)/afu_driver/src && make clean && BIT32=y make

$(PSLSE_LIBCXL_DIR)/libcxl.a:
	@cd $(PSLSE_LIBCXL_DIR) && make clean && make

$(PSLSE_DIR)/pslse/pslse:
	@cd $(PSLSE_DIR)/pslse && make clean && make DEBUG=1

.PHONY: build-libdpi
build-libdpi: $(PSLSE_DIR)/afu_driver/src/libdpi.so

.PHONY: build-libcxl
build-libcxl: $(PSLSE_LIBCXL_DIR)/libcxl.a

.PHONY: build-pslse
build-pslse: $(PSLSE_DIR)/pslse/pslse
	
$(APP_DIR)/$(BIN_DIR)/$(GAPP)-capi : $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO_CAPI) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT) $(PSLSE_LIBCXL_DIR)/libcxl.a
	@$(CC) $(CFLAGS) -o $@ $^ $(LFLAGS) $(CAPI_LINKFLAGS) 
	
$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)-capi : $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(GAPP_TEST)-capi.o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO_CAPI) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT) $(PSLSE_LIBCXL_DIR)/libcxl.a
	@$(CC) $(CFLAGS) -o $@ $^ $(LFLAGS) $(CAPI_LINKFLAGS)

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/capi/%.o : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/capi/%.c
	$(CC) $(CFLAGS) $(OPENMP_INC) $(CAPI_INC) -c -o $@ $< -DSIM

$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(GAPP_TEST)-capi.o : $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(GAPP_TEST).c 
	$(CC) $(CFLAGS) $(OPENMP_INC) $(CAPI_INC) -c -o $@ $< -DSIM

.PHONY: clean-sim
clean-sim:
	@rm -f $(CAPI_SIM)/modelsim.ini
	@rm -f $(CAPI_SIM)/transcript
	@rm -f $(CAPI_SIM)/vsim_stacktrace.vstf
	@rm -f $(CAPI_SIM)/vsim.wlf
	@rm -rf $(CAPI_SIM)/work
	@rm -f $(CAPI_SIM)/debug.log
	@rm -f $(CAPI_SIM)/gmon.out	 

##################################################
##################################################

#########################################################
#       		 LLVM TRACER GENERATION    				#
#########################################################

.PHONY: directories-aladdin
directories-aladdin:
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin
	@mkdir -p $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(DYNAMIC_TRACES_DIR)
	@mkdir -p $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE)
	@mkdir -p $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(ALADDIN_STATS_DIR)
	

# Generate the source code labelmap
$(APP_DIR)/labelmap: $(ALL_SRCS_GEM5ALADDIN)
	$(GET_LABELED_STMTS) $(ALL_SRCS_GEM5ALADDIN) -- -I$(LLVM_HOME)/lib/clang/$(LLVM_VERSION)/include $(LLVM_INC) 

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/full.llvm: $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP)-opt.llvm $(LLVM_OBJ_FILES_UTIL) $(LLVM_OBJ_FILES_ALGO) $(LLVM_OBJ_FILES_PREPRO) $(LLVM_OBJ_FILES_STRUCT)
	llvm-link -o $@ $^ $(LOGGER)

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/full.s: $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/full.llvm
	llc -O0 -disable-fp-elim -filetype=asm -o $@ $<

$(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-instrumented: $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/full.s
	$(CXX) -static -O0 -fno-inline -o $@ $< $(LLVM_LIBS) -fopenmp -lJudy

$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP)-opt.llvm : $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/accel-graph.c $(APP_DIR)/labelmap
	clang 	 $(LLVMFLAGS) $(LLVM_INC) -o $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/$*.llvm $<
	opt 	-S -load=$(TRACER) -fulltrace -labelmapwriter $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/$*.llvm -o $@ 

$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%-opt.llvm : $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c $(APP_DIR)/labelmap
	clang 	 $(LLVMFLAGS) $(LLVM_INC) -o $(APP_DIR)/$(OBJ_DIR)//$(UTIL_DIR)/$*.llvm $<
	opt 	-S -load=$(TRACER) -fulltrace -labelmapwriter $(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/$*.llvm -o $@

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/%-opt.llvm : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/gem5aladdin/%.c $(APP_DIR)/labelmap
	clang 	 $(LLVMFLAGS) $(LLVM_INC) -DCPU_HARNESS -o $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/$*.llvm $<
	opt 	-S -load=$(TRACER) -fulltrace -labelmapwriter $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/$*.llvm -o $@

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
	@rm -fr $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(DYNAMIC_TRACES_DIR)
	@rm -fr $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(ALADDIN_STATS_DIR)



##################################################
##################################################

#########################################################
#       		 	GEM5 GENERATION  	  				#
#########################################################
.PHONY: directories-gem5
directories-gem5:
	@mkdir -p $(APP_DIR)/$(BIN_DIR)
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin
	@mkdir -p $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)
	@mkdir -p $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/accel
	@mkdir -p $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/cpu
	@mkdir -p $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/openmp
	@mkdir -p $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/cache

.PHONY: config-symlink-gem5
config-symlink-gem5:
	@mkdir -p $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/$(INTEGRATION)/$(BENCHMARK_SIGNATURE) &&\
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/$(INTEGRATION)/$(BENCHMARK_SIGNATURE)  && \
	ln -sf ../../../$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE)/$(BENCHMARK_SIGNATURE)_dynamic_trace.gz ./dynamic_trace.gz &&\
	cp ../../../$(ALADDIN_CACTI_DIR)/cacti_cache.cfg ./cacti_cache.cfg &&\
	cp ../../../$(ALADDIN_CACTI_DIR)/cacti_tlb.cfg ./cacti_tlb.cfg &&\
	cp ../../../$(ALADDIN_CACTI_DIR)/cacti_lq.cfg ./cacti_lq.cfg &&\
	cp ../../../$(ALADDIN_CACTI_DIR)/cacti_sq.cfg ./cacti_sq.cfg &&\
	cp ../../../$(ALADDIN_ALGO_DIR)/$(DATA_STRUCTURES)/$(ALGORITHMS)/$(UNROLLING).cfg ./algorithm.cfg

.PHONY: config-symlink-gem5-cache
config-symlink-gem5-cache: INTEGRATION = cache
config-symlink-gem5-cache: config-symlink-gem5

# These are relative to gem5.cfg file
.PHONY: config-symlink-gem5-cpu
config-symlink-gem5-cpu: INTEGRATION = cpu
config-symlink-gem5-cpu: config-symlink-gem5
	

.PHONY: config-symlink-gem5-accel
config-symlink-gem5-accel: INTEGRATION = accel
config-symlink-gem5-accel: config-symlink-gem5
	

.PHONY: config-symlink-gem5-openmp
config-symlink-gem5-openmp: INTEGRATION = openmp
config-symlink-gem5-openmp: config-symlink-gem5
	

.PHONY: graph-gem5-accel
graph-gem5-accel : directories directories-gem5 $(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-accel
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> AccelGraph: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: graph-gem5-cpu
graph-gem5-cpu : directories directories-gem5 $(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-cpu
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> AccelGraph: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: graph-gem5-cache
graph-gem5-cache : directories directories-gem5 $(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-cache
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> AccelGraph: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"


$(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-accel:  $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP)-gem5aladdin-accel.o  $(GEM5_FULL_SRCS) $(OBJ_FILES_UTIL_ALADDIN) $(OBJ_FILES_ALGO_ALADDIN_ACCEL) $(OBJ_FILES_PREPRO_ALADDIN) $(OBJ_FILES_STRUCT_ALADDIN)
	@$(CC) $(GEM5_CFLAGS) $(ALADDIN_CFLAGS) -o $@ $^  $(LFLAGS) 

$(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-cpu:  $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP)-gem5aladdin-cpu.o $(OBJ_FILES_UTIL_ALADDIN) $(OBJ_FILES_ALGO_ALADDIN_CPU) $(OBJ_FILES_PREPRO_ALADDIN) $(OBJ_FILES_STRUCT_ALADDIN)
	@$(CC) $(GEM5_CFLAGS) $(ALADDIN_CFLAGS) -o $@ $^  $(LFLAGS)

$(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-cache:  $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP)-gem5aladdin-cache.o $(OBJ_FILES_UTIL_ALADDIN) $(OBJ_FILES_ALGO_ALADDIN_CACHE) $(OBJ_FILES_PREPRO_ALADDIN) $(OBJ_FILES_STRUCT_ALADDIN)
	@$(CC) $(GEM5_CFLAGS) $(ALADDIN_CFLAGS) -o $@ $^  $(LFLAGS)

$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP)-gem5aladdin-accel.o: $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/accel-graph.c
	$(CC) $(GEM5_CFLAGS) $(ALADDIN_CFLAGS) $(GEM5_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP)-gem5aladdin-cpu.o: $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/accel-graph.c
	$(CC) $(GEM5_CFLAGS) $(ALADDIN_CFLAGS) $(GEM5_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(GAPP)-gem5aladdin-cache.o: $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/accel-graph.c
	$(CC) $(GEM5_CFLAGS) $(ALADDIN_CFLAGS) $(GEM5_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(UTIL_DIR)/%-gem5aladdin.o : $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/%.c
	$(CC) $(GEM5_CFLAGS) $(ALADDIN_CFLAGS) $(GEM5_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/%-cpu.o : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/gem5aladdin/%.c
	$(CC) $(GEM5_CFLAGS) $(MODE) $(ALADDIN_CFLAGS) $(GEM5_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/%-cache.o : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/gem5aladdin/%.c
	$(CC) $(GEM5_CFLAGS) $(MODE) $(ALADDIN_CFLAGS) $(GEM5_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/gem5aladdin/%-accel.o : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/gem5aladdin/%.c
	$(CC) $(GEM5_CFLAGS) $(MODE) $(ALADDIN_CFLAGS) $(GEM5_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(PREPRO_DIR)/%-gem5aladdin.o : $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/%.c
	$(CC) $(GEM5_CFLAGS) $(ALADDIN_CFLAGS) $(GEM5_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(STRUCT_DIR)/%-gem5aladdin.o : $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/%.c
	$(CC) $(GEM5_CFLAGS) $(ALADDIN_CFLAGS) $(GEM5_INC) -c -o $@ $<


# $(GEM5_DIR)/util/m5/m5op_x86.o $(GEM5_DIR)/util/m5/m5_mmap.o
# only use as backup for gem5-accel target
.PHONY: gem5-build 
gem5-build: directories-gem5 $(GEM5_FULL_SRCS) 
	@echo Building benchmark ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-$(INTEGRATION).
	@$(CC) $(GEM5_CFLAGS) $(ALADDIN_CFLAGS) $(MODE) $(ALL_SRCS_GEM5ALADDIN) $(GEM5_FULL_SRCS) $(GEM5_INC) -o $(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-$(INTEGRATION) $(LFLAGS)


# Builds the standalone CPU version only with simple cache
.PHONY: gem5-cache 
gem5-cache: MODE 		= -DCACHE_HARNESS
gem5-cache: INTEGRATION = cache
gem5-cache: graph-gem5-cache

.PHONY: gem5-cache-prefetch
gem5-cache-prefetch: MODE 		 = -DCACHE_HARNESS -DPREFETCH
gem5-cache-prefetch: INTEGRATION = cache
gem5-cache-prefetch: graph-gem5-cache

# Builds the standalone CPU version only.
.PHONY: gem5-cpu
gem5-cpu: MODE 			= -DCPU_HARNESS
gem5-cpu: INTEGRATION 	= cpu
gem5-cpu: graph-gem5-cpu 

# Builds the gem5 version with HW acceleration turned on. target specific variables
.PHONY: gem5-accel
gem5-accel: MODE 		= -DGEM5_HARNESS
gem5-accel: INTEGRATION = accel
gem5-accel: graph-gem5-accel
	
.PHONY: clean-gem5 
clean-gem5:
	@rm -rf ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-cpu 
	@rm -fr ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-accel
	@rm -rf ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-cache
	@rm -fr ./$(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)
	@rm -fr $(GEM5_FULL_OBJ)
##################################################
##################################################

############################################
#      LLVM TRACER  TOP LEVEL RULES        #
############################################

.PHONY: trace-binary
trace-binary: directories directories-aladdin $(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-instrumented
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE"
	@echo " * ---> AccelGraph: $(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: dma-trace-binary
dma-trace-binary :
	$(MAKE) -C . DMA_MODE=1 trace-binary

.PHONY: run-llvm-tracer
run-llvm-tracer : $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE)/$(BENCHMARK_SIGNATURE)_dynamic_trace.gz
	
$(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE)/$(BENCHMARK_SIGNATURE)_dynamic_trace.gz : trace-binary 
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE) && \
	../../../$(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-instrumented -f ../../../$(FILE_BIN) $(ARGS)
	mv $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE)/dynamic_trace.gz $@

.PHONY: run-llvm-tracer-force
run-llvm-tracer-force : trace-binary 
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE) && \
	../../../$(APP_DIR)/$(BIN_DIR)/$(GAPP)-gem5aladdin-instrumented -f ../../../$(FILE_BIN) $(ARGS)
	mv $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE)/dynamic_trace.gz $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE)_dynamic_trace.gz

.PHONY: run-aladdin
run-aladdin : run-llvm-tracer
	cd $(ALADDIN_HOME)/common && make
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(ALADDIN_STATS_DIR) && \
	$(ALADDIN_HOME)/common/aladdin $(BENCHMARK_SIGNATURE) ../$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE)/$(BENCHMARK_SIGNATURE)_dynamic_trace.gz ../$(ALADDIN_ALGO_DIR)/$(DATA_STRUCTURES)/$(ALGORITHMS)/$(UNROLLING).cfg

.PHONY: run-aladdin-force
run-aladdin-force : run-llvm-tracer-force
	cd $(ALADDIN_HOME)/common && make
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(ALADDIN_STATS_DIR) && \
	$(ALADDIN_HOME)/common/aladdin $(BENCHMARK_SIGNATURE) ../$(DYNAMIC_TRACES_DIR)/$(BENCHMARK_SIGNATURE)/$(BENCHMARK_SIGNATURE)_dynamic_trace.gz ../$(ALADDIN_ALGO_DIR)/$(DATA_STRUCTURES)/$(ALGORITHMS)/$(UNROLLING).cfg


##################################################
##################################################

############################################
#      		GEM5  TOP LEVEL RULES          #
############################################

# Builds both standalone CPU version and the HW accelerated version.
.PHONY: gem5 
gem5: gem5-cpu gem5-accel

.PHONY: run-gem5
run-gem5: run-gem5-cpu run-gem5-accel

.PHONY: run-gem5-cache-prefetch 
run-gem5-cache-prefetch: gem5-cache-prefetch config-symlink-gem5-cache
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/cache/$(BENCHMARK_SIGNATURE)  && \
	../../../../$(BIN_DIR)/$(GAPP)-gem5aladdin-cache -f ../../../../$(FILE_BIN) $(ARGS)

.PHONY: run-gem5-cache 
run-gem5-cache: gem5-cache config-symlink-gem5-cache
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/cache/$(BENCHMARK_SIGNATURE)  && \
	../../../../$(BIN_DIR)/$(GAPP)-gem5aladdin-cache -f ../../../../$(FILE_BIN) $(ARGS)

.PHONY: run-gem5-openmp 
run-gem5-openmp: directories-gem5 graph-openmp config-symlink-gem5-openmp run-llvm-tracer
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/openmp/$(BENCHMARK_SIGNATURE)  && \
	$(GEM5_DIR)/build/X86/gem5.opt \
	$(GEM5_ARGS) \
	-c ../../../../$(BIN_DIR)/$(GAPP)-openmp -o "-f ../../../../$(FILE_BIN) $(ARGS)" \
	| gzip -c > stdout.sim.gz

.PHONY: run-gem5-cpu
run-gem5-cpu: gem5-cpu config-symlink-gem5-cpu run-llvm-tracer
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/cpu/$(BENCHMARK_SIGNATURE)  && \
	$(GEM5_DIR)/build/X86/gem5.opt \
	$(GEM5_ARGS) \
	-c ../../../../$(BIN_DIR)/$(GAPP)-gem5aladdin-cpu -o "-f ../../../../$(FILE_BIN) $(ARGS)" \
	| gzip -c > stdout.sim.gz

.PHONY: run-gem5-cpu-only
run-gem5-cpu-only: gem5-cpu config-symlink-gem5-cpu run-llvm-tracer
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/cpu/$(BENCHMARK_SIGNATURE)  && \
	../../../../$(BIN_DIR)/$(GAPP)-gem5aladdin-cpu -f ../../../../$(FILE_BIN) $(ARGS) 

.PHONY: run-gem5-accel
run-gem5-accel: gem5-accel config-symlink-gem5-accel run-llvm-tracer
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/accel/$(BENCHMARK_SIGNATURE)  && \
	$(GEM5_DIR)/build/X86/gem5.opt \
	$(GEM5_ARGS) \
	-c ../../../../$(BIN_DIR)/$(GAPP)-gem5aladdin-accel -o "-f ../../../../$(FILE_BIN) $(ARGS)" \
	| gzip -c > stdout.sim.gz

.PHONY: run-gem5-accel-debug
run-gem5-accel-debug: gem5-accel config-symlink-gem5-accel run-llvm-tracer
	cd $(APP_DIR)/$(ALADDIN_COMMON_DIR)/$(GEM5_STATS_DIR)/accel/$(BENCHMARK_SIGNATURE) l && \
	$(GEM5_DIR)/build/X86/gem5.opt \
	$(GEM5_ARGS_DEBUG) \
	-c ../../../../$(BIN_DIR)/$(GAPP)-gem5aladdin-accel -o "-f ../../../../$(FILE_BIN) $(ARGS)" \
	| gzip -c > stdout.sim.gz &&\

	  
##################################################
##################################################

##############################################
#         ACCEL GRAPH TOP LEVEL RULES        #
##############################################

.PHONY: help
help: graph-openmp
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-openmp  --help

.PHONY: run
run: run-openmp

.PHONY: run-openmp
run-openmp: graph-openmp
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-openmp  -f $(FILE_BIN) $(ARGS)

.PHONY: convert
convert: graph-openmp
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-openmp  -w -x -c $(CONVERT_FORMAT) -f $(FILE_BIN) -z $(FILE_FORMAT)

.PHONY: stats-openmp
stats-openmp: graph-openmp
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-openmp -x -f $(FILE_BIN) -n $(NUM_THREADS) -i $(BIN_SIZE) -o $(SORT_TYPE) -l $(REORDER) -p $(INOUT_STATS)

.PHONY: debug-openmp
debug-openmp: graph-openmp	
	gdb -ex=r --args ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-openmp -f $(FILE_BIN) $(ARGS)

.PHONY: debug-memory-openmp
debug-memory-openmp: graph-openmp	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-openmp -f $(FILE_BIN) $(ARGS)

.PHONY: test-verbose
test-verbose:
	$(MAKE) run-test -C $(APP_DIR) | grep -E 'PASS|FAIL'

# test files
.PHONY: test
test:
	@if $(MAKE) run-test -C $(APP_DIR) | grep FAIL > /dev/null; \
		then exit 1; \
	fi
	
.PHONY: run-test
run-test: run-test-openmp

.PHONY: run-test-openmp
run-test-openmp: test-openmp
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)-openmp

.PHONY: debug-test-openmp
debug-test-openmp: test-openmp	
	gdb ./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)-openmp

.PHONY: debug-memory-test-openmp
debug-memory-test-openmp: test-openmp	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)-openmp
# cache performance
.PHONY: cachegrind-perf-openmp
cachegrind-perf-openmp: graph-openmp
	valgrind --tool=cachegrind ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-openmp -f $(FILE_BIN) $(ARGS)
.PHONY: cache-perf
cache-perf-openmp: graph-openmp
	sudo perf record -d ./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-openmp -f $(FILE_BIN) $(ARGS)

##################################################
##################################################

##############################################
#      ACCEL GRAPH CAPI TOP LEVEL RULES      #
##############################################

.PHONY: run-capi
run-capi: graph-capi
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP)-capi  -f $(FILE_BIN) $(ARGS)

.PHONY: run-test-capi
run-test-capi: test-capi
	./$(APP_DIR)/$(BIN_DIR)/$(GAPP_TEST)-capi

.PHONY: run-vsim
run-vsim: build-libdpi
	cd $(CAPI_SIM) && vsim -do vsim.tcl

.PHONY: run-pslse
run-pslse: build-pslse
	cd $(CAPI_SIM) && ./../../pslse/pslse/pslse
	  
##################################################
##################################################