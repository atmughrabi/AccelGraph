// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_graph_algorithm_control.sv
// Create : 2019-09-26 15:19:08
// Revise : 2019-11-07 18:11:05
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_graph_algorithm_control #(parameter NUM_VERTEX_CU = NUM_VERTEX_CU_GLOBAL) (
	input  logic                          clock                   , // Clock
	input  logic                          rstn                    ,
	input  logic                          enabled_in              ,
	input  logic [                  0:63] cu_configure            ,
	input  WEDInterface                   wed_request_in          ,
	input  ResponseBufferLine             read_response_in        ,
	input  ResponseBufferLine             write_response_in       ,
	input  ReadWriteDataLine              read_data_0_in          ,
	input  ReadWriteDataLine              read_data_1_in          ,
	input  BufferStatus                   read_buffer_status      ,
	input  logic                          read_command_bus_grant  ,
	output logic                          read_command_bus_request,
	output CommandBufferLine              read_command_out        ,
	input  BufferStatus                   write_buffer_status     ,
	output CommandBufferLine              write_command_out       ,
	output ReadWriteDataLine              write_data_0_out        ,
	output ReadWriteDataLine              write_data_1_out        ,
	input  VertexInterface                vertex_job              ,
	output logic                          vertex_job_request      ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done
);

	BufferStatus read_buffer_status_latched ;
	BufferStatus write_buffer_status_latched;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_latched;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_latched  ;

	logic read_command_bus_grant_latched  ;
	logic read_command_bus_request_latched;

// vertex control variables
	logic           vertex_job_request_latched   ;
	VertexInterface vertex_job_latched           ;

	//output latched
	ReadWriteDataLine write_data_0_out_latched ;
	ReadWriteDataLine write_data_1_out_latched ;
	CommandBufferLine write_command_out_latched;

	//input lateched
	WEDInterface       wed_request_in_latched   ;
	ResponseBufferLine read_response_in_latched ;
	ResponseBufferLine write_response_in_latched;
	ReadWriteDataLine  read_data_0_in_latched   ;
	ReadWriteDataLine  read_data_1_in_latched   ;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_cu[0:NUM_VERTEX_CU-1];
	logic [  0:(EDGE_SIZE_BITS-1)] edge_num_counter_cu  [0:NUM_VERTEX_CU-1];

	CommandBufferLine         read_command_cu        [0:NUM_VERTEX_CU-1];
	logic [NUM_VERTEX_CU-1:0] ready_read_command_cu                     ;
	logic [NUM_VERTEX_CU-1:0] request_read_command_cu                   ;

	EdgeDataWrite             edge_data_write_cu        [0:NUM_VERTEX_CU-1];
	logic [NUM_VERTEX_CU-1:0] ready_edge_data_write_cu                     ;
	logic [NUM_VERTEX_CU-1:0] request_edge_data_write_cu                   ;
	logic [NUM_VERTEX_CU-1:0] enable_cu                                    ;


	ResponseBufferLine read_response_cu [0:NUM_VERTEX_CU-1];
	ResponseBufferLine write_response_cu[0:NUM_VERTEX_CU-1];

	ReadWriteDataLine read_data_0_cu[0:NUM_VERTEX_CU-1];
	ReadWriteDataLine read_data_1_cu[0:NUM_VERTEX_CU-1];


	VertexInterface           vertex_job_cu        [0:NUM_VERTEX_CU-1];
	logic [NUM_VERTEX_CU-1:0] request_vertex_job_cu                   ;
	logic                     enabled                                 ;
	logic [             0:63] cu_configure_latched                    ;

	BufferStatus      burst_read_command_buffer_states_cu;
	CommandBufferLine burst_read_command_buffer_out      ;

	BufferStatus      burst_edge_data_write_cu_buffer_states_cu                   ;
	EdgeDataWrite     burst_edge_data_buffer_out                                  ;
	EdgeDataRead      edge_data_read_cu                        [0:NUM_VERTEX_CU-1];


	genvar i;
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
	//Drive output
	////////////////////////////////////////////////////////////////////////////

	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out        <= 0;
			write_data_0_out         <= 0;
			write_data_1_out         <= 0;
			read_command_out         <= 0;
			vertex_job_request       <= 0;
			vertex_job_counter_done  <= 0;
			edge_job_counter_done    <= 0;
			
			read_command_bus_request <= 0;
		end else begin
			write_command_out        <= write_command_out_latched;
			write_data_0_out         <= write_data_0_out_latched;
			write_data_1_out         <= write_data_1_out_latched;
			read_command_out         <= burst_read_command_buffer_out;
			vertex_job_request       <= vertex_job_request_latched;
			vertex_job_counter_done  <= vertex_job_counter_done_latched;
			edge_job_counter_done    <= edge_job_counter_done_latched;
			
			read_command_bus_request <= read_command_bus_request_latched;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//Drive input
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched            <= 0;
			read_response_in_latched          <= 0;
			write_response_in_latched         <= 0;
			read_data_0_in_latched            <= 0;
			read_data_1_in_latched            <= 0;
			cu_configure_latched              <= 0;
			read_buffer_status_latched        <= 0;
			read_buffer_status_latched.empty  <= 1;
			write_buffer_status_latched       <= 0;
			write_buffer_status_latched.empty <= 1;
			vertex_job_latched                <= 0;
			read_command_bus_grant_latched   <= 0;
		end else begin
			if(enabled)begin
				wed_request_in_latched      <= wed_request_in;
				read_response_in_latched    <= read_response_in;
				write_response_in_latched   <= write_response_in;
				read_data_0_in_latched      <= read_data_0_in;
				read_data_1_in_latched      <= read_data_1_in;
				read_buffer_status_latched  <= read_buffer_status;
				write_buffer_status_latched <= write_buffer_status;
				vertex_job_latched          <= vertex_job;
				read_command_bus_grant_latched   <= read_command_bus_grant;
				if((|cu_configure))
					cu_configure_latched <= cu_configure;
			end
		end
	end


	////////////////////////////////////////////////////////////////////////////
	// Write command CU Generatrion add data to be written to a cacheline
	////////////////////////////////////////////////////////////////////////////

	cu_edge_data_write_control cu_edge_data_write_control_instant (
		.clock            (clock                     ),
		.rstn             (rstn                      ),
		.enabled_in       (enabled                   ),
		.cu_configure     (cu_configure_latched      ),
		.wed_request_in   (wed_request_in_latched    ),
		.edge_data_write  (burst_edge_data_buffer_out),
		.write_data_0_out (write_data_0_out_latched  ),
		.write_data_1_out (write_data_1_out_latched  ),
		.write_command_out(write_command_out_latched )
	);


	////////////////////////////////////////////////////////////////////////////
	// Vertex-centric Algorithm Module Generate
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_pagerank_cu
			cu_vertex_pagerank #(.PAGERANK_CU_ID(i)) cu_vertex_pagerank_instant (
				.clock                      (clock                                    ),
				.rstn                       (rstn                                     ),
				.enabled_in                 (enable_cu[i]                             ),
				.wed_request_in             (wed_request_in_latched                   ),
				.cu_configure               (cu_configure_latched                     ),
				.read_response_in           (read_response_cu[i]                      ),
				.write_response_in          (write_response_cu[i]                     ),
				.read_command_bus_grant     (ready_read_command_cu[i]                 ),
				.read_command_bus_request   (request_read_command_cu[i]               ),
				.edge_data_write_bus_grant  (ready_edge_data_write_cu[i]              ),
				.edge_data_write_bus_request(request_edge_data_write_cu[i]            ),
				.edge_data_read_in          (edge_data_read_cu[i]                     ),
				.read_data_0_in             (read_data_0_cu[i]                        ),
				.read_data_1_in             (read_data_1_cu[i]                        ),
				.read_buffer_status         (burst_read_command_buffer_states_cu      ),
				.read_command_out           (read_command_cu[i]                       ),
				.write_buffer_status        (burst_edge_data_write_cu_buffer_states_cu),
				.edge_data_write_out        (edge_data_write_cu[i]                    ),
				.vertex_job                 (vertex_job_cu[i]                         ),
				.vertex_job_request         (request_vertex_job_cu[i]                 ),
				.vertex_num_counter         (vertex_num_counter_cu[i]                 ),
				.edge_num_counter           (edge_num_counter_cu[i]                   )
			);
		end
	endgenerate


////////////////////////////////////////////////////////////////////////////
//Graph algorithm compute units arbitration
////////////////////////////////////////////////////////////////////////////

	cu_vertex_pagerank_arbiter_control #(.NUM_VERTEX_CU(NUM_VERTEX_CU)) cu_vertex_pagerank_arbiter_control_instant (
		.clock                                        (clock                                    ),
		.rstn                                         (rstn                                     ),
		.enabled_in                                   (enabled                                  ),
		.enable_cu_out                                (enable_cu                                ),
		.cu_configure                                 (cu_configure_latched                     ),
		.read_response_in                             (read_response_in_latched                 ),
		.read_data_0_in                               (read_data_0_in_latched                   ),
		.read_data_1_in                               (read_data_1_in_latched                   ),
		.read_buffer_status                           (read_buffer_status_latched               ),
		.write_buffer_status                          (write_buffer_status_latched              ),
		.read_command_bus_grant                       (read_command_bus_grant_latched           ),
		.read_command_bus_request                     (read_command_bus_request_latched         ),
		.read_response_cu_out                         (read_response_cu                         ),
		.write_response_in                            (write_response_in_latched                ),
		.write_response_cu_out                        (write_response_cu                        ),
		.read_command_cu_in                           (read_command_cu                          ),
		.request_read_command_cu_in                   (request_read_command_cu                  ),
		.ready_read_command_cu_out                    (ready_read_command_cu                    ),
		.read_command_out                             (burst_read_command_buffer_out            ),
		.edge_data_write_cu_in                        (edge_data_write_cu                       ),
		.request_edge_data_write_cu_in                (request_edge_data_write_cu               ),
		.ready_edge_data_write_cu_out                 (ready_edge_data_write_cu                 ),
		.burst_edge_data_out                          (burst_edge_data_buffer_out               ),
		.read_data_0_cu_out                           (read_data_0_cu                           ),
		.read_data_1_cu_out                           (read_data_1_cu                           ),
		.edge_data_read_cu_out                        (edge_data_read_cu                        ),
		.burst_read_command_buffer_states_cu_out      (burst_read_command_buffer_states_cu      ),
		.burst_edge_data_write_cu_buffer_states_cu_out(burst_edge_data_write_cu_buffer_states_cu),
		.vertex_job_cu_out                            (vertex_job_cu                            ),
		.request_vertex_job_cu_in                     (request_vertex_job_cu                    ),
		.vertex_job                                   (vertex_job_latched                       ),
		.vertex_job_request                           (vertex_job_request_latched               ),
		.vertex_num_counter_cu_in                     (vertex_num_counter_cu                    ),
		.edge_num_counter_cu_in                       (edge_num_counter_cu                      ),
		.vertex_job_counter_done_out                  (vertex_job_counter_done_latched          ),
		.edge_job_counter_done_out                    (edge_job_counter_done_latched            )
	);



endmodule