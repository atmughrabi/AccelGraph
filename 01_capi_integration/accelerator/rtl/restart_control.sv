// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : restart_control.sv
// Create : 2019-11-05 08:05:09
// Revise : 2019-11-05 08:30:20
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_PKG::*;
import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module restart_control (
	input                     clock              , // Clock
	input                     enabled_in         ,
	input                     rstn               , // Asynchronous reset active low
	input  CommandBufferLine  command_arbiter_in ,
	input  logic [0:7]        command_tag_in     ,
	input  ResponseBufferLine restart_response_in,
	input  ResponseInterface  response_filtered  ,
	output CommandBufferLine  restart_command_out,
	output logic              restart_pending
);



////////////////////////////////////////////////////////////////////////////
// Tag -> CU bookeeping for outstanding commands in PSL
////////////////////////////////////////////////////////////////////////////

	ram #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(TAG_COUNT               )
	) outstanding_cmds_ram_instant (
		.clock   (clock   ),
		.we      (we      ),
		.wr_addr (wr_addr ),
		.data_in (data_in ),
		.rd_addr (rd_addr ),
		.data_out(data_out)
	);

endmodule