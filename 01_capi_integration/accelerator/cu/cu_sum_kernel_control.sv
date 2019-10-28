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
// Revise : 2019-10-28 05:42:54
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_sum_kernel_control #(parameter CU_ID = 1) (
	input  logic                          clock                           , // Clock
	input  logic                          rstn                            ,
	input  logic                          enabled_in                      ,
	input  WEDInterface                   wed_request_in                  ,
	input  ResponseBufferLine             write_response_in               ,
	input  BufferStatus                   write_buffer_status             ,
	input  EdgeDataRead                   edge_data                       ,
	input  BufferStatus                   data_buffer_status              ,
	output logic                          edge_data_request               ,
	output ReadWriteDataLine              write_data_0_out                ,
	output ReadWriteDataLine              write_data_1_out                ,
	output CommandBufferLine              write_command_out               ,
	input  VertexInterface                vertex_job                      ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_resp         ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum         ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum_internal
);


	EdgeDataRead      edge_data_latched        ;
	EdgeDataWrite     edge_data_accumulator    ;
	CommandTagLine    cmd                      ;
	logic             enabled                  ;
	VertexInterface   vertex_job_latched       ;
	ReadWriteDataLine write_data_0_out_latched ;
	ReadWriteDataLine write_data_1_out_latched ;
	CommandBufferLine write_command_out_latched;
	WEDInterface      wed_request_in_latched   ;
	logic [0:7]       offset_data              ;

////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////
	assign edge_data_request = ~data_buffer_status.empty;

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
			vertex_job_latched     <= 0;
			wed_request_in_latched <= 0;
		end else begin
			if(enabled) begin
				vertex_job_latched     <= vertex_job;
				wed_request_in_latched <= wed_request_in;
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
			edge_data_accumulator            <= 0;
			edge_data_counter_accum_internal <= 0;
		end else begin
			if (enabled) begin
				if(edge_data_latched.valid)begin
					edge_data_accumulator.valid      <= 1;
					edge_data_accumulator.data       <= edge_data_accumulator.data + edge_data_latched.data;
					edge_data_counter_accum_internal <= edge_data_counter_accum_internal +1;
				end

				if(edge_data_counter_accum_internal == vertex_job_latched.inverse_out_degree && vertex_job_latched.valid)begin
					edge_data_accumulator            <= 0;
					edge_data_counter_accum_internal <= 0;
				end
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//edge_data_accumulate counter
////////////////////////////////////////////////////////////////////////////

	always_comb begin
		cmd                  = 0;
		offset_data          = (((CACHELINE_SIZE >> ($clog2(DATA_SIZE_WRITE)+1))-1) & vertex_job_latched.id);
		cmd.vertex_struct    = WRITE_GRAPH_DATA;
		cmd.cacheline_offest = (((vertex_job_latched.id << $clog2(DATA_SIZE_WRITE)) & ADDRESS_DATA_WRITE_MOD_MASK) >> $clog2(DATA_SIZE_WRITE));
		cmd.cu_id            = CU_ID;
		cmd.cmd_type         = CMD_WRITE;
	end

	always_comb begin
		write_command_out_latched = 0;
		write_data_0_out_latched  = 0;
		write_data_1_out_latched  = 0;
		if(edge_data_counter_accum_internal == vertex_job_latched.inverse_out_degree && vertex_job_latched.valid)begin
			write_command_out_latched.valid   = edge_data_accumulator.valid;
			// write_command_out_latched.command = WRITE_NA;
			write_command_out_latched.command            <= WRITE_MS;
			write_command_out_latched.address = wed_request_in_latched.wed.auxiliary2 + (vertex_job_latched.id << $clog2(DATA_SIZE_WRITE));
			write_command_out_latched.size    = DATA_SIZE_WRITE;
			write_command_out_latched.cmd     = cmd;

			write_data_0_out_latched.valid                                                        = edge_data_accumulator.valid;
			write_data_0_out_latched.cmd                                                          = cmd;
			write_data_0_out_latched.data[offset_data*DATA_SIZE_WRITE_BITS+:DATA_SIZE_WRITE_BITS] = swap_endianness_data_write(edge_data_accumulator.data) ;

			write_data_1_out_latched.valid                                                        = edge_data_accumulator.valid;
			write_data_1_out_latched.cmd                                                          = cmd;
			write_data_1_out_latched.data[offset_data*DATA_SIZE_WRITE_BITS+:DATA_SIZE_WRITE_BITS] = swap_endianness_data_write(edge_data_accumulator.data) ;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_counter_accum <= 0;
		end else begin
			if (enabled) begin
				if(edge_data_latched.valid) begin
					edge_data_counter_accum <= edge_data_counter_accum + 1;
				end
			end
		end
	end


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_num_counter_resp <= 0;
		end else begin
			if (enabled) begin
				if(write_response_in.valid) begin
					vertex_num_counter_resp <= vertex_num_counter_resp + 1;
				end
			end
		end
	end

endmodule