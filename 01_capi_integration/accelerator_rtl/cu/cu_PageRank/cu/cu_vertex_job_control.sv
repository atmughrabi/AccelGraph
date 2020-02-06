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
// Revise : 2019-11-08 10:50:37
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_job_control (
	input  logic                          clock                      , // Clock
	input  logic                          rstn                       ,
	input  logic                          enabled_in                 ,
	input  logic [                  0:63] cu_configure               ,
	input  WEDInterface                   wed_request_in             ,
	input  ResponseBufferLine             read_response_in           ,
	input  ReadWriteDataLine              read_data_0_in             ,
	input  ReadWriteDataLine              read_data_1_in             ,
	input  BufferStatus                   read_buffer_status         ,
	input  logic                          vertex_request             ,
	output CommandBufferLine              read_command_out           ,
	output BufferStatus                   vertex_buffer_status       ,
	output VertexInterface                vertex                     ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter         ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_filtered
);


	localparam CACHELINE_STREAM_READ_ADDR_BITS  = $clog2((VERTEX_SIZE_BITS < CACHELINE_SIZE_BITS_HF) ? (1 * CACHELINE_SIZE_BITS_HF)/VERTEX_SIZE_BITS : 1);
	localparam CACHELINE_STREAM_WRITE_ADDR_BITS = $clog2((VERTEX_SIZE_BITS < CACHELINE_SIZE_BITS_HF) ? 1 : (1 * VERTEX_SIZE_BITS)/CACHELINE_SIZE_BITS_HF);

	logic [0:(CACHELINE_STREAM_WRITE_ADDR_BITS-1)] address_wr_0;
	logic [ 0:(CACHELINE_STREAM_READ_ADDR_BITS-1)] address_rd_0;
	logic [0:(CACHELINE_STREAM_WRITE_ADDR_BITS-1)] address_wr_1;
	logic [ 0:(CACHELINE_STREAM_READ_ADDR_BITS-1)] address_rd_1;

	logic [0:CACHELINE_INT_COUNTER_BITS] shift_limit_0    ;
	logic [0:CACHELINE_INT_COUNTER_BITS] shift_limit_1    ;
	logic                                shift_limit_clear;
	logic [0:CACHELINE_INT_COUNTER_BITS] shift_counter    ;
	logic                                start_shift_hf_0 ;
	logic                                start_shift_hf_1 ;
	logic                                switch_shift_hf  ;
	logic                                push_shift       ;

	logic we_IN_DEGREE_0     ;
	logic we_OUT_DEGREE_0    ;
	logic we_EDGES_IDX_0     ;
	logic we_INV_IN_DEGREE_0 ;
	logic we_INV_OUT_DEGREE_0;
	logic we_INV_EDGES_IDX_0 ;

	logic we_IN_DEGREE_1     ;
	logic we_OUT_DEGREE_1    ;
	logic we_EDGES_IDX_1     ;
	logic we_INV_IN_DEGREE_1 ;
	logic we_INV_OUT_DEGREE_1;
	logic we_INV_EDGES_IDX_1 ;

	ReadWriteDataLine read_data_0_in_latched_S2;
	ReadWriteDataLine read_data_1_in_latched_S2;

	logic clear_data_ready      ;
	logic fill_vertex_job_buffer;

	//output latched
	VertexInterface vertex_latched;

	//input lateched
	WEDInterface       wed_request_in_latched  ;
	ResponseBufferLine read_response_in_latched;
	ReadWriteDataLine  read_data_0_in_latched  ;
	ReadWriteDataLine  read_data_1_in_latched  ;

	logic vertex_request_latched;

	CommandBufferLine read_command_out_latched         ;
	CommandBufferLine read_command_out_latched_S2      ;
	BufferStatus      read_buffer_status_internal      ;
	logic             read_command_job_vertex_burst_pop;

	BufferStatus    vertex_buffer_burst_status;
	logic           vertex_buffer_burst_pop   ;
	VertexInterface vertex_burst_variable     ;

	// internal registers to track logic
	// Read/write commands require the size to be a power of 2 (1, 2, 4, 8, 16, 32,64, 128).
	logic                          send_request_ready       ;
	logic [                  0:63] vertex_next_offest       ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter       ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_id_counter        ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_pushed;
	logic                          generate_read_command    ;
	logic                          setup_read_command       ;
	VertexInterface                vertex_variable          ;

	logic [0:(VERTEX_SIZE_BITS-1)] in_degree_data               ;
	logic [0:(VERTEX_SIZE_BITS-1)] out_degree_data              ;
	logic [0:(VERTEX_SIZE_BITS-1)] edges_idx_degree_data        ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_in_degree_data       ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_out_degree_data      ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_edges_idx_degree_data;

	logic [0:(VERTEX_SIZE_BITS-1)] in_degree_data_0               ;
	logic [0:(VERTEX_SIZE_BITS-1)] out_degree_data_0              ;
	logic [0:(VERTEX_SIZE_BITS-1)] edges_idx_degree_data_0        ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_in_degree_data_0       ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_out_degree_data_0      ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_edges_idx_degree_data_0;

	logic [0:(VERTEX_SIZE_BITS-1)] in_degree_data_1               ;
	logic [0:(VERTEX_SIZE_BITS-1)] out_degree_data_1              ;
	logic [0:(VERTEX_SIZE_BITS-1)] edges_idx_degree_data_1        ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_in_degree_data_1       ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_out_degree_data_1      ;
	logic [0:(VERTEX_SIZE_BITS-1)] inverse_edges_idx_degree_data_1;

	logic in_degree_data_ready               ;
	logic out_degree_data_ready              ;
	logic edges_idx_degree_data_ready        ;
	logic inverse_in_degree_data_ready       ;
	logic inverse_out_degree_data_ready      ;
	logic inverse_edges_idx_degree_data_ready;

	logic push_vertex  ;
	logic filter_vertex;


	vertex_struct_state current_state, next_state;
	logic               enabled             ;
	logic               enabled_cmd         ;
	logic [0:63]        cu_configure_latched;



	assign vertex                 = vertex_latched;
	assign vertex_request_latched = vertex_request;



////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled <= 0;
			enabled_cmd <= 0;
		end else begin
			enabled <= enabled_in;
			enabled_cmd <= enabled && (|cu_configure_latched);
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
			cu_configure_latched     <= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched   <= wed_request_in;
				read_response_in_latched <= read_response_in;
				read_data_0_in_latched   <= read_data_0_in;
				read_data_1_in_latched   <= read_data_1_in;
				// vertex_request_latched <= vertex_request;
				if((|cu_configure))
					cu_configure_latched <= cu_configure;
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
				if(wed_request_in_latched.valid && enabled_cmd)
					next_state = SEND_VERTEX_INIT;
				else
					next_state = SEND_VERTEX_RESET;
			end
			SEND_VERTEX_INIT : begin
				next_state = SEND_VERTEX_IDLE;
			end
			SEND_VERTEX_IDLE : begin
				if(send_request_ready)
					next_state = START_VERTEX_REQ;
				else
					next_state = SEND_VERTEX_IDLE;
			end
			START_VERTEX_REQ : begin
				next_state = CALC_VERTEX_REQ_SIZE;
			end
			CALC_VERTEX_REQ_SIZE : begin
				next_state = SEND_VERTEX_START;
			end
			SEND_VERTEX_START : begin
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
				next_state = WAIT_VERTEX_DATA;
			end
			WAIT_VERTEX_DATA : begin
				if(fill_vertex_job_buffer)
					next_state = SHIFT_VERTEX_DATA_START;
				else
					next_state = WAIT_VERTEX_DATA;
			end
			SHIFT_VERTEX_DATA_START : begin
				next_state = SHIFT_VERTEX_DATA_0;
			end
			SHIFT_VERTEX_DATA_0 : begin
				if((shift_counter < shift_limit_0))
					next_state = SHIFT_VERTEX_DATA_0;
				else
					next_state = SHIFT_VERTEX_DATA_DONE_0;
			end
			SHIFT_VERTEX_DATA_DONE_0 : begin
				next_state = SHIFT_VERTEX_DATA_1;
			end
			SHIFT_VERTEX_DATA_1 : begin
				if((shift_counter < shift_limit_1))
					next_state = SHIFT_VERTEX_DATA_1;
				else
					next_state = SHIFT_VERTEX_DATA_DONE_1;
			end
			SHIFT_VERTEX_DATA_DONE_1 : begin
				next_state = SEND_VERTEX_IDLE;
			end
		endcase
	end // always_comb

	always_ff @(posedge clock) begin
		case (current_state)
			SEND_VERTEX_RESET : begin
				read_command_out_latched <= 0;
				vertex_next_offest       <= 0;
				generate_read_command    <= 0;
				setup_read_command       <= 0;
				clear_data_ready         <= 0;
				shift_limit_clear        <= 0;
				start_shift_hf_0         <= 0;
				start_shift_hf_1         <= 0;
				switch_shift_hf          <= 0;
				shift_counter            <= 0;
				address_rd_0             <= 0;
				address_rd_1             <= 0;
			end
			SEND_VERTEX_INIT : begin
				read_command_out_latched <= 0;
				setup_read_command       <= 1;
			end
			SEND_VERTEX_IDLE : begin
				read_command_out_latched <= 0;
				setup_read_command       <= 0;
				shift_limit_clear        <= 0;
				shift_counter            <= 0;
				address_rd_0             <= 0;
				address_rd_1             <= 0;
			end
			START_VERTEX_REQ : begin
				read_command_out_latched <= 0;
				generate_read_command    <= 1;
				shift_limit_clear        <= 0;
			end
			CALC_VERTEX_REQ_SIZE : begin
				generate_read_command <= 0;
			end
			SEND_VERTEX_START : begin
				read_command_out_latched <= read_command_out_latched_S2;
			end
			SEND_VERTEX_IN_DEGREE : begin
				read_command_out_latched.valid            <= 1'b1;
				read_command_out_latched.address          <= wed_request_in_latched.wed.vertex_in_degree + vertex_next_offest;
				read_command_out_latched.cmd.array_struct <= IN_DEGREE;
			end
			SEND_VERTEX_OUT_DEGREE : begin
				read_command_out_latched.address          <= wed_request_in_latched.wed.vertex_out_degree + vertex_next_offest;
				read_command_out_latched.cmd.array_struct <= OUT_DEGREE;
			end
			SEND_VERTEX_EDGES_IDX : begin
				read_command_out_latched.address          <= wed_request_in_latched.wed.vertex_edges_idx + vertex_next_offest;
				read_command_out_latched.cmd.array_struct <= EDGES_IDX;
			end
			SEND_VERTEX_INV_IN_DEGREE : begin
				read_command_out_latched.address          <= wed_request_in_latched.wed.inverse_vertex_in_degree + vertex_next_offest;
				read_command_out_latched.cmd.array_struct <= INV_IN_DEGREE;
			end
			SEND_VERTEX_INV_OUT_DEGREE : begin
				read_command_out_latched.address          <= wed_request_in_latched.wed.inverse_vertex_out_degree + vertex_next_offest;
				read_command_out_latched.cmd.array_struct <= INV_OUT_DEGREE;
			end
			SEND_VERTEX_INV_EDGES_IDX : begin
				read_command_out_latched.address          <= wed_request_in_latched.wed.inverse_vertex_edges_idx + vertex_next_offest;
				read_command_out_latched.cmd.array_struct <= INV_EDGES_IDX;
				vertex_next_offest                        <= vertex_next_offest + CACHELINE_SIZE;
			end
			WAIT_VERTEX_DATA : begin
				read_command_out_latched <= 0;
				if(fill_vertex_job_buffer) begin
					clear_data_ready <= 1;
				end
			end
			SHIFT_VERTEX_DATA_START : begin
				clear_data_ready <= 0;
				start_shift_hf_0 <= 0;
				start_shift_hf_1 <= 0;
				switch_shift_hf  <= 0;
			end
			SHIFT_VERTEX_DATA_0 : begin
				start_shift_hf_0 <= 1;
				start_shift_hf_1 <= 0;
				switch_shift_hf  <= 0;
				shift_counter    <= shift_counter + 1;
				address_rd_0     <= address_rd_0 + 1;
			end
			SHIFT_VERTEX_DATA_DONE_0 : begin
				start_shift_hf_0 <= 0;
				start_shift_hf_1 <= 0;
				switch_shift_hf  <= 0;
				address_rd_0     <= 0;
				shift_counter    <= 0;
			end
			SHIFT_VERTEX_DATA_1 : begin
				start_shift_hf_0 <= 0;
				start_shift_hf_1 <= 1;
				switch_shift_hf  <= 1;
				shift_counter    <= shift_counter + 1;
				address_rd_1     <= address_rd_1 + 1;
			end
			SHIFT_VERTEX_DATA_DONE_1 : begin
				start_shift_hf_0  <= 0;
				start_shift_hf_1  <= 0;
				shift_limit_clear <= 1;
				switch_shift_hf   <= 0;
				shift_counter     <= 0;
				address_rd_0      <= 0;
				address_rd_1      <= 0;
			end
		endcase
	end // always_ff @(posedge clock)

////////////////////////////////////////////////////////////////////////////
//generate Vertex data offset
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_out_latched_S2 <= 0;
			vertex_num_counter          <= 0;
		end else begin
			if(setup_read_command)
				vertex_num_counter <= wed_request_in_latched.wed.num_vertices;

			if (generate_read_command) begin
				if(vertex_num_counter > CACHELINE_VERTEX_NUM)begin
					vertex_num_counter                              <= vertex_num_counter - CACHELINE_VERTEX_NUM;
					read_command_out_latched_S2.cmd.real_size       <= CACHELINE_VERTEX_NUM;
					read_command_out_latched_S2.cmd.real_size_bytes <= 128;
					read_command_out_latched_S2.size                <= 12'h080;

					if (cu_configure_latched[3]) begin
						read_command_out_latched_S2.command <= READ_CL_S;
					end else begin
						read_command_out_latched_S2.command <= READ_CL_NA;
					end

				end
				else if (vertex_num_counter <= CACHELINE_VERTEX_NUM) begin
					vertex_num_counter                              <= 0;
					read_command_out_latched_S2.cmd.real_size       <= vertex_num_counter;
					read_command_out_latched_S2.cmd.real_size_bytes <= (vertex_num_counter << $clog2(VERTEX_SIZE));

					if (cu_configure_latched[3]) begin
						read_command_out_latched_S2.command <= READ_CL_S;
						read_command_out_latched_S2.size    <= 12'h080;
					end else begin
						read_command_out_latched_S2.command <= READ_PNA;
						read_command_out_latched_S2.size    <= cmd_size_calculate(vertex_num_counter);
					end
				end

				read_command_out_latched_S2.cmd.cu_id            <= VERTEX_CONTROL_ID;
				read_command_out_latched_S2.cmd.cmd_type         <= CMD_READ;
				read_command_out_latched_S2.cmd.cacheline_offest <= 0;

				read_command_out_latched_S2.cmd.abt <= map_CABT(cu_configure_latched[0:2]);
				read_command_out_latched_S2.abt     <= map_CABT(cu_configure_latched[0:2]);
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Read Vertex data into registers
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			we_IN_DEGREE_0            <= 0;
			we_OUT_DEGREE_0           <= 0;
			we_EDGES_IDX_0            <= 0;
			we_INV_IN_DEGREE_0        <= 0;
			we_INV_OUT_DEGREE_0       <= 0;
			we_INV_EDGES_IDX_0        <= 0;
			address_wr_0              <= 0;
			read_data_0_in_latched_S2 <= 0;
		end else begin
			if(enabled_cmd && read_data_0_in_latched.valid) begin

				read_data_0_in_latched_S2 <= read_data_0_in_latched;

				case (read_data_0_in_latched.cmd.array_struct)
					IN_DEGREE : begin
						we_IN_DEGREE_0      <= 1;
						we_OUT_DEGREE_0     <= 0;
						we_EDGES_IDX_0      <= 0;
						we_INV_IN_DEGREE_0  <= 0;
						we_INV_OUT_DEGREE_0 <= 0;
						we_INV_EDGES_IDX_0  <= 0;
					end
					OUT_DEGREE : begin
						we_IN_DEGREE_0      <= 0;
						we_OUT_DEGREE_0     <= 1;
						we_EDGES_IDX_0      <= 0;
						we_INV_IN_DEGREE_0  <= 0;
						we_INV_OUT_DEGREE_0 <= 0;
						we_INV_EDGES_IDX_0  <= 0;
					end
					EDGES_IDX : begin
						we_IN_DEGREE_0      <= 0;
						we_OUT_DEGREE_0     <= 0;
						we_EDGES_IDX_0      <= 1;
						we_INV_IN_DEGREE_0  <= 0;
						we_INV_OUT_DEGREE_0 <= 0;
						we_INV_EDGES_IDX_0  <= 0;
					end
					INV_IN_DEGREE : begin
						we_IN_DEGREE_0      <= 0;
						we_OUT_DEGREE_0     <= 0;
						we_EDGES_IDX_0      <= 0;
						we_INV_IN_DEGREE_0  <= 1;
						we_INV_OUT_DEGREE_0 <= 0;
						we_INV_EDGES_IDX_0  <= 0;
					end
					INV_OUT_DEGREE : begin
						we_IN_DEGREE_0      <= 0;
						we_OUT_DEGREE_0     <= 0;
						we_EDGES_IDX_0      <= 0;
						we_INV_IN_DEGREE_0  <= 0;
						we_INV_OUT_DEGREE_0 <= 1;
						we_INV_EDGES_IDX_0  <= 0;
					end
					INV_EDGES_IDX : begin
						we_IN_DEGREE_0      <= 0;
						we_OUT_DEGREE_0     <= 0;
						we_EDGES_IDX_0      <= 0;
						we_INV_IN_DEGREE_0  <= 0;
						we_INV_OUT_DEGREE_0 <= 0;
						we_INV_EDGES_IDX_0  <= 1;
					end
					default : begin
						we_IN_DEGREE_0      <= 0;
						we_OUT_DEGREE_0     <= 0;
						we_EDGES_IDX_0      <= 0;
						we_INV_IN_DEGREE_0  <= 0;
						we_INV_OUT_DEGREE_0 <= 0;
						we_INV_EDGES_IDX_0  <= 0;
						address_wr_0        <= 0;
					end
				endcase
			end else begin
				we_IN_DEGREE_0            <= 0;
				we_OUT_DEGREE_0           <= 0;
				we_EDGES_IDX_0            <= 0;
				we_INV_IN_DEGREE_0        <= 0;
				we_INV_OUT_DEGREE_0       <= 0;
				we_INV_EDGES_IDX_0        <= 0;
				address_wr_0              <= 0;
				read_data_0_in_latched_S2 <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			we_IN_DEGREE_1            <= 0;
			we_OUT_DEGREE_1           <= 0;
			we_EDGES_IDX_1            <= 0;
			we_INV_IN_DEGREE_1        <= 0;
			we_INV_OUT_DEGREE_1       <= 0;
			we_INV_EDGES_IDX_1        <= 0;
			address_wr_1              <= 0;
			read_data_1_in_latched_S2 <= 0;
		end else begin
			if(enabled_cmd && read_data_1_in_latched.valid) begin

				read_data_1_in_latched_S2 <= read_data_1_in_latched;

				case (read_data_1_in_latched.cmd.array_struct)
					IN_DEGREE : begin
						we_IN_DEGREE_1      <= 1;
						we_OUT_DEGREE_1     <= 0;
						we_EDGES_IDX_1      <= 0;
						we_INV_IN_DEGREE_1  <= 0;
						we_INV_OUT_DEGREE_1 <= 0;
						we_INV_EDGES_IDX_1  <= 0;
					end
					OUT_DEGREE : begin
						we_IN_DEGREE_1      <= 0;
						we_OUT_DEGREE_1     <= 1;
						we_EDGES_IDX_1      <= 0;
						we_INV_IN_DEGREE_1  <= 0;
						we_INV_OUT_DEGREE_1 <= 0;
						we_INV_EDGES_IDX_1  <= 0;
					end
					EDGES_IDX : begin
						we_IN_DEGREE_1      <= 0;
						we_OUT_DEGREE_1     <= 0;
						we_EDGES_IDX_1      <= 1;
						we_INV_IN_DEGREE_1  <= 0;
						we_INV_OUT_DEGREE_1 <= 0;
						we_INV_EDGES_IDX_1  <= 0;
					end
					INV_IN_DEGREE : begin
						we_IN_DEGREE_1      <= 0;
						we_OUT_DEGREE_1     <= 0;
						we_EDGES_IDX_1      <= 0;
						we_INV_IN_DEGREE_1  <= 1;
						we_INV_OUT_DEGREE_1 <= 0;
						we_INV_EDGES_IDX_1  <= 0;
					end
					INV_OUT_DEGREE : begin
						we_IN_DEGREE_1      <= 0;
						we_OUT_DEGREE_1     <= 0;
						we_EDGES_IDX_1      <= 0;
						we_INV_IN_DEGREE_1  <= 0;
						we_INV_OUT_DEGREE_1 <= 1;
						we_INV_EDGES_IDX_1  <= 0;
					end
					INV_EDGES_IDX : begin
						we_IN_DEGREE_1      <= 0;
						we_OUT_DEGREE_1     <= 0;
						we_EDGES_IDX_1      <= 0;
						we_INV_IN_DEGREE_1  <= 0;
						we_INV_OUT_DEGREE_1 <= 0;
						we_INV_EDGES_IDX_1  <= 1;
					end
					default : begin
						we_IN_DEGREE_1      <= 0;
						we_OUT_DEGREE_1     <= 0;
						we_EDGES_IDX_1      <= 0;
						we_INV_IN_DEGREE_1  <= 0;
						we_INV_OUT_DEGREE_1 <= 0;
						we_INV_EDGES_IDX_1  <= 0;
						address_wr_1        <= 0;
					end
				endcase
			end else begin
				we_IN_DEGREE_1            <= 0;
				we_OUT_DEGREE_1           <= 0;
				we_EDGES_IDX_1            <= 0;
				we_INV_IN_DEGREE_1        <= 0;
				we_INV_OUT_DEGREE_1       <= 0;
				we_INV_EDGES_IDX_1        <= 0;
				address_wr_1              <= 0;
				read_data_1_in_latched_S2 <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			in_degree_data_ready                <= 0;
			out_degree_data_ready               <= 0;
			edges_idx_degree_data_ready         <= 0;
			inverse_in_degree_data_ready        <= 0;
			inverse_out_degree_data_ready       <= 0;
			inverse_edges_idx_degree_data_ready <= 0;

		end else begin
			if(enabled_cmd && read_response_in_latched.valid) begin

				case (read_response_in_latched.cmd.array_struct)
					IN_DEGREE : begin
						in_degree_data_ready <= 1;
					end
					OUT_DEGREE : begin
						out_degree_data_ready <= 1;
					end
					EDGES_IDX : begin
						edges_idx_degree_data_ready <= 1;
					end
					INV_IN_DEGREE : begin
						inverse_in_degree_data_ready <= 1;
					end
					INV_OUT_DEGREE : begin
						inverse_out_degree_data_ready <= 1;
					end
					INV_EDGES_IDX : begin
						inverse_edges_idx_degree_data_ready <= 1;
					end
					default : begin
					end
				endcase
			end

			if(clear_data_ready) begin
				in_degree_data_ready                <= 0;
				out_degree_data_ready               <= 0;
				edges_idx_degree_data_ready         <= 0;
				inverse_in_degree_data_ready        <= 0;
				inverse_out_degree_data_ready       <= 0;
				inverse_edges_idx_degree_data_ready <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			shift_limit_0 <= 0;
			shift_limit_1 <= 0;
		end else begin
			if(enabled_cmd && read_response_in_latched.valid) begin
				if(~(|shift_limit_0) && ~shift_limit_clear) begin
					if(read_response_in_latched.cmd.real_size > CACHELINE_VERTEX_NUM_HF) begin
						shift_limit_0 <= CACHELINE_VERTEX_NUM_HF-1;
						shift_limit_1 <= read_response_in_latched.cmd.real_size - CACHELINE_VERTEX_NUM_HF - 1;
					end else begin
						shift_limit_0 <= read_response_in_latched.cmd.real_size-1;
						shift_limit_1 <= 0;
					end
				end
			end

			if(shift_limit_clear) begin
				shift_limit_0 <= 0;
				shift_limit_1 <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Read Vertex registers into vertex job queue
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Vertices
////////////////////////////////////////////////////////////////////////////

	assign send_request_ready     = read_buffer_status_internal.empty && vertex_buffer_burst_status.empty  && (|vertex_num_counter) && wed_request_in_latched.valid;
	assign fill_vertex_job_buffer = in_degree_data_ready && out_degree_data_ready && edges_idx_degree_data_ready &&
		inverse_in_degree_data_ready && inverse_out_degree_data_ready && inverse_edges_idx_degree_data_ready;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_variable   <= 0;
			vertex_id_counter <= 0;
		end
		else begin
			if(push_shift) begin
				vertex_id_counter                  <= vertex_id_counter+1;
				vertex_variable.valid              <= push_shift;
				vertex_variable.id                 <= vertex_id_counter;
				vertex_variable.in_degree          <= swap_endianness_vertex_read(in_degree_data);
				vertex_variable.out_degree         <= swap_endianness_vertex_read(out_degree_data);
				vertex_variable.edges_idx          <= swap_endianness_vertex_read(edges_idx_degree_data);
				vertex_variable.inverse_in_degree  <= swap_endianness_vertex_read(inverse_in_degree_data);
				vertex_variable.inverse_out_degree <= swap_endianness_vertex_read(inverse_out_degree_data);
				vertex_variable.inverse_edges_idx  <= swap_endianness_vertex_read(inverse_edges_idx_degree_data);
			end else begin
				vertex_variable <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			in_degree_data                <= 0;
			out_degree_data               <= 0;
			edges_idx_degree_data         <= 0;
			inverse_in_degree_data        <= 0;
			inverse_out_degree_data       <= 0;
			inverse_edges_idx_degree_data <= 0;
			push_shift                    <= 0;
		end else begin
			if(~switch_shift_hf && start_shift_hf_0) begin
				push_shift                    <= 1;
				in_degree_data                <= in_degree_data_0;
				out_degree_data               <= out_degree_data_0;
				edges_idx_degree_data         <= edges_idx_degree_data_0;
				inverse_in_degree_data        <= inverse_in_degree_data_0;
				inverse_out_degree_data       <= inverse_out_degree_data_0;
				inverse_edges_idx_degree_data <= inverse_edges_idx_degree_data_0;
			end else if(switch_shift_hf && start_shift_hf_1) begin
				push_shift                    <= 1;
				in_degree_data                <= in_degree_data_1;
				out_degree_data               <= out_degree_data_1;
				edges_idx_degree_data         <= edges_idx_degree_data_1;
				inverse_in_degree_data        <= inverse_in_degree_data_1;
				inverse_out_degree_data       <= inverse_out_degree_data_1;
				inverse_edges_idx_degree_data <= inverse_edges_idx_degree_data_1;
			end else begin
				push_shift                    <= 0;
				in_degree_data                <= 0;
				out_degree_data               <= 0;
				edges_idx_degree_data         <= 0;
				inverse_in_degree_data        <= 0;
				inverse_out_degree_data       <= 0;
				inverse_edges_idx_degree_data <= 0;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
// If the vertex has no in/out neighbors don't schedule it vertex_job_latched.inverse_out_degree;
////////////////////////////////////////////////////////////////////////////
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
			vertex_job_counter          <= 0;
			edge_job_counter_filtered   <= 0;
		end else begin
			if(filter_vertex)
				vertex_job_counter_filtered <= vertex_job_counter_filtered + 1;;

			if(vertex_latched.valid) begin
				vertex_job_counter        <= vertex_job_counter + 1;
				edge_job_counter_filtered <= edge_job_counter_filtered + vertex_latched.inverse_out_degree;
			end

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
		.DEPTH(16                       )
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

///////////////////////////////////////////////////////////////////////////
// different data_structures cacheline storage half 0
////////////////////////////////////////////////////////////////////////////

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_IN_DEGREE_0 (
		.clock   (clock                         ),
		.we      (we_IN_DEGREE_0                ),
		.wr_addr (address_wr_0                  ),
		.data_in (read_data_0_in_latched_S2.data),
		
		.rd_addr (address_rd_0                  ),
		.data_out(in_degree_data_0              )
	);

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_OUT_DEGREE_0 (
		.clock   (clock                         ),
		.we      (we_OUT_DEGREE_0               ),
		.wr_addr (address_wr_0                  ),
		.data_in (read_data_0_in_latched_S2.data),
		
		.rd_addr (address_rd_0                  ),
		.data_out(out_degree_data_0             )
	);

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_EDGES_IDX_0 (
		.clock   (clock                         ),
		.we      (we_EDGES_IDX_0                ),
		.wr_addr (address_wr_0                  ),
		.data_in (read_data_0_in_latched_S2.data),
		
		.rd_addr (address_rd_0                  ),
		.data_out(edges_idx_degree_data_0       )
	);

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_INV_IN_DEGREE_0 (
		.clock   (clock                         ),
		.we      (we_INV_IN_DEGREE_0            ),
		.wr_addr (address_wr_0                  ),
		.data_in (read_data_0_in_latched_S2.data),
		
		.rd_addr (address_rd_0                  ),
		.data_out(inverse_in_degree_data_0      )
	);

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_INV_OUT_DEGREE_0 (
		.clock   (clock                         ),
		.we      (we_INV_OUT_DEGREE_0           ),
		.wr_addr (address_wr_0                  ),
		.data_in (read_data_0_in_latched_S2.data),
		
		.rd_addr (address_rd_0                  ),
		.data_out(inverse_out_degree_data_0     )
	);

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_INV_EDGES_IDX_0 (
		.clock   (clock                          ),
		.we      (we_INV_EDGES_IDX_0             ),
		.wr_addr (address_wr_0                   ),
		.data_in (read_data_0_in_latched_S2.data ),
		
		.rd_addr (address_rd_0                   ),
		.data_out(inverse_edges_idx_degree_data_0)
	);


///////////////////////////////////////////////////////////////////////////
// different data_structures cacheline storage half 1
////////////////////////////////////////////////////////////////////////////

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_IN_DEGREE_1 (
		.clock   (clock                         ),
		.we      (we_IN_DEGREE_1                ),
		.wr_addr (address_wr_1                  ),
		.data_in (read_data_1_in_latched_S2.data),
		
		.rd_addr (address_rd_1                  ),
		.data_out(in_degree_data_1              )
	);

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_OUT_DEGREE_1 (
		.clock   (clock                         ),
		.we      (we_OUT_DEGREE_1               ),
		.wr_addr (address_wr_1                  ),
		.data_in (read_data_1_in_latched_S2.data),
		
		.rd_addr (address_rd_1                  ),
		.data_out(out_degree_data_1             )
	);

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_EDGES_IDX_1 (
		.clock   (clock                         ),
		.we      (we_EDGES_IDX_1                ),
		.wr_addr (address_wr_1                  ),
		.data_in (read_data_1_in_latched_S2.data),
		
		.rd_addr (address_rd_1                  ),
		.data_out(edges_idx_degree_data_1       )
	);

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_INV_IN_DEGREE_1 (
		.clock   (clock                         ),
		.we      (we_INV_IN_DEGREE_1            ),
		.wr_addr (address_wr_1                  ),
		.data_in (read_data_1_in_latched_S2.data),
		
		.rd_addr (address_rd_1                  ),
		.data_out(inverse_in_degree_data_1      )
	);

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_INV_OUT_DEGREE_1 (
		.clock   (clock                         ),
		.we      (we_INV_OUT_DEGREE_1           ),
		.wr_addr (address_wr_1                  ),
		.data_in (read_data_1_in_latched_S2.data),
		
		.rd_addr (address_rd_1                  ),
		.data_out(inverse_out_degree_data_1     )
	);

	mixed_width_ram #(
		.WORDS(1                     ),
		.WW   (CACHELINE_SIZE_BITS_HF),
		.RW   (VERTEX_SIZE_BITS      )
	) cacheline_instant_INV_EDGES_IDX_1 (
		.clock   (clock                          ),
		.we      (we_INV_EDGES_IDX_1             ),
		.wr_addr (address_wr_1                   ),
		.data_in (read_data_1_in_latched_S2.data ),
		
		.rd_addr (address_rd_1                   ),
		.data_out(inverse_edges_idx_degree_data_1)
	);




endmodule