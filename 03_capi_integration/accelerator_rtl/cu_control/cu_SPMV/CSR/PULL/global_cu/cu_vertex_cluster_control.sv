// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_vertex_cluster_control.sv
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

module cu_vertex_cluster_control #(
	parameter NUM_VERTEX_CU = NUM_VERTEX_CU_GLOBAL,
	parameter NUM_GRAPH_CU  = NUM_GRAPH_CU_GLOBAL ,
	parameter CU_ID_Y       = 1
) (
	input  logic                          clock                    , // Clock
	input  logic                          rstn_in                  ,
	input  logic                          enabled_in               ,
	input  logic [                  0:63] cu_configure             ,
	input  WEDInterface                   wed_request_in           ,
	input  ResponseBufferLine             read_response_in         ,
	input  ResponseBufferLine             write_response_in        ,
	input  ReadWriteDataLine              read_data_0_in           ,
	input  ReadWriteDataLine              read_data_1_in           ,
	input  BufferStatus                   read_buffer_status       ,
	input  logic                          read_command_bus_grant   ,
	output logic                          read_command_bus_request ,
	output CommandBufferLine              read_command_out         ,
	input  BufferStatus                   write_buffer_status      ,
	input  logic                          write_command_bus_grant  ,
	output logic                          write_command_bus_request,
	output EdgeDataWrite                  edge_data_write_out      ,
	input  VertexInterface                vertex_job               ,
	output logic                          vertex_job_request       ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done  ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done
);

	logic rstn       ;
	logic rstn_input ;
	logic rstn_output;

	logic                     reset_cu                   ;
	logic [NUM_VERTEX_CU-1:0] reset_cu_in                ;
	BufferStatus              read_buffer_status_latched ;
	BufferStatus              write_buffer_status_latched;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_latched;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_latched  ;

	logic read_command_bus_grant_latched   ;
	logic read_command_bus_request_latched ;
	logic write_command_bus_grant_latched  ;
	logic write_command_bus_request_latched;

// vertex control variables
	logic           vertex_job_request_latched;
	VertexInterface vertex_job_latched        ;

	//output latched

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

	BufferStatus      burst_read_command_buffer_states_cu[0:NUM_VERTEX_CU-1];
	CommandBufferLine burst_read_command_buffer_out                         ;

	BufferStatus  burst_edge_data_write_cu_buffer_states_cu[0:NUM_VERTEX_CU-1];
	EdgeDataWrite burst_edge_data_buffer_out                                  ;

	EdgeDataRead edge_data_read_cu[0:NUM_VERTEX_CU-1];


	logic [0:63] cu_configure_out  [0:NUM_VERTEX_CU-1];
	WEDInterface cu_wed_request_out[0:NUM_VERTEX_CU-1];

	genvar i;
	////////////////////////////////////////////////////////////////////////////
	//enable logic
	////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn_in) begin
		if(~rstn_in) begin
			rstn        <= 0;
			rstn_input  <= 0;
			rstn_output <= 0;
		end else begin
			rstn        <= rstn_in;
			rstn_input  <= rstn_in;
			rstn_output <= rstn_in;
		end
	end

	always_ff @(posedge clock or negedge rstn_input) begin
		if(~rstn_input) begin
			enabled <= 0;
		end else begin
			enabled <= enabled_in;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//Drive output
	////////////////////////////////////////////////////////////////////////////

	// drive outputs
	always_ff @(posedge clock or negedge rstn_output) begin
		if(~rstn_output) begin
			edge_data_write_out.valid <= 0;
			read_command_out.valid    <= 0;
			vertex_job_request        <= 0;
			vertex_job_counter_done   <= 0;
			edge_job_counter_done     <= 0;
			read_command_bus_request  <= 0;
			write_command_bus_request <= 0;
		end else begin
			edge_data_write_out.valid <= burst_edge_data_buffer_out.valid;
			read_command_out.valid    <= burst_read_command_buffer_out.valid;
			vertex_job_request        <= vertex_job_request_latched;
			vertex_job_counter_done   <= vertex_job_counter_done_latched;
			edge_job_counter_done     <= edge_job_counter_done_latched;
			read_command_bus_request  <= read_command_bus_request_latched;
			write_command_bus_request <= write_command_bus_request_latched;
		end
	end

	// drive outputs
	always_ff @(posedge clock or negedge rstn_output) begin
		if(~rstn_output) begin
			edge_data_write_out.payload <= 0;
			read_command_out.payload    <= 0;
		end else begin
			edge_data_write_out.payload <= burst_edge_data_buffer_out.payload;
			read_command_out.payload    <= burst_read_command_buffer_out.payload;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//Drive input
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_input) begin
		if(~rstn_input) begin
			wed_request_in_latched.valid      <= 0;
			read_response_in_latched.valid    <= 0;
			write_response_in_latched.valid   <= 0;
			read_data_0_in_latched.valid      <= 0;
			read_data_1_in_latched.valid      <= 0;
			vertex_job_latched.valid          <= 0;
			read_buffer_status_latched        <= 0;
			read_buffer_status_latched.empty  <= 1;
			write_buffer_status_latched       <= 0;
			write_buffer_status_latched.empty <= 1;
			read_command_bus_grant_latched    <= 0;
			write_command_bus_grant_latched   <= 0;
			cu_configure_latched              <= 0;
		end else begin
			if(enabled)begin
				wed_request_in_latched.valid    <= wed_request_in.valid;
				read_response_in_latched.valid  <= read_response_in.valid;
				write_response_in_latched.valid <= write_response_in.valid;
				read_data_0_in_latched.valid    <= read_data_0_in.valid;
				read_data_1_in_latched.valid    <= read_data_1_in.valid;
				vertex_job_latched.valid        <= vertex_job.valid;
				read_buffer_status_latched      <= read_buffer_status;
				write_buffer_status_latched     <= write_buffer_status;
				read_command_bus_grant_latched  <= read_command_bus_grant;
				write_command_bus_grant_latched <= write_command_bus_grant;
				if((|cu_configure))
					cu_configure_latched <= cu_configure;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_input) begin
		if(~rstn_input) begin
			wed_request_in_latched.payload    <= 0;
			read_response_in_latched.payload  <= 0;
			write_response_in_latched.payload <= 0;
			read_data_0_in_latched.payload    <= 0;
			read_data_1_in_latched.payload    <= 0;
			vertex_job_latched.payload        <= 0;
		end else begin
			wed_request_in_latched.payload    <= wed_request_in.payload;
			read_response_in_latched.payload  <= read_response_in.payload;
			write_response_in_latched.payload <= write_response_in.payload;
			read_data_0_in_latched.payload    <= read_data_0_in.payload;
			read_data_1_in_latched.payload    <= read_data_1_in.payload;
			vertex_job_latched.payload        <= vertex_job.payload;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Vertex-centric Algorithm Module Generate
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_spmv_cu
			cu_vertex_spmv #(
				.CU_ID_X(i),
				.CU_ID_Y(CU_ID_Y)
			) cu_vertex_spmv_instant (
				.clock                      (clock                                       ),
				.rstn_in                    (reset_cu_in[i]                              ),
				.enabled_in                 (enable_cu[i]                                ),
				.wed_request_in             (cu_wed_request_out[i]                       ),
				.cu_configure               (cu_configure_out[i]                         ),
				.read_response_in           (read_response_cu[i]                         ),
				.write_response_in          (write_response_cu[i]                        ),
				.read_command_bus_grant     (ready_read_command_cu[i]                    ),
				.read_command_bus_request   (request_read_command_cu[i]                  ),
				.edge_data_write_bus_grant  (ready_edge_data_write_cu[i]                 ),
				.edge_data_write_bus_request(request_edge_data_write_cu[i]               ),
				.edge_data_read_in          (edge_data_read_cu[i]                        ),
				.read_data_0_in             (read_data_0_cu[i]                           ),
				.read_data_1_in             (read_data_1_cu[i]                           ),
				.read_buffer_status         (burst_read_command_buffer_states_cu[i]      ),
				.read_command_out           (read_command_cu[i]                          ),
				.write_buffer_status        (burst_edge_data_write_cu_buffer_states_cu[i]),
				.edge_data_write_out        (edge_data_write_cu[i]                       ),
				.vertex_job                 (vertex_job_cu[i]                            ),
				.vertex_job_request         (request_vertex_job_cu[i]                    ),
				.vertex_num_counter         (vertex_num_counter_cu[i]                    ),
				.edge_num_counter           (edge_num_counter_cu[i]                      )
			);

			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					reset_cu_in[i] <= 0;
				end else begin
					reset_cu_in[i] <= reset_cu;
				end
			end
		end
	endgenerate


////////////////////////////////////////////////////////////////////////////
//Graph algorithm compute units arbitration
////////////////////////////////////////////////////////////////////////////

	cu_vertex_spmv_arbiter_control #(
		.NUM_VERTEX_CU(NUM_VERTEX_CU),
		.NUM_GRAPH_CU (NUM_GRAPH_CU ),
		.CU_ID_Y      (CU_ID_Y      )
	) cu_vertex_spmv_arbiter_control_instant (
		.clock                                        (clock                                    ),
		.rstn_in                                      (rstn                                     ),
		.enabled_in                                   (enabled                                  ),
		.wed_request_in                               (wed_request_in_latched                   ),
		.cu_wed_request_out                           (cu_wed_request_out                       ),
		.enable_cu_out                                (enable_cu                                ),
		.cu_configure                                 (cu_configure_latched                     ),
		.cu_configure_out                             (cu_configure_out                         ),
		.read_response_in                             (read_response_in_latched                 ),
		.read_data_0_in                               (read_data_0_in_latched                   ),
		.read_data_1_in                               (read_data_1_in_latched                   ),
		.read_buffer_status                           (read_buffer_status_latched               ),
		.write_buffer_status                          (write_buffer_status_latched              ),
		.read_command_bus_grant                       (read_command_bus_grant_latched           ),
		.read_command_bus_request                     (read_command_bus_request_latched         ),
		.write_command_bus_grant                      (write_command_bus_grant_latched          ),
		.write_command_bus_request                    (write_command_bus_request_latched        ),
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

	reset_control #(.NUM_EXTERNAL_RESETS(1)) reset_instant (
		.clock        (clock   ),
		.external_rstn(rstn    ),
		.rstn         (reset_cu)
	);

endmodule