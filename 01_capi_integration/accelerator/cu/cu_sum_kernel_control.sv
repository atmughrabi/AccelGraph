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
// Revise : 2019-10-07 02:25:28
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_sum_kernel_control #(parameter CU_ID = 1) (
	input  logic                        clock                  , // Clock
	input  logic                        rstn                   ,
	input  logic                        enabled_in             ,
	input  WEDInterface                 wed_request_in         ,
	input  ResponseBufferLine           write_response_in      ,
	input  BufferStatus                 write_buffer_status    ,
	input  EdgeData                     edge_data              ,
	input  BufferStatus                 data_buffer_status     ,
	output logic                        edge_data_request      ,
	output ReadWriteDataLine            write_data_0_out       ,
	output ReadWriteDataLine            write_data_1_out       ,
	output CommandBufferLine            write_command_out      ,
	input  VertexInterface              vertex_job             ,
	output logic [0:(EDGE_SIZE_BITS-1)] edge_data_counter_pushed
);


	EdgeData edge_data_latched    ;
	EdgeData edge_data_accumulator;
	assign edge_data_request = ~data_buffer_status.empty;
	logic enabled;

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled <= 0;
		end else begin
			enabled <= enabled_in;
		end
	end

////////////////////////////////////////////////////////////////////////////
//edge_data_latched
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_latched <= 0;
		end else begin
			if (enabled) begin
				if(edge_data.valid)
					edge_data_latched <= edge_data;
				else
					edge_data_latched <= 0;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//edge_data_accumulate
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_accumulator <= 0;
		end else begin
			if (enabled) begin
				if(edge_data.valid)
					edge_data_accumulator.data <= edge_data_accumulator.data + edge_data_latched.data;
			end
		end
	end


endmodule