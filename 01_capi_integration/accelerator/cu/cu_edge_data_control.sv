// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_edge_data_control.sv
// Create : 2019-09-26 15:18:46
// Revise : 2019-10-02 14:14:17
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_data_control #(parameter CU_ID = 1) (
	input  logic                        clock                  , // Clock
	input  logic                        rstn                   ,
	input  logic                        enabled_in             ,
	input  ResponseBufferLine           read_response_in       ,
	input  ReadWriteDataLine            read_data_0_in         ,
	input  ReadWriteDataLine            read_data_1_in         ,
	input  BufferStatus                 read_buffer_status     ,
	input  VertexInterface              vertex_job             ,
	input  logic                        edge_data_request      ,
	input  EdgeInterface                edge_job               ,
	output logic                        edge_request           ,
	output CommandBufferLine            read_command_out       ,
	output BufferStatus                 data_buffer_status     ,
	output EdgeData                     edge_data              ,
	output logic [0:(EDGE_SIZE_BITS-1)] edge_job_counter_pulled
);

	//output latched
	EdgeInterface   edge_job_latched  ;
	EdgeData        edge_data_latched ;
	VertexInterface vertex_job_latched;
	//input lateched
	ResponseBufferLine read_response_in_latched;
	ReadWriteDataLine  read_data_0_in_latched  ;
	ReadWriteDataLine  read_data_1_in_latched  ;
	logic              edge_request_latched    ;

	CommandBufferLine read_command_out_latched       ;
	BufferStatus      read_buffer_status_internal    ;
	logic             read_command_job_edge_burst_pop;

	logic enabled                  ;
	logic edge_data_request_latched;

	assign edge_request_latched = 1; // request edges for Data job control

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
			edge_request <= 0;
		end else begin
			if(enabled) begin
				edge_request <= edge_request_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_in_latched  <= 0;
			read_data_0_in_latched    <= 0;
			read_data_1_in_latched    <= 0;
			edge_job_latched          <= 0;
			vertex_job_latched        <= 0;
			edge_data_request_latched <= 0;
		end else begin
			if(enabled) begin
				read_response_in_latched  <= read_response_in;
				read_data_0_in_latched    <= read_data_0_in;
				read_data_1_in_latched    <= read_data_1_in;
				edge_job_latched          <= edge_job;
				vertex_job_latched        <= vertex_job;
				edge_data_request_latched <= edge_data_request;
			end
		end
	end




// if the edge has no in/out neighbors don't schedule it
	assign push_edge = (edge_job_latched.valid);

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_job_counter_pulled <= 0;
		end else begin
			if(edge_job_latched.valid)begin
				if(push_edge)begin
					edge_job_counter_pulled <= edge_job_counter_pulled + 1;
				end
				if(edge_job_counter_pulled == vertex_job_latched.inverse_out_degree)begin
					edge_job_counter_pulled <= 0;
				end
			end
		end
	end

endmodule