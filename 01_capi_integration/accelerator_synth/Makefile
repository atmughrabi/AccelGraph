########################################################################
##
## Copyright 2015 PMC-Sierra, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License. You may
## obtain a copy of the License at
## http://www.apache.org/licenses/LICENSE-2.0 Unless required by
## applicable law or agreed to in writing, software distributed under the
## License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
## CONDITIONS OF ANY KIND, either express or implied. See the License for
## the specific language governing permissions and limitations under the
## License.
##
########################################################################

########################################################################
##
##   Author: Logan Gunthorpe
##
##   Description:
##     Makefile which invokes Quartus to synthesize the FPGA
##
########################################################################


ALTERA_PART?=5SGXMA7H2F35C2
PROJECT ?= accel-graph

DATA_STRUCTURES ?= 0
ALGORITHMS 		?= 1
PULL_PUSH 		?= 2
NUM_THREADS  	?= 25
SCRIPT_DIR   	?= ../../03_scripts
CU_SET_SYNTH 	?= $(shell python ./$(SCRIPT_DIR)/choose_algorithm_synth.py $(DATA_STRUCTURES) $(ALGORITHMS) $(PULL_PUSH))

CU_GRAPH_ALGORITHM ?= $(word 1, $(CU_SET_SYNTH))
CU_DATA_STRUCTURE ?=  $(word 2, $(CU_SET_SYNTH))
CU_DIRECTION ?=       $(word 3, $(CU_SET_SYNTH))
CU_PRECISION ?= 	  $(word 4, $(CU_SET_SYNTH))

SYNTH_DIR ?= synthesize_$(CU_GRAPH_ALGORITHM)_$(CU_DATA_STRUCTURE)_$(CU_DIRECTION)_$(CU_PRECISION)_CU$(NUM_THREADS)

VERSION_GIT ?= $(shell python ./capi/scripts/version.py)
TIME_STAMP ?= $(shell date +%Y_%m_%d_%H_%M_%S)
ACCEL_RTL_DIR = accelerator_rtl
ACCEL_BIN_DIR = accelerator_bin
SOURCE_FILES =  $(wildcard ../$(ACCEL_RTL_DIR)/afu/*.vhdl) $(wildcard ../$(ACCEL_RTL_DIR)/afu/*.vhd) $(wildcard ../$(ACCEL_RTL_DIR)/afu/*.v) $(wildcard ../$(ACCEL_RTL_DIR)/afu/*.sv)   \
				$(wildcard ../$(ACCEL_RTL_DIR)/pkg/*.vhdl) $(wildcard ../$(ACCEL_RTL_DIR)/pkg/*.vhd) $(wildcard ../$(ACCEL_RTL_DIR)/pkg/*.v) $(wildcard ../$(ACCEL_RTL_DIR)/pkg/*.sv)   \
				$(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/global_cu/*.vhdl) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/global_cu/*.vhd) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/global_cu/*.v) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/global_cu/*.sv)\
				$(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/global_pkg/*.vhdl) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/global_pkg/*.vhd) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/global_pkg/*.v) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/global_pkg/*.sv)\
				$(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/$(CU_PRECISION)/cu/*.vhdl) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/$(CU_PRECISION)/cu/*.vhd) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/$(CU_PRECISION)/cu/*.v) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/$(CU_PRECISION)/cu/*.sv)\
				$(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/$(CU_PRECISION)/pkg/*.vhdl) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/$(CU_PRECISION)/pkg/*.vhd) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/$(CU_PRECISION)/pkg/*.v) $(wildcard ../$(ACCEL_RTL_DIR)/cu/$(CU_GRAPH_ALGORITHM)/$(CU_DATA_STRUCTURE)/$(CU_DIRECTION)/$(CU_PRECISION)/pkg/*.sv)     


export LM_LICENSE_FILE := $(LM_LICENSE_FILE):$(shell pwd)/psl_fpga/psl/psl_A000_license.dat

###################################################################
# Project Configuration:
# Specify the name of the design (project), the Quartus II Settings
# File (.qsf), and the list of source files used.
###################################################################

ASSIGNMENT_FILES = $(PROJECT).qpf $(PROJECT).qsf

###################################################################
# Main Targets #
# all: build everything
# clean: remove output files and database
###################################################################

default:rbf
all: rbf smart.log $(PROJECT).asm.rpt $(PROJECT).sta.rpt $(PROJECT).pow.rpt

clean:
	rm -rf *~ ./tcl/*~ *.rpt *.chg smart.log *.htm *.eqn *.pin *.sof *.pof db dse seed_rpt *.summary *.qpf *.qsf incremental_db *.smsg *.done *~ *.txt *.qxp *.bsf *.qarlog *.cmp *.v *.rbf nohup.out *.log hc_output reconfig_mif *.jdi *.qdf *.sld *.qws .qsys_edit *.xml

map: smart.log $(PROJECT).map.rpt
fit: smart.log $(PROJECT).fit.rpt
asm: smart.log $(PROJECT).asm.rpt
sta: smart.log $(PROJECT).sta.rpt
pow: smart.log $(PROJECT).pow.rpt
qxp: smart.log $(PROJECT).qxp
rbf: smart.log $(PROJECT).rbf

smart: smart.log

###################################################################
# Executable Configuration
###################################################################
MAP_ARGS = --family=StratixV --part=$(ALTERA_PART)
FIT_ARGS = --part=$(ALTERA_PART)
ASM_ARGS =
POW_ARGS =
STA_ARGS = --do_report_timing

###################################################################
# Target implementations
###################################################################
STAMP = echo done >

$(PROJECT).map.rpt: map.chg $(SOURCE_FILES) | $(ASSIGNMENT_FILES)
	quartus_map --64bit $(MAP_ARGS) $(PROJECT)
	$(STAMP) merge.chg

$(PROJECT).merge.rpt: merge.chg $(PROJECT).map.rpt
	quartus_cdb --64bit --merge $(PROJECT)
	$(STAMP) fit.chg

$(PROJECT).fit.rpt: fit.chg $(PROJECT).merge.rpt
	quartus_fit --64bit $(FIT_ARGS) $(PROJECT)
	$(STAMP) asm.chg $(STAMP) sta.chg

$(PROJECT).asm.rpt $(PROJECT).sof: asm.chg $(PROJECT).fit.rpt
	quartus_asm --64bit $(ASM_ARGS) $(PROJECT)

$(PROJECT).sta.rpt: sta.chg $(PROJECT).fit.rpt
	quartus_sta --64bit $(STA_ARGS) $(PROJECT)

$(PROJECT).pow.rpt: pow.chg $(PROJECT).asm.rpt
	quartus_pow --64bit $(POW_ARGS) $(PROJECT)

$(PROJECT).rbf: $(PROJECT).asm.rpt
	quartus_cpf --64bit -c $(PROJECT).sof $(PROJECT).rbf &&\
	cp $(PROJECT).rbf ../$(ACCEL_BIN_DIR)/$(PROJECT)_$(CU_GRAPH_ALGORITHM)_$(CU_DATA_STRUCTURE)_$(CU_DIRECTION)_$(CU_PRECISION)_$(VERSION_GIT)_$(TIME_STAMP).rbf 

smart.log: $(ASSIGNMENT_FILES)
	quartus_sh --64bit --determine_smart_action $(PROJECT) > smart.log

###################################################################
# QXP File (uses scripts)
###################################################################

$(PROJECT).qxp: $(PROJECT).map.rpt
	./top_qxp_export.sh
	mv $(PROJECT).qxp ../Qxp/

###################################################################
# Project initialization
###################################################################

$(ASSIGNMENT_FILES): $(PROJECT).tcl ./capi/fpga/*.tcl
	quartus_sh -t  $(PROJECT).tcl $(CU_SET_SYNTH) $(NUM_THREADS)
	quartus_sh --prepare $(PROJECT)
	#quartus_stp $(PROJECT) --enable --logic_analyzer_interface --lai_file=probes.lai

map.chg:
	$(STAMP) map.chg
fit.chg:
	$(STAMP) fit.chg
sta.chg:
	$(STAMP) sta.chg
asm.chg:
	$(STAMP) asm.chg
pow.chg:
	$(STAMP) pow.chg
merge.chg:
	$(STAMP) merge.chg
sweep.chg:
	$(STAMP) sweep.chg

.PHONY:program
program: $(PROJECT).sof
	quartus_pgm -c "USB-Blaster on cgy1-flash.pmc-sierra.internal" -m jtag -o S\;EPM2210 -o P\;$<
	
.PHONY:gen-rbf
gen-rbf:
	quartus_cpf --64bit -c $(PROJECT).sof $(PROJECT).rbf &&\
	cp $(PROJECT).rbf ../$(ACCEL_BIN_DIR)/$(PROJECT)_$(CU_GRAPH_ALGORITHM)_$(CU_DATA_STRUCTURE)_$(CU_DIRECTION)_$(CU_PRECISION)_$(VERSION_GIT)_$(TIME_STAMP).rbf 

.PHONY:copy-rbf
copy-rbf:
	cp $(PROJECT).rbf ../$(ACCEL_BIN_DIR)/$(PROJECT)_$(CU_GRAPH_ALGORITHM)_$(CU_DATA_STRUCTURE)_$(CU_DIRECTION)_$(CU_PRECISION)_$(VERSION_GIT)_$(TIME_STAMP).rbf 

.PHONY:stats
stats:
	altera_stats.py $(PROJECT)

.PHONY:gui
gui: $(ASSIGNMENT_FILES)
	quartus $(PROJECT).qpf 

.PHONY:sweep 
sweep: sweep.chg $(PROJECT).merge.rpt
	quartus_sh --64bit -t sweep.tcl $(CU_SET_SYNTH) $(NUM_THREADS)
