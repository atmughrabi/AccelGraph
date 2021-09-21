#########################################################
#       		 GENERAL DIRECTOIRES   	    			#
#########################################################
# globals binaary /bin/accel-graph name doesn't need to match main/accel-graph.c
export APP               = open-graph
export APP_CAPI          = accel-graph
# test name needs to match the file name test/test_accel-graph.c
# export APP_TEST           ?= test_open-graph-match

export APP_TEST           ?=  sweep_order-OpenGraph-performance-graph
# export APP_TEST           ?=  sweep_order-PR-performance-graph
# export APP_TEST           ?=  sweep_order-BFS-performance-graph
# export APP_TEST           ?=  pagerRank-accuracy-report
# export APP_TEST           ?=  pagerRank-capi-report


# dirs Root app
export APP_DIR              	= .
export APP_DIR_OPEN_GRAPH   	= ../00_open_graph/00_graph_bench
export APP_DIR_CAPI_PRECIS  	= ./01_capi_precis
export CAPI_PRECIS_INTEG_DIR   	= $(APP_DIR_CAPI_PRECIS)/01_capi_integration
export CAPI_INTEG_DIR      		= 03_capi_integration
export SCRIPT_DIR          		= 05_scripts

export BENCHMARKS_DIR_LOCAL    	= 01_test_graphs
# export BENCHMARKS_DIR    		= ../../../01_GraphDatasets

#dir root/managed_folders
export SRC_DIR           	= src
export OBJ_DIR			  	= obj
export INC_DIR			  	= include
export BIN_DIR			  	= bin
export RES_DIR			  	= results



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
export CONFIG_DIR			= config

#contains the tests use make run-test to compile what in this directory
export TEST_DIR		  	= tests

#contains the main for the graph processing framework
export MAIN_DIR		  	= main

##################################################
##################################################

#########################################################
#       		 ACCEL RUN GRAPH ARGUMENTS    			#
#########################################################

# export BENCHMARKS_DIR    	?= ../../01_GraphDatasets
export BENCHMARKS_DIR    	?= ../01_test_graphs

# export GRAPH_SUIT ?=
export GRAPH_SUIT ?= TEST
# export GRAPH_SUIT ?= LAW
# export GRAPH_SUIT ?= GAP
# export GRAPH_SUIT ?= SNAP
# export GRAPH_SUIT ?= KONECT
# export GRAPH_SUIT ?= GONG

# TEST # small test graphs
# export GRAPH_NAME ?= test
# export GRAPH_NAME ?= v51_e1021
# export GRAPH_NAME ?= v300_e2730
export GRAPH_NAME ?= graphbrew

# GONG # https://gonglab.pratt.duke.edu/google-dataset
# export GRAPH_NAME ?= GONG-gplus
# export GRAPH_NAME ?= Gong-gplus

# GAP # https://sparse.tamu.edu/MM/GAP/
# export GRAPH_NAME ?= GAP-twitter
# export GRAPH_NAME ?= GAP-road

# SNAP # https://snap.stanford.edu/data/
# export GRAPH_NAME ?= SNAP-cit-Patents
# export GRAPH_NAME ?= SNAP-com-Orkut
# export GRAPH_NAME ?= SNAP-soc-LiveJournal1
# export GRAPH_NAME ?= SNAP-soc-Pokec
# export GRAPH_NAME ?= SNAP-web-Google

# KONECT # http://konect.cc/networks/wikipedia_link_en/
# export GRAPH_NAME ?= KONECT-wikipedia_link_en

# LAW # https://sparse.tamu.edu/MM/LAW/
# export GRAPH_NAME ?= LAW-amazon-2008
# export GRAPH_NAME ?= LAW-arabic-2005
# export GRAPH_NAME ?= LAW-cnr-2000
# export GRAPH_NAME ?= LAW-dblp-2010
# export GRAPH_NAME ?= LAW-enron
# export GRAPH_NAME ?= LAW-eu-2005
# export GRAPH_NAME ?= LAW-hollywood-2009
# export GRAPH_NAME ?= LAW-in-2004
# export GRAPH_NAME ?= LAW-indochina-2004
# export GRAPH_NAME ?= LAW-it-2004
# export GRAPH_NAME ?= LAW-ljournal-2008
# export GRAPH_NAME ?= LAW-uk-2002
# export GRAPH_NAME ?= LAW-uk-2005
# export GRAPH_NAME ?= LAW-webbase-2001

# export FILE_BIN_TYPE ?= graph
export FILE_BIN_TYPE ?= graph.bin
# export FILE_BIN_TYPE ?= graph.wbin

# export FILE_LABEL_TYPE ?= graph_Gorder.labels
export FILE_LABEL_TYPE ?= graph_Rabbit.labels

#GRAPH file
export FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_SUIT)/$(GRAPH_NAME)/$(FILE_BIN_TYPE)
export FILE_LABEL = $(BENCHMARKS_DIR)/$(GRAPH_SUIT)/$(GRAPH_NAME)/$(FILE_LABEL_TYPE)

#ALGORITHM
export ALGORITHMS 		?= 6
export PULL_PUSH 		?= 0


#GRAPH DATA_STRUCTURES
export SORT_TYPE		?= 1
export DATA_STRUCTURES  ?= 0
export REORDER_LAYER1 	?= 0
export REORDER_LAYER2   ?= 4
export REORDER_LAYER3   ?= 0
export CACHE_SIZE       ?= 32768 # 32KB

#ALGORITHM SPECIFIC ARGS
export ROOT 			?= 1
export TOLERANCE 		?= 1e-8
export DELTA			?= 800
export NUM_ITERATIONS	?= 1

#PERFORMANCE
export NUM_THREADS_PRE  ?= $(shell grep -c ^processor /proc/cpuinfo)
export NUM_THREADS_ALGO ?= $(shell grep -c ^processor /proc/cpuinfo)
export NUM_THREADS_KER  ?= $(NUM_THREADS_ALGO)

# export NUM_THREADS_PRE  ?= 1
# export NUM_THREADS_ALGO ?= 1
# export NUM_THREADS_KER  ?= $(NUM_THREADS_ALGO)

#EXPERIMENTS
export NUM_TRIALS 		?= 1

#GRAPH FROMAT EDGELIST
export FILE_FORMAT		?= 1
export CONVERT_FORMAT 	?= 1

#STATS COLLECTION VARIABLES
export BIN_SIZE 		?= 1000
export INOUT_STATS 		?= 0
export MASK_MODE 		?= 0

##################################################

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
export CU_CONFIG_MODE=0x00000000

# // cu_vertex_job_control        5-bits STRICT | READ_CL_S | WRITE_NA 00010 [27:31] [4] [3] [0:2]
# // 0b 00010 00000 00000 00000 00000 00000 00
# export CU_CONFIG_MODE=0x10000000

# // cu_edge_job_control          5-bits STRICT | READ_CL_S | WRITE_NA 00010 [22:26] [9] [8] [5:7]
# // 0b 00000 00010 00000 00000 00000 00000 00
# export CU_CONFIG_MODE=0x00800000

# // cu_edge_data_control         5-bits STRICT | READ_CL_S | WRITE_NA 00010 [22:26] [14] [13] [10:12]
# // 0b 00000 00000 00010 00000 00000 00000 00
# export CU_CONFIG_MODE=0x00040000

# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_MS 00001 [22:26] [19] [18] [15:17]
# // 0b 00000 00000 00000 00001 00000 00000 00
# export CU_CONFIG_MODE=0x00001000

# // cu_vertex_job_control        5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits STRICT | READ_CL_NA | WRITE_NA 00000 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_MS 00001 [22:26] [19] [18] [15:17]
# // 0b 00000 00000 00010 00001 00000 00000 00
# export CU_CONFIG_MODE=0x00041000

# // cu_vertex_job_control        5-bits STRICT | READ_CL_NA  | WRITE_NA 00010 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_MS 00001 [22:26] [19] [18] [15:17]
# // 0b 00000 00010 00010 00001 00000 00000 00
# export CU_CONFIG_MODE=0x00841000

# // cu_vertex_job_control        5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits STRICT | READ_CL_NA  | WRITE_NA 00010 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_MS 00001 [22:26] [19] [18] [15:17]
# // 0b 00010 00010 00010 00001 00000 00000 00
# export CU_CONFIG_MODE=0x10041000

# // cu_vertex_job_control        5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [27:31] [4] [3] [0:2]
# // cu_edge_job_control          5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [22:26] [9] [8] [5:7]
# // cu_edge_data_control         5-bits STRICT | READ_CL_S  | WRITE_NA 00010 [22:26] [14] [13] [10:12]
# // cu_edge_data_write_control   5-bits STRICT | READ_CL_NA | WRITE_MS 00001 [22:26] [19] [18] [15:17]
# // 0b 00010 00010 00010 00001 00000 00000 00
# export CU_CONFIG_MODE=0x10841000


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
MAKE_DIR_ACCELGRAPH     = 02_capi_graph
MAKE_DIR_OPENGRAPH      = 00_open_graph
MAKE_DIR_SYNTH          = $(CAPI_INTEG_DIR)/$(SYNTH_DIR)

MAKE_NUM_THREADS        = $(shell grep -c ^processor /proc/cpuinfo)
MAKE_ARGS_OPENGRAPH     = -C $(APP_DIR)/$(MAKE_DIR_OPENGRAPH)  -j$(MAKE_NUM_THREADS)
MAKE_ARGS_ACCELGRAPH    = -w -C $(APP_DIR)/$(MAKE_DIR_ACCELGRAPH) -j$(MAKE_NUM_THREADS)
MAKE_ARGS_SYNTH         = -w -C $(APP_DIR)/$(MAKE_DIR_SYNTH)      -j$(MAKE_NUM_THREADS)


#########################################################
#                RUN  ARGUMENTS                         #
#########################################################

export ARGS ?= -w -k -M $(MASK_MODE) -j $(INOUT_STATS) -g $(BIN_SIZE) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS_PRE) -N $(NUM_THREADS_ALGO) -K $(NUM_THREADS_KER) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -F $(FILE_LABEL) -l $(REORDER_LAYER1) -L $(REORDER_LAYER2) -O $(REORDER_LAYER3) -b $(DELTA) -C $(CACHE_SIZE)

export ARGS_CAPI = -q $(CU_CONFIG_GENERIC) -m $(AFU_CONFIG_GENERIC) $(ARGS)

##################################################
##################################################

##############################################
#         ACCEL GRAPH TOP LEVEL RULES        #
##############################################

.PHONY: help
help:
	$(MAKE) help $(MAKE_ARGS_OPENGRAPH)

.PHONY: run
run:
	$(MAKE) run $(MAKE_ARGS_OPENGRAPH)

.PHONY: sweep-run
sweep-run:
	$(MAKE) run-test $(MAKE_ARGS_OPENGRAPH)

.PHONY: run-openmp
run-openmp:
	$(MAKE) run-openmp $(MAKE_ARGS_OPENGRAPH)

.PHONY: convert
convert:
	$(MAKE) convert $(MAKE_ARGS_OPENGRAPH)

.PHONY: sweep-convert
sweep-convert:
	$(MAKE) sweep-convert $(MAKE_ARGS_OPENGRAPH)

.PHONY: convert-w
convert-w:
	$(MAKE) convert-w $(MAKE_ARGS_OPENGRAPH)

.PHONY: stats-openmp
stats-openmp: 
	$(MAKE) stats-openmp $(MAKE_ARGS_OPENGRAPH)

.PHONY: debug-openmp
debug-openmp:
	$(MAKE) debug-openmp $(MAKE_ARGS_OPENGRAPH)

.PHONY: debug-memory-openmp
debug-memory-openmp:
	$(MAKE) debug-memory-openmp $(MAKE_ARGS_OPENGRAPH)

.PHONY: test-verbose
test-verbose:
	$(MAKE) test-verbose $(MAKE_ARGS_OPENGRAPH)

# test files
.PHONY: test
test:
	$(MAKE) test $(MAKE_ARGS_OPENGRAPH)

.PHONY: run-test
run-test:
	$(MAKE) run-test $(MAKE_ARGS_OPENGRAPH)

.PHONY: run-test-openmp
run-test-openmp:
	$(MAKE) run-test-openmp $(MAKE_ARGS_OPENGRAPH)

.PHONY: debug-test-openmp
debug-test-openmp:
	$(MAKE) debug-test-openmp $(MAKE_ARGS_OPENGRAPH)

.PHONY: debug-memory-test-openmp
debug-memory-test-openmp:
	$(MAKE) debug-memory-test-openmp $(MAKE_ARGS_OPENGRAPH)
# cache performance
.PHONY: cachegrind-perf-openmp
cachegrind-perf-openmp:
	$(MAKE) cachegrind-perf-openmp $(MAKE_ARGS_OPENGRAPH)

.PHONY: cache-perf
cache-perf-openmp:
	$(MAKE) cache-perf-openmp $(MAKE_ARGS_OPENGRAPH)

.PHONY: clean
clean:
	$(MAKE) clean $(MAKE_ARGS_OPENGRAPH)
	$(MAKE) clean $(MAKE_ARGS_ACCELGRAPH)

.PHONY: clean-obj
clean-obj:
	$(MAKE) clean-obj $(MAKE_ARGS_OPENGRAPH)
	$(MAKE) clean-obj $(MAKE_ARGS_ACCELGRAPH)

.PHONY: clean-all
clean-all: clean

.PHONY: scrub
scrub: clean clean-nohup clean-stats clean-sim clean-synth-all
	$(MAKE) scrub $(MAKE_ARGS_OPENGRAPH)
	$(MAKE) scrub $(MAKE_ARGS_ACCELGRAPH)
	

.PHONY: clean-stats
clean-stats:
	$(MAKE) clean-stats $(MAKE_ARGS_OPENGRAPH)

.PHONY: clean-nohup
clean-nohup:
	@rm -f $(APP_DIR)/nohup.out

##################################################
##################################################

##############################################
# Simulation/Synthesis CONFIG 						     #
##############################################
# put your design in 01_capi_integration/accelerator_rtl/cu/$CU(algorithm name)
#

export PART=5SGXMA7H2F35C2
export PROJECT = accel-graph
export CU_SET_SIM=$(shell python ./$(SCRIPT_DIR)/choose_algorithm_sim.py $(DATA_STRUCTURES) $(ALGORITHMS) $(PULL_PUSH) $(NUM_THREADS_KER))
export CU_SET_SYNTH=$(shell python ./$(SCRIPT_DIR)/choose_algorithm_synth.py $(DATA_STRUCTURES) $(ALGORITHMS) $(PULL_PUSH))

export CU_GRAPH_ALGORITHM 	= 	$(word 1, $(CU_SET_SYNTH))
export CU_DATA_STRUCTURE 	= 	$(word 2, $(CU_SET_SYNTH))
export CU_DIRECTION 		=   $(word 3, $(CU_SET_SYNTH))
export CU_PRECISION 		= 	$(word 4, $(CU_SET_SYNTH))

export VERSION_GIT = $(shell python ./$(SCRIPT_DIR)/version.py)
export TIME_STAMP = $(shell date +%Y_%m_%d_%H_%M_%S)

export SYNTH_DIR = synthesize_$(CU_GRAPH_ALGORITHM)_$(CU_DATA_STRUCTURE)_$(CU_DIRECTION)_$(CU_PRECISION)_CU$(NUM_THREADS_KER)

# export CU = cu_PageRank_pull

##############################################
#      ACCEL GRAPH CAPI TOP LEVEL RULES      #
##############################################

.PHONY: run-capi-sim
run-capi-sim:
	$(MAKE) run-capi-sim $(MAKE_ARGS_ACCELGRAPH)

.PHONY: run-capi-fpga
run-capi-fpga:
	$(MAKE) run-capi-fpga $(MAKE_ARGS_ACCELGRAPH)

.PHONY: run-capi-sim-verbose
run-capi-sim-verbose:
	$(MAKE) run-capi-sim-verbose $(MAKE_ARGS_ACCELGRAPH)

.PHONY: run-capi-sim-verbose2
run-capi-sim-verbose2:
	$(MAKE) run-capi-sim-verbose2 $(MAKE_ARGS_ACCELGRAPH)

.PHONY: run-capi-sim-verbose3
run-capi-sim-verbose3:
	$(MAKE) run-capi-sim-verbose3 $(MAKE_ARGS_ACCELGRAPH)

.PHONY: run-capi-fpga-verbose
run-capi-fpga-verbose:
	$(MAKE) run-capi-fpga-verbose $(MAKE_ARGS_ACCELGRAPH)

.PHONY: run-capi-fpga-verbose2
run-capi-fpga-verbose2:
	$(MAKE) run-capi-fpga-verbose2 $(MAKE_ARGS_ACCELGRAPH)

.PHONY: run-capi-fpga-verbose3
run-capi-fpga-verbose3:
	$(MAKE) run-capi-fpga-verbose3 $(MAKE_ARGS_ACCELGRAPH)

.PHONY: capi
capi:
	$(MAKE) run-capi-fpga-verbose2 $(MAKE_ARGS_ACCELGRAPH) &&\
	sudo ./$(SCRIPT_DIR)/clear_cache.sh

.PHONY: run-test-capi
run-test-capi:
	$(MAKE) run-test-capi $(MAKE_ARGS_ACCELGRAPH)

.PHONY: run-test-capi-sim
run-test-capi-sim:
	$(MAKE) run-test-capi-sim $(MAKE_ARGS_ACCELGRAPH)

.PHONY: run-vsim
run-vsim:
	$(MAKE) run-vsim $(MAKE_ARGS_ACCELGRAPH)

.PHONY: run-pslse
run-pslse:
	$(MAKE) run-pslse $(MAKE_ARGS_ACCELGRAPH)

.PHONY: build-pslse
build-pslse:
	  $(MAKE) build-pslse $(MAKE_ARGS_ACCELGRAPH)

.PHONY: clean-sim
clean-sim:
	 $(MAKE) clean-sim $(MAKE_ARGS_ACCELGRAPH)

.PHONY: clean-accel
clean-accel:
	 $(MAKE) clean $(MAKE_ARGS_ACCELGRAPH)

.PHONY: law-capi
law-capi:
	$(MAKE) law-capi $(MAKE_ARGS_ACCELGRAPH)

.PHONY: mix-capi
mix-capi:
	$(MAKE) mix-capi $(MAKE_ARGS_ACCELGRAPH)
##################################################
##################################################

##############################################
#           ACCEL SYNTHESIZE LEVEL RULES     #
##############################################

.PHONY: run-synth
run-synth: synth-directories
	$(MAKE) all $(MAKE_ARGS_SYNTH)

.PHONY: run-synth-gui
run-synth-gui: synth-directories
	$(MAKE) gui $(MAKE_ARGS_SYNTH)

.PHONY: run-synth-sweep
run-synth-sweep: synth-directories
	$(MAKE) sweep $(MAKE_ARGS_SYNTH)

.PHONY: map
map: synth-directories
	$(MAKE) map $(MAKE_ARGS_SYNTH)

.PHONY: fit
fit: synth-directories
	$(MAKE) fit $(MAKE_ARGS_SYNTH)

.PHONY: asm
asm: synth-directories
	$(MAKE) asm $(MAKE_ARGS_SYNTH)

.PHONY: sta
sta: synth-directories
	$(MAKE) sta $(MAKE_ARGS_SYNTH)

.PHONY: qxp
qxp: synth-directories
	$(MAKE) qxp $(MAKE_ARGS_SYNTH)

.PHONY: rbf
rbf: synth-directories
	$(MAKE) rbf $(MAKE_ARGS_SYNTH)

.PHONY: smart
smart: synth-directories
	$(MAKE) smart $(MAKE_ARGS_SYNTH)

.PHONY: program
program: synth-directories
	$(MAKE) program $(MAKE_ARGS_SYNTH)

.PHONY: timing
timing: synth-directories
	$(MAKE) timing $(MAKE_ARGS_SYNTH)

.PHONY: gen-rbf
gen-rbf: synth-directories
	$(MAKE) gen-rbf $(MAKE_ARGS_SYNTH)

.PHONY:copy-rbf
copy-rbf: synth-directories
	$(MAKE) copy-rbf $(MAKE_ARGS_SYNTH)

.PHONY: clean-synth
clean-synth:
	$(MAKE) clean $(MAKE_ARGS_SYNTH)

.PHONY: clean-synth-all
clean-synth-all:
	@rm -rf $(APP_DIR)/$(CAPI_INTEG_DIR)/synthesize_*

.PHONY: synth-directories
synth-directories : $(APP_DIR)/$(CAPI_INTEG_DIR)/$(SYNTH_DIR)

.PHONY: $(APP_DIR)/$(CAPI_INTEG_DIR)/$(SYNTH_DIR)
$(APP_DIR)/$(CAPI_INTEG_DIR)/$(SYNTH_DIR) :
	@mkdir -p $(APP_DIR)/$(CAPI_INTEG_DIR)/$(SYNTH_DIR)
	@cp  -a $(APP_DIR)/$(CAPI_INTEG_DIR)/accelerator_synth/* $(APP_DIR)/$(CAPI_INTEG_DIR)/$(SYNTH_DIR)

##################################################
##################################################