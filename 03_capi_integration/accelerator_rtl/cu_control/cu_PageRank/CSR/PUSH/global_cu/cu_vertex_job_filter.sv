// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_vertex_job_filter.sv
// Create : 2019-09-26 15:19:30
// Revise : 2019-11-08 10:50:37
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_job_filter (
	input  logic                          clock                      , // Clock
	input  logic                          rstn                       ,
	input  logic                          enabled_in                 ,
	input  VertexInterface                vertex_in                  ,
	input  logic                          vertex_request_filtered    ,
	output logic                          vertex_request_unfiltered  ,
	output VertexInterface                vertex_out                 ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered
);

	logic        filter_vertex                    ;
	BufferStatus vertex_job_filtered_buffer_status;

	VertexInterface                vertex_in_latched                  ;
	logic                          vertex_request_filtered_latched    ;
	logic                          vertex_request_unfiltered_latched  ;
	VertexInterface                vertex_out_latched                 ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered_latched;

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
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_out                  <= 0;
			vertex_request_unfiltered   <= 0;
			vertex_job_counter_filtered <= 0;
		end else begin
			if(enabled) begin
				vertex_out                  <= vertex_out_latched;
				vertex_request_unfiltered   <= vertex_request_unfiltered_latched;
				vertex_job_counter_filtered <= vertex_job_counter_filtered_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_in_latched               <= 0;
			vertex_request_filtered_latched <= 0;
		end else begin
			if(enabled) begin
				vertex_in_latched               <= vertex_in;
				vertex_request_filtered_latched <= vertex_request_filtered;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Filter logic inputs
////////////////////////////////////////////////////////////////////////////

	assign filter_vertex = (vertex_in_latched.valid)   && (~(|vertex_in_latched.out_degree));
	assign push_vertex   = (vertex_in_latched.valid)   && ((|vertex_in_latched.out_degree));

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_counter_filtered_latched <= 0;
		end else begin
			if(filter_vertex) begin
				vertex_job_counter_filtered_latched <= vertex_job_counter_filtered_latched + 1;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Read Vertex double buffer
////////////////////////////////////////////////////////////////////////////
	assign vertex_job_filtered_pop           = vertex_request_filtered_latched && ~vertex_job_filtered_buffer_status.empty;
	assign vertex_request_unfiltered_latched = ~vertex_job_filtered_buffer_status.alfull;

	fifo #(
		.WIDTH($bits(VertexInterface)   ),
		.DEPTH(CU_VERTEX_JOB_BUFFER_SIZE)
	) vertex_job_filtered_buffer_fifo_instant (
		.clock   (clock                                   ),
		.rstn    (rstn                                    ),
		
		.push    (push_vertex                             ),
		.data_in (vertex_in_latched                       ),
		.full    (vertex_job_filtered_buffer_status.full  ),
		.alFull  (vertex_job_filtered_buffer_status.alfull),
		
		.pop     (vertex_job_filtered_pop                  ),
		.valid   (vertex_job_filtered_buffer_status.valid ),
		.data_out(vertex_out_latched                      ),
		.empty   (vertex_job_filtered_buffer_status.empty )
	);

endmodule