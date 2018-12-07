# globals
APP                = test_afu
GAPP               = main
# GAPP               = test_fixedpoint
# GAPP               = test
# GAPP               = test_graphCSR
# GAPP               = test_graphGrid
# GAPP               = test_graphAdjLinkedList
# GAPP               = test_graphAdjArray
# GAPP               = test_grid
TEST               = test


# dirs
PSLSE_DIR         = sim/pslse
PSLSE_COMMON_DIR  = sim/pslse/common
PSLSE_LIBCXL_DIR  = sim/pslse/libcxl
APP_DIR           = host/app
SRC_DIR           = src
OBJ_DIR			  = obj
INC_DIR			  = include
STRUCT_DIR		  = structures
PREPRO_DIR		  = preprocessing
ALGO_DIR		  = graphalgorithms
TEST_DIR		  = tests
UTIL_DIR		  = utils


# compilers
# CPP               = c++
# CC				  = clang
CC				  = gcc 

CAPI = 	-I$(PSLSE_COMMON_DIR) 					\
		-I$(PSLSE_LIBCXL_DIR) 					\
	 	-lrt -lpthread -D SIM

INC = 	-I$(APP_DIR)/include/$(STRUCT_DIR)/ \
		-I$(APP_DIR)/include/$(ALGO_DIR)/ 	\
		-I$(APP_DIR)/include/$(TEST_DIR)/ 	\
		-I$(APP_DIR)/include/$(PREPRO_DIR)/ \
		-I$(APP_DIR)/include/$(UTIL_DIR)/ 	\
		



# flags
CFLAGS            = -O3 -Wall -m64 -fopenmp -g

all: test

pslse-build:
	cd $(PSLSE_DIR)/afu_driver/src && make clean && BIT32=y make
	cd $(PSLSE_DIR)/pslse && make clean && make DEBUG=1
	cd $(PSLSE_LIBCXL_DIR) && make clean && make

pslse-run:
	cd sim && ./pslse/pslse/pslse

sim-build:
	mkdir -p $(APP_DIR)/sim-build
	$(CC) $(APP_DIR)/$(SRC_DIR)/$(APP).c  -o $(APP_DIR)/sim-build/$(APP) $(PSLSE_LIBCXL_DIR)/libcxl.a $(CFLAGS) $(INC) -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -lrt -lpthread -D SIM

sim-run:
	cd sim && ../$(APP_DIR)/sim-build/$(APP) $(ARGS)

vsim-run:
	cd sim && vsim -do vsim.tcl

$(APP_DIR)/$(OBJ_DIR)/mt19937.o: $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/mt19937.c $(APP_DIR)/$(INC_DIR)/$(UTIL_DIR)/mt19937.h
	@echo 'making $(GAPP) <- mt19937.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/mt19937.o $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/mt19937.c

$(APP_DIR)/$(OBJ_DIR)/graphRun.o: $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/graphRun.c $(APP_DIR)/$(INC_DIR)/$(UTIL_DIR)/graphRun.h
	@echo 'making $(GAPP) <- graphRun.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/graphRun.o $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/graphRun.c

$(APP_DIR)/$(OBJ_DIR)/myMalloc.o: $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/myMalloc.c $(APP_DIR)/$(INC_DIR)/$(UTIL_DIR)/myMalloc.h
	@echo 'making $(GAPP) <- myMalloc.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/myMalloc.o $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/myMalloc.c

$(APP_DIR)/$(OBJ_DIR)/progressbar.o: $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/progressbar.c $(APP_DIR)/$(INC_DIR)/$(UTIL_DIR)/progressbar.h
	@echo 'making $(GAPP) <- progressbar.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/progressbar.o $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/progressbar.c

$(APP_DIR)/$(OBJ_DIR)/fixedPoint.o: $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/fixedPoint.c $(APP_DIR)/$(INC_DIR)/$(UTIL_DIR)/fixedPoint.h
	@echo 'making $(GAPP) <- fixedPoint.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/fixedPoint.o $(APP_DIR)/$(SRC_DIR)/$(UTIL_DIR)/fixedPoint.c

$(APP_DIR)/$(OBJ_DIR)/radixsort.o: $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/radixsort.c $(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)/radixsort.h
	@echo 'making $(GAPP) <- radixsort.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/radixsort.o $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/radixsort.c

$(APP_DIR)/$(OBJ_DIR)/reorder.o: $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/reorder.c $(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)/reorder.h
	@echo 'making $(GAPP) <- reorder.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/reorder.o $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/reorder.c

$(APP_DIR)/$(OBJ_DIR)/countsort.o: $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/countsort.c $(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)/countsort.h
	@echo 'making $(GAPP) <- countsort.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/countsort.o $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/countsort.c

$(APP_DIR)/$(OBJ_DIR)/sortRun.o: $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/sortRun.c $(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)/sortRun.h
	@echo 'making $(GAPP) <- sortRun.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/sortRun.o $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/sortRun.c

$(APP_DIR)/$(OBJ_DIR)/vertex.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/vertex.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/vertex.h
	@echo 'making $(GAPP) <- vertex.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/vertex.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/vertex.c

$(APP_DIR)/$(OBJ_DIR)/grid.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/grid.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/grid.h
	@echo 'making $(GAPP) <- grid.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/grid.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/grid.c

$(APP_DIR)/$(OBJ_DIR)/adjLinkedList.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/adjLinkedList.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/adjLinkedList.h
	@echo 'making $(GAPP) <- adjLinkedList.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/adjLinkedList.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/adjLinkedList.c

$(APP_DIR)/$(OBJ_DIR)/adjArrayList.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/adjArrayList.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/adjArrayList.h
	@echo 'making $(GAPP) <- adjLinkedList.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/adjArrayList.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/adjArrayList.c

$(APP_DIR)/$(OBJ_DIR)/cluster.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/cluster.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/cluster.h
	@echo 'making $(GAPP) <- cluster.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/cluster.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/cluster.c

$(APP_DIR)/$(OBJ_DIR)/libchash.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/libchash.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/libchash.h
	@echo 'making $(GAPP) <- libchash.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/libchash.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/libchash.c

$(APP_DIR)/$(OBJ_DIR)/dynamicQueue.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/dynamicQueue.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/dynamicQueue.h
	@echo 'making $(GAPP) <- dynamicQueue.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/dynamicQueue.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/dynamicQueue.c

$(APP_DIR)/$(OBJ_DIR)/timer.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/timer.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/timer.h
	@echo 'making $(GAPP) <- timer.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/timer.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/timer.c

$(APP_DIR)/$(OBJ_DIR)/edgeList.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/edgeList.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/edgeList.h
	@echo 'making $(GAPP) <- edgeList.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/edgeList.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/edgeList.c

$(APP_DIR)/$(OBJ_DIR)/graphCSR.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/graphCSR.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/graphCSR.h
	@echo 'making $(GAPP) <- graphCSR.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/graphCSR.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/graphCSR.c

$(APP_DIR)/$(OBJ_DIR)/graphAdjLinkedList.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/graphAdjLinkedList.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/graphAdjLinkedList.h
	@echo 'making $(GAPP) <- graphAdjLinkedList.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/graphAdjLinkedList.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/graphAdjLinkedList.c

$(APP_DIR)/$(OBJ_DIR)/graphAdjArrayList.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/graphAdjArrayList.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/graphAdjArrayList.h
	@echo 'making $(GAPP) <- graphAdjArrayList.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/graphAdjArrayList.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/graphAdjArrayList.c

$(APP_DIR)/$(OBJ_DIR)/graphGrid.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/graphGrid.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/graphGrid.h
	@echo 'making $(GAPP) <- graphGrid.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/graphGrid.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/graphGrid.c

$(APP_DIR)/$(OBJ_DIR)/bitmap.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/bitmap.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/bitmap.h
	@echo 'making $(GAPP) <- bitmap.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/bitmap.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/bitmap.c

$(APP_DIR)/$(OBJ_DIR)/arrayQueue.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/arrayQueue.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/arrayQueue.h
	@echo 'making $(GAPP) <- arrayQueue.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/arrayQueue.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/arrayQueue.c

$(APP_DIR)/$(OBJ_DIR)/arrayStack.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/arrayStack.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/arrayStack.h
	@echo 'making $(GAPP) <- arrayStack.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/arrayStack.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/arrayStack.c

$(APP_DIR)/$(OBJ_DIR)/bellmanFord.o: $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/bellmanFord.c $(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/bellmanFord.h
	@echo 'making $(GAPP) <- bellmanFord.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/bellmanFord.o $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/bellmanFord.c

$(APP_DIR)/$(OBJ_DIR)/BFS.o: $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/BFS.c $(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/BFS.h
	@echo 'making $(GAPP) <- BFS.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/BFS.o $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/BFS.c

$(APP_DIR)/$(OBJ_DIR)/DFS.o: $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/DFS.c $(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/DFS.h
	@echo 'making $(GAPP) <- DFS.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/DFS.o $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/DFS.c

$(APP_DIR)/$(OBJ_DIR)/pageRank.o: $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/pageRank.c $(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/pageRank.h
	@echo 'making $(GAPP) <- pageRank.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/pageRank.o $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/pageRank.c

$(APP_DIR)/$(OBJ_DIR)/incrementalAggregation.o: $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/incrementalAggregation.c $(APP_DIR)/$(INC_DIR)/$(ALGO_DIR)/incrementalAggregation.h
	@echo 'making $(GAPP) <- incrementalAggregation.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/incrementalAggregation.o $(APP_DIR)/$(SRC_DIR)/$(ALGO_DIR)/incrementalAggregation.c

$(APP_DIR)/$(OBJ_DIR)/$(GAPP).o: $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(GAPP).c
	@echo 'making $(GAPP) <- $(GAPP).o'
	@$(CC) $(CFLAGS) -c -o $(APP_DIR)/$(OBJ_DIR)/$(GAPP).o \
	$(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(GAPP).c \
	$(INC) \

$(APP_DIR)/$(OBJ_DIR)/$(GAPP)-capi.o: $(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(GAPP).c
	@echo 'making $(GAPP) <- $(GAPP)-capi.o'
	@$(CC) $(CFLAGS) -c -o $(APP_DIR)/$(OBJ_DIR)/$(GAPP)-capi.o \
	$(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(GAPP).c \
	$(INC) \
	$(CAPI)
	

arrayQueue: $(APP_DIR)/$(OBJ_DIR)/arrayQueue.o

arrayStack: $(APP_DIR)/$(OBJ_DIR)/arrayStack.o

bitmap: $(APP_DIR)/$(OBJ_DIR)/bitmap.o

myMalloc: $(APP_DIR)/$(OBJ_DIR)/myMalloc.o

progressbar: $(APP_DIR)/$(OBJ_DIR)/progressbar.o

fixedPoint: $(APP_DIR)/$(OBJ_DIR)/fixedPoint.o

timer: $(APP_DIR)/$(OBJ_DIR)/timer.o

app: $(APP_DIR)/$(OBJ_DIR)/$(GAPP).o

app-capi: $(APP_DIR)/$(OBJ_DIR)/$(GAPP)-capi.o

vertex: $(APP_DIR)/$(OBJ_DIR)/vertex.o

countsort: $(APP_DIR)/$(OBJ_DIR)/countsort.o

radixsort: $(APP_DIR)/$(OBJ_DIR)/radixsort.o

reorder: $(APP_DIR)/$(OBJ_DIR)/reorder.o

sortRun: $(APP_DIR)/$(OBJ_DIR)/sortRun.o

edgeList: $(APP_DIR)/$(OBJ_DIR)/edgeList.o

graphCSR: $(APP_DIR)/$(OBJ_DIR)/graphCSR.o

libchash: $(APP_DIR)/$(OBJ_DIR)/libchash.o

grid: $(APP_DIR)/$(OBJ_DIR)/grid.o

graphAdjLinkedList: $(APP_DIR)/$(OBJ_DIR)/graphAdjLinkedList.o

graphAdjArrayList: $(APP_DIR)/$(OBJ_DIR)/graphAdjArrayList.o

graphGrid: $(APP_DIR)/$(OBJ_DIR)/graphGrid.o

adjLinkedList: $(APP_DIR)/$(OBJ_DIR)/adjLinkedList.o

adjArrayList: $(APP_DIR)/$(OBJ_DIR)/adjArrayList.o

mt19937: $(APP_DIR)/$(OBJ_DIR)/mt19937.o

dynamicQueue: $(APP_DIR)/$(OBJ_DIR)/dynamicQueue.o

cluster: $(APP_DIR)/$(OBJ_DIR)/cluster.o

graphRun: $(APP_DIR)/$(OBJ_DIR)/graphRun.o

BFS: $(APP_DIR)/$(OBJ_DIR)/BFS.o

bellmanFord: $(APP_DIR)/$(OBJ_DIR)/bellmanFord.o

DFS: $(APP_DIR)/$(OBJ_DIR)/DFS.o

pageRank: $(APP_DIR)/$(OBJ_DIR)/pageRank.o

incrementalAggregation : $(APP_DIR)/$(OBJ_DIR)/incrementalAggregation.o
	
test: libchash bellmanFord incrementalAggregation cluster DFS arrayStack reorder fixedPoint sortRun mt19937 graphRun graphGrid grid graphAdjArrayList adjArrayList adjLinkedList dynamicQueue edgeList countsort radixsort vertex graphCSR graphAdjLinkedList timer progressbar myMalloc app bitmap arrayQueue BFS pageRank
	@echo 'linking $(GAPP) <- libchash.o DFS.o arrayStack.o reorder.o fixedPoint.o sortRun.o mt19937.o graphRun.o graphGrid.o grid.o graphAdjArrayList.o adjArrayList.o adjLinkedList.o graphCSR.o graphAdjLinkedList.o dynamicQueue.o edgeList.o countsort.o radixsort.o vertex.o timer.o bitmap.o progressbar.o arrayQueue.o BFS.o pageRank.o'
	@mkdir -p $(APP_DIR)/test
	@$(CC) $(APP_DIR)/$(OBJ_DIR)/$(GAPP).o 	\
	$(APP_DIR)/$(OBJ_DIR)/graphRun.o 		\
	$(APP_DIR)/$(OBJ_DIR)/reorder.o 		\
	$(APP_DIR)/$(OBJ_DIR)/libchash.o 		\
	$(APP_DIR)/$(OBJ_DIR)/bellmanFord.o 			\
	$(APP_DIR)/$(OBJ_DIR)/BFS.o 			\
	$(APP_DIR)/$(OBJ_DIR)/DFS.o 			\
	$(APP_DIR)/$(OBJ_DIR)/pageRank.o 		\
	$(APP_DIR)/$(OBJ_DIR)/incrementalAggregation.o 		\
	$(APP_DIR)/$(OBJ_DIR)/cluster.o 		\
	$(APP_DIR)/$(OBJ_DIR)/arrayQueue.o 		\
	$(APP_DIR)/$(OBJ_DIR)/arrayStack.o 		\
	$(APP_DIR)/$(OBJ_DIR)/bitmap.o 			\
	$(APP_DIR)/$(OBJ_DIR)/graphCSR.o 		\
	$(APP_DIR)/$(OBJ_DIR)/grid.o 			\
	$(APP_DIR)/$(OBJ_DIR)/graphAdjLinkedList.o 		\
	$(APP_DIR)/$(OBJ_DIR)/graphAdjArrayList.o 		\
	$(APP_DIR)/$(OBJ_DIR)/graphGrid.o 		\
	$(APP_DIR)/$(OBJ_DIR)/progressbar.o 	\
	$(APP_DIR)/$(OBJ_DIR)/fixedPoint.o 		\
	$(APP_DIR)/$(OBJ_DIR)/myMalloc.o 		\
	$(APP_DIR)/$(OBJ_DIR)/vertex.o 			\
	$(APP_DIR)/$(OBJ_DIR)/countsort.o 		\
	$(APP_DIR)/$(OBJ_DIR)/radixsort.o 		\
	$(APP_DIR)/$(OBJ_DIR)/sortRun.o 		\
	$(APP_DIR)/$(OBJ_DIR)/adjLinkedList.o 	\
	$(APP_DIR)/$(OBJ_DIR)/adjArrayList.o 	\
	$(APP_DIR)/$(OBJ_DIR)/dynamicQueue.o 	\
	$(APP_DIR)/$(OBJ_DIR)/timer.o 			\
	$(APP_DIR)/$(OBJ_DIR)/edgeList.o 		\
	$(APP_DIR)/$(OBJ_DIR)/mt19937.o 		\
	 -o $(APP_DIR)/test/$(GAPP)				\
	 $(CFLAGS)

test-capi: app-capi fixedPoint sortRun mt19937 graphRun graphGrid grid graphAdjArrayList adjArrayList adjLinkedList dynamicQueue edgeList countsort radixsort vertex graphCSR graphAdjLinkedList timer progressbar myMalloc bitmap arrayQueue BFS
	@echo 'linking $(GAPP) <- fixedPoint.o sortRun.o mt19937.o graphRun.o graphGrid.o grid.o graphAdjArrayList.o adjArrayList.o adjLinkedList.o graphCSR.o graphAdjLinkedList.o dynamicQueue.o edgeList.o countsort.o radixsort.o vertex.o timer.o bitmap.o progressbar.o arrayQueue.o BFS.o'
	@mkdir -p $(APP_DIR)/test
	@$(CC) $(APP_DIR)/$(OBJ_DIR)/$(GAPP)-capi.o 	\
	$(APP_DIR)/$(OBJ_DIR)/graphRun.o 		\
	$(APP_DIR)/$(OBJ_DIR)/reorder.o 		\
	$(APP_DIR)/$(OBJ_DIR)/BFS.o 			\
	$(APP_DIR)/$(OBJ_DIR)/DFS.o 			\
	$(APP_DIR)/$(OBJ_DIR)/pageRank.o 		\
	$(APP_DIR)/$(OBJ_DIR)/incrementalAggregation.o 		\
	$(APP_DIR)/$(OBJ_DIR)/cluster.o 		\
	$(APP_DIR)/$(OBJ_DIR)/arrayQueue.o 		\
	$(APP_DIR)/$(OBJ_DIR)/arrayStack.o 		\
	$(APP_DIR)/$(OBJ_DIR)/bitmap.o 			\
	$(APP_DIR)/$(OBJ_DIR)/graphCSR.o 		\
	$(APP_DIR)/$(OBJ_DIR)/grid.o 			\
	$(APP_DIR)/$(OBJ_DIR)/graphAdjLinkedList.o 		\
	$(APP_DIR)/$(OBJ_DIR)/graphAdjArrayList.o 		\
	$(APP_DIR)/$(OBJ_DIR)/graphGrid.o 		\
	$(APP_DIR)/$(OBJ_DIR)/progressbar.o 	\
	$(APP_DIR)/$(OBJ_DIR)/fixedPoint.o 		\
	$(APP_DIR)/$(OBJ_DIR)/myMalloc.o 		\
	$(APP_DIR)/$(OBJ_DIR)/vertex.o 			\
	$(APP_DIR)/$(OBJ_DIR)/countsort.o 		\
	$(APP_DIR)/$(OBJ_DIR)/radixsort.o 		\
	$(APP_DIR)/$(OBJ_DIR)/sortRun.o 		\
	$(APP_DIR)/$(OBJ_DIR)/adjLinkedList.o 	\
	$(APP_DIR)/$(OBJ_DIR)/adjArrayList.o 	\
	$(APP_DIR)/$(OBJ_DIR)/dynamicQueue.o 	\
	$(APP_DIR)/$(OBJ_DIR)/timer.o 			\
	$(APP_DIR)/$(OBJ_DIR)/edgeList.o 		\
	$(APP_DIR)/$(OBJ_DIR)/mt19937.o 		\
	$(PSLSE_LIBCXL_DIR)/libcxl.a 			\
	 -o $(APP_DIR)/test/$(GAPP)-capi		\
	$(CAPI) \
	$(CFLAGS) \

# Usage: ./main -f <graph file> -d [data structure] -a [algorithm] -r [root] -n [num threads] [-h -c -u -s -w]
 #  -a [algorithm] : [0]-BFS, [1]-Pagerank, [2]-SSSP, [3]-DFS [4]-IncrementalAggregation
 #  -d [data structure] : [0]-CSR, [1]-Grid, [2]-Adj LinkedList, [3]-Adj ArrayList [4-5] same order bitmap frontiers
 #  -r [root]: BFS, DFS, SSSP root
 #  -p [algorithm direction] [0-1]-push/pull [2-3]-push/pull fixed point arithmetic [4-6]-same order but using data driven
 #  -o [sorting algorithm] [0]-radix-src [1]-radix-src-dest [2]-count-src [3]-count-src-dst.
 #  -n [num threads] default:max number of threads the system has
 #  -i [num iterations] number of iterations for pagerank to converge [default:20]
 #  -t [num trials] number of random trials for each whole run [default:0]
 #  -e [epsilon/tolerance] tolerance value of for page rank [default:0.0001]
 #  -l [mode] lightweight reordering [default:0]-no-reordering [1]-pagerank-order [2]-in-degree [3]-out-degree [4]-in/out degree [5]-Rabbit  
 #  -c: read text format convert to bin file on load example:-f <graph file> -c




# fnameb = "../01_GraphDatasets/RMAT/RMAT-26"
# fnameb = "../01_GraphDatasets/RMAT/RMAT19"
# fnameb = "../01_GraphDatasets/RMAT/RMAT20"
# fnameb = "../01_GraphDatasets/RMAT/RMAT21"
# fnameb = "../01_GraphDatasets/RMAT/RMAT22"

fnameb = "../01_GraphDatasets/RMAT/RMAT20.wbin"
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
# root  = 19

# fnameb = "../01_GraphDatasets/facebook/facebook_combined.txt.wbin"
# root = 107
# root = 3120
# fnameb = "../01_GraphDatasets/wiki-vote/wiki-Vote.txt.bin"
# root = 428333
datastructure = 0
algorithm = 1
numThreads  = 8
iterations = 20
trials = 0
tolerance = 1e-8
sort = 0
pushpull = 1


convert: test
	./$(APP_DIR)/test/$(GAPP) -c -w -f $(fnameb)

run: test
	# ulimit -s unlimited 
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d $(datastructure) -a $(algorithm) -r $(root) -n $(numThreads) -i $(iterations) -o $(sort) -p $(pushpull) -t $(trials) -e $(tolerance) -l $(reorder)
	
run-bfs: test
	# ./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d 0 -a 0 -n $(numThreads) -t $(trials) #CSR with Qs
	# ./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d 1 -a 0 -n $(numThreads) -t $(trials) #Grid with Qs
	# ./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d 3 -a 0 -n $(numThreads) -t $(trials) #Linked array
	# ./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d 4 -a 0 -n $(numThreads) -t $(trials) #CSR with bitmap
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d 5 -a 0 -n $(numThreads) -t $(trials) #Grid with bitmaps

run-pr: test
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d $(datastructure) -a 1 -n $(numThreads) -i $(iterations) -e $(tolerance) -t $(trials) -p 0
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d $(datastructure) -a 1 -n $(numThreads) -i $(iterations) -e $(tolerance) -t $(trials) -p 1
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d $(datastructure) -a 1 -n $(numThreads) -i $(iterations) -e $(tolerance) -t $(trials) -p 2
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d $(datastructure) -a 1 -n $(numThreads) -i $(iterations) -e $(tolerance) -t $(trials) -p 3
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d $(datastructure) -a 1 -n $(numThreads) -i $(iterations) -e $(tolerance) -t $(trials) -p 4
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d $(datastructure) -a 1 -n $(numThreads) -i $(iterations) -e $(tolerance) -t $(trials) -p 5
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d $(datastructure) -a 1 -n $(numThreads) -i $(iterations) -e $(tolerance) -t $(trials) -p 6

run-sort: test
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d 0 -a -1 -n $(numThreads) -i 0 -o 0 #radix src
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d 0 -a -1 -n $(numThreads) -i 0 -o 1 #radix src-dst
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d 0 -a -1 -n $(numThreads) -i 0 -o 2 #count src
	./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d 0 -a -1 -n $(numThreads) -i 0 -o 3 #count src-dst

run-capi: test-capi
	./$(APP_DIR)/test/$(GAPP)-capi -f $(fnameb) -d $(datastructure) -a $(algorithm) -r $(root) -n $(numThreads) -i $(iterations)

debug: test	
	gdb ./$(APP_DIR)/test/$(GAPP)

debug-memory: test	
	valgrind --leak-check=full --show-leak-kinds=all ./$(APP_DIR)/test/$(GAPP) -f $(fnameb) -d $(datastructure) -a $(algorithm) -r $(root) -n $(numThreads) -i $(iterations)
	

profile: 


clean:
	@rm -fr $(APP_DIR)/graphCSR-build
	@rm -fr $(APP_DIR)/test
	@rm -fr $(APP_DIR)/sim-build
	@rm -f $(APP_DIR)/$(OBJ_DIR)/*
	@rm -f sim/modelsim.ini
	@rm -f sim/transcript
	@rm -f sim/vsim_stacktrace.vstf
	@rm -f sim/vsim.wlf
	@rm -rf sim/work
	@rm -f sim/debug.log
	@rm -f sim/gmon.out	 

