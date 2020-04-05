#########################################################
#       		 GENERAL DIRECTOIRES   	    			#
#########################################################
# globals binaary /bin/accel-graph name doesn't need to match main/accel-graph.c
export APP               = accel-graph

# test name needs to match the file name test/test_accel-graph.c
# export APP_TEST          =  test_accel-graph
# export APP_TEST          =  pagerRank-accuracy-report
export APP_TEST          =  levenshtein


# dirs Root app 
export APP_DIR              = .
export CAPI_INTEG_DIR      	= 01_capi_integration
export SCRIPT_DIR          	= 03_scripts

export BENCHMARKS_DIR    	= ../04_test_graphs
# export BENCHMARKS_DIR    	= ../../01_GraphDatasets

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


#contains the tests use make run-test to compile what in this directory
export TEST_DIR		  	= tests

#contains the main for the graph processing framework
export MAIN_DIR		  	= main

##################################################
##################################################

#########################################################
#       		 ACCEL RUN GRAPH ARGUMENTS    			#
#########################################################

# small test graphs
export GRAPH_NAME = test
# export GRAPH_NAME = v51_e1021
# export GRAPH_NAME = v300_e2730

# GAP https://sparse.tamu.edu/MM/GAP/
# export GRAPH_NAME = GAP-kron
# export GRAPH_NAME = GAP-road
# export GRAPH_NAME = GAP-twitter
# export GRAPH_NAME = GAP-urand
# export GRAPH_NAME = GAP-web

# LAW https://sparse.tamu.edu/MM/LAW/
# export GRAPH_NAME = amazon-2008
# export GRAPH_NAME = arabic-2005
# export GRAPH_NAME = cnr-2000
# export GRAPH_NAME = dblp-2010
# export GRAPH_NAME = enron
# export GRAPH_NAME = eu-2005
# export GRAPH_NAME = hollywood-2009
# export GRAPH_NAME = in-2004
# export GRAPH_NAME = indochina-2004
# export GRAPH_NAME = it-2004
# export GRAPH_NAME = ljournal-2008
# export GRAPH_NAME = sk-2005
# export GRAPH_NAME = uk-2002
# export GRAPH_NAME = uk-2005
# export GRAPH_NAME = webbase-2001

export LAW = amazon-2008 arabic-2005 cnr-2000 dblp-2010 enron eu-2005 hollywood-2009 in-2004 indochina-2004 it-2004 ljournal-2008 sk-2005 uk-2002 uk-2005 webbase-2001 
export GAP = GAP-kron GAP-road GAP-twitter GAP-urand GAP-web
export CU_CONFIG_MODES = 0x00000000 0x00041000 0x00841000 0x10041000 0x10841000

# TEXT formant
# export FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_NAME)/graph

#UNWEIGHTED
# export FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_NAME)/graph.bin

# export FILE_BIN_TYPE = graph
# export FILE_BIN_TYPE = graph.bin
export FILE_BIN_TYPE = graph.wbin

#WEIGHTED
export FILE_BIN = $(BENCHMARKS_DIR)/$(GRAPH_NAME)/$(FILE_BIN_TYPE)



#GRAPH RUN
export SORT_TYPE 		= 0
export REORDER 		    = 0
export DATA_STRUCTURES  = 0
export ALGORITHMS 		= 1

export ROOT 			= 164
export PULL_PUSH 		= 11
export TOLERANCE 		= 1e-8
export DELTA 			= 800

export START_THREADS    = 1
export INC_THREADS      = 1
export NUM_THREADS  	= 25
# NUM_THREADS  	= $(shell grep -c ^processor /proc/cpuinfo)
export NUM_ITERATIONS 	= 200
export NUM_TRIALS 		= 1

export FILE_FORMAT 		= 1
export CONVERT_FORMAT 	= 1

#STATS COLLECTION VARIABLES
export BIN_SIZE 		= 10
export INOUT_STATS 		= 2

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
# // 0b 00010 00010 00010 00001 00000 00000 00
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
MAKE_DIR                = 00_bench
# MAKE_DIR_SYNTH          = 01_capi_integration/accelerator_synth
MAKE_DIR_SYNTH          = $(CAPI_INTEG_DIR)/$(SYNTH_DIR)

MAKE_NUM_THREADS        = $(shell grep -c ^processor /proc/cpuinfo)
MAKE_ARGS               = -w -C $(APP_DIR)/$(MAKE_DIR) -j$(MAKE_NUM_THREADS)
MAKE_ARGS_SYNTH         = -w -C $(APP_DIR)/$(MAKE_DIR_SYNTH) -j$(MAKE_NUM_THREADS)

#########################################################
#                RUN  ARGUMENTS                         #
#########################################################

export ARGS = --stats -g $(BIN_SIZE) -q $(CU_CONFIG_GENERIC) -m $(AFU_CONFIG_GENERIC) -z $(FILE_FORMAT) -d $(DATA_STRUCTURES) -a $(ALGORITHMS) -r $(ROOT) -n $(NUM_THREADS) -i $(NUM_ITERATIONS) -o $(SORT_TYPE) -p $(PULL_PUSH) -t $(NUM_TRIALS) -e $(TOLERANCE) -l $(REORDER) -b $(DELTA)

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
clean-all: clean clean-sim

.PHONY: purge
purge: clean clean-sim clean-synth-all clean-nohup clean-stats

.PHONY: clean-stats
clean-stats:
	$(MAKE) clean-stats $(MAKE_ARGS)

.PHONY: clean-nohup
clean-nohup: 
	@rm -f $(APP_DIR)/nohup.out

.PHONY: law
law:
	$(MAKE) law $(MAKE_ARGS)

.PHONY: gap
gap:
	$(MAKE) gap $(MAKE_ARGS)

.PHONY: results
results:
	$(MAKE) results $(MAKE_ARGS)

.PHONY: results-law
results-law:
	$(MAKE) results-law $(MAKE_ARGS)

.PHONY: results-gap
results-gap:
	$(MAKE) results-gap $(MAKE_ARGS)

##################################################
##################################################

##############################################
# Simulation/Synthesis CONFIG 						     #
##############################################
# put your design in 01_capi_integration/accelerator_rtl/cu/$CU(algorithm name)
# 

export PART=5SGXMA7H2F35C2
export PROJECT = accel-graph
export CU_SET_SIM=$(shell python ./$(SCRIPT_DIR)/choose_algorithm_sim.py $(DATA_STRUCTURES) $(ALGORITHMS) $(PULL_PUSH) $(NUM_THREADS))
export CU_SET_SYNTH=$(shell python ./$(SCRIPT_DIR)/choose_algorithm_synth.py $(DATA_STRUCTURES) $(ALGORITHMS) $(PULL_PUSH))

export CU_GRAPH_ALGORITHM 	= 	$(word 1, $(CU_SET_SYNTH))
export CU_DATA_STRUCTURE 	= 	$(word 2, $(CU_SET_SYNTH))
export CU_DIRECTION 		=   $(word 3, $(CU_SET_SYNTH))
export CU_PRECISION 		= 	$(word 4, $(CU_SET_SYNTH))

export VERSION_GIT = $(shell python ./$(SCRIPT_DIR)/version.py)
export TIME_STAMP = $(shell date +%Y_%m_%d_%H_%M_%S)

export SYNTH_DIR = synthesize_$(CU_GRAPH_ALGORITHM)_$(CU_DATA_STRUCTURE)_$(CU_DIRECTION)_$(CU_PRECISION)_CU$(NUM_THREADS)

# export CU = cu_PageRank_pull

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

.PHONY: run-capi-sim-verbose3
run-capi-sim-verbose3:
	$(MAKE) run-capi-sim-verbose3 $(MAKE_ARGS)

.PHONY: run-capi-fpga-verbose
run-capi-fpga-verbose:
	$(MAKE) run-capi-fpga-verbose $(MAKE_ARGS)

.PHONY: run-capi-fpga-verbose2
run-capi-fpga-verbose2:
	$(MAKE) run-capi-fpga-verbose2 $(MAKE_ARGS)

.PHONY: run-capi-fpga-verbose3
run-capi-fpga-verbose3:
	$(MAKE) run-capi-fpga-verbose3 $(MAKE_ARGS)

.PHONY: capi
capi:
	$(MAKE) run-capi-fpga-verbose2 $(MAKE_ARGS) &&\
	sudo ./$(SCRIPT_DIR)/clear_cache.sh

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

.PHONY: law-capi
law-capi:
	$(MAKE) law-capi $(MAKE_ARGS)

.PHONY: gap-capi
gap-capi:
	$(MAKE) gap-capi $(MAKE_ARGS)
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

.PHONY: stats
stats: synth-directories
	$(MAKE) stats $(MAKE_ARGS_SYNTH)

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