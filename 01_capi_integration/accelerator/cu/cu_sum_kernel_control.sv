// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_sum_kernel_control.sv
// Create : 2019-09-26 15:19:17
// Revise : 2019-10-06 23:07:04
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_sum_kernel_control #(parameter CU_ID = 1) (
	input  logic              clock              , // Clock
	input  logic              rstn               ,
	input  logic              enabled_in         ,
	input  WEDInterface       wed_request_in     ,
	input  ResponseBufferLine write_response_in  ,
	input  BufferStatus       write_buffer_status,
	input  EdgeData           edge_data          ,
	input  BufferStatus       data_buffer_status ,
	output logic              edge_data_request  ,
	output ReadWriteDataLine  write_data_0_out   ,
	output ReadWriteDataLine  write_data_1_out   ,
	output CommandBufferLine  write_command_out
);



	assign edge_data_request = 1;

endmodule