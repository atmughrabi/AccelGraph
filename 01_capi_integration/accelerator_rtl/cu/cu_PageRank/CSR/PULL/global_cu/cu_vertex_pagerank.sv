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
	parameter NUM_EDGE_CU    = 1,
	parameter PAGERANK_CU_ID = 1,
	parameter NUM_REQUESTS   = 2
) (
	input  logic                          clock                      , // Clock
	input  logic                          rstn                       ,
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


	logic read_command_bus_grant_latched     ;
	logic read_command_bus_request_latched   ;
	logic edge_data_write_bus_grant_latched  ;
	logic edge_data_write_bus_request_latched;

	BufferStatus read_buffer_status_latched ;
	BufferStatus write_buffer_status_latched;

// vertex control variables
	logic           vertex_job_request_send;
	VertexInterface vertex_job_latched     ;
	logic [0:63]    cu_configure_latched   ;

	logic           vertex_request_internal      ;
	BufferStatus    vertex_buffer_status_internal;
	VertexInterface vertex_job_burst_in          ;
	VertexInterface vertex_job_burst_out         ;

	//output latched
	CommandBufferLine read_command_out_latched;

	//input lateched
	WEDInterface       wed_request_in_latched   ;
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

	EdgeDataRead edge_data  ;
	logic        enabled    ;
	logic        enabled_cmd;

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

	ReadWriteDataLine  read_data_0_data_out  [0:1];
	ReadWriteDataLine  read_data_1_data_out  [0:1];
	ResponseBufferLine read_response_data_out[0:1];

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled     <= 0;
			enabled_cmd <= 0;
		end else begin
			enabled     <= enabled_in;
			enabled_cmd <= (|cu_configure_latched) && wed_request_in_latched.valid;
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
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_out    <= 0;
			vertex_job_request  <= 0;
			edge_data_write_out <= 0;
		end else begin
			if(enabled_cmd)begin
				edge_data_write_out <= edge_data_write_out_internal;
				read_command_out    <= read_command_out_latched;
				vertex_job_request  <= vertex_job_request_send;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// drive inputs
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched            <= 0;
			read_response_in_latched          <= 0;
			write_response_in_latched         <= 0;
			read_data_0_in_latched            <= 0;
			read_data_1_in_latched            <= 0;
			edge_data_read                    <= 0;
			cu_configure_latched              <= 0;
			vertex_job_burst_in               <= 0;
			write_buffer_status_latched       <= 0;
			write_buffer_status_latched.empty <= 1;
			read_buffer_status_latched        <= 0;
			read_buffer_status_latched.empty  <= 1;
		end else begin
			if(enabled)begin
				wed_request_in_latched      <= wed_request_in;
				read_response_in_latched    <= read_response_in;
				write_response_in_latched   <= write_response_in;
				read_data_0_in_latched      <= read_data_0_in;
				read_data_1_in_latched      <= read_data_1_in;
				edge_data_read              <= edge_data_read_in;
				vertex_job_burst_in         <= vertex_job;
				write_buffer_status_latched <= write_buffer_status;
				read_buffer_status_latched  <= read_buffer_status;
				if((|cu_configure))
					cu_configure_latched <= cu_configure;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// count complete vertex request
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_latched <= 0;
		end else begin
			if(enabled)begin
				if(vertex_job_burst_out.valid && ~processing_vertex) begin
					vertex_job_latched <= vertex_job_burst_out;
				end
				if ((edge_data_counter_accum_internal == vertex_job_latched.inverse_out_degree) && vertex_job_latched.valid) begin
					vertex_job_latched <= 0;
				end
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// count complete vertex request
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_num_counter <= 0;
		end else begin
			if(enabled)begin
				vertex_num_counter <= vertex_num_counter_resp;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// count complete edge request
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_num_counter <= 0;
		end else begin
			if(enabled)begin
				edge_num_counter <= edge_data_counter_accum;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// If a vertex job is recieved set flag
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			processing_vertex <= 0;
		end else begin
			if(enabled)begin
				if(vertex_job_latched.valid) begin
					if(~processing_vertex) begin
						processing_vertex <= 1;
					end
					if (edge_data_counter_accum_internal == vertex_job_latched.inverse_out_degree) begin
						processing_vertex <= 0;
					end
				end
			end
		end
	end


	assign vertex_request_internal = (~vertex_buffer_status_internal.empty) && (~processing_vertex) && ~vertex_job_latched.valid;
	assign vertex_job_request_send = vertex_buffer_status_internal.empty;

	////////////////////////////////////////////////////////////////////////////
	// Edge job control
	////////////////////////////////////////////////////////////////////////////

	cu_edge_job_control #(.CU_ID(PAGERANK_CU_ID)) cu_edge_job_control_instant (
		.clock                   (clock                       ),
		.rstn                    (rstn                        ),
		.enabled_in              (enabled_cmd                 ),
		.cu_configure            (cu_configure_latched        ),
		.wed_request_in          (wed_request_in_latched      ),
		.read_response_in        (read_response_in_edge_job   ),
		.read_data_0_in          (read_data_0_in_edge_job     ),
		.read_data_1_in          (read_data_1_in_edge_job     ),
		.read_buffer_status      (read_buffer_status_latched  ),
		.edge_request            (edge_request                ),
		.vertex_job              (vertex_job_latched          ),
		.read_command_bus_grant  (ready[0]                    ),
		.read_command_bus_request(requests[0]                 ),
		.read_command_out        (read_command_edge_job_buffer),
		.edge_job                (edge_job                    )
	);

	////////////////////////////////////////////////////////////////////////////
	// Edge Data control
	////////////////////////////////////////////////////////////////////////////

	cu_edge_data_control #(.CU_ID(PAGERANK_CU_ID)) cu_edge_data_control_instant (
		.clock                   (clock                        ),
		.rstn                    (rstn                         ),
		.enabled_in              (enabled_cmd                  ),
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

	cu_sum_kernel_control #(.CU_ID(PAGERANK_CU_ID)) cu_sum_kernel_control_instant (
		.clock                           (clock                              ),
		.rstn                            (rstn                               ),
		.enabled_in                      (enabled_cmd                        ),
		.wed_request_in                  (wed_request_in                     ),
		.write_response_in               (write_response_in_edge_data        ),
		.write_buffer_status             (write_buffer_status_latched        ),
		.edge_data                       (edge_data                          ),
		.edge_data_request               (edge_data_request                  ),
		.data_buffer_status              (data_buffer_status                 ),
		.edge_data_write_bus_grant       (edge_data_write_bus_grant_latched  ),
		.edge_data_write_bus_request     (edge_data_write_bus_request_latched),
		.edge_data_write_out             (edge_data_write_out_internal       ),
		.vertex_job                      (vertex_job_latched                 ),
		.vertex_num_counter_resp         (vertex_num_counter_resp            ),
		.edge_data_counter_accum         (edge_data_counter_accum            ),
		.edge_data_counter_accum_internal(edge_data_counter_accum_internal   )
	);

////////////////////////////////////////////////////////////////////////////
//read response arbitration logic - input
////////////////////////////////////////////////////////////////////////////

	assign read_response_in_edge_job  = read_response_data_out[0];
	assign read_response_in_edge_data = read_response_data_out[1];

	array_struct_type_demux_bus #(
		.DATA_WIDTH($bits(ResponseBufferLine)),
		.BUS_WIDTH (2                        )
	) read_response_array_struct_type_demux_bus_instant (
		.clock     (clock                                    ),
		.rstn      (rstn                                     ),
		.enabled_in(read_response_in_latched.valid           ),
		.sel_in    (read_response_in_latched.cmd.array_struct),
		.data_in   (read_response_in_latched                 ),
		.data_out  (read_response_data_out                   )
	);

////////////////////////////////////////////////////////////////////////////
//write response arbitration logic - input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_response_in_edge_data <= 0;
		end else begin
			if(enabled && write_response_in_latched.valid) begin
				case (write_response_in_latched.cmd.array_struct)
					WRITE_GRAPH_DATA : begin
						write_response_in_edge_data <= write_response_in_latched;
					end
					default : begin
						write_response_in_edge_data <= 0;
					end
				endcase
			end else begin
				write_response_in_edge_data <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//read data request logic - input
////////////////////////////////////////////////////////////////////////////

	assign read_data_0_in_edge_job  = read_data_0_data_out[0];
	assign read_data_0_in_edge_data = read_data_0_data_out[1];

	array_struct_type_demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH (2                       )
	) read_data_0_array_struct_type_demux_bus_instant (
		.clock     (clock                                  ),
		.rstn      (rstn                                   ),
		.enabled_in(read_data_0_in_latched.valid           ),
		.sel_in    (read_data_0_in_latched.cmd.array_struct),
		.data_in   (read_data_0_in_latched                 ),
		.data_out  (read_data_0_data_out                   )
	);

	assign read_data_1_in_edge_job  = read_data_1_data_out[0];
	assign read_data_1_in_edge_data = read_data_1_data_out[1];

	array_struct_type_demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH (2                       )
	) read_data_1_array_struct_type_demux_bus_instant (
		.clock     (clock                                  ),
		.rstn      (rstn                                   ),
		.enabled_in(read_data_1_in_latched.valid           ),
		.sel_in    (read_data_1_in_latched.cmd.array_struct),
		.data_in   (read_data_1_in_latched                 ),
		.data_out  (read_data_1_data_out                   )
	);

	////////////////////////////////////////////////////////////////////////////
	//Burst Buffer Read Commands
	////////////////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////////////
	// Bus requests Grants
	///////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_bus_grant_latched <= 0;
			read_command_bus_request       <= 0;
		end else begin
			if(enabled_cmd) begin
				read_command_bus_grant_latched <= read_command_bus_grant;
				read_command_bus_request       <= read_command_bus_request_latched;
			end
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

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_write_bus_grant_latched <= 0;
			edge_data_write_bus_request       <= 0;
		end else begin
			if(enabled_cmd) begin
				edge_data_write_bus_grant_latched <= edge_data_write_bus_grant;
				edge_data_write_bus_request       <= edge_data_write_bus_request_latched;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Vretex job burst guard
	////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(VertexInterface)),
		.DEPTH(16                    )
	) vertex_job_burst_in_buffer_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (vertex_job_burst_in.valid           ),
		.data_in (vertex_job_burst_in                 ),
		.full    (vertex_buffer_status_internal.full  ),
		.alFull  (vertex_buffer_status_internal.alfull),
		
		.pop     (vertex_request_internal             ),
		.valid   (vertex_buffer_status_internal.valid ),
		.data_out(vertex_job_burst_out                ),
		.empty   (vertex_buffer_status_internal.empty )
	);


endmodule