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
// Revise : 2019-10-07 15:45:55
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
	output logic [0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum
);


	EdgeData edge_data_latched    ;
	EdgeData edge_data_accumulator;
	assign edge_data_request = ~data_buffer_status.empty;
	logic             enabled                  ;
	VertexInterface   vertex_job_latched       ;
	ReadWriteDataLine write_data_0_out_latched ;
	ReadWriteDataLine write_data_1_out_latched ;
	CommandBufferLine write_command_out_latched;

////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_data_0_out  <= 0;
			write_data_1_out  <= 0;
			write_command_out <= 0;
		end else begin
			if(enabled) begin
				write_data_0_out  <= write_data_0_out_latched;
				write_data_1_out  <= write_data_1_out_latched;
				write_command_out <= write_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_latched <= 0;
		end else begin
			if(enabled) begin
				vertex_job_latched <= vertex_job;
			end
		end
	end

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
				if(edge_data_latched.valid)begin
					edge_data_accumulator.valid <= 1;
					edge_data_accumulator.data  <= edge_data_accumulator.data + edge_data_latched.data;
				end

				if(edge_data_counter_accum == vertex_job_latched.inverse_out_degree && vertex_job_latched.valid)begin
					edge_data_accumulator <= 0;
				end
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//edge_data_accumulate counter
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_counter_accum   <= 0;
			write_command_out_latched <= 0;
			write_data_0_out_latched  <= 0;
			write_data_1_out_latched  <= 0;
		end else begin
			if (enabled) begin
				if(edge_data_latched.valid)
					edge_data_counter_accum <= edge_data_counter_accum + 1;
			end
			if(edge_data_counter_accum == vertex_job_latched.inverse_out_degree && vertex_job_latched.valid)begin
				edge_data_counter_accum <= 0;

				// write_command_out_latched.valid                <= 1'b1;
				// write_command_out_latched.command              <= READ_CL_NA;
				// // read_command_out_latched.command            <= READ_CL_S;
				// write_command_out_latched.address              <= wed_request_in_latched.wed.auxiliary2 + (vertex_job_latched.id << $clog2(DATA_SIZE));
				// write_command_out_latched.size                 <= DATA_SIZE;
				// write_command_out_latched.cmd.vertex_struct    <= WRITE_GRAPH_DATA;
				// write_command_out_latched.cmd.cacheline_offest <= (((vertex_job_latched.id << $clog2(DATA_SIZE)) & ADDRESS_MOD_MASK) >> $clog2(DATA_SIZE));
				// write_command_out_latched.cmd.cu_id            <= CU_ID;
				// write_command_out_latched.cmd.cmd_type         <= CMD_WRITE;

				// write_data_0_out_latched.valid <= 1'b1;
				// write_data_1_out_latched.valid <= 1'b1;

			end
		end
	end



endmodule