# globals
APP                = test_afu
GAPP               = test
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


# compilers
CPP               = c++
CC				  =gcc

INC = 	-I$(APP_DIR)/include/$(STRUCT_DIR)/ \
		-I$(APP_DIR)/include/$(ALGO_DIR)/ 	\
		-I$(APP_DIR)/include/$(TEST_DIR)/ 	\
		-I$(APP_DIR)/include/$(PREPRO_DIR)/ \
# flags
CFLAGS            = -O2 -Wall -m64 -g

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


$(APP_DIR)/$(OBJ_DIR)/radixsort.o: $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/radixsort.c $(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)/radixsort.h
	@echo 'making $(GAPP) <- radixsort.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/radixsort.o $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/radixsort.c

$(APP_DIR)/$(OBJ_DIR)/countsort.o: $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/countsort.c $(APP_DIR)/$(INC_DIR)/$(PREPRO_DIR)/countsort.h
	@echo 'making $(GAPP) <- countsort.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/countsort.o $(APP_DIR)/$(SRC_DIR)/$(PREPRO_DIR)/countsort.c

$(APP_DIR)/$(OBJ_DIR)/vertex.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/vertex.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/vertex.h
	@echo 'making $(GAPP) <- vertex.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/vertex.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/vertex.c

$(APP_DIR)/$(OBJ_DIR)/adjlist.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/adjlist.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/adjlist.h
	@echo 'making $(GAPP) <- adjlist.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/adjlist.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/adjlist.c

$(APP_DIR)/$(OBJ_DIR)/queue.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/queue.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/queue.h
	@echo 'making $(GAPP) <- queue.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/queue.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/queue.c

$(APP_DIR)/$(OBJ_DIR)/edgelist.o: $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/edgelist.c $(APP_DIR)/$(INC_DIR)/$(STRUCT_DIR)/edgelist.h
	@echo 'making $(GAPP) <- edgelist.o'
	@$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/edgelist.o $(APP_DIR)/$(SRC_DIR)/$(STRUCT_DIR)/edgelist.c

$(APP_DIR)/$(OBJ_DIR)/$(GAPP).o:
	@echo 'making $(GAPP) <- $(GAPP).o'
	@$(CC) $(CFLAGS) -c -o $(APP_DIR)/$(OBJ_DIR)/$(GAPP).o \
	$(APP_DIR)/$(SRC_DIR)/$(TEST_DIR)/$(GAPP).c \
	-I$(PSLSE_LIBCXL_DIR) \
	$(INC) \
	-I$(PSLSE_COMMON_DIR) 

graph: $(APP_DIR)/$(OBJ_DIR)/$(GAPP).o

vertex: $(APP_DIR)/$(OBJ_DIR)/vertex.o

countsort: $(APP_DIR)/$(OBJ_DIR)/countsort.o

radixsort: $(APP_DIR)/$(OBJ_DIR)/radixsort.o

edgelist: $(APP_DIR)/$(OBJ_DIR)/edgelist.o

graph: $(APP_DIR)/$(OBJ_DIR)/$(GAPP).o

adjlist: $(APP_DIR)/$(OBJ_DIR)/adjlist.o

queue: $(APP_DIR)/$(OBJ_DIR)/queue.o



test: adjlist graph queue edgelist countsort radixsort vertex graph
	@echo 'linking $(GAPP) <- adjlist.o graph.o queue.o edgelist.o countsort.o radixsort.o vertex.o'
	@mkdir -p $(APP_DIR)/test
	@$(CC) $(APP_DIR)/$(OBJ_DIR)/$(GAPP).o 	\
	$(APP_DIR)/$(OBJ_DIR)/vertex.o 			\
	$(APP_DIR)/$(OBJ_DIR)/countsort.o 		\
	$(APP_DIR)/$(OBJ_DIR)/radixsort.o 		\
	$(APP_DIR)/$(OBJ_DIR)/adjlist.o 		\
	$(APP_DIR)/$(OBJ_DIR)/queue.o 			\
	$(APP_DIR)/$(OBJ_DIR)/edgelist.o 		\
	$(PSLSE_LIBCXL_DIR)/libcxl.a 			\
	 -o $(APP_DIR)/test/$(GAPP)				\
	 -I$(PSLSE_COMMON_DIR) 					\
	 -I$(PSLSE_LIBCXL_DIR) 					\
	 -lrt -lpthread -D SIM 

clean:
	@rm -fr $(APP_DIR)/graph-build
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

