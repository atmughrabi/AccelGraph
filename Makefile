# globals
APP                = test_afu
GAPP               = test_afu

# dirs
PSLSE_DIR         = sim/pslse
PSLSE_COMMON_DIR  = sim/pslse/common
PSLSE_LIBCXL_DIR  = sim/pslse/libcxl
APP_DIR           = host/app
SRC_DIR           = src

# compilers
CPP               = c++
CC				  =gcc

# flags
CFLAGS            = -O3 -Wall -m64

pslse-build:
	cd $(PSLSE_DIR)/afu_driver/src && make clean && BIT32=y make
	cd $(PSLSE_DIR)/pslse && make clean && make DEBUG=1
	cd $(PSLSE_LIBCXL_DIR) && make clean && make

pslse-run:
	cd sim && ./pslse/pslse/pslse

sim-build:
	mkdir -p $(APP_DIR)/sim-build
	$(CC) $(APP_DIR)/$(SRC_DIR)/$(APP).c -o $(APP_DIR)/sim-build/$(APP) $(PSLSE_LIBCXL_DIR)/libcxl.a $(CFLAGS) -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -lrt -lpthread -D SIM

sim-run:
	cd sim && ../$(APP_DIR)/sim-build/$(APP) $(ARGS)

vsim-run:
	cd sim && vsim -do vsim.tcl

graph-build:
	mkdir -p $(APP_DIR)/graph-build
	$(CC) $(APP_DIR)/$(SRC_DIR)/$(APP).c -o $(APP_DIR)/graph-build/$(APP) $(PSLSE_LIBCXL_DIR)/libcxl.a $(CFLAGS) -I$(PSLSE_COMMON_DIR) -I$(PSLSE_LIBCXL_DIR) -lrt -lpthread -D SIM

