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
// Revise : 2019-11-02 22:49:09
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


	EdgeDataRead      edge_data_latched          ;
	EdgeDataWrite     edge_data_accumulator      ;
	EdgeDataWrite     edge_data_accumulator_latch;
	logic             enabled                    ;
	VertexInterface   vertex_job_latched         ;
	ReadWriteDataLine write_data_0_out_latched   ;
	ReadWriteDataLine write_data_1_out_latched   ;
	CommandBufferLine write_command_out_latched  ;
	WEDInterface      wed_request_in_latched     ;

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
			edge_data_accumulator_latch      <= 0;
		end else begin
			if (enabled) begin
				if(edge_data_latched.valid)begin
					edge_data_accumulator.valid      <= 1;
					edge_data_accumulator.index      <= vertex_job_latched.id;
					edge_data_accumulator.cu_id      <= CU_ID;
					edge_data_accumulator.data       <= edge_data_accumulator.data + edge_data_latched.data;
					edge_data_counter_accum_internal <= edge_data_counter_accum_internal + 1;
				end

				if(edge_data_counter_accum_internal == vertex_job_latched.inverse_out_degree && vertex_job_latched.valid)begin
					edge_data_accumulator            <= 0;
					edge_data_counter_accum_internal <= 0;
					edge_data_accumulator_latch      <= edge_data_accumulator;
				end else begin
					edge_data_accumulator_latch <= 0;
				end
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//edge_data_accumulate send wrtie request
////////////////////////////////////////////////////////////////////////////

	cu_edge_data_write_control #(.CU_ID(CU_ID)) cu_edge_data_write_control_instant (
		.clock            (clock                      ),
		.rstn             (rstn                       ),
		.enabled_in       (enabled                    ),
		.wed_request_in   (wed_request_in_latched     ),
		.edge_data_write  (edge_data_accumulator_latch),
		.write_data_0_out (write_data_0_out_latched   ),
		.write_data_1_out (write_data_1_out_latched   ),
		.write_command_out(write_command_out_latched  )
	);

////////////////////////////////////////////////////////////////////////////
//counter trackings
////////////////////////////////////////////////////////////////////////////

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