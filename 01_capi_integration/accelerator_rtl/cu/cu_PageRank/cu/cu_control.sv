// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_control.sv
// Create : 2019-09-26 15:18:39
// Revise : 2019-11-07 19:49:13
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_control #(parameter NUM_REQUESTS = 2) (
	input  logic              clock                       , // Clock
	input  logic              rstn                        ,
	input  logic              enabled_in                  ,
	input  WEDInterface       wed_request_in              ,
	input  ResponseBufferLine read_response_in            ,
	input  ResponseBufferLine prefetch_read_response_in   ,
	input  ResponseBufferLine prefetch_write_response_in  ,
	input  ResponseBufferLine write_response_in           ,
	input  ReadWriteDataLine  read_data_0_in              ,
	input  ReadWriteDataLine  read_data_1_in              ,
	input  BufferStatus       read_buffer_status          ,
	input  BufferStatus       prefetch_read_buffer_status ,
	input  BufferStatus       prefetch_write_buffer_status,
	input  BufferStatus       write_buffer_status         ,
	input  cu_configure_type  cu_configure                ,
	output cu_return_type     cu_return                   ,
	output logic              cu_done                     ,
	output logic [0:63]       cu_status                   ,
	output CommandBufferLine  read_command_out            ,
	output CommandBufferLine  prefetch_read_command_out   ,
	output CommandBufferLine  prefetch_write_command_out  ,
	output CommandBufferLine  write_command_out           ,
	output ReadWriteDataLine  write_data_0_out            ,
	output ReadWriteDataLine  write_data_1_out
);
	// vertex control variables


	BufferStatus    vertex_buffer_status;
	VertexInterface vertex_job          ;
	logic           vertex_job_request  ;

	//output latched
	CommandBufferLine write_command_out_latched;
	ReadWriteDataLine write_data_0_out_latched ;
	ReadWriteDataLine write_data_1_out_latched ;
	CommandBufferLine read_command_out_latched ;

	CommandBufferLine read_command_out_vertex          ;

	//input lateched
	WEDInterface       wed_request_in_latched       ;
	ResponseBufferLine read_response_in_latched     ;

	ResponseBufferLine write_response_in_latched  ;
	ReadWriteDataLine  read_data_0_in_latched     ;
	ReadWriteDataLine  read_data_1_in_latched     ;

	cu_return_type cu_return_latched     ;
	logic [0:63]   cu_configure_latched  ;
	logic [0:63]   cu_configure_2_latched;

	logic done_algorithm;


	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done    ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done      ;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered_latched;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_latched    ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_latched      ;

	logic enabled           ;
	logic enabled_vertex_job;
	CommandBufferLine burst_command_buffer_out      ;
	logic             cu_ready                      ;

	ResponseBufferLine prefetch_read_response_in_latched;
	CommandBufferLine  prefetch_read_command_out_latched;

	ResponseBufferLine prefetch_write_response_in_latched;
	CommandBufferLine  prefetch_write_command_out_latched;

	logic enabled_prefetch_read ;
	logic enabled_prefetch_write;

	assign prefetch_read_command_out_latched  = 0;
	assign prefetch_write_command_out_latched = 0;
	assign write_command_out_latched = 0;
	assign write_data_0_out_latched = 0;
	assign write_data_1_out_latched = 0;

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled            <= 0;
			enabled_vertex_job <= 0;
		end else begin
			enabled            <= enabled_in;
			enabled_vertex_job <= cu_ready;
		end
	end

	assign cu_ready = (|cu_configure_latched) && wed_request_in_latched.valid;

////////////////////////////////////////////////////////////////////////////
//Done signal
//Final return value with done signal asserted.
////////////////////////////////////////////////////////////////////////////a

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cu_return_latched <= 0;
			done_algorithm    <= 0;
		end else begin
			if(wed_request_in_latched.valid)begin
				cu_return_latched.var1 <= {(vertex_job_counter_filtered+vertex_job_counter_done)};
				cu_return_latched.var2 <= {edge_job_counter_done_latched};
				done_algorithm         <= (wed_request_in_latched.wed.num_vertices == (vertex_job_counter_filtered_latched+vertex_job_counter_done_latched)) &&
					(wed_request_in_latched.wed.num_edges == edge_job_counter_done_latched);
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cu_return                           <= 0;
			cu_status                           <= 0;
			cu_done                             <= 0;
			vertex_job_counter_filtered_latched <= 0;
			vertex_job_counter_done_latched     <= 0;
			edge_job_counter_done_latched       <= 0;
		end else begin
			if(enabled)begin
				cu_return                           <= cu_return_latched;
				cu_done                             <= done_algorithm;
				cu_status                           <= cu_configure_latched;
				vertex_job_counter_filtered_latched <= vertex_job_counter_filtered;
				vertex_job_counter_done_latched     <= vertex_job_counter_done;
				edge_job_counter_done_latched       <= edge_job_counter_done;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input output
////////////////////////////////////////////////////////////////////////////

	assign read_command_out_latched = burst_command_buffer_out;



	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out <= 0;
			write_data_0_out  <= 0;
			write_data_1_out  <= 0;
			read_command_out  <= 0;
		end else begin
			if(enabled)begin
				write_command_out <= write_command_out_latched;
				write_data_0_out  <= write_data_0_out_latched;
				write_data_1_out  <= write_data_1_out_latched;
				read_command_out  <= read_command_out_vertex;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched    <= 0;
			read_response_in_latched  <= 0;
			write_response_in_latched <= 0;
			read_data_0_in_latched    <= 0;
			read_data_1_in_latched    <= 0;
		end else begin
			if(enabled)begin
				wed_request_in_latched    <= wed_request_in;
				read_response_in_latched  <= read_response_in;
				write_response_in_latched <= write_response_in;
				read_data_0_in_latched    <= read_data_0_in;
				read_data_1_in_latched    <= read_data_1_in;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cu_configure_latched   <= 0;
			cu_configure_2_latched <= 0;
		end else begin
			if(enabled)begin
				if((|cu_configure.var1))
					cu_configure_latched <= cu_configure.var1;

				if((|cu_configure.var2))
					cu_configure_2_latched <= cu_configure.var2;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//Prefetch Stream
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled_prefetch_read  <= 0;
			enabled_prefetch_write <= 0;
		end else begin
			if(enabled) begin
				// enabled_prefetch_read  <= cu_ready && cu_configure_latched[30];
				// enabled_prefetch_write <= cu_ready && cu_configure_latched[31];

				enabled_prefetch_read  <= 0;
				enabled_prefetch_write <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_read_response_in_latched <= 0;
		end else begin
			if(enabled_prefetch_read)begin
				prefetch_read_response_in_latched <= prefetch_read_response_in;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive output
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_read_command_out <= 0;
		end else begin
			if(enabled_prefetch_read)begin
				prefetch_read_command_out <= prefetch_read_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_write_response_in_latched <= 0;
		end else begin
			if(enabled_prefetch_write)begin
				prefetch_write_response_in_latched <= prefetch_write_response_in;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive output write prefetch
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_write_command_out <= 0;
		end else begin
			if(enabled_prefetch_write)begin
				prefetch_write_command_out <= prefetch_write_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control - vertex job queue
////////////////////////////////////////////////////////////////////////////

	cu_vertex_job_control cu_vertex_job_control_instant (
		.clock                      (clock                      ),
		.rstn                       (rstn                       ),
		.enabled_in                 (enabled_vertex_job         ),
		.cu_configure               (cu_configure_latched       ),
		.wed_request_in             (wed_request_in_latched     ),
		.read_response_in           (read_response_in_latched   ),
		.read_data_0_in             (read_data_0_in_latched     ),
		.read_data_1_in             (read_data_1_in_latched     ),
		.read_buffer_status         (read_buffer_status         ),
		.vertex_request             (vertex_job_request         ),
		.read_command_out           (read_command_out_vertex    ),
		.vertex_buffer_status       (vertex_buffer_status       ),
		.vertex                     (vertex_job                 ),
		.vertex_job_counter_filtered(vertex_job_counter_filtered),
		.vertex_job_counter         (vertex_job_counter_done    ),
		.edge_job_counter_filtered  (edge_job_counter_done      )
	);

	assign vertex_job_request = (~vertex_buffer_status.empty);


endmodule