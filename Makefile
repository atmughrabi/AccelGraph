
APP_DIR           	= .
BENCHMARKS_DIR      = 00_graph_bench



##############################################
#         ACCEL GRAPH TOP LEVEL RULES        #
##############################################

.PHONY: help
help:
	$(MAKE) help -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run
run:
	$(MAKE) run -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-openmp
run-openmp:
	$(MAKE) run-openmp -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: convert
convert:
	$(MAKE) convert -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: stats-openmp
stats-openmp: graph-openmp
	$(MAKE) stats-openmp -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: debug-openmp
debug-openmp: 
	$(MAKE) debug-openmp -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: debug-memory-openmp
debug-memory-openmp: 
	$(MAKE) debug-memory-openmp -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: test-verbose
test-verbose:
	$(MAKE) test-verbose -C $(APP_DIR)/$(BENCHMARKS_DIR) 
	
# test files
.PHONY: test
test:
	$(MAKE) test -C $(APP_DIR)/$(BENCHMARKS_DIR) 
	
.PHONY: run-test
run-test: 
	$(MAKE) run-test -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-test-openmp
run-test-openmp:
	$(MAKE) run-test-openmp -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: debug-test-openmp
debug-test-openmp: 
	$(MAKE) debug-test-openmp -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: debug-memory-test-openmp
debug-memory-test-openmp:	
	$(MAKE) debug-memory-test-openmp -C $(APP_DIR)/$(BENCHMARKS_DIR)
# cache performance
.PHONY: cachegrind-perf-openmp
cachegrind-perf-openmp:
	$(MAKE) cachegrind-perf-openmp -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: cache-perf
cache-perf-openmp: 
	$(MAKE) cache-perf-openmp -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: clean
clean: 
	$(MAKE) clean -C $(APP_DIR)/$(BENCHMARKS_DIR)

##################################################
##################################################

############################################
#      		GEM5  TOP LEVEL RULES          #
############################################

# Builds both standalone CPU version and the HW accelerated version.
.PHONY: gem5 
gem5: 
	$(MAKE) gem5 -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-gem5
run-gem5: 
	$(MAKE) run-gem5 -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-gem5-openmp 
run-gem5-openmp: 
	$(MAKE) run-gem5-openmp -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-gem5-cache 
run-gem5-cache: 
	$(MAKE) run-gem5-cache -C $(APP_DIR)/$(BENCHMARKS_DIR)
	
.PHONY: run-gem5-cpu 
run-gem5-cpu: 
	$(MAKE) run-gem5-cpu -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-gem5-accel 
run-gem5-accel: 
	$(MAKE) run-gem5-accel -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-gem5-accel-debug
run-gem5-accel-debug: 
	$(MAKE) run-gem5-accel-debug -C $(APP_DIR)/$(BENCHMARKS_DIR)
	  
##################################################
##################################################


############################################
#      LLVM TRACER  TOP LEVEL RULES        #
############################################

.PHONY: trace-binary
trace-binary:
	$(MAKE) trace-binary -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: dma-trace-binary
dma-trace-binary :
	$(MAKE) dma-trace-binary -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-llvm-tracer
run-llvm-tracer :
	$(MAKE) run-llvm-tracer -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-llvm-tracer-force
run-llvm-tracer-force :
	$(MAKE) run-llvm-tracer-force -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-aladdin
run-aladdin :
	$(MAKE) run-aladdin -C $(APP_DIR)/$(BENCHMARKS_DIR)

.PHONY: run-aladdin-force
run-aladdin-force :
	$(MAKE) run-aladdin-force -C $(APP_DIR)/$(BENCHMARKS_DIR)

##################################################
##################################################