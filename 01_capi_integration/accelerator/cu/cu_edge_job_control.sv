// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_edge_job_control.sv
// Create : 2019-09-26 15:18:56
// Revise : 2019-10-09 18:26:23
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_job_control #(parameter CU_ID = 1) (
	input  logic                        clock                  , // Clock
	input  logic                        rstn                   ,
	input  logic                        enabled_in             ,
	input  WEDInterface                 wed_request_in         ,
	input  ResponseBufferLine           read_response_in       ,
	input  ReadWriteDataLine            read_data_0_in         ,
	input  ReadWriteDataLine            read_data_1_in         ,
	input  BufferStatus                 read_buffer_status     ,
	input  logic                        edge_request           ,
	input  VertexInterface              vertex_job             ,
	output CommandBufferLine            read_command_out       ,
	output BufferStatus                 edge_buffer_status     ,
	output EdgeInterface                edge_job               ,
	output logic [0:(EDGE_SIZE_BITS-1)] edge_job_counter_pushed
);

	//output latched
	EdgeInterface edge_latched;

	//input lateched
	WEDInterface       wed_request_in_latched  ;
	ResponseBufferLine read_response_in_latched;
	ReadWriteDataLine  read_data_0_in_latched  ;
	ReadWriteDataLine  read_data_1_in_latched  ;
	logic              edge_request_latched    ;

	CommandBufferLine read_command_out_latched       ;
	BufferStatus      read_buffer_status_internal    ;
	logic             read_command_job_edge_burst_pop;


	BufferStatus  edge_buffer_burst_status;
	logic         edge_buffer_burst_pop   ;
	EdgeInterface edge_burst_variable     ;

	// internal registers to track logic
	// Read/write commands require the size to be a power of 2 (1, 2, 4, 8, 16, 32,64, 128).
	logic [0:11] request_size            ;
	logic        send_request_ready      ;
	logic        fill_edge_buffer_pending;
	logic [ 0:7] response_counter        ;
	logic [0:63] edge_next_offest        ;

	logic [0:(EDGE_SIZE_BITS-1)] edge_num_counter;
	logic [0:(EDGE_SIZE_BITS-1)] edge_id_counter ;
	logic [                 0:7] shift_seek      ;
	logic [                 0:7] remainder       ;
	logic [                0:63] aligned         ;
	EdgeInterface                edge_variable   ;

	logic                        fill_edge_buffer  ;
	VertexInterface              vertex_job_latched;
	logic [0:(EDGE_SIZE_BITS-1)] src_cacheline     ;
	logic [0:(EDGE_SIZE_BITS-1)] dest_cacheline    ;
	logic [0:(EDGE_SIZE_BITS-1)] weight_cacheline  ;

	logic src_cacheline_pending   ;
	logic dest_cacheline_pending  ;
	logic weight_cacheline_pending;

	logic src_cacheline_ready   ;
	logic dest_cacheline_ready  ;
	logic weight_cacheline_ready;

	logic start_shift;
	logic push_edge  ;

	logic done_vertex_edge_processing;
	logic read_vertex                ;
	logic read_vertex_new            ;
	logic read_vertex_new_latched    ;

	edge_struct_state current_state, next_state;

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
			edge_job <= 0;
		end else begin
			if(enabled) begin
				edge_job <= edge_latched;
			end
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
			edge_request_latched     <= 0;
			vertex_job_latched       <= 0;
			read_vertex_new          <= 0;
			read_vertex_new_latched  <= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched   <= wed_request_in;
				read_response_in_latched <= read_response_in;
				read_data_0_in_latched   <= read_data_0_in;
				read_data_1_in_latched   <= read_data_1_in;
				edge_request_latched     <= edge_request;

				if(read_vertex)begin
					vertex_job_latched <= vertex_job;
					read_vertex_new    <= 1;
				end

				if(read_vertex_new && (~(|edge_num_counter)))begin
					read_vertex_new <= 0;
				end

				read_vertex_new_latched <= read_vertex_new;
			end
		end
	end

	always_comb begin
		read_vertex = 0;
		if(done_vertex_edge_processing && vertex_job.valid && ~vertex_job_latched.valid)begin
			read_vertex = 1;
		end

		if(done_vertex_edge_processing && vertex_job.valid && vertex_job_latched.valid)begin
			if(vertex_job_latched.id != vertex_job.id)begin
				read_vertex = 1;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//1. Generate Read Commands to obtain edge structural info
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= SEND_EDGE_RESET;
		else
			current_state <= next_state;
	end // always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			SEND_EDGE_RESET : begin
				if(vertex_job_latched.valid && wed_request_in_latched.valid)
					next_state = SEND_EDGE_INIT;
				else
					next_state = SEND_EDGE_RESET;
			end
			SEND_EDGE_INIT : begin
				if(|edge_num_counter)
					next_state = SEND_EDGE_WAIT;
				else
					next_state = SEND_EDGE_INIT;
			end
			SEND_EDGE_WAIT : begin
				if(send_request_ready)
					next_state = CALC_EDGE_REQ_SIZE;
			end
			CALC_EDGE_REQ_SIZE : begin
				next_state = SEND_EDGE_IDLE;
			end
			SEND_EDGE_IDLE : begin
				next_state = SEND_EDGE_INV_SRC;
			end
			SEND_EDGE_INV_SRC : begin
				next_state = SEND_EDGE_INV_DEST;
			end
			SEND_EDGE_INV_DEST : begin
				next_state = SEND_EDGE_INV_WEIGHT;
			end
			SEND_EDGE_INV_WEIGHT : begin
				if(|edge_num_counter)
					next_state = SEND_EDGE_WAIT;
				else
					next_state = SEND_EDGE_INIT;
			end
		endcase
	end // always_comb

	always_ff @(posedge clock) begin
		case (current_state)
			SEND_EDGE_RESET : begin
				read_command_out_latched    <= 0;
				request_size                <= 0;
				edge_next_offest            <= 0;
				edge_num_counter            <= 0;
				shift_seek                  <= 0;
				remainder                   <= 0;
				aligned                     <= 0;
				done_vertex_edge_processing <= 1;
			end
			SEND_EDGE_INIT : begin
				read_command_out_latched <= 0;
				if(read_vertex_new_latched)begin
					edge_num_counter <= vertex_job_latched.inverse_out_degree;
					edge_next_offest <= (vertex_job_latched.inverse_edges_idx << $clog2(EDGE_SIZE));
				end
			end
			SEND_EDGE_WAIT : begin
				done_vertex_edge_processing <= 0;
				read_command_out_latched    <= 0;
				request_size                <= 0;
				remainder                   <= (edge_next_offest & ADDRESS_EDGE_MOD_MASK);
				aligned                     <= (edge_next_offest & ADDRESS_EDGE_ALIGN_MASK);
			end
			CALC_EDGE_REQ_SIZE : begin
				if(|remainder) begin // misaligned access
					request_size <= CACHELINE_SIZE; // bring the whole cacheline

					if(edge_num_counter >= ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE))) begin
						edge_num_counter                       <= edge_num_counter - ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE));
						read_command_out_latched.cmd.real_size <= ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE));
					end
					else if (edge_num_counter < ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE))) begin
						edge_num_counter                       <= 0;
						read_command_out_latched.cmd.real_size <= edge_num_counter;
					end
				end else begin
					request_size <= cmd_size_calculate(edge_num_counter);

					if(edge_num_counter >= CACHELINE_EDGE_NUM)begin
						edge_num_counter                       <= edge_num_counter - CACHELINE_EDGE_NUM;
						read_command_out_latched.cmd.real_size <= CACHELINE_EDGE_NUM;
					end
					else if (edge_num_counter < CACHELINE_EDGE_NUM) begin
						edge_num_counter                       <= 0;
						read_command_out_latched.cmd.real_size <= edge_num_counter;
					end
				end

				read_command_out_latched.cmd.cacheline_offest <= (remainder >> $clog2(EDGE_SIZE));
				read_command_out_latched.cmd.cu_id            <= CU_ID;
				read_command_out_latched.cmd.cmd_type         <= CMD_READ;
			end
			SEND_EDGE_IDLE    : begin
			end
			SEND_EDGE_INV_SRC : begin
				read_command_out_latched.valid             <= 1'b1;
				read_command_out_latched.command           <= READ_CL_NA; // just zero it out
				read_command_out_latched.address           <= wed_request_in_latched.wed.inverse_edges_array_src + aligned;
				read_command_out_latched.size              <= request_size;
				read_command_out_latched.cmd.vertex_struct <= INV_EDGE_ARRAY_SRC;
			end
			SEND_EDGE_INV_DEST : begin
				read_command_out_latched.valid   <= 1'b1;
				read_command_out_latched.command <= READ_CL_NA; // just zero it out
				read_command_out_latched.address <= wed_request_in_latched.wed.inverse_edges_array_dest + aligned;
				read_command_out_latched.size    <= request_size;

				read_command_out_latched.cmd.vertex_struct <= INV_EDGE_ARRAY_DEST;
			end
			SEND_EDGE_INV_WEIGHT : begin
				read_command_out_latched.valid   <= 1'b1;
				read_command_out_latched.command <= READ_CL_NA; // just zero it out
				read_command_out_latched.address <= wed_request_in_latched.wed.inverse_edges_array_weight + aligned;
				read_command_out_latched.size    <= request_size;

				read_command_out_latched.cmd.vertex_struct <= INV_EDGE_ARRAY_WEIGHT;

				if(|remainder)
					edge_next_offest <= edge_next_offest + (CACHELINE_SIZE-remainder);
				else
					edge_next_offest <= edge_next_offest + CACHELINE_SIZE;

				if(~(|edge_num_counter))
					done_vertex_edge_processing <= 1;
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
			if ( read_command_out_latched.valid) begin
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

	cu_cacheline_stream #(.SIZE_BITS(EDGE_SIZE_BITS)) cu_cacheline_stream_inverse_src (
		.clock         (clock                 ),
		.rstn          (rstn                  ),
		.enabled       (enabled               ),
		.start_shift   (start_shift           ),
		.read_data_0_in(read_data_0_in_latched),
		.read_data_1_in(read_data_1_in_latched),
		.vertex_struct (INV_EDGE_ARRAY_SRC    ),
		.vertex        (src_cacheline         ),
		.pending       (src_cacheline_pending ),
		.valid         (src_cacheline_ready   )
	);

	cu_cacheline_stream #(.SIZE_BITS(EDGE_SIZE_BITS)) cu_cacheline_stream_inverse_dest (
		.clock         (clock                 ),
		.rstn          (rstn                  ),
		.enabled       (enabled               ),
		.start_shift   (start_shift           ),
		.read_data_0_in(read_data_0_in_latched),
		.read_data_1_in(read_data_1_in_latched),
		.vertex_struct (INV_EDGE_ARRAY_DEST   ),
		.vertex        (dest_cacheline        ),
		.pending       (dest_cacheline_pending),
		.valid         (dest_cacheline_ready  )
	);

	cu_cacheline_stream #(.SIZE_BITS(EDGE_SIZE_BITS)) cu_cacheline_stream_inverse_weight (
		.clock         (clock                   ),
		.rstn          (rstn                    ),
		.enabled       (enabled                 ),
		.start_shift   (start_shift             ),
		.read_data_0_in(read_data_0_in_latched  ),
		.read_data_1_in(read_data_1_in_latched  ),
		.vertex_struct (INV_EDGE_ARRAY_WEIGHT   ),
		.vertex        (weight_cacheline        ),
		.pending       (weight_cacheline_pending),
		.valid         (weight_cacheline_ready  )
	);


////////////////////////////////////////////////////////////////////////////
//Read Edges registers into edge job queue
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Vertices
////////////////////////////////////////////////////////////////////////////
	assign fill_edge_buffer_pending = src_cacheline_pending || dest_cacheline_pending || weight_cacheline_pending;
	assign send_request_ready       = read_buffer_status_internal.empty && edge_buffer_burst_status.empty && ~fill_edge_buffer_pending &&  (|edge_num_counter)
		&& ~(|response_counter) && wed_request_in_latched.valid && vertex_job_latched.valid;
	assign fill_edge_buffer = src_cacheline_ready && dest_cacheline_ready && weight_cacheline_ready;
	assign start_shift      = fill_edge_buffer_pending && ~(|response_counter);


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_variable   <= 0;
			edge_id_counter <= 0;
		end
		else begin
			if(fill_edge_buffer) begin
				edge_id_counter      <= edge_id_counter + 1;
				edge_variable.valid  <= fill_edge_buffer;
				edge_variable.id     <= edge_id_counter;
				edge_variable.src    <= swap_endianness_edge_read(src_cacheline);
				edge_variable.dest   <= swap_endianness_edge_read(dest_cacheline);
				edge_variable.weight <= swap_endianness_edge_read(weight_cacheline);
			end else begin
				edge_variable <= 0;
			end
		end
	end

	// if the edge has no in/out neighbors don't schedule it
	assign push_edge = (edge_variable.valid);

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_job_counter_pushed <= 0;
		end else begin
			if(vertex_job_latched.valid)begin
				if(push_edge)begin
					edge_job_counter_pushed <= edge_job_counter_pushed + 1;
				end
				if(edge_job_counter_pushed == vertex_job_latched.inverse_out_degree)begin
					edge_job_counter_pushed <= 0;
				end
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Read Edge double buffer
////////////////////////////////////////////////////////////////////////////

	assign edge_buffer_burst_pop = ~edge_buffer_status.alfull && ~edge_buffer_burst_status.empty;

	fifo #(
		.WIDTH($bits(EdgeInterface)),
		.DEPTH(CACHELINE_EDGE_NUM  )
	) edge_job_buffer_burst_fifo_instant (
		.clock   (clock                          ),
		.rstn    (rstn                           ),
		
		.push    (push_edge                      ),
		.data_in (edge_variable                  ),
		.full    (edge_buffer_burst_status.full  ),
		.alFull  (edge_buffer_burst_status.alfull),
		
		.pop     (edge_buffer_burst_pop          ),
		.valid   (edge_buffer_burst_status.valid ),
		.data_out(edge_burst_variable            ),
		.empty   (edge_buffer_burst_status.empty )
	);

	fifo #(
		.WIDTH($bits(EdgeInterface)   ),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE)
	) edge_job_buffer_fifo_instant (
		.clock   (clock                    ),
		.rstn    (rstn                     ),
		
		.push    (edge_burst_variable.valid),
		.data_in (edge_burst_variable      ),
		.full    (edge_buffer_status.full  ),
		.alFull  (edge_buffer_status.alfull),
		
		.pop     (edge_request_latched     ),
		.valid   (edge_buffer_status.valid ),
		.data_out(edge_latched             ),
		.empty   (edge_buffer_status.empty )
	);


///////////////////////////////////////////////////////////////////////////
//Read Command Edge double buffer
////////////////////////////////////////////////////////////////////////////

	assign read_command_job_edge_burst_pop = ~read_buffer_status_internal.empty && ~read_buffer_status.alfull;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(4                       )
	) read_command_job_edge_burst_fifo_instant (
		.clock   (clock                             ),
		.rstn    (rstn                              ),
		
		.push    (read_command_out_latched.valid    ),
		.data_in (read_command_out_latched          ),
		.full    (read_buffer_status_internal.full  ),
		.alFull  (read_buffer_status_internal.alfull),
		
		.pop     (read_command_job_edge_burst_pop   ),
		.valid   (read_buffer_status_internal.valid ),
		.data_out(read_command_out                  ),
		.empty   (read_buffer_status_internal.empty )
	);

endmodule