// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_vertex_job_control.sv
// Create : 2019-09-26 15:19:30
// Revise : 2019-09-30 20:59:15
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_job_control (
	input  logic                          clock                      , // Clock
	input  logic                          rstn                       ,
	input  logic                          enabled_in                 ,
	input  WEDInterface                   wed_request_in             ,
	input  ResponseBufferLine             read_response_in           ,
	input  ReadWriteDataLine              read_data_0_in             ,
	input  ReadWriteDataLine              read_data_1_in             ,
	input  BufferStatus                   read_buffer_status         ,
	input  logic                          vertex_request             ,
	output CommandBufferLine              read_command_out           ,
	output BufferStatus                   vertex_buffer_status       ,
	output VertexInterface                vertex                     ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered
);

	//output latched
	VertexInterface vertex_latched;

	//input lateched
	WEDInterface       wed_request_in_latched  ;
	ResponseBufferLine read_response_in_latched;
	ReadWriteDataLine  read_data_0_in_latched  ;
	ReadWriteDataLine  read_data_1_in_latched  ;
	logic              vertex_request_latched  ;

	CommandBufferLine read_command_out_latched         ;
	BufferStatus      read_buffer_status_internal      ;
	logic             read_command_job_vertex_burst_pop;


	BufferStatus    vertex_buffer_burst_status;
	logic           vertex_buffer_burst_pop   ;
	VertexInterface vertex_burst_variable     ;

	// internal registers to track logic
	// Read/write commands require the size to be a power of 2 (1, 2, 4, 8, 16, 32,64, 128).
	logic [                  0:11] request_size              ;
	logic                          send_request_ready        ;
	logic                          fill_vertex_buffer_pending;
	logic [                   0:7] response_counter          ;
	logic [                  0:63] vertex_next_offest        ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter        ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_id_counter         ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_pushed ;

	VertexInterface vertex_variable;

	logic fill_vertex_buffer;

	logic [0:(VERTEX_SIZE_BITS-1)] in_degree_cacheline               ;
	logic [0:(VERTEX_SIZE_BITS-1)] out_degree_cacheline              ;
	logic [0:(VERTEX_SIZE_BITS-1)] edges_idx_degree_cacheline        ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_in_degree_cacheline       ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_out_degree_cacheline      ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_edges_idx_degree_cacheline;

	logic in_degree_cacheline_ready               ;
	logic out_degree_cacheline_ready              ;
	logic edges_idx_degree_cacheline_ready        ;
	logic inverse_in_degree_cacheline_ready       ;
	logic inverse_out_degree_cacheline_ready      ;
	logic inverse_edges_idx_degree_cacheline_ready;

	logic in_degree_cacheline_pending               ;
	logic out_degree_cacheline_pending              ;
	logic edges_idx_degree_cacheline_pending        ;
	logic inverse_in_degree_cacheline_pending       ;
	logic inverse_out_degree_cacheline_pending      ;
	logic inverse_edges_idx_degree_cacheline_pending;

	logic push_vertex  ;
	logic filter_vertex;
	logic start_shift  ;

	vertex_struct_state current_state, next_state;
	logic               enabled      ;

	assign vertex                 = vertex_latched;
	assign vertex_request_latched = vertex_request;



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
//drive inputs
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched   <= 0;
			read_response_in_latched <= 0;
			read_data_0_in_latched   <= 0;
			read_data_1_in_latched   <= 0;
			// vertex_request_latched     <= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched   <= wed_request_in;
				read_response_in_latched <= read_response_in;
				read_data_0_in_latched   <= read_data_0_in;
				read_data_1_in_latched   <= read_data_1_in;
				// vertex_request_latched <= vertex_request;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//1. Generate Read Commands to obtain vertex structural info
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= SEND_VERTEX_RESET;
		else begin
			if(enabled) begin
				current_state <= next_state;
			end
		end
	end // always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			SEND_VERTEX_RESET : begin
				if(wed_request_in_latched.valid)
					next_state = SEND_VERTEX_INIT;
				else
					next_state = SEND_VERTEX_RESET;
			end
			SEND_VERTEX_INIT : begin
				next_state = SEND_VERTEX_WAIT;
			end
			SEND_VERTEX_WAIT : begin
				if(send_request_ready )
					next_state = CALC_VERTEX_REQ_SIZE;
				else
					next_state = SEND_VERTEX_WAIT;
			end
			CALC_VERTEX_REQ_SIZE : begin
				next_state = SEND_VERTEX_IDLE;
			end
			SEND_VERTEX_IDLE : begin
				next_state = SEND_VERTEX_IN_DEGREE;
			end
			SEND_VERTEX_IN_DEGREE : begin
				next_state = SEND_VERTEX_OUT_DEGREE;
			end
			SEND_VERTEX_OUT_DEGREE : begin
				next_state = SEND_VERTEX_EDGES_IDX;
			end
			SEND_VERTEX_EDGES_IDX : begin
				next_state = SEND_VERTEX_INV_IN_DEGREE;
			end
			SEND_VERTEX_INV_IN_DEGREE : begin
				next_state = SEND_VERTEX_INV_OUT_DEGREE;
			end
			SEND_VERTEX_INV_OUT_DEGREE : begin
				next_state = SEND_VERTEX_INV_EDGES_IDX;
			end
			SEND_VERTEX_INV_EDGES_IDX : begin
				next_state = SEND_VERTEX_WAIT;
			end
		endcase
	end // always_comb

	always_ff @(posedge clock) begin
		case (current_state)
			SEND_VERTEX_RESET : begin
				read_command_out_latched <= 0;
				request_size             <= 0;
				vertex_next_offest       <= 0;
				vertex_num_counter       <= 0;
			end
			SEND_VERTEX_INIT : begin
				read_command_out_latched <= 0;
				vertex_num_counter       <= wed_request_in_latched.wed.num_vertices;
			end
			SEND_VERTEX_WAIT : begin
				read_command_out_latched <= 0;
				request_size             <= 0;
			end
			CALC_VERTEX_REQ_SIZE : begin
				request_size <= cmd_size_calculate(vertex_num_counter);

				if(vertex_num_counter >= CACHELINE_VERTEX_NUM)begin
					vertex_num_counter                     <= vertex_num_counter - CACHELINE_VERTEX_NUM;
					read_command_out_latched.cmd.real_size <= CACHELINE_VERTEX_NUM;
				end
				else if (vertex_num_counter < CACHELINE_VERTEX_NUM) begin
					vertex_num_counter                     <= 0;
					read_command_out_latched.cmd.real_size <= vertex_num_counter;
				end

				read_command_out_latched.cmd.cu_id            <= VERTEX_CONTROL_ID;
				read_command_out_latched.cmd.cmd_type         <= CMD_READ;
				read_command_out_latched.cmd.cacheline_offest <= 0;
			end
			SEND_VERTEX_IDLE      : begin
			end
			SEND_VERTEX_IN_DEGREE : begin
				read_command_out_latched.valid   <= 1'b1;
				read_command_out_latched.command <= READ_CL_NA; // just zero it out
				read_command_out_latched.address <= wed_request_in_latched.wed.vertex_in_degree + vertex_next_offest;
				read_command_out_latched.size    <= request_size;

				read_command_out_latched.cmd.vertex_struct <= IN_DEGREE;
			end
			SEND_VERTEX_OUT_DEGREE : begin
				read_command_out_latched.valid   <= 1'b1;
				read_command_out_latched.command <= READ_CL_NA; // just zero it out
				read_command_out_latched.address <= wed_request_in_latched.wed.vertex_out_degree + vertex_next_offest;
				read_command_out_latched.size    <= request_size;

				read_command_out_latched.cmd.vertex_struct <= OUT_DEGREE;
			end
			SEND_VERTEX_EDGES_IDX : begin
				read_command_out_latched.valid   <= 1'b1;
				read_command_out_latched.command <= READ_CL_NA; // just zero it out
				read_command_out_latched.address <= wed_request_in_latched.wed.vertex_edges_idx + vertex_next_offest;
				read_command_out_latched.size    <= request_size;

				read_command_out_latched.cmd.vertex_struct <= EDGES_IDX;
			end
			SEND_VERTEX_INV_IN_DEGREE : begin
				read_command_out_latched.valid   <= 1'b1;
				read_command_out_latched.command <= READ_CL_NA; // just zero it out
				read_command_out_latched.address <= wed_request_in_latched.wed.inverse_vertex_in_degree + vertex_next_offest;
				read_command_out_latched.size    <= request_size;

				read_command_out_latched.cmd.vertex_struct <= INV_IN_DEGREE;
			end
			SEND_VERTEX_INV_OUT_DEGREE : begin
				read_command_out_latched.valid   <= 1'b1;
				read_command_out_latched.command <= READ_CL_NA; // just zero it out
				read_command_out_latched.address <= wed_request_in_latched.wed.inverse_vertex_out_degree + vertex_next_offest;
				read_command_out_latched.size    <= request_size;

				read_command_out_latched.cmd.vertex_struct <= INV_OUT_DEGREE;
			end
			SEND_VERTEX_INV_EDGES_IDX : begin
				read_command_out_latched.valid   <= 1'b1;
				read_command_out_latched.command <= READ_CL_NA; // just zero it out
				read_command_out_latched.address <= wed_request_in_latched.wed.inverse_vertex_edges_idx + vertex_next_offest;
				read_command_out_latched.size    <= request_size;

				read_command_out_latched.cmd.vertex_struct <= INV_EDGES_IDX;

				vertex_next_offest <= vertex_next_offest + CACHELINE_SIZE;
			end
		endcase
	end // always_ff @(posedge clock)
////////////////////////////////////////////////////////////////////////////
//response tracking logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			response_counter <= 0;
		else begin
			if ( read_command_out.valid) begin
				response_counter <= response_counter + 1;
			end else if (read_response_in_latched.valid) begin
				response_counter <= response_counter - 1;
			end else begin
				response_counter <= response_counter;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Read Vertex data into registers
////////////////////////////////////////////////////////////////////////////


	cu_cacheline_stream cu_cacheline_stream_in_degree (
		.clock         (clock                      ),
		.rstn          (rstn                       ),
		.enabled       (enabled                    ),
		.start_shift   (start_shift                ),
		.read_data_0_in(read_data_0_in_latched     ),
		.read_data_1_in(read_data_1_in_latched     ),
		.vertex_struct (IN_DEGREE                  ),
		.vertex        (in_degree_cacheline        ),
		.pending       (in_degree_cacheline_pending),
		.valid         (in_degree_cacheline_ready  )
	);

	cu_cacheline_stream cu_cacheline_stream_out_degree (
		.clock         (clock                       ),
		.rstn          (rstn                        ),
		.enabled       (enabled                     ),
		.start_shift   (start_shift                 ),
		.read_data_0_in(read_data_0_in_latched      ),
		.read_data_1_in(read_data_1_in_latched      ),
		.vertex_struct (OUT_DEGREE                  ),
		.vertex        (out_degree_cacheline        ),
		.pending       (out_degree_cacheline_pending),
		.valid         (out_degree_cacheline_ready  )
	);

	cu_cacheline_stream cu_cacheline_stream_edges_idx (
		.clock         (clock                             ),
		.rstn          (rstn                              ),
		.enabled       (enabled                           ),
		.start_shift   (start_shift                       ),
		.read_data_0_in(read_data_0_in_latched            ),
		.read_data_1_in(read_data_1_in_latched            ),
		.vertex_struct (EDGES_IDX                         ),
		.vertex        (edges_idx_degree_cacheline        ),
		.pending       (edges_idx_degree_cacheline_pending),
		.valid         (edges_idx_degree_cacheline_ready  )
	);

	cu_cacheline_stream cu_cacheline_stream_inverse_in_degree (
		.clock         (clock                              ),
		.rstn          (rstn                               ),
		.enabled       (enabled                            ),
		.start_shift   (start_shift                        ),
		.read_data_0_in(read_data_0_in_latched             ),
		.read_data_1_in(read_data_1_in_latched             ),
		.vertex_struct (INV_IN_DEGREE                      ),
		.vertex        (inverse_in_degree_cacheline        ),
		.pending       (inverse_in_degree_cacheline_pending),
		.valid         (inverse_in_degree_cacheline_ready  )
	);

	cu_cacheline_stream cu_cacheline_stream_inverse_out_degree (
		.clock         (clock                               ),
		.rstn          (rstn                                ),
		.enabled       (enabled                             ),
		.start_shift   (start_shift                         ),
		.read_data_0_in(read_data_0_in_latched              ),
		.read_data_1_in(read_data_1_in_latched              ),
		.vertex_struct (INV_OUT_DEGREE                      ),
		.vertex        (inverse_out_degree_cacheline        ),
		.pending       (inverse_out_degree_cacheline_pending),
		.valid         (inverse_out_degree_cacheline_ready  )
	);

	cu_cacheline_stream cu_cacheline_stream_inverse_edges_idx (
		.clock         (clock                                     ),
		.rstn          (rstn                                      ),
		.enabled       (enabled                                   ),
		.start_shift   (start_shift                               ),
		.read_data_0_in(read_data_0_in_latched                    ),
		.read_data_1_in(read_data_1_in_latched                    ),
		.vertex_struct (INV_EDGES_IDX                             ),
		.vertex        (inverse_edges_idx_degree_cacheline        ),
		.pending       (inverse_edges_idx_degree_cacheline_pending),
		.valid         (inverse_edges_idx_degree_cacheline_ready  )
	);


////////////////////////////////////////////////////////////////////////////
//Read Vertex registers into vertex job queue
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Vertices
////////////////////////////////////////////////////////////////////////////
	assign fill_vertex_buffer_pending = in_degree_cacheline_pending || out_degree_cacheline_pending|| edges_idx_degree_cacheline_pending ||
		inverse_in_degree_cacheline_pending || inverse_out_degree_cacheline_pending || inverse_edges_idx_degree_cacheline_pending;
	assign send_request_ready = read_buffer_status_internal.empty && vertex_buffer_burst_status.empty && ~fill_vertex_buffer_pending && (|vertex_num_counter) && ~(|response_counter) && wed_request_in_latched.valid;
	assign fill_vertex_buffer = in_degree_cacheline_ready && out_degree_cacheline_ready && edges_idx_degree_cacheline_ready &&
		inverse_in_degree_cacheline_ready && inverse_out_degree_cacheline_ready && inverse_edges_idx_degree_cacheline_ready;
	assign start_shift = fill_vertex_buffer_pending && ~(|response_counter);

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_variable   <= 0;
			vertex_id_counter <= 0;
		end
		else begin
			if(fill_vertex_buffer) begin
				vertex_id_counter                  <= vertex_id_counter+1;
				vertex_variable.valid              <= fill_vertex_buffer;
				vertex_variable.id                 <= vertex_id_counter;
				vertex_variable.in_degree          <= in_degree_cacheline;
				vertex_variable.out_degree         <= out_degree_cacheline;
				vertex_variable.edges_idx          <= edges_idx_degree_cacheline;
				vertex_variable.inverse_in_degree  <= inverse_in_degree_cacheline;
				vertex_variable.inverse_out_degree <= inverse_out_degree_cacheline;
				vertex_variable.inverse_edges_idx  <= inverse_edges_idx_degree_cacheline;
			end else begin
				vertex_variable <= 0;
			end
		end
	end

	// if the vertex has no in/out neighbors don't schedule it vertex_job_latched.inverse_out_degree;
	assign push_vertex   = (vertex_variable.valid)   && ((|vertex_variable.inverse_out_degree));
	assign filter_vertex = (vertex_variable.valid)   && (~(|vertex_variable.inverse_out_degree));

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_counter_pushed <= 0;
		end else begin
			if(push_vertex && ~vertex_request_latched)
				vertex_job_counter_pushed <= vertex_job_counter_pushed + 1;
			else if (vertex_request_latched && ~push_vertex)
				vertex_job_counter_pushed <= vertex_job_counter_pushed - 1;
			else
				vertex_job_counter_pushed <= vertex_job_counter_pushed;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_counter_filtered <= 0;
		end else begin
			if(filter_vertex)
				vertex_job_counter_filtered <= vertex_job_counter_filtered + 1;;
		end
	end



////////////////////////////////////////////////////////////////////////////
//Read Vertex double buffer
////////////////////////////////////////////////////////////////////////////
	assign vertex_buffer_burst_pop = ~vertex_buffer_status.alfull && ~vertex_buffer_burst_status.empty;

	fifo #(
		.WIDTH($bits(VertexInterface)),
		.DEPTH(CACHELINE_VERTEX_NUM  )
	) vertex_job_buffer_burst_fifo_instant (
		.clock   (clock                            ),
		.rstn    (rstn                             ),
		
		.push    (push_vertex                      ),
		.data_in (vertex_variable                  ),
		.full    (vertex_buffer_burst_status.full  ),
		.alFull  (vertex_buffer_burst_status.alfull),
		
		.pop     (vertex_buffer_burst_pop          ),
		.valid   (vertex_buffer_burst_status.valid ),
		.data_out(vertex_burst_variable            ),
		.empty   (vertex_buffer_burst_status.empty )
	);

	fifo #(
		.WIDTH($bits(VertexInterface)   ),
		.DEPTH(CU_VERTEX_JOB_BUFFER_SIZE)
	) vertex_job_buffer_fifo_instant (
		.clock   (clock                      ),
		.rstn    (rstn                       ),
		
		.push    (vertex_burst_variable.valid),
		.data_in (vertex_burst_variable      ),
		.full    (vertex_buffer_status.full  ),
		.alFull  (vertex_buffer_status.alfull),
		
		.pop     (vertex_request_latched     ),
		.valid   (vertex_buffer_status.valid ),
		.data_out(vertex_latched             ),
		.empty   (vertex_buffer_status.empty )
	);

///////////////////////////////////////////////////////////////////////////
//Read Command Vertex double buffer
////////////////////////////////////////////////////////////////////////////


	assign read_command_job_vertex_burst_pop = ~read_buffer_status.alfull && ~read_buffer_status_internal.empty;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(8                       )
	) read_command_job_vertex_burst_fifo_instant (
		.clock   (clock                             ),
		.rstn    (rstn                              ),
		
		.push    (read_command_out_latched.valid    ),
		.data_in (read_command_out_latched          ),
		.full    (read_buffer_status_internal.full  ),
		.alFull  (read_buffer_status_internal.alfull),
		
		.pop     (read_command_job_vertex_burst_pop ),
		.valid   (read_buffer_status_internal.valid ),
		.data_out(read_command_out                  ),
		.empty   (read_buffer_status_internal.empty )
	);



endmodule