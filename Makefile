# globals
APP                = test_afu
GAPP               = test

# dirs
PSLSE_DIR         = sim/pslse
PSLSE_COMMON_DIR  = sim/pslse/common
PSLSE_LIBCXL_DIR  = sim/pslse/libcxl
APP_DIR           = host/app
SRC_DIR           = src
OBJ_DIR			  = obj
INC_DIR			  = include

# compilers
CPP               = c++
CC				  =gcc

INC = -I$(APP_DIR)/include
# flags
CFLAGS            = -O3 -Wall -m64 -g

all: graph-build

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

$(APP_DIR)/$(OBJ_DIR)/adjlist.o: $(APP_DIR)/$(SRC_DIR)/adjlist.c $(APP_DIR)/$(INC_DIR)/adjlist.h
	$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/adjlist.o $(APP_DIR)/$(SRC_DIR)/adjlist.c

$(APP_DIR)/$(OBJ_DIR)/queue.o: $(APP_DIR)/$(SRC_DIR)/queue.c $(APP_DIR)/$(INC_DIR)/queue.h
	$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/queue.o $(APP_DIR)/$(SRC_DIR)/queue.c

$(APP_DIR)/$(OBJ_DIR)/edgelist.o: $(APP_DIR)/$(SRC_DIR)/edgelist.c $(APP_DIR)/$(INC_DIR)/edgelist.h
	$(CC) $(CFLAGS) $(INC) -c -o $(APP_DIR)/$(OBJ_DIR)/edgelist.o $(APP_DIR)/$(SRC_DIR)/edgelist.c

$(APP_DIR)/$(OBJ_DIR)/$(GAPP).o:
	$(CC) $(CFLAGS) -c -o $(APP_DIR)/$(OBJ_DIR)/$(GAPP).o \
	$(APP_DIR)/$(SRC_DIR)/$(GAPP).c \
	-I$(PSLSE_LIBCXL_DIR) \
	-I$(APP_DIR)/include \
	-I$(PSLSE_COMMON_DIR) 



edgelist: $(APP_DIR)/$(OBJ_DIR)/edgelist.o

graph: $(APP_DIR)/$(OBJ_DIR)/$(GAPP).o

adjlist: $(APP_DIR)/$(OBJ_DIR)/adjlist.o

queue: $(APP_DIR)/$(OBJ_DIR)/queue.o

graph-build: adjlist graph queue edgelist
	mkdir -p $(APP_DIR)/graph-build
	$(CC) $(APP_DIR)/$(OBJ_DIR)/$(GAPP).o \
	$(APP_DIR)/$(OBJ_DIR)/adjlist.o \
	$(APP_DIR)/$(OBJ_DIR)/queue.o \
	$(APP_DIR)/$(OBJ_DIR)/edgelist.o \
	$(PSLSE_LIBCXL_DIR)/libcxl.a \
	 -o $(APP_DIR)/graph-build/$(GAPP)\
	 -I$(PSLSE_COMMON_DIR) \
	 -I$(PSLSE_LIBCXL_DIR) \
	 -lrt -lpthread -D SIM 

clean:
	@rm -fr $(APP_DIR)/graph-build
	@rm -fr $(APP_DIR)/sim-build
	@rm -f $(APP_DIR)/$(OBJ_DIR)/*
	@rm -f sim/modelsim.ini
	@rm -f sim/transcript
	@rm -f sim/vsim_stacktrace.vstf
	@rm -f sim/vsim.wlf
	@rm -rf sim/work
	@rm -f sim/debug.log
	@rm -f sim/gmon.out	 

