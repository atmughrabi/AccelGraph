// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_edge_data_write_control.sv
// Create : 2019-10-31 14:36:36
// Revise : 2019-10-31 16:14:05
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

mport GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_data_write_control  #(parameter CU_ID = 1)(
	input  logic             clock             , // Clock
	input  logic             rstn              ,
	input  logic             enabled_in        ,
	input  ReadWriteDataLine read_data_0_in    ,
	input  ReadWriteDataLine read_data_1_in    ,
	input  logic             edge_data_request ,
	output EdgeDataRead      edge_data
);





endmodule