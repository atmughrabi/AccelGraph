
##################################################

APP_DIR           	= .
BENCHMARKS_DIR      = 00_graph_bench
NUM_THREADS  	= $(shell grep -c ^processor /proc/cpuinfo)
ARGS = -C $(APP_DIR)/$(BENCHMARKS_DIR) -j$(NUM_THREADS)

##################################################
##################################################

##############################################
#         ACCEL GRAPH TOP LEVEL RULES        #
##############################################

.PHONY: help
help:
	$(MAKE) help $(ARGS)

.PHONY: run
run:
	$(MAKE) run $(ARGS)

.PHONY: run-openmp
run-openmp:
	$(MAKE) run-openmp $(ARGS)

.PHONY: convert
convert:
	$(MAKE) convert $(ARGS)

.PHONY: stats-openmp
stats-openmp: graph-openmp
	$(MAKE) stats-openmp $(ARGS)

.PHONY: debug-openmp
debug-openmp: 
	$(MAKE) debug-openmp $(ARGS)

.PHONY: debug-memory-openmp
debug-memory-openmp: 
	$(MAKE) debug-memory-openmp $(ARGS)

.PHONY: test-verbose
test-verbose:
	$(MAKE) test-verbose $(ARGS)
	
# test files
.PHONY: test
test:
	$(MAKE) test $(ARGS)
	
.PHONY: run-test
run-test: 
	$(MAKE) run-test $(ARGS)

.PHONY: run-test-openmp
run-test-openmp:
	$(MAKE) run-test-openmp $(ARGS)

.PHONY: debug-test-openmp
debug-test-openmp: 
	$(MAKE) debug-test-openmp $(ARGS)

.PHONY: debug-memory-test-openmp
debug-memory-test-openmp:	
	$(MAKE) debug-memory-test-openmp $(ARGS)
# cache performance
.PHONY: cachegrind-perf-openmp
cachegrind-perf-openmp:
	$(MAKE) cachegrind-perf-openmp $(ARGS)

.PHONY: cache-perf
cache-perf-openmp: 
	$(MAKE) cache-perf-openmp $(ARGS)

.PHONY: clean
clean: 
	$(MAKE) clean $(ARGS)

.PHONY: clean-obj
clean-obj: 
	$(MAKE) clean-obj $(ARGS)

##################################################
##################################################

############################################
#      		GEM5  TOP LEVEL RULES          #
############################################

# Builds both standalone CPU version and the HW accelerated version.
.PHONY: gem5 
gem5: 
	$(MAKE) gem5 $(ARGS)

.PHONY: run-gem5
run-gem5: 
	$(MAKE) run-gem5 $(ARGS)

.PHONY: run-gem5-openmp 
run-gem5-openmp: 
	$(MAKE) run-gem5-openmp $(ARGS)

.PHONY: run-gem5-cache-prefetch 
run-gem5-cache-prefetch:
	$(MAKE) run-gem5-cache-prefetch $(ARGS)

.PHONY: run-gem5-cache 
run-gem5-cache: 
	$(MAKE) run-gem5-cache $(ARGS)
	
.PHONY: run-gem5-cpu 
run-gem5-cpu: 
	$(MAKE) run-gem5-cpu $(ARGS)

.PHONY: run-gem5-cpu-only 
run-gem5-cpu-only: 
	$(MAKE) run-gem5-cpu-only $(ARGS)

.PHONY: run-gem5-accel 
run-gem5-accel: 
	$(MAKE) run-gem5-accel $(ARGS)

.PHONY: run-gem5-accel-debug
run-gem5-accel-debug: 
	$(MAKE) run-gem5-accel-debug $(ARGS)
	  
##################################################
##################################################

############################################
#      LLVM TRACER  TOP LEVEL RULES        #
############################################

.PHONY: trace-binary
trace-binary:
	$(MAKE) trace-binary $(ARGS)

.PHONY: dma-trace-binary
dma-trace-binary :
	$(MAKE) dma-trace-binary $(ARGS)

.PHONY: run-llvm-tracer
run-llvm-tracer :
	$(MAKE) run-llvm-tracer $(ARGS)

.PHONY: run-llvm-tracer-force
run-llvm-tracer-force :
	$(MAKE) run-llvm-tracer-force $(ARGS)

.PHONY: run-aladdin
run-aladdin :
	$(MAKE) run-aladdin $(ARGS)

.PHONY: run-aladdin-force
run-aladdin-force :
	$(MAKE) run-aladdin-force $(ARGS)

##################################################
##################################################


##############################################
#      ACCEL GRAPH CAPI TOP LEVEL RULES      #
##############################################

.PHONY: run-capi
run-capi:
	$(MAKE) run-capi $(ARGS)

.PHONY: run-test-capi
run-test-capi:
	$(MAKE) run-test-capi $(ARGS)

.PHONY: run-vsim
run-vsim:
	$(MAKE) run-vsim $(ARGS)

.PHONY: run-pslse
run-pslse:
	$(MAKE) run-pslse $(ARGS)

.PHONY: build-pslse
build-pslse:
	  $(MAKE) build-pslse $(ARGS)

.PHONY: clean-sim
clean-sim:
	 $(MAKE) clean-sim $(ARGS)
##################################################
##################################################