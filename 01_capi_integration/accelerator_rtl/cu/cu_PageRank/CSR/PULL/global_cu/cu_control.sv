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

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered                      ;
	logic [      NUM_REQUESTS-1:0] submit                                           ;
	logic [      NUM_REQUESTS-1:0] requests                                         ;
	logic [      NUM_REQUESTS-1:0] ready                                            ;
	CommandBufferLine              read_command_buffer_arbiter_in [0:NUM_REQUESTS-1];
	CommandBufferLine              read_command_buffer_arbiter_out                  ;

	CommandBufferLine read_command_buffer_arbiter_out_cu0;
	CommandBufferLine read_command_buffer_arbiter_out_cu1;

	// vertex control variables

	//output latched
	CommandBufferLine write_command_out_graph_algorithm;
	ReadWriteDataLine write_data_0_out_graph_algorithm ;
	ReadWriteDataLine write_data_1_out_graph_algorithm ;

	//input lateched
	WEDInterface       wed_request_in_latched          ;
	ResponseBufferLine read_response_in_latched        ;
	ResponseBufferLine read_response_in_vertex_job     ;
	ResponseBufferLine read_response_in_graph_algorithm;

	BufferStatus write_buffer_status_latched;
	BufferStatus read_buffer_status_latched ;

	ResponseBufferLine write_response_in_graph_algorithm;
	ReadWriteDataLine  read_data_0_in_latched           ;
	ReadWriteDataLine  read_data_1_in_latched           ;

	ReadWriteDataLine read_data_0_in_vertex_job     ;
	ReadWriteDataLine read_data_0_in_graph_algorithm;
	ReadWriteDataLine read_data_1_in_vertex_job     ;
	ReadWriteDataLine read_data_1_in_graph_algorithm;

	cu_return_type cu_return_latched     ;
	logic [0:63]   cu_configure_latched  ;
	logic [0:63]   cu_configure_2_latched;

	logic                          done_algorithm                  ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done         ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done           ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_latched ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_latched   ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_total_latched;

	logic enabled                ;
	logic enabled_cmd            ;
	logic enabled_vertex_job     ;
	logic enabled_graph_algorithm;
	logic cu_ready               ;

	VertexInterface vertex_unfiltered        ;
	logic           vertex_request_filtered  ;
	logic           vertex_request_unfiltered;
	VertexInterface vertex_filtered          ;

	ResponseBufferLine prefetch_read_response_in_latched;
	CommandBufferLine  prefetch_read_command_out_latched;

	ResponseBufferLine prefetch_write_response_in_latched;
	CommandBufferLine  prefetch_write_command_out_latched;

	logic enabled_prefetch_read ;
	logic enabled_prefetch_write;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_read_command_out_latched  <= 0;
			prefetch_write_command_out_latched <= 0;
		end else begin
			prefetch_read_command_out_latched  <= 0;
			prefetch_write_command_out_latched <= 0;
		end
	end

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled                <= 0;
			enabled_vertex_job     <= 0;
			enabled_prefetch_read  <= 0;
			enabled_prefetch_write <= 0;
		end else begin
			enabled                 <= enabled_in;
			enabled_vertex_job      <= cu_ready;
			enabled_graph_algorithm <= cu_ready;
			enabled_cmd             <= cu_ready;
			// enabled_prefetch_read  <= cu_ready && cu_configure_latched[30];
			// enabled_prefetch_write <= cu_ready && cu_configure_latched[31];

			enabled_prefetch_read  <= 0;
			enabled_prefetch_write <= 0;
		end
	end

	assign cu_ready = (|cu_configure_latched) && wed_request_in_latched.valid;

////////////////////////////////////////////////////////////////////////////
//Done signal
//Final return value with done signal asserted.
//number of vertecies and edges processed returned
////////////////////////////////////////////////////////////////////////////a

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cu_return_latched <= 0;
			done_algorithm    <= 0;

		end else begin
			if(enabled_vertex_job)begin
				cu_return_latched.var1 <= vertex_job_counter_total_latched;
				cu_return_latched.var2 <= edge_job_counter_done_latched;
				done_algorithm         <= (wed_request_in_latched.payload.wed.num_vertices == vertex_job_counter_total_latched) && (wed_request_in_latched.payload.wed.num_edges == edge_job_counter_done_latched);
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cu_return                        <= 0;
			cu_status                        <= 0;
			cu_done                          <= 0;
			vertex_job_counter_done_latched  <= 0;
			edge_job_counter_done_latched    <= 0;
			vertex_job_counter_total_latched <= 0;
		end else begin
			if(enabled)begin
				cu_return                        <= cu_return_latched;
				cu_done                          <= done_algorithm;
				cu_status                        <= cu_configure_latched;
				vertex_job_counter_done_latched  <= vertex_job_counter_done;
				edge_job_counter_done_latched    <= edge_job_counter_done;
				vertex_job_counter_total_latched <= vertex_job_counter_done_latched + vertex_job_counter_filtered;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input output
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out                 <= 0;
			write_data_0_out                  <= 0;
			write_data_1_out                  <= 0;
			read_command_out                  <= 0;
			write_buffer_status_latched       <= 0;
			read_buffer_status_latched        <= 0;
			write_buffer_status_latched.empty <= 1;
			read_buffer_status_latched.empty  <= 1;
		end else begin
			if(enabled_cmd)begin
				write_command_out           <= write_command_out_graph_algorithm;
				write_data_0_out            <= write_data_0_out_graph_algorithm;
				write_data_1_out            <= write_data_1_out_graph_algorithm;
				read_command_out            <= read_command_buffer_arbiter_out;
				write_buffer_status_latched <= write_buffer_status;
				read_buffer_status_latched  <= read_buffer_status;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched            <= 0;
			read_response_in_latched          <= 0;
			write_response_in_graph_algorithm <= 0;
			read_data_0_in_latched            <= 0;
			read_data_1_in_latched            <= 0;
		end else begin
			if(enabled)begin
				wed_request_in_latched            <= wed_request_in;
				read_response_in_latched          <= read_response_in;
				write_response_in_graph_algorithm <= write_response_in;
				read_data_0_in_latched            <= read_data_0_in;
				read_data_1_in_latched            <= read_data_1_in;
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
//Drive Read Prefetch
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_read_response_in_latched <= 0;
			prefetch_read_command_out         <= 0;
		end else begin
			if(enabled_prefetch_read)begin
				prefetch_read_response_in_latched <= prefetch_read_response_in;
				prefetch_read_command_out         <= prefetch_read_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive Write Prefetch
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_write_response_in_latched <= 0;
			prefetch_write_command_out         <= 0;
		end else begin
			if(enabled_prefetch_write)begin
				prefetch_write_response_in_latched <= prefetch_write_response_in;
				prefetch_write_command_out         <= prefetch_write_command_out_latched;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//cu_vertex_control - graph algorithm compute units arbitration
//read commands / data read commands / read reponses
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//read response arbitration logic - input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_in_vertex_job      <= 0;
			read_response_in_graph_algorithm <= 0;
		end else begin
			if(enabled && read_response_in_latched.valid) begin
				case (read_response_in_latched.payload.cmd.cu_id)
					VERTEX_CONTROL_ID : begin
						read_response_in_vertex_job      <= read_response_in_latched;
						read_response_in_graph_algorithm <= 0;
					end
					default : begin
						read_response_in_graph_algorithm <= read_response_in_latched;
						read_response_in_vertex_job      <= 0;
					end
				endcase
			end else begin
				read_response_in_vertex_job      <= 0;
				read_response_in_graph_algorithm <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//read data request logic - input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_0_in_vertex_job      <= 0;
			read_data_0_in_graph_algorithm <= 0;
		end else begin
			if(enabled && read_data_0_in_latched.valid) begin
				case (read_data_0_in_latched.payload.cmd.cu_id)
					VERTEX_CONTROL_ID : begin
						read_data_0_in_vertex_job      <= read_data_0_in_latched;
						read_data_0_in_graph_algorithm <= 0;
					end
					default : begin
						read_data_0_in_graph_algorithm <= read_data_0_in_latched;
						read_data_0_in_vertex_job      <= 0;
					end
				endcase
			end else begin
				read_data_0_in_vertex_job      <= 0;
				read_data_0_in_graph_algorithm <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_1_in_vertex_job      <= 0;
			read_data_1_in_graph_algorithm <= 0;
		end else begin
			if(enabled && read_data_1_in_latched.valid) begin
				case (read_data_1_in_latched.payload.cmd.cu_id)
					VERTEX_CONTROL_ID : begin
						read_data_1_in_vertex_job      <= read_data_1_in_latched;
						read_data_1_in_graph_algorithm <= 0;
					end
					default : begin
						read_data_1_in_graph_algorithm <= read_data_1_in_latched;
						read_data_1_in_vertex_job      <= 0;
					end
				endcase
			end else begin
				read_data_1_in_vertex_job      <= 0;
				read_data_1_in_graph_algorithm <= 0;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//read Buffer arbitration logic
////////////////////////////////////////////////////////////////////////////

	assign submit[0] = read_command_buffer_arbiter_in[0].valid;
	assign submit[1] = read_command_buffer_arbiter_in[1].valid;

	assign read_command_buffer_arbiter_out_cu0 = read_command_buffer_arbiter_in[0];
	assign read_command_buffer_arbiter_out_cu1 = read_command_buffer_arbiter_in[1];

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_REQUESTS            ),
		.WIDTH       ($bits(CommandBufferLine))
	) read_command_buffer_arbiter_instant (
		.clock      (clock                          ),
		.rstn       (rstn                           ),
		.enabled    (enabled_vertex_job             ),
		.buffer_in  (read_command_buffer_arbiter_in ),
		.submit     (submit                         ),
		.requests   (requests                       ),
		.arbiter_out(read_command_buffer_arbiter_out),
		.ready      (ready                          )
	);

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control - vertex job queue generation
////////////////////////////////////////////////////////////////////////////

	cu_vertex_job_control cu_vertex_job_control_instant (
		.clock                   (clock                            ),
		.rstn                    (rstn                             ),
		.enabled_in              (enabled_vertex_job               ),
		.cu_configure            (cu_configure_latched             ),
		.wed_request_in          (wed_request_in_latched           ),
		.read_response_in        (read_response_in_vertex_job      ),
		.read_data_0_in          (read_data_0_in_vertex_job        ),
		.read_data_1_in          (read_data_1_in_vertex_job        ),
		.read_buffer_status      (read_buffer_status_latched       ),
		.vertex_request          (vertex_request_unfiltered        ),
		.read_command_bus_grant  (ready[0]                         ),
		.read_command_bus_request(requests[0]                      ),
		.read_command_out        (read_command_buffer_arbiter_in[0]),
		.vertex                  (vertex_unfiltered                )
	);

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control - vertex job queue filter
//if indegree(inverse outdegree) is zero don't push
////////////////////////////////////////////////////////////////////////////


	cu_vertex_job_filter cu_vertex_job_filter_instant (
		.clock                      (clock                      ),
		.rstn                       (rstn                       ),
		.enabled_in                 (enabled_vertex_job         ),
		.vertex_in                  (vertex_unfiltered          ),
		.vertex_request_filtered    (vertex_request_filtered    ),
		.vertex_request_unfiltered  (vertex_request_unfiltered  ),
		.vertex_out                 (vertex_filtered            ),
		.vertex_job_counter_filtered(vertex_job_counter_filtered)
	);


////////////////////////////////////////////////////////////////////////////
//graph algorithm compute units Pagerank
////////////////////////////////////////////////////////////////////////////

	cu_graph_algorithm_control #(.NUM_VERTEX_CU(NUM_VERTEX_CU_GLOBAL)) cu_graph_algorithm_control_instant (
		.clock                   (clock                            ),
		.rstn                    (rstn                             ),
		.enabled_in              (enabled_graph_algorithm          ),
		.cu_configure            (cu_configure_latched             ),
		.wed_request_in          (wed_request_in_latched           ),
		.read_response_in        (read_response_in_graph_algorithm ),
		.write_response_in       (write_response_in_graph_algorithm),
		.write_buffer_status     (write_buffer_status_latched      ),
		.read_data_0_in          (read_data_0_in_graph_algorithm   ),
		.read_data_1_in          (read_data_1_in_graph_algorithm   ),
		.read_buffer_status      (read_buffer_status_latched       ),
		.vertex_job              (vertex_filtered                  ),
		.read_command_bus_grant  (ready[1]                         ),
		.read_command_bus_request(requests[1]                      ),
		.read_command_out        (read_command_buffer_arbiter_in[1]),
		.write_command_out       (write_command_out_graph_algorithm),
		.write_data_0_out        (write_data_0_out_graph_algorithm ),
		.write_data_1_out        (write_data_1_out_graph_algorithm ),
		.vertex_job_request      (vertex_request_filtered          ),
		.vertex_job_counter_done (vertex_job_counter_done          ),
		.edge_job_counter_done   (edge_job_counter_done            )
	);

endmodule