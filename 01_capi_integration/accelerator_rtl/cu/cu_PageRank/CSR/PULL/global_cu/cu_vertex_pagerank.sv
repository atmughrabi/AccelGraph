// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_vertex_pagerank.sv
// Create : 2019-09-26 15:19:37
// Revise : 2019-11-03 11:31:04
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_pagerank #(
	parameter CU_ID_X      = 1,
	parameter CU_ID_Y      = 1,
	parameter NUM_REQUESTS = 2
) (
	input  logic                          clock                      , // Clock
	input  logic                          rstn_in                    ,
	input  logic                          enabled_in                 ,
	input  WEDInterface                   wed_request_in             ,
	input  logic [                  0:63] cu_configure               ,
	input  ResponseBufferLine             read_response_in           ,
	input  ResponseBufferLine             write_response_in          ,
	input  logic                          read_command_bus_grant     ,
	output logic                          read_command_bus_request   ,
	input  logic                          edge_data_write_bus_grant  ,
	output logic                          edge_data_write_bus_request,
	input  ReadWriteDataLine              read_data_0_in             ,
	input  ReadWriteDataLine              read_data_1_in             ,
	input  EdgeDataRead                   edge_data_read_in          ,
	input  BufferStatus                   read_buffer_status         ,
	output CommandBufferLine              read_command_out           ,
	input  BufferStatus                   write_buffer_status        ,
	output EdgeDataWrite                  edge_data_write_out        ,
	input  VertexInterface                vertex_job                 ,
	output logic                          vertex_job_request         ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter         ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_num_counter
);

	logic rstn_internal;
	logic rstn         ;
	logic rstn_input   ;
	logic rstn_output  ;

	logic read_command_bus_grant_latched     ;
	logic read_command_bus_request_latched   ;
	logic edge_data_write_bus_grant_latched  ;
	logic edge_data_write_bus_request_latched;

	BufferStatus read_buffer_status_latched ;
	BufferStatus write_buffer_status_latched;

// vertex control variables
	logic           vertex_job_request_send    ;
	VertexInterface vertex_job_latched         ;
	VertexInterface vertex_job_internal_latched;

	logic [0:63] cu_configure_latched         ;
	logic [0:63] cu_configure_internal        ;
	logic [0:63] cu_configure_internal_latched;

	logic           vertex_request_internal      ;
	BufferStatus    vertex_buffer_status_internal;
	VertexInterface vertex_job_burst_in          ;

	VertexInterface vertex_job_burst_out        ;
	VertexInterface vertex_job_burst_out_latched;

	//output latched
	CommandBufferLine read_command_out_latched;

	//input lateched
	WEDInterface wed_request_in_latched;

	ResponseBufferLine read_response_in_latched ;
	ResponseBufferLine write_response_in_latched;
	ReadWriteDataLine  read_data_0_in_latched   ;
	ReadWriteDataLine  read_data_1_in_latched   ;

	ResponseBufferLine write_response_in_edge_data;
	ResponseBufferLine read_response_in_edge_job  ;
	ReadWriteDataLine  read_data_0_in_edge_job    ;
	ReadWriteDataLine  read_data_1_in_edge_job    ;

	ResponseBufferLine read_response_in_edge_data;
	ReadWriteDataLine  read_data_0_in_edge_data  ;
	ReadWriteDataLine  read_data_1_in_edge_data  ;

	logic         edge_request      ;
	EdgeInterface edge_job          ;
	BufferStatus  data_buffer_status;
	logic         processing_vertex ;

	EdgeDataRead edge_data        ;
	logic        enabled          ;
	logic        enabled_cmd      ;
	logic        enabled_edge_job ;
	logic        enabled_edge_data;
	logic        enabled_sum_data ;

	CommandBufferLine              command_arbiter_out                               ;
	logic [      NUM_REQUESTS-1:0] requests                                          ;
	logic [      NUM_REQUESTS-1:0] ready                                             ;
	logic [      NUM_REQUESTS-1:0] submit                                            ;
	CommandBufferLine              command_buffer_in               [0:NUM_REQUESTS-1];
	CommandBufferLine              read_command_edge_job_buffer                      ;
	CommandBufferLine              read_command_edge_data_buffer                     ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum                           ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum_internal                  ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_resp                           ;

	BufferStatus      burst_read_command_buffer_states_cu;
	CommandBufferLine burst_read_command_buffer_out      ;
	EdgeDataRead      edge_data_read                     ;
	EdgeDataWrite     edge_data_write_out_internal       ;

	ReadWriteDataLine  read_data_0_data_out                [0:1];
	ReadWriteDataLine  read_data_1_data_out                [0:1];
	ResponseBufferLine read_response_data_out              [0:1];
	ResponseBufferLine read_response_data_out_latched      [0:1];
	logic              read_response_data_out_latched_valid[0:1];
	ReadWriteDataLine  read_data_0_data_out_latched        [0:1];
	ReadWriteDataLine  read_data_1_data_out_latched        [0:1];
	logic              read_data_0_data_out_latched_valid  [0:1];
	logic              read_data_1_data_out_latched_valid  [0:1];

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_in) begin
		if(~rstn_in) begin
			rstn_internal <= 0;
		end else begin
			rstn_internal <= rstn_in;
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			rstn        <= 0;
			rstn_input  <= 0;
			rstn_output <= 0;
		end else begin
			rstn        <= rstn_internal;
			rstn_input  <= rstn_internal;
			rstn_output <= rstn_internal;
		end
	end

	always_ff @(posedge clock or negedge rstn_input) begin
		if(~rstn_input) begin
			enabled <= 0;
		end else begin
			enabled <= enabled_in;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled_cmd <= 0;
		end else begin
			enabled_cmd <= ((|cu_configure_latched) && wed_request_in_latched.valid);
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled_edge_job  <= 0;
			enabled_edge_data <= 0;
			enabled_sum_data  <= 0;
		end else begin
			enabled_edge_job  <= enabled_cmd;
			enabled_edge_data <= enabled_cmd;
			enabled_sum_data  <= enabled_cmd;
		end
	end

////////////////////////////////////////////////////////////////////////////
// Request Pulse generation
////////////////////////////////////////////////////////////////////////////

	assign command_buffer_in[0] = read_command_edge_job_buffer;
	assign command_buffer_in[1] = read_command_edge_data_buffer;

	assign submit[0] = read_command_edge_job_buffer.valid;
	assign submit[1] = read_command_edge_data_buffer.valid;

	assign read_command_out_latched = burst_read_command_buffer_out;

////////////////////////////////////////////////////////////////////////////
//Buffer arbitration logic
////////////////////////////////////////////////////////////////////////////


	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_REQUESTS            ),
		.WIDTH       ($bits(CommandBufferLine))
	) read_command_buffer_arbiter_instant (
		.clock      (clock              ),
		.rstn       (rstn               ),
		.enabled    (enabled            ),
		.buffer_in  (command_buffer_in  ),
		.submit     (submit             ),
		.requests   (requests           ),
		.arbiter_out(command_arbiter_out),
		.ready      (ready              )
	);


////////////////////////////////////////////////////////////////////////////
//Drive input out put
////////////////////////////////////////////////////////////////////////////

	// drive outputs
	always_ff @(posedge clock or negedge rstn_output) begin
		if(~rstn_output) begin
			vertex_job_request        <= 0;
			edge_data_write_out.valid <= 0;
			read_command_out.valid    <= 0;
		end else begin
			vertex_job_request        <= vertex_job_request_send;
			edge_data_write_out.valid <= edge_data_write_out_internal.valid;
			read_command_out.valid    <= read_command_out_latched.valid;
		end
	end

	always_ff @(posedge clock) begin
		edge_data_write_out.payload <= edge_data_write_out_internal.payload;
		read_command_out.payload    <= read_command_out_latched.payload;
	end

	////////////////////////////////////////////////////////////////////////////
	// drive inputs
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_input) begin
		if(~rstn_input) begin
			read_data_0_in_latched.valid    <= 0;
			read_data_1_in_latched.valid    <= 0;
			wed_request_in_latched.valid    <= 0;
			read_response_in_latched.valid  <= 0;
			write_response_in_latched.valid <= 0;
			vertex_job_burst_in.valid       <= 0;
			edge_data_read.valid            <= 0;
			cu_configure_internal           <= 0;
		end else begin
			read_data_0_in_latched.valid    <= read_data_0_in.valid;
			read_data_1_in_latched.valid    <= read_data_1_in.valid;
			wed_request_in_latched.valid    <= wed_request_in.valid;
			read_response_in_latched.valid  <= read_response_in.valid;
			write_response_in_latched.valid <= write_response_in.valid;
			vertex_job_burst_in.valid       <= vertex_job.valid;
			edge_data_read.valid            <= edge_data_read_in.valid;
			cu_configure_internal           <= cu_configure;
		end
	end

	always_ff @(posedge clock) begin
		read_data_0_in_latched.payload    <= read_data_0_in.payload;
		read_data_1_in_latched.payload    <= read_data_1_in.payload;
		wed_request_in_latched.payload    <= wed_request_in.payload;
		read_response_in_latched.payload  <= read_response_in.payload;
		write_response_in_latched.payload <= write_response_in.payload;
		vertex_job_burst_in.payload       <= vertex_job.payload;
		edge_data_read.payload            <= edge_data_read_in.payload;
	end

	always_ff @(posedge clock or negedge rstn_input) begin
		if(~rstn_input) begin
			cu_configure_internal_latched     <= 0;
			write_buffer_status_latched       <= 0;
			write_buffer_status_latched.empty <= 1;
			read_buffer_status_latched        <= 0;
			read_buffer_status_latched.empty  <= 1;
		end else begin
			write_buffer_status_latched   <= write_buffer_status;
			read_buffer_status_latched    <= read_buffer_status;
			cu_configure_internal_latched <= cu_configure_internal;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cu_configure_latched <= 0;
		end else begin
			if((|cu_configure_internal_latched))
				cu_configure_latched <= cu_configure_internal_latched;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// count complete vertex request
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_latched.valid <= 0;
		end else begin
			if(vertex_job_burst_out.valid && ~processing_vertex) begin
				vertex_job_latched.valid <= vertex_job_burst_out.valid;
			end
			if ((edge_data_counter_accum_internal == vertex_job_latched.payload.inverse_out_degree) && vertex_job_latched.valid) begin
				vertex_job_latched.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		if(vertex_job_burst_out.valid && ~processing_vertex) begin
			vertex_job_latched.payload <= vertex_job_burst_out.payload;
		end
		if ((edge_data_counter_accum_internal == vertex_job_latched.payload.inverse_out_degree) && vertex_job_latched.valid) begin
			vertex_job_latched.payload <= 0;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// count complete vertex request
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_output) begin
		if(~rstn_output) begin
			vertex_num_counter <= 0;
		end else begin
			vertex_num_counter <= vertex_num_counter_resp;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// count complete edge request
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_output) begin
		if(~rstn_output) begin
			edge_num_counter <= 0;
		end else begin
			edge_num_counter <= edge_data_counter_accum;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// If a vertex job is recieved set flag
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			processing_vertex <= 0;
		end else begin
			if(vertex_job_latched.valid) begin
				if(~processing_vertex) begin
					processing_vertex <= 1;
				end
				if (edge_data_counter_accum_internal == vertex_job_latched.payload.inverse_out_degree) begin
					processing_vertex <= 0;
				end
			end
		end
	end


	assign vertex_request_internal = (~vertex_buffer_status_internal.empty) && (~processing_vertex) && ~vertex_job_latched.valid && ~vertex_job_burst_out.valid;
	assign vertex_job_request_send = vertex_buffer_status_internal.empty;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_burst_out        <= 0;
			vertex_job_internal_latched <= 0;
		end else begin
			vertex_job_burst_out        <= vertex_job_burst_out_latched;
			vertex_job_internal_latched <= vertex_job_latched;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Edge job control
	////////////////////////////////////////////////////////////////////////////

	cu_edge_job_control #(
		.CU_ID_X(CU_ID_X),
		.CU_ID_Y(CU_ID_Y)
	) cu_edge_job_control_instant (
		.clock                   (clock                       ),
		.rstn_in                 (rstn                        ),
		.enabled_in              (enabled_edge_job            ),
		.cu_configure            (cu_configure_latched        ),
		.wed_request_in          (wed_request_in_latched      ),
		.read_response_in        (read_response_in_edge_job   ),
		.read_data_0_in          (read_data_0_in_edge_job     ),
		.read_data_1_in          (read_data_1_in_edge_job     ),
		.read_buffer_status      (read_buffer_status_latched  ),
		.edge_request            (edge_request                ),
		.vertex_job              (vertex_job_internal_latched ),
		.read_command_bus_grant  (ready[0]                    ),
		.read_command_bus_request(requests[0]                 ),
		.read_command_out        (read_command_edge_job_buffer),
		.edge_job                (edge_job                    )
	);

	////////////////////////////////////////////////////////////////////////////
	// Edge Data control
	////////////////////////////////////////////////////////////////////////////

	cu_edge_data_read_command_control #(
		.CU_ID_X(CU_ID_X),
		.CU_ID_Y(CU_ID_Y)
	) cu_edge_data_read_command_control_instant (
		.clock                   (clock                        ),
		.rstn_in                 (rstn                         ),
		.enabled_in              (enabled_edge_data            ),
		.cu_configure            (cu_configure_latched         ),
		.wed_request_in          (wed_request_in_latched       ),
		.read_response_in        (read_response_in_edge_data   ),
		.edge_data_read_in       (edge_data_read               ),
		.read_buffer_status      (read_buffer_status_latched   ),
		.edge_data_request       (edge_data_request            ),
		.edge_job                (edge_job                     ),
		.edge_request            (edge_request                 ),
		.read_command_bus_grant  (ready[1]                     ),
		.read_command_bus_request(requests[1]                  ),
		.read_command_out        (read_command_edge_data_buffer),
		.data_buffer_status      (data_buffer_status           ),
		.edge_data               (edge_data                    )
	);

	////////////////////////////////////////////////////////////////////////////
	// Data SUM control Float/Fixed Point
	////////////////////////////////////////////////////////////////////////////

	cu_sum_kernel_control #(
		.CU_ID_X(CU_ID_X),
		.CU_ID_Y(CU_ID_Y)
	) cu_sum_kernel_control_instant (
		.clock                               (clock                              ),
		.rstn_in                             (rstn                               ),
		.enabled_in                          (enabled_sum_data                   ),
		.write_response_in                   (write_response_in_edge_data        ),
		.write_buffer_status                 (write_buffer_status_latched        ),
		.edge_data                           (edge_data                          ),
		.edge_data_request                   (edge_data_request                  ),
		.data_buffer_status                  (data_buffer_status                 ),
		.edge_data_write_bus_grant           (edge_data_write_bus_grant_latched  ),
		.edge_data_write_bus_request         (edge_data_write_bus_request_latched),
		.edge_data_write_out                 (edge_data_write_out_internal       ),
		.vertex_job                          (vertex_job_internal_latched        ),
		.vertex_num_counter_resp_out         (vertex_num_counter_resp            ),
		.edge_data_counter_accum_out         (edge_data_counter_accum            ),
		.edge_data_counter_accum_internal_out(edge_data_counter_accum_internal   )
	);

////////////////////////////////////////////////////////////////////////////
//read response arbitration logic - input
////////////////////////////////////////////////////////////////////////////

	array_struct_type_demux_bus #(
		.DATA_WIDTH($bits(ResponseBufferLine)),
		.BUS_WIDTH (2                        )
	) read_response_in_array_struct_type_demux_bus_instant (
		.clock         (clock                                            ),
		.rstn          (rstn                                             ),
		.sel_in        (read_response_in_latched.payload.cmd.array_struct),
		.data_in       (read_response_in_latched                         ),
		.data_in_valid (read_response_in_latched.valid                   ),
		.data_out      (read_response_data_out_latched                   ),
		.data_out_valid(read_response_data_out_latched_valid             )
	);

	always_ff @(posedge clock) begin
		read_response_data_out[0].valid <= read_response_data_out_latched_valid[0];
		read_response_data_out[1].valid <= read_response_data_out_latched_valid[1];
		read_response_data_out[0].payload <= read_response_data_out_latched[0].payload;
		read_response_data_out[1].payload <= read_response_data_out_latched[1].payload;
	end

	assign read_response_in_edge_job  = read_response_data_out[0];
	assign read_response_in_edge_data = read_response_data_out[1];

////////////////////////////////////////////////////////////////////////////
//write response arbitration logic - input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_response_in_edge_data.valid <= 0;
		end else begin
			if(write_response_in_latched.valid) begin
				case (write_response_in_latched.payload.cmd.array_struct)
					WRITE_GRAPH_DATA : begin
						write_response_in_edge_data.valid <= write_response_in_latched.valid;
					end
					default : begin
						write_response_in_edge_data.valid <= 0;
					end
				endcase
			end else begin
				write_response_in_edge_data.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		write_response_in_edge_data.payload <= write_response_in_latched.payload;
	end

////////////////////////////////////////////////////////////////////////////
//read data request logic - input
////////////////////////////////////////////////////////////////////////////

	array_struct_type_demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH (2                       )
	) read_data_0_array_struct_type_demux_bus_instant (
		.clock         (clock                                          ),
		.rstn          (rstn                                           ),
		.sel_in        (read_data_0_in_latched.payload.cmd.array_struct),
		.data_in       (read_data_0_in_latched                         ),
		.data_in_valid (read_data_0_in_latched.valid                   ),
		.data_out      (read_data_0_data_out_latched                   ),
		.data_out_valid(read_data_0_data_out_latched_valid             )
	);

	always_ff @(posedge clock) begin
		read_data_0_data_out[0].valid <= read_data_0_data_out_latched_valid[0];
		read_data_0_data_out[1].valid <= read_data_0_data_out_latched_valid[1];
		read_data_0_data_out[0].payload <= read_data_0_data_out_latched[0].payload;
		read_data_0_data_out[1].payload <= read_data_0_data_out_latched[1].payload;
	end

	assign read_data_0_in_edge_job  = read_data_0_data_out[0];
	assign read_data_0_in_edge_data = read_data_0_data_out[1];

	array_struct_type_demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH (2                       )
	) read_data_1_array_struct_type_demux_bus_instant (
		.clock         (clock                                          ),
		.rstn          (rstn                                           ),
		.sel_in        (read_data_1_in_latched.payload.cmd.array_struct),
		.data_in       (read_data_1_in_latched                         ),
		.data_in_valid (read_data_1_in_latched.valid                   ),
		.data_out      (read_data_1_data_out_latched                   ),
		.data_out_valid(read_data_1_data_out_latched_valid             )
	);

	always_ff @(posedge clock) begin
		read_data_1_data_out[0].valid <= read_data_1_data_out_latched_valid[0];
		read_data_1_data_out[1].valid <= read_data_1_data_out_latched_valid[1];
		read_data_1_data_out[0].payload <= read_data_1_data_out_latched[0].payload;
		read_data_1_data_out[1].payload <= read_data_1_data_out_latched[1].payload;
	end

	assign read_data_1_in_edge_job  = read_data_1_data_out[0];
	assign read_data_1_in_edge_data = read_data_1_data_out[1];


	////////////////////////////////////////////////////////////////////////////
	//Burst Buffer Read Commands
	////////////////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////////////
	// Bus requests Grants
	///////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_output) begin
		if(~rstn_output) begin
			read_command_bus_request <= 0;
		end else begin
			read_command_bus_request <= read_command_bus_request_latched;
		end
	end

	always_ff @(posedge clock or negedge rstn_input) begin
		if(~rstn_input) begin
			read_command_bus_grant_latched <= 0;
		end else begin
			read_command_bus_grant_latched <= read_command_bus_grant && ~read_buffer_status_latched.alfull;
		end
	end

	assign read_command_bus_request_latched = ~burst_read_command_buffer_states_cu.empty && ~read_buffer_status_latched.alfull;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) burst_read_command_buffer_fifo_instant (
		.clock   (clock                                     ),
		.rstn    (rstn                                      ),
		
		.push    (command_arbiter_out.valid                 ),
		.data_in (command_arbiter_out                       ),
		.full    (burst_read_command_buffer_states_cu.full  ),
		.alFull  (burst_read_command_buffer_states_cu.alfull),
		
		.pop     (read_command_bus_grant_latched            ),
		.valid   (burst_read_command_buffer_states_cu.valid ),
		.data_out(burst_read_command_buffer_out             ),
		.empty   (burst_read_command_buffer_states_cu.empty )
	);

	////////////////////////////////////////////////////////////////////////////
	// write Edge DATA CU Buffers
	////////////////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////////////
	// Bus requests Grants PageRank write data
	///////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_output) begin
		if(~rstn_output) begin
			edge_data_write_bus_grant_latched <= 0;
		end else begin
			edge_data_write_bus_grant_latched <= edge_data_write_bus_grant;
		end
	end

	always_ff @(posedge clock or negedge rstn_input) begin
		if(~rstn_input) begin
			edge_data_write_bus_request <= 0;
		end else begin
			edge_data_write_bus_request <= edge_data_write_bus_request_latched;
		end
	end


	fifo #(
		.WIDTH($bits(VertexInterface)),
		.DEPTH(32                    )
	) vertex_job_burst_in_buffer_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (vertex_job_burst_in.valid           ),
		.data_in (vertex_job_burst_in                 ),
		.full    (vertex_buffer_status_internal.full  ),
		.alFull  (vertex_buffer_status_internal.alfull),
		
		.pop     (vertex_request_internal             ),
		.valid   (vertex_buffer_status_internal.valid ),
		.data_out(vertex_job_burst_out_latched        ),
		.empty   (vertex_buffer_status_internal.empty )
	);

endmodule