


#########################################################
#       		 GENERAL DIRECTOIRES   	    			#
#########################################################
# globals binaary /bin/accel-graph name doesn't need to match main/accel-graph.c
export APP               = accel-graph

# test name needs to match the file name test/test_accel-graph.c
#   GAPP_TEST          = test_accel-graph
export APP_TEST          = test_afu


# dirs Root app 
export APP_DIR              = .
export BENCHMARKS_DIR    	= ../04_test_graphs

#dir root/managed_folders
export SRC_DIR           	= src
export OBJ_DIR			  	= obj
export INC_DIR			  	= include
export BIN_DIR			  	= bin

#if you want to compile from cmake you need this directory
#cd build
#cmake ..
export BUILD_DIR		  	= build

# relative directories used for managing src/obj files
export STRUCT_DIR		  	= structures
export PREPRO_DIR		  	= preprocess
export ALGO_DIR		  		= algorithms
export UTIL_DIR		  		= utils
export CAPI_UTIL_DIR		= capi_utils


#contains the tests use make run-test to compile what in this directory
export TEST_DIR		  	= tests

#contains the main for the graph processing framework
export MAIN_DIR		  	= main

##################################################
##################################################

#########################################################
#       		 ACCEL RUN GRAPH ARGUMENTS    			#
#########################################################

#small test graphs
# export GRAPH_NAME = test
export GRAPH_NAME = v51_e1021
# export GRAPH_NAME = v300_e2730

#gem5-Aladdin small dynamic traces
# export GRAPH_NAME = Gnutella
# export GRAPH_NAME = dblp
# export GRAPH_NAME = amazon
# export GRAPH_NAME = euall

# generates large dynamic traces for gem5-Aladdin
# export GRAPH_NAME = com-youtube
# export GRAPH_NAME = web-BerkStan
# export GRAPH_NAME = web-Google
# export GRAPH_NAME = wiki-Talk

# synthetic graphs
# export GRAPH_NAME = RMAT20
# export GRAPH_NAME = RMAT22

# real world large graphs binary format
# export GRAPH_NAME = orkut
# export GRAPH_NAME = gplus
# export GRAPH_NAME = sk-2005
# export GRAPH_NAME = twitter
# export GRAPH_NAME = livejournal
# export GRAPH_NAME = USA-Road
# export GRAPH_NAME = enwiki-2013
# export GRAPH_NAME = arabic-2005


#UNWEIGHTED
# export FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_NAME)/graph.bin

#WEIGHTED
export FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_NAME)/graph.wbin



#GRAPH RUN
export SORT_TYPE 		= 0
export REORDER 		    = 0
export DATA_STRUCTURES  = 0
export ALGORITHMS 		= 1

export ROOT 			= 164
export PULL_PUSH 		= 2
export TOLERANCE 		= 1e-8
export DELTA 			= 800

export NUM_THREADS  	= 64
# NUM_THREADS  	= $(shell grep -c ^processor /proc/cpuinfo)
export NUM_ITERATIONS 	= 1
export NUM_TRIALS 		= 1

export FILE_FORMAT 	= 1
export CONVERT_FORMAT 	= 1

#STATS COLLECTION VARIABLES
export BIN_SIZE = 512
export INOUT_STATS = 2

##############################################
# CAPI FPGA AFU PREFETCH CONFIG              #
##############################################

#disable both PREFETCH
ENABLE_RD_WR_PREFETCH=0
#enable write PREFETCH
# ENABLE_RD_WR_PREFETCH=1
#enable read PREFETCH
# ENABLE_RD_WR_PREFETCH=2
#enable both PREFETCH
# export ENABLE_RD_WR_PREFETCH=3

##############################################
# CAPI FPGA  GRAPH AFU PERFORMANCE CONFIG    #
##############################################
# // cu_vertex_job_control        5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [19] [18] [15:17]
# // 0b 00000 00000 00000 00000 00000 00000 00
# export CU_CONFIG_MODE=0x0000000$(ENABLE_RD_WR_PREFETCH)  

# // cu_vertex_job_control        5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_MS 00001 [22:26] [19] [18] [15:17]
# // 0b 00000 00000 00010 00001 00000 00000 00
export CU_CONFIG_MODE=0x00041000  

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

export ROUND_ROBIN_ARB=0x1111000000000001
export FIXED_ARB=0x1111000000000002

##############################################
# CAPI FPGA AFU/CU      CONFIG               #
##############################################

export AFU_CONFIG_MODE=$(ROUND_ROBIN_ARB)
# export AFU_CONFIG_MODE=$(FIXED_ARB)

export CU_CONFIG_GENERIC=$(CU_CONFIG_MODE)
export AFU_CONFIG_GENERIC=$(AFU_CONFIG_MODE)

##################################################

APP_DIR                 = .
MAKE_DIR                = 00_bench
MAKE_DIR_SYNTH          = 01_capi_integration/accelerator_synth

MAKE_NUM_THREADS        = $(shell grep -c ^processor /proc/cpuinfo)
MAKE_ARGS               = -w -C $(APP_DIR)/$(MAKE_DIR) -j$(MAKE_NUM_THREADS)
MAKE_ARGS_SYNTH         = -w -C $(APP_DIR)/$(MAKE_DIR_SYNTH) -j$(MAKE_NUM_THREADS)

#########################################################
#                RUN  ARGUMENTS                         #
#########################################################

export ARGS = -q $(CU_CONFIG_GENERIC) -m $(AFU_CONFIG_GENERIC) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)


##################################################
##################################################

##############################################
#         ACCEL GRAPH TOP LEVEL RULES        #
##############################################

.PHONY: help
help:
	$(MAKE) help $(MAKE_ARGS)

.PHONY: run
run:
	$(MAKE) run $(MAKE_ARGS)

.PHONY: run-openmp
run-openmp:
	$(MAKE) run-openmp $(MAKE_ARGS)

.PHONY: convert
convert:
	$(MAKE) convert $(MAKE_ARGS)

.PHONY: stats-openmp
stats-openmp: graph-openmp
	$(MAKE) stats-openmp $(MAKE_ARGS)

.PHONY: debug-openmp
debug-openmp: 
	$(MAKE) debug-openmp $(MAKE_ARGS)

.PHONY: debug-memory-openmp
debug-memory-openmp: 
	$(MAKE) debug-memory-openmp $(MAKE_ARGS)

.PHONY: test-verbose
test-verbose:
	$(MAKE) test-verbose $(MAKE_ARGS)
	
# test files
.PHONY: test
test:
	$(MAKE) test $(MAKE_ARGS)
	
.PHONY: run-test
run-test: 
	$(MAKE) run-test $(MAKE_ARGS)

.PHONY: run-test-openmp
run-test-openmp:
	$(MAKE) run-test-openmp $(MAKE_ARGS)

.PHONY: debug-test-openmp
debug-test-openmp: 
	$(MAKE) debug-test-openmp $(MAKE_ARGS)

.PHONY: debug-memory-test-openmp
debug-memory-test-openmp:	
	$(MAKE) debug-memory-test-openmp $(MAKE_ARGS)
# cache performance
.PHONY: cachegrind-perf-openmp
cachegrind-perf-openmp:
	$(MAKE) cachegrind-perf-openmp $(MAKE_ARGS)

.PHONY: cache-perf
cache-perf-openmp: 
	$(MAKE) cache-perf-openmp $(MAKE_ARGS)

.PHONY: clean
clean: 
	$(MAKE) clean $(MAKE_ARGS)

.PHONY: clean-obj
clean-obj: 
	$(MAKE) clean-obj $(MAKE_ARGS)

.PHONY: clean-all
clean-all: clean clean-sim clean-synth

##################################################
##################################################

##############################################
#      ACCEL GRAPH CAPI TOP LEVEL RULES      #
##############################################

.PHONY: run-capi-sim
run-capi-sim:
	$(MAKE) run-capi-sim $(MAKE_ARGS)

.PHONY: run-capi-fpga
run-capi-fpga:
	$(MAKE) run-capi-fpga $(MAKE_ARGS)

.PHONY: run-capi-sim-verbose
run-capi-sim-verbose:
	$(MAKE) run-capi-sim-verbose $(MAKE_ARGS)

.PHONY: run-capi-sim-verbose2
run-capi-sim-verbose2:
	$(MAKE) run-capi-sim-verbose2 $(MAKE_ARGS)

.PHONY: run-capi-fpga-verbose
run-capi-fpga-verbose:
	$(MAKE) run-capi-fpga-verbose $(MAKE_ARGS)

.PHONY: run-capi-fpga-verbose2
run-capi-fpga-verbose2:
	$(MAKE) run-capi-fpga-verbose2 $(MAKE_ARGS)

.PHONY: capi
capi:
	$(MAKE) run-capi-fpga-verbose $(MAKE_ARGS) &&\
	sudo ./03_scripts/clear_cache.sh

.PHONY: run-test-capi
run-test-capi:
	$(MAKE) run-test-capi $(MAKE_ARGS)

.PHONY: run-vsim
run-vsim:
	$(MAKE) run-vsim $(MAKE_ARGS)

.PHONY: run-pslse
run-pslse:
	$(MAKE) run-pslse $(MAKE_ARGS)

.PHONY: build-pslse
build-pslse:
	  $(MAKE) build-pslse $(MAKE_ARGS)

.PHONY: clean-sim
clean-sim:
	 $(MAKE) clean-sim $(MAKE_ARGS)
##################################################
##################################################

##############################################
#           ACCEL SYNTHESIZE LEVEL RULES     #
##############################################

.PHONY: run-capi-synth
run-capi-synth:
	$(MAKE) all $(MAKE_ARGS_SYNTH)

.PHONY: run-capi-gui
run-capi-gui:
	$(MAKE) gui $(MAKE_ARGS_SYNTH)

.PHONY: run-capi-sweep
run-capi-sweep:
	$(MAKE) sweep $(MAKE_ARGS_SYNTH)

.PHONY: map
map:
	$(MAKE) map $(MAKE_ARGS_SYNTH)

.PHONY: fit
fit:
	$(MAKE) fit $(MAKE_ARGS_SYNTH)

.PHONY: asm
asm:
	$(MAKE) asm $(MAKE_ARGS_SYNTH)

.PHONY: sta
sta:
	$(MAKE) sta $(MAKE_ARGS_SYNTH)

.PHONY: qxp
qxp:
	$(MAKE) qxp $(MAKE_ARGS_SYNTH)

.PHONY: rbf
rbf:
	$(MAKE) rbf $(MAKE_ARGS_SYNTH)

.PHONY: smart
smart:
	$(MAKE) smart $(MAKE_ARGS_SYNTH)

.PHONY: program
program:
	$(MAKE) program $(MAKE_ARGS_SYNTH)

.PHONY: timing
timing:
	$(MAKE) timing $(MAKE_ARGS_SYNTH)

.PHONY: stats
stats:
	$(MAKE) stats $(MAKE_ARGS_SYNTH)

.PHONY: gen-rbf
gen-rbf:
	$(MAKE) gen-rbf $(MAKE_ARGS_SYNTH)

.PHONY:copy-rbf
copy-rbf:
	$(MAKE) copy-rbf $(MAKE_ARGS_SYNTH)

.PHONY: clean-synth
clean-synth:
	$(MAKE) clean $(MAKE_ARGS_SYNTH)
##################################################
##################################################