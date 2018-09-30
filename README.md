# Graph Processing Framework With OpenMP/CAPI/OpenCL

AFU framework for Graph Processing algorithms with CAPI connected FGPAs With OpenCL/Verilog/OpenMP

More info
* ~~Webinar: TO BE ADDED ~~  

* Slides: [ TO BE ADDED ]( TO BE ADDED )

**Please note the following;**

* **It is recommended to read the [CAPI Users Guide](http://www.nallatech.com/wp-content/uploads/IBM_CAPI_Users_Guide_1-2.pdf) before using this framework.**

* **For now there is very limited instructions and documentation, but this will all be added later. An example project file for the Nallatech P385-A7 card with the Altera Stratix V GX A7 FPGA will also be added later. The current Computing Unit (CU) implements a simple memcpy function.**

* **This framework runs in dedicated mode and was developed to be used with Ubuntu-Linux.**

## Overview

This will be added later.

## Organization

* `accelerator`
  * `lib` - System Verilog global packages
    * `functions.sv` - Helper functions
    * `psl.sv` - PSL constants and interface records
    * `wed.sv` - WED record and parse procedure
  * `pkg` - System Verilog packages
  * `rtl` - System Verilog architectures
    * `afu.sv` - PSL to AFU wrapper
    * `control.sv` - Framework control
    * `cu.sv` - Computing Unit - implements the actual AFU functionality
    * `dma.sv` - Direct Memory Access
    * `fifo.sv` - First-In-First-Out
    * `frame.sv` - AFU top level
    * `mmio.sv` - Memory-Mapped-Input-Output
    * `ram.sv` - Random-Access-Memory
* `host`
	* `app` - Host application sources
* `sim`
  * `pslse` - [PSL Simulation Engine](https://github.com/ibm-capi/pslse) sources
  * *`pslse.parms`* - PSLSE parameter file
  * *`pslse_server.dat`* - PSLSE server used by the host application to attach
  * *`shim_host.dat`* - Simulation host used by the PSLSE
  * *`vsim.tcl`* - Compilation and simulation script for vsim
  * *`wave.do`* - Wave script for vsim
* *`Makefile`* - Global makefile

## Details

This will be added later.

### AFU wrapper and Frame

### Control

### Memory-Mapped-Input-Output (MMIO)

### Direct Memory Access (DMA)

### Computing Unit (CU)

The Computing Unit (CU) implements the actual function of the AFU.

#### Work-Element-Descriptor (WED)

#### DMA procedures

The `dma_package` defines a number of procedures that can be used to communicate with the DMA. They will be updated soon to match the specifications in the slides.

##### Read procedures

##### Write procedures

## Simulation

The following instructions target ModelSim (vsim).

Starting from release 15.0 of Quartus II, the included [ModelSim-Altera Starter Edition](https://www.altera.com/products/design-software/model---simulation/modelsim-altera-software.html) (free) has mixed-language support, which is required for simulation of this framework with the current PSLSE.

It is assumed that the 32-bit version of vsim is installed in `/opt/altera/15.0/modelsim_ase/` and `/opt/altera/15.0/modelsim_ase/bin` is added to your PATH.

Please note that all listed `make` commands should be executed from the root of this project.

### Initial setup For FPGA Development With CAPI

1. Clone the repository. enter the directory and initialize the submodules
  ```bash
  git clone https://github.ncsu.edu/atmughra/CAPI-Graph.git
  cd CAPI-Graph
  git submodule update --init
  ```

2. Set your `VPI_USER_H_DIR` environment variable to point to the `include` directory of your simulator e.g.:
  ```bash
  export VPI_USER_H_DIR=/opt/altera/15.0/modelsim_ase/include
  ```

3. Build the [`PSLSE`](https://github.com/ibm-capi/pslse):
  ```bash
  make pslse-build
  ```
  This will build the PSLSE with the DEBUG flag and the AFU driver for a 32-bit simulator.

4. Build the host application for simulation:
  ```bash
  make sim-build
  ```

### Run simulation

1. Start the simulator:
  ```bash
  make vsim-run 
  ```

  This will start vsim and execute the `vsim.tcl` script, which will automatically compile the sources.

2. Start simulation:

  Use the following command in the vsim console to start the simulation.
  ```bash
  s
  ```

3. Open a new terminal and start the PSLSE:
  ```bash
  make pslse-run
  ```

4. Open a new terminal and run your host application. This will run your host application from the `sim` directory:
  ```bash
  make sim-run ARGS="<Algorithm>"
  ```

5. Wait for your host application to terminate then switch to the PSLSE terminal and kill (`CTRL+C`) the running PSLSE process to inspect the wave.

### Initial compilation for the Graph frame work with OpenMP

1. Clone the repository. enter the directory and initialize the submodules
  ```bash
 Usage: ./main -f <graph file> -d [data structure] -a [algorithm] -r [root] -n [num threads] [-u -s -w].
   -a [algorithm] : 0 bfs, 1 pagerank, 2 SSSP.
   -d [data structure] : 0 CSR, 1 Grid, 2 Adj Linked List, 3 Adj Array List [4-5] same order bitmap frontiers.
   -r [root]: BFS & SSSP root.
   -p [algorithm direction] 0 push 1 pull 2 push/pull.
   -n [num threads] default:max number of threads the system has.
   -i [num iterations] number of random trials [default:0].
   -t [num iterations] number of iterations for page rank random.
   -e [epsilon/tolerance ] tolerance value of for page rank [default:0.0001].
   -c: convert to bin file on load example:-f <graph file> -c.
   -u: create undirected on load => check graphConfig.h -> define DIRECTED 0 then recompile.
   -w: weighted input graph check graphConfig.h ->define WEIGHTED 1 then recompile.
   -s: symmetric graph, if not given set of incoming edges will be created . 
```

### Development

During development `vsim` can be kept running.

The `vsim.tcl` script also allows to quickly run the following commands again from the `vsim` console:
* `r` - Recompile the `HDL` source files
* `s` - Start the simulation
* `rs` - Recompile the `HDL` source files and restart the simulation

## FPGA build

This will be added later. A timing issue needs to be resolved first.
