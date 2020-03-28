
#########################################################
#       		 GENERAL DIRECTOIRES   	    			#
#########################################################
# globals binaary /bin/accel-graph name doesn't need to match main/accel-graph.c
APP               ?= accel-graph

# test name needs to match the file name test/test_accel-graph.c
#   APP_TEST          = test_accel-graph
APP_TEST          ?= test_accel-graph


# dirs Root app 
APP_DIR           	?= .
CAPI_INTEG_DIR      ?= 01_capi_integration
SCRIPT_DIR          ?= 03_scripts
BENCHMARKS_DIR    	?= ../../01_GraphDatasets
# BENCHMARKS_DIR    	?= ../04_test_graphs

#dir root/managed_folders
SRC_DIR           	?= src
OBJ_DIR			  	?= obj
INC_DIR			  	?= include
BIN_DIR			  	?= bin
RES_DIR			  	?= results

#if you want to compile from cmake you need this directory
#cd build
#cmake ..
BUILD_DIR		  	?= build

# relative directories used for managing src/obj files
STRUCT_DIR		  	?= structures
PREPRO_DIR		  	?= preprocess
ALGO_DIR		  	?= algorithms
UTIL_DIR		  	?= utils
CAPI_UTIL_DIR		?= capi_utils

# Folders needed when using CAPI


#contains the tests use make run-test to compile what in this directory
TEST_DIR		  	?= tests

#contains the main for the graph processing framework
MAIN_DIR		  	?= main

##################################################
##################################################

#########################################################
#       		 ACCEL RUN GRAPH ARGUMENTS    			#
#########################################################

#small test graphs
GRAPH_NAME ?= test
# GRAPH_NAME ?= v51_e1021
# GRAPH_NAME  ?= v300_e2730

#gem5-Aladdin small dynamic traces
# GRAPH_NAME ?= Gnutella
# GRAPH_NAME ?= dblp
# GRAPH_NAME ?= amazon
# GRAPH_NAME ?= euall

# generates large dynamic traces for gem5-Aladdin
# GRAPH_NAME ?= com-youtube
# GRAPH_NAME ?= web-BerkStan
# GRAPH_NAME ?= web-Google
# GRAPH_NAME ?= wiki-Talk

# synthetic graphs
# GRAPH_NAME ?= RMAT20
# GRAPH_NAME ?= RMAT22

# real world large graphs binary format
# GRAPH_NAME ?= orkut
# GRAPH_NAME ?= gplus
# GRAPH_NAME ?= sk-2005
# GRAPH_NAME ?= twitter
# GRAPH_NAME ?= livejournal
# GRAPH_NAME ?= USA-Road
# GRAPH_NAME ?= enwiki-2013
# GRAPH_NAME ?= arabic-2005

# real world large graphs binary LAW
# GRAPH_NAME ?= amazon-2008
# GRAPH_NAME ?= arabic-2005
# GRAPH_NAME ?= cnr-2000
# GRAPH_NAME ?= dblp-2010
# GRAPH_NAME ?= enron
# GRAPH_NAME ?= eu-2005
# GRAPH_NAME ?= hollywood-2009
# GRAPH_NAME ?= in-2004
# GRAPH_NAME ?= indochina-2004
# GRAPH_NAME ?= it-2004
# GRAPH_NAME ?= ljournal-2008
# GRAPH_NAME ?= sk-2005
# GRAPH_NAME ?= uk-2002
# GRAPH_NAME ?= uk-2005
# GRAPH_NAME ?= webbase-2001

LAW ?= amazon-2008 arabic-2005 cnr-2000 dblp-2010 enron eu-2005 hollywood-2009 in-2004 indochina-2004 it-2004 ljournal-2008 sk-2005 uk-2002 uk-2005 webbase-2001
GAP ?= GAP-kron GAP-road GAP-twitter GAP-urand GAP-web
CU_CONFIG_MODES ?= 0x00000000 0x00041000 0x00841000 0x10041000 0x10841000

# TEXT formant
# export FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_NAME)/graph

#UNWEIGHTED
# export FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_NAME)/graph.bin

# FILE_BIN_TYPE ?= graph
# FILE_BIN_TYPE ?= graph.bin
FILE_BIN_TYPE ?= graph.wbin

#WEIGHTED
FILE_BIN ?= $(BENCHMARKS_DIR)/$(GRAPH_NAME)/$(FILE_BIN_TYPE)



#GRAPH RUN
SORT_TYPE 		?= 0
REORDER 		?= 0
DATA_STRUCTURES ?= 0
ALGORITHMS 		?= 1

ROOT 			?= 164
PULL_PUSH 		?= 2
TOLERANCE 		?= 1e-8
DELTA 			?= 800

START_THREADS   ?= 1
INC_THREADS     ?= 1
NUM_THREADS  	?= 64
# NUM_THREADS  	= $(shell grep -c ^processor /proc/cpuinfo)
NUM_ITERATIONS 	?= 1
NUM_TRIALS 		?= 1

FILE_FORMAT 	?= 1
CONVERT_FORMAT 	?= 1

#STATS COLLECTION VARIABLES
BIN_SIZE ?= 512
INOUT_STATS ?= 2

ARGS ?= -q $(CU_CONFIG_GENERIC) -m $(AFU_CONFIG_GENERIC) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)

##############################################
# CAPI FPGA  GRAPH AFU PERFORMANCE CONFIG    #
##############################################
# // cu_vertex_job_control        5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [19] [18] [15:17]
# // 0b 00000 00000 00000 00000 00000 00000 00
CU_CONFIG_MODE?=0x00000000  

# // cu_vertex_job_control        5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_MS 00001 [22:26] [19] [18] [15:17]
# // 0b 00000 00000 00010 00001 00000 00000 00
# export CU_CONFIG_MODE=0x00041000  

# // cu_vertex_job_control        5-bits ABORT | READ_CL_NA | WRITE_NA 10000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits ABORT | READ_CL_NA | WRITE_NA 10000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits ABORT | READ_CL_S  | WRITE_NA 10010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits ABORT | READ_CL_NA | WRITE_MS 10001 [22:26] [19] [18] [15:17]
#  // 0b 10000 10000 10010 10001 00000 00000 00
# export CU_CONFIG_MODE=0x84251000 

# // cu_vertex_job_control        5-bits PREF | READ_CL_NA | WRITE_NA 11000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits PREF | READ_CL_NA | WRITE_NA 11000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits PREF | READ_CL_NA | WRITE_NA 11000 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits PREF | READ_CL_NA | WRITE_NA 11000 [22:26] [19] [18] [15:17]
# // 0b 11000 11000 11000 11000 00000 00000 00
# export CU_CONFIG_MODE=0xC6318000  

# // cu_vertex_job_control        5-bits PREF | READ_CL_NA | WRITE_NA 11000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits PREF | READ_CL_NA | WRITE_NA 11000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits PREF | READ_CL_S  | WRITE_NA 11010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits PREF | READ_CL_NA | WRITE_MS 11001 [22:26] [19] [18] [15:17]
# // 0b 11000 11000 11010 11001 00000 00000 00
# export CU_CONFIG_MODE=0xC6359000 
 
##############################################
# CAPI FPGA AFU ARBITER CONFIG               #
##############################################
# shift credits >> 
# read_credits            [0:3]
# write_credits           [4:7]
# prefetch_read_credits   [8:11]
# prefetch_write_credits  [12:15]
# FIXED_ARB               [62]
# ROUND_ROBIN_ARB         [63]

ROUND_ROBIN_ARB?=0x1111000000000001
FIXED_ARB?=0x1111000000000002

##############################################
# CAPI FPGA AFU/CU      CONFIG               #
##############################################

AFU_CONFIG_MODE?=$(ROUND_ROBIN_ARB)
# export AFU_CONFIG_MODE=$(FIXED_ARB)

CU_CONFIG_GENERIC?=$(CU_CONFIG_MODE)
AFU_CONFIG_GENERIC?=$(AFU_CONFIG_MODE)
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

ARCHITECTURE = $(shell uname -p) # store the output of the command in a variable if on intel run simulation if power8 run fpga

PSLSE_DIR         = ../$(CAPI_INTEG_DIR)/pslse
LIBCXL_DIR        = ../$(CAPI_INTEG_DIR)/libcxl
CAPI_UTILS_DIR    = ../$(CAPI_INTEG_DIR)/capi-utils
CAPI_ACCEL		  = ../$(CAPI_INTEG_DIR)/accelerator_rtl
CAPI_COMMON		  = ../$(CAPI_INTEG_DIR)/accelerator_sim

CAPI_SIM		  = $(CAPI_COMMON)/sim
CAPI_SERVER		  = $(CAPI_COMMON)/server


PSLSE_COMMON_DIR  = $(PSLSE_DIR)/common
# PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl


SRC_FILES_ALGO_CAPI			=  $(wildcard $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/capi/*.c) 
OBJ_FILES_ALGO_CAPI 		=  $(patsubst $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/capi/%.c,$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/capi/%.o,$(SRC_FILES_ALGO_CAPI))

SRC_FILES_CAPI_UTIL		=	$(wildcard $(APP_DIR)/$(SRC_DIR)/$(CAPI_UTIL_DIR)/*.c)
OBJ_FILES_CAPI_UTIL 	=   $(patsubst $(APP_DIR)/$(SRC_DIR)/$(CAPI_UTIL_DIR)/%.c,$(APP_DIR)/$(OBJ_DIR)/$(CAPI_UTIL_DIR)/%.o,$(SRC_FILES_CAPI_UTIL)) 


CAPI_LINKFLAGS = -lrt -lpthread

# CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
# CAPI_FLAGS = -DSIM -DVERBOSE 

##################################################
##################################################

#########################################################
#       		 ACCEL GRAPH GENERATION    				#
#########################################################

.PHONY: app-openmp
app-openmp : directories directories-openmp $(APP_DIR)/$(BIN_DIR)/$(APP)-openmp
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> AccelGraph: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: test-openmp
test-openmp : directories directories-openmp $(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-openmp
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

$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp : $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(APP).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO_OPENMP) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^  $(LFLAGS)
	
$(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-openmp : $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(APP_TEST).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO_OPENMP) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^  $(LFLAGS)

$(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(APP).o : $(APP_DIR)/$(SRC_DIR)/$(MAIN_DIR)/accel-graph.c
	$(CC) $(CFLAGS) $(OPENMP_INC) -c -o $@ $<

$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(APP_TEST).o : $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(APP_TEST).c 
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
clean: 
	@rm -fr $(APP_DIR)/$(OBJ_DIR)
	@rm -fr $(APP_DIR)/$(BIN_DIR)
	@rm -f $(BENCHMARKS_DIR)/*/*.perf


.PHONY: results-law
results-law:
	@mkdir -p $(APP_DIR)/$(RES_DIR)/results-law_$(DATA_STRUCTURES)_$(ALGORITHMS)_$(PULL_PUSH)
	@for graph in $(LAW); do \
			if [ -e $(BENCHMARKS_DIR)/$$graph/$(FILE_BIN_TYPE).perf ]; then \
				cp $(BENCHMARKS_DIR)/$$graph/$(FILE_BIN_TYPE).perf $(APP_DIR)/$(RES_DIR)/results-law_$(DATA_STRUCTURES)_$(ALGORITHMS)_$(PULL_PUSH)/$$graph; \
			fi ; \
	done

.PHONY: results-gap
results-gap:
	@mkdir -p $(APP_DIR)/$(RES_DIR)/results-gap_$(DATA_STRUCTURES)_$(ALGORITHMS)_$(PULL_PUSH)
	@for graph in $(GAP); do \
			if [ -e $(BENCHMARKS_DIR)/$$graph/$(FILE_BIN_TYPE).perf ]; then \
				cp $(BENCHMARKS_DIR)/$$graph/$(FILE_BIN_TYPE).perf $(APP_DIR)/$(RES_DIR)/results-gap_$(DATA_STRUCTURES)_$(ALGORITHMS)_$(PULL_PUSH)/$$graph; \
			fi ; \
	done


.PHONY: results
results: results-law results-gap

##################################################
##################################################

#########################################################
#       		 CAPI GRAPH GENERATION    				#
#########################################################

.PHONY: clean-pslse
clean-pslse:
	@cd $(PSLSE_DIR)/afu_driver/src && make clean
	@cd $(PSLSE_DIR)/pslse && make clean
	@cd $(PSLSE_DIR)/libcxl && make clean

.PHONY: app-capi
app-capi : directories directories-capi $(APP_DIR)/$(BIN_DIR)/$(APP)-capi
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> AccelGraph: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: test-capi
test-capi : directories directories-capi $(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-capi
	@echo "\n ******************************************************************************  "
	@echo " * DONE!! NOTHING ELSE TO COMPILE ---> TEST: ./$(word 3,$^)"
	@echo " ******************************************************************************  \n"

.PHONY: directories-capi
directories-capi :
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/capi
	@mkdir -p $(APP_DIR)/$(OBJ_DIR)/$(CAPI_UTIL_DIR)

$(PSLSE_DIR)/afu_driver/src/libdpi.so:
	@cd $(PSLSE_DIR)/afu_driver/src && make clean && BIT32=y make

$(PSLSE_LIBCXL_DIR)/libcxl.a:
	@cd $(PSLSE_LIBCXL_DIR) && make

$(PSLSE_DIR)/pslse/pslse:
	@cd $(PSLSE_DIR)/pslse && make DEBUG=1

.PHONY: build-libdpi
build-libdpi: $(PSLSE_DIR)/afu_driver/src/libdpi.so

.PHONY: build-libcxl
build-libcxl: $(PSLSE_LIBCXL_DIR)/libcxl.a

.PHONY: build-pslse
build-pslse: $(PSLSE_DIR)/pslse/pslse
	
$(APP_DIR)/$(BIN_DIR)/$(APP)-capi : $(APP_DIR)/$(OBJ_DIR)/$(MAIN_DIR)/$(APP).o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO_CAPI) $(OBJ_FILES_CAPI_UTIL) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT)
	@$(CC) $(CFLAGS) -o $@ $^ $(LFLAGS) $(PSLSE_LIBCXL_DIR)/libcxl.a $(CAPI_LINKFLAGS) 

$(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-capi : $(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(APP_TEST)-capi.o $(OBJ_FILES_UTIL) $(OBJ_FILES_ALGO_CAPI) $(OBJ_FILES_CAPI_UTIL) $(OBJ_FILES_PREPRO) $(OBJ_FILES_STRUCT) 
	@$(CC) $(CFLAGS) -o $@ $^ $(PSLSE_LIBCXL_DIR)/libcxl.a $(LFLAGS) $(CAPI_LINKFLAGS)

$(APP_DIR)/$(OBJ_DIR)/$(CAPI_UTIL_DIR)/%.o : $(APP_DIR)/$(SRC_DIR)/$(CAPI_UTIL_DIR)/%.c build-libcxl
	$(CC) $(CFLAGS) $(OPENMP_INC) $(CAPI_INC) -c -o $@ $< $(CAPI_FLAGS)

$(APP_DIR)/$(OBJ_DIR)/$(ALGO_DIR)/capi/%.o : $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/capi/%.c
	$(CC) $(CFLAGS) $(OPENMP_INC) $(CAPI_INC) -c -o $@ $< $(CAPI_FLAGS)

$(APP_DIR)/$(OBJ_DIR)/$(TEST_DIR)/$(APP_TEST)-capi.o : $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(APP_TEST).c 
	$(CC) $(CFLAGS) $(OPENMP_INC) $(CAPI_INC) -c -o $@ $< $(CAPI_FLAGS)

.PHONY: clean-sim
clean-sim:
	@rm -f $(CAPI_SIM)/modelsim.ini
	@rm -f $(CAPI_SIM)/transcript
	@rm -f $(CAPI_SIM)/vsim_stacktrace.vstf
	@rm -f $(CAPI_SIM)/vish_stacktrace.vstf
	@rm -f $(CAPI_SIM)/vsim.wlf
	@rm -f $(CAPI_SIM)/*.vcd
	@rm -rf $(CAPI_SIM)/work
	@rm -rf $(CAPI_SIM)/libraries
	@rm -f $(CAPI_SERVER)/debug.log
	@rm -f $(CAPI_SIM)/gmon.out
	@cd $(PSLSE_DIR)/afu_driver/src && make clean
	@cd $(PSLSE_DIR)/libcxl && make clean
	@cd $(PSLSE_DIR)/pslse && make  clean

##################################################
##################################################

##############################################
#         ACCEL GRAPH TOP LEVEL RULES        #
##############################################

.PHONY: help
help: app-openmp
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp  --help

.PHONY: run
run: run-openmp

.PHONY: run-openmp
run-openmp: app-openmp
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp  -f $(FILE_BIN) $(ARGS)

.PHONY: convert
convert: app-openmp
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp  -w -x -c $(CONVERT_FORMAT) -f $(FILE_BIN) -z $(FILE_FORMAT)

.PHONY: stats-openmp
stats-openmp: app-openmp
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp -x -f $(FILE_BIN) -n $(NUM_THREADS) -i $(BIN_SIZE) -o $(SORT_TYPE) -l $(REORDER) -p $(INOUT_STATS)

.PHONY: debug-openmp
debug-openmp: app-openmp	
	gdb -ex=r --args ./$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp -f $(FILE_BIN) $(ARGS)

.PHONY: debug-memory-openmp
debug-memory-openmp: app-openmp	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp -f $(FILE_BIN) $(ARGS)

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
	./$(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-openmp

.PHONY: debug-test-openmp
debug-test-openmp: test-openmp	
	gdb ./$(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-openmp

.PHONY: debug-memory-test-openmp
debug-memory-test-openmp: test-openmp	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-openmp
# cache performance
.PHONY: cachegrind-perf-openmp
cachegrind-perf-openmp: app-openmp
	valgrind --tool=cachegrind ./$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp -f $(FILE_BIN) $(ARGS)

.PHONY: cache-perf
cache-perf-openmp: app-openmp
	sudo perf record -d ./$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp -f $(FILE_BIN) $(ARGS)

.PHONY: law
law: app-openmp
	for graph in $(LAW); do \
	    for num in `seq $(START_THREADS) $(INC_THREADS) $(NUM_THREADS)`; do \
	    	echo $$config $$graph $$num ; \
	    	./$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp  -f $(BENCHMARKS_DIR)/$$graph/graph.wbin -q $$config -m $(AFU_CONFIG_GENERIC) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $$num  -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA) ;\
	    done ; \
    done

.PHONY: gap
gap: app-openmp
	for graph in $(GAP); do \
	    for num in `seq $(START_THREADS) $(INC_THREADS) $(NUM_THREADS)`; do \
	    	echo $$config $$graph $$num ; \
	    	./$(APP_DIR)/$(BIN_DIR)/$(APP)-openmp  -f $(BENCHMARKS_DIR)/$$graph/graph.wbin -q $$config -m $(AFU_CONFIG_GENERIC) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $$num  -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA) ;\
	    done ; \
    done

##################################################
##################################################

 PART?=5SGXMA7H2F35C2
 PROJECT?= accel-graph
 CU_SET_SIM?=$(shell python ../$(SCRIPT_DIR)/choose_algorithm_sim.py $(DATA_STRUCTURES) $(ALGORITHMS) $(PULL_PUSH) $(NUM_THREADS))

##############################################
#      ACCEL GRAPH CAPI TOP LEVEL RULES      #
##############################################


.PHONY: run-capi-sim
run-capi-sim: CAPI_FLAGS = -DSIM
run-capi-sim: PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl
run-capi-sim: CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-sim: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-capi  -f $(FILE_BIN) $(ARGS)

.PHONY: run-capi-sim-verbose
run-capi-sim-verbose: CAPI_FLAGS = -DSIM -DVERBOSE 
run-capi-sim-verbose: PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl
run-capi-sim-verbose: CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-sim-verbose: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-capi  -f $(FILE_BIN) $(ARGS)

.PHONY: run-capi-sim-verbose2
run-capi-sim-verbose2: CAPI_FLAGS = -DSIM -DVERBOSE -DVERBOSE_2 
run-capi-sim-verbose2: PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl
run-capi-sim-verbose2: CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-sim-verbose2: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-capi  -f $(FILE_BIN) $(ARGS)

.PHONY: run-capi-sim-verbose3
run-capi-sim-verbose3: CAPI_FLAGS = -DSIM -DVERBOSE -DVERBOSE_3 
run-capi-sim-verbose3: PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl
run-capi-sim-verbose3: CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-sim-verbose3: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-capi  -f $(FILE_BIN) $(ARGS)

.PHONY: run-capi-fpga
run-capi-fpga: CAPI_FLAGS = 
run-capi-fpga: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
run-capi-fpga: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-fpga: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-capi  -f $(FILE_BIN) $(ARGS)

.PHONY: run-capi-fpga-verbose
run-capi-fpga-verbose: CAPI_FLAGS = -DVERBOSE 
run-capi-fpga-verbose: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
run-capi-fpga-verbose: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-fpga-verbose: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-capi  -f $(FILE_BIN) $(ARGS)

.PHONY: run-capi-fpga-verbose2
run-capi-fpga-verbose2: CAPI_FLAGS = -DVERBOSE -DVERBOSE_2 
run-capi-fpga-verbose2: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
run-capi-fpga-verbose2: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-fpga-verbose2: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-capi  -f $(FILE_BIN) $(ARGS)

.PHONY: run-capi-fpga-verbose3
run-capi-fpga-verbose3: CAPI_FLAGS = -DVERBOSE -DVERBOSE_3 
run-capi-fpga-verbose3: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
run-capi-fpga-verbose3: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-capi-fpga-verbose3: app-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP)-capi  -f $(FILE_BIN) $(ARGS)

.PHONY: run-test-capi
run-test-capi: CAPI_FLAGS = -DSIM -DVERBOSE 
run-test-capi: PSLSE_LIBCXL_DIR  = $(PSLSE_DIR)/libcxl
run-test-capi: CAPI_INC   = -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
run-test-capi: test-capi
	./$(APP_DIR)/$(BIN_DIR)/$(APP_TEST)-capi 

.PHONY: run-vsim
run-vsim: build-libdpi
	cd $(CAPI_SIM) && vsim -do "$(CU_SET_SIM);source vsim.tcl"

.PHONY: run-pslse
run-pslse: build-pslse
	cd $(CAPI_SIM) && ./../../pslse/pslse/pslse

.PHONY: law-capi
law-capi: CAPI_FLAGS = -DVERBOSE
law-capi: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
law-capi: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
law-capi: app-capi
	@for config in $(CU_CONFIG_MODES); do \
		for graph in $(LAW); do \
		    for num in `seq $(START_THREADS) $(INC_THREADS) $(NUM_THREADS)`; do \
		    	echo $$config $$graph $$num ; \
		    	./$(APP_DIR)/$(BIN_DIR)/$(APP)-capi  -f $(BENCHMARKS_DIR)/$$graph/graph.wbin -q $$config -m $(AFU_CONFIG_GENERIC) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $$num  -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA) ;\
		    done ; \
	    done ; \
	done

.PHONY: gap-capi
gap-capi: CAPI_FLAGS = -DVERBOSE
gap-capi: PSLSE_LIBCXL_DIR  = $(LIBCXL_DIR)
gap-capi: CAPI_INC = -I$(LIBCXL_DIR) -I$(APP_DIR)/$(INC_DIR)/$(CAPI_UTIL_DIR)
gap-capi: app-capi
	@for config in $(CU_CONFIG_MODES); do \
		for graph in $(LAW); do \
		    for num in `seq $(START_THREADS) $(INC_THREADS) $(NUM_THREADS)`; do \
		    	echo $$config $$graph $$num ; \
		    	./$(APP_DIR)/$(BIN_DIR)/$(APP)-capi  -f $(BENCHMARKS_DIR)/$$graph/graph.wbin -q $$config -m $(AFU_CONFIG_GENERIC) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $$num  -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA) ;\
		    done ; \
	    done ; \
	done
	  
##################################################
##################################################