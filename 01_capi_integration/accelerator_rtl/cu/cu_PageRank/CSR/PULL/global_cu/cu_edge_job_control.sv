// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_edge_job_control.sv
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

module cu_edge_job_control #(
	parameter CU_ID_X = 1,
	parameter CU_ID_Y = 1
) (
	input  logic              clock                   , // Clock
	input  logic              rstn                    ,
	input  logic              enabled_in              ,
	input  logic [0:63]       cu_configure            ,
	input  WEDInterface       wed_request_in          ,
	input  ResponseBufferLine read_response_in        ,
	input  ReadWriteDataLine  read_data_0_in          ,
	input  ReadWriteDataLine  read_data_1_in          ,
	input  BufferStatus       read_buffer_status      ,
	input  logic              edge_request            ,
	input  VertexInterface    vertex_job              ,
	input  logic              read_command_bus_grant  ,
	output logic              read_command_bus_request,
	output CommandBufferLine  read_command_out        ,
	output EdgeInterface      edge_job
);

	VertexInterface vertex_job_latched              ;
	logic           read_command_bus_grant_latched  ;
	logic           read_command_bus_request_latched;
	BufferStatus    edge_buffer_status              ;
	logic [0:63]    cu_configure_internal           ;

	logic [0:CACHELINE_INT_COUNTER_BITS] shift_limit_0            ;
	logic [0:CACHELINE_INT_COUNTER_BITS] shift_limit_1            ;
	logic [0:CACHELINE_INT_COUNTER_BITS] shift_seek               ;
	logic [0:CACHELINE_INT_COUNTER_BITS] global_shift_counter     ;
	logic                                shift_limit_clear        ;
	logic [0:CACHELINE_INT_COUNTER_BITS] shift_counter            ;
	logic                                start_shift_hf_0         ;
	logic                                start_shift_hf_1         ;
	logic                                switch_shift_hf          ;
	logic                                push_shift               ;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_INV_EDGE_ARRAY_DEST_0;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_INV_EDGE_ARRAY_DEST_1;

	logic clear_data_ready    ;
	logic fill_edge_job_buffer;

	//output latched
	EdgeInterface     edge_latched            ;
	CommandBufferLine read_command_out_latched;

	//input lateched
	WEDInterface       wed_request_in_latched  ;
	ResponseBufferLine read_response_in_latched;
	ReadWriteDataLine  read_data_0_in_latched  ;
	ReadWriteDataLine  read_data_1_in_latched  ;

	logic edge_request_latched;

	CommandBufferLine read_command_edge_job_latched   ;
	CommandBufferLine read_command_edge_job_latched_S2;
	BufferStatus      read_buffer_status_internal     ;

	BufferStatus  edge_buffer_burst_status;
	logic         edge_buffer_burst_pop   ;
	EdgeInterface edge_burst_variable     ;

	// internal registers to track logic
	// Read/write commands require the size to be a power of 2 (1, 2, 4, 8, 16, 32,64, 128).
	logic                        send_request_ready   ;
	logic [                0:63] edge_next_offest     ;
	logic [0:(EDGE_SIZE_BITS-1)] edge_num_counter     ;
	logic [0:(EDGE_SIZE_BITS-1)] edge_id_counter      ;
	logic                        generate_read_command;
	logic                        setup_read_command   ;
	EdgeInterface                edge_variable        ;
	logic [                 0:7] remainder            ;
	logic [                0:63] aligned              ;

	logic [0:(EDGE_SIZE_BITS-1)] inverse_edge_array_dest_data      ;
	logic                        inverse_edge_array_dest_data_ready;
	logic                        zero_pass                         ; // a signal when edges are 17 you get this extra edge at the othe have

	edge_struct_state current_state       ;
	edge_struct_state next_state          ;
	logic             enabled             ;
	logic             enabled_cmd         ;
	logic [0:63]      cu_configure_latched;


	logic done_vertex_edge_processing;
	logic read_vertex                ;
	logic read_vertex_new            ;
	logic read_vertex_new_latched    ;

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled               <= 0;
			enabled_cmd           <= 0;
			cu_configure_internal <= 0;
		end else begin
			enabled               <= enabled_in;
			enabled_cmd           <= enabled && (|cu_configure_latched);
			cu_configure_internal <= cu_configure;
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_job.valid         <= 0;
			read_command_out.valid <= 0;
		end else begin
			if(enabled) begin
				edge_job.valid         <= edge_latched.valid;
				read_command_out.valid <= read_command_out_latched.valid;
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_job.payload         <= edge_latched.payload;
		read_command_out.payload <= read_command_out_latched.payload;
	end


////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_0_in_latched.valid   <= 0;
			read_data_1_in_latched.valid   <= 0;
			read_response_in_latched.valid <= 0;
			edge_request_latched           <= 0;
			wed_request_in_latched.valid   <= 0;
		end else begin
			if(enabled_cmd) begin
				read_response_in_latched.valid <= read_response_in.valid ;
				read_data_0_in_latched.valid   <= read_data_0_in.valid ;
				read_data_1_in_latched.valid   <= read_data_1_in.valid ;
				wed_request_in_latched.valid   <= wed_request_in.valid;
				edge_request_latched           <= edge_request && ~edge_buffer_status.empty;
			end
		end
	end

	always_ff @(posedge clock) begin
		wed_request_in_latched.payload   <= wed_request_in.payload;
		read_response_in_latched.payload <= read_response_in.payload;
		read_data_0_in_latched.payload   <= read_data_0_in.payload;
		read_data_1_in_latched.payload   <= read_data_1_in.payload;
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cu_configure_latched     <= 0;
			read_vertex_new          <= 0;
			read_vertex_new_latched  <= 0;
			vertex_job_latched.valid <= 0;
		end else begin
			if(enabled) begin

				if((|cu_configure_internal))
					cu_configure_latched <= cu_configure_internal;

				if(read_vertex)begin
					vertex_job_latched.valid <= vertex_job.valid;
					read_vertex_new          <= 1;
				end

				if(read_vertex_new && (~(|edge_num_counter)))begin
					read_vertex_new <= 0;
				end

				read_vertex_new_latched <= read_vertex_new;
			end
		end
	end

	always_ff @(posedge clock ) begin
		if(read_vertex)begin
			vertex_job_latched.payload <= vertex_job.payload;
		end
	end

	always_comb begin
		read_vertex = 0;
		if(done_vertex_edge_processing && vertex_job.valid && ~vertex_job_latched.valid)begin
			read_vertex = 1;
		end

		if(done_vertex_edge_processing && vertex_job.valid && vertex_job_latched.valid)begin
			if(vertex_job_latched.payload.id != vertex_job.payload.id)begin
				read_vertex = 1;
			end
		end
	end
////////////////////////////////////////////////////////////////////////////
//1. Generate Read Commands to obtain edge_job structural info
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= SEND_EDGE_RESET;
		else begin
			if(enabled) begin
				current_state <= next_state;
			end
		end
	end // always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			SEND_EDGE_RESET : begin
				if(wed_request_in_latched.valid && enabled_cmd && vertex_job_latched.valid)
					next_state = SEND_EDGE_INIT;
				else
					next_state = SEND_EDGE_RESET;
			end
			SEND_EDGE_INIT : begin
				if(|edge_num_counter)
					next_state = SEND_EDGE_IDLE;
				else
					next_state = SEND_EDGE_INIT;
			end
			SEND_EDGE_IDLE : begin
				if(send_request_ready)
					next_state = START_EDGE_REQ;
				else
					next_state = SEND_EDGE_IDLE;
			end
			START_EDGE_REQ : begin
				next_state = CALC_EDGE_REQ_SIZE;
			end
			CALC_EDGE_REQ_SIZE : begin
				next_state = SEND_EDGE_START;
			end
			SEND_EDGE_START : begin
				next_state = SEND_EDGE_INV_EDGE_ARRAY_DEST;
			end
			SEND_EDGE_INV_EDGE_ARRAY_DEST : begin
				next_state = WAIT_EDGE_DATA;
			end
			WAIT_EDGE_DATA : begin
				if(fill_edge_job_buffer)
					next_state = SHIFT_EDGE_DATA_START;
				else
					next_state = WAIT_EDGE_DATA;
			end
			SHIFT_EDGE_DATA_START : begin
				next_state = SHIFT_EDGE_DATA_0;
			end
			SHIFT_EDGE_DATA_0 : begin
				if((shift_counter < shift_limit_0))
					next_state = SHIFT_EDGE_DATA_0;
				else
					next_state = SHIFT_EDGE_DATA_DONE_0;
			end
			SHIFT_EDGE_DATA_DONE_0 : begin
				if(|shift_limit_1 || zero_pass)
					next_state = SHIFT_EDGE_DATA_1;
				else
					next_state = SHIFT_EDGE_DATA_DONE_1;
			end
			SHIFT_EDGE_DATA_1 : begin
				if((shift_counter < shift_limit_1))
					next_state = SHIFT_EDGE_DATA_1;
				else
					next_state = SHIFT_EDGE_DATA_DONE_1;
			end
			SHIFT_EDGE_DATA_DONE_1 : begin
				if(|edge_num_counter)
					next_state = SEND_EDGE_IDLE;
				else
					next_state = SEND_EDGE_INIT;
			end
		endcase
	end // always_comb

	always_ff @(posedge clock) begin
		case (current_state)
			SEND_EDGE_RESET : begin
				read_command_edge_job_latched.valid <= 0;
				edge_next_offest                    <= 0;
				generate_read_command               <= 0;
				setup_read_command                  <= 0;
				clear_data_ready                    <= 1;
				shift_limit_clear                   <= 1;
				start_shift_hf_0                    <= 0;
				start_shift_hf_1                    <= 0;
				switch_shift_hf                     <= 0;
				shift_counter                       <= 0;
				remainder                           <= 0;
				aligned                             <= 0;
				done_vertex_edge_processing         <= 1;
			end
			SEND_EDGE_INIT : begin
				read_command_edge_job_latched.valid <= 0;
				clear_data_ready                    <= 0;
				shift_limit_clear                   <= 0;
				setup_read_command                  <= read_vertex_new_latched;
				if(read_vertex_new_latched)begin
					edge_next_offest <= (vertex_job_latched.payload.inverse_edges_idx << $clog2(EDGE_SIZE));
				end
			end
			SEND_EDGE_IDLE : begin
				done_vertex_edge_processing         <= 0;
				read_command_edge_job_latched.valid <= 0;
				setup_read_command                  <= 0;
				shift_limit_clear                   <= 0;
				shift_counter                       <= 0;
				remainder                           <= (edge_next_offest & ADDRESS_EDGE_MOD_MASK);
				aligned                             <= (edge_next_offest & ADDRESS_EDGE_ALIGN_MASK);
			end
			START_EDGE_REQ : begin
				read_command_edge_job_latched.valid <= 0;
				generate_read_command               <= 1;
				shift_limit_clear                   <= 0;
			end
			CALC_EDGE_REQ_SIZE : begin
				generate_read_command <= 0;
			end
			SEND_EDGE_START : begin
				read_command_edge_job_latched.payload <= read_command_edge_job_latched_S2.payload;
			end
			SEND_EDGE_INV_EDGE_ARRAY_DEST : begin
				read_command_edge_job_latched.valid                    <= 1'b1;
				read_command_edge_job_latched.payload.address          <= wed_request_in_latched.payload.wed.inverse_edges_array_dest + aligned;
				read_command_edge_job_latched.payload.cmd.array_struct <= INV_EDGE_ARRAY_DEST;

				if(|remainder)
					edge_next_offest <= edge_next_offest + (CACHELINE_SIZE-remainder);
				else
					edge_next_offest <= edge_next_offest + CACHELINE_SIZE;
			end
			WAIT_EDGE_DATA : begin
				read_command_edge_job_latched.valid <= 0;
				if(fill_edge_job_buffer) begin
					clear_data_ready <= 1;
				end
			end
			SHIFT_EDGE_DATA_START : begin
				clear_data_ready <= 0;
			end
			SHIFT_EDGE_DATA_0 : begin
				start_shift_hf_0 <= 1;
				shift_counter    <= shift_counter + 1;
			end
			SHIFT_EDGE_DATA_DONE_0 : begin
				start_shift_hf_0 <= 0;
				shift_counter    <= 0;
			end
			SHIFT_EDGE_DATA_1 : begin
				start_shift_hf_1 <= 1;
				switch_shift_hf  <= 1;
				shift_counter    <= shift_counter + 1;
			end
			SHIFT_EDGE_DATA_DONE_1 : begin
				start_shift_hf_1  <= 0;
				shift_limit_clear <= 1;
				switch_shift_hf   <= 0;
				shift_counter     <= 0;

				if(~(|edge_num_counter))
					done_vertex_edge_processing <= 1;
			end
		endcase
	end // always_ff @(posedge clock)

////////////////////////////////////////////////////////////////////////////
//generate Edge data offset
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_edge_job_latched_S2.valid <= 0;
			edge_num_counter                       <= 0;
		end
		else begin

			if(read_vertex_new_latched && (vertex_job_latched.valid && wed_request_in_latched.valid))begin
				edge_num_counter <= vertex_job_latched.payload.inverse_out_degree;
			end

			if (generate_read_command) begin
				if(|remainder) begin // misaligned access

					read_command_edge_job_latched_S2.payload.size <= CACHELINE_SIZE;

					if(edge_num_counter > ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE))) begin
						edge_num_counter                                             <= edge_num_counter - ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE));
						read_command_edge_job_latched_S2.payload.cmd.real_size       <= ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE));
						read_command_edge_job_latched_S2.payload.cmd.real_size_bytes <= ((CACHELINE_SIZE - remainder));

						if (cu_configure_latched[8]) begin
							read_command_edge_job_latched_S2.payload.command <= READ_CL_S;
						end else begin
							read_command_edge_job_latched_S2.payload.command <= READ_CL_NA;
						end
					end
					else if (edge_num_counter <= ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE))) begin
						edge_num_counter                                             <= 0;
						read_command_edge_job_latched_S2.payload.cmd.real_size       <= edge_num_counter;
						read_command_edge_job_latched_S2.payload.cmd.real_size_bytes <= edge_num_counter << $clog2(EDGE_SIZE) ;

						if (cu_configure_latched[8]) begin
							read_command_edge_job_latched_S2.payload.command <= READ_CL_S;
						end else begin
							read_command_edge_job_latched_S2.payload.command <= READ_PNA;
						end
					end
				end else begin
					if(edge_num_counter > CACHELINE_EDGE_NUM)begin
						edge_num_counter                                             <= edge_num_counter - CACHELINE_EDGE_NUM;
						read_command_edge_job_latched_S2.payload.cmd.real_size       <= CACHELINE_EDGE_NUM;
						read_command_edge_job_latched_S2.payload.cmd.real_size_bytes <= CACHELINE_EDGE_NUM << $clog2(EDGE_SIZE) ;

						if (cu_configure_latched[8]) begin
							read_command_edge_job_latched_S2.payload.command <= READ_CL_S;
							read_command_edge_job_latched_S2.payload.size    <= CACHELINE_SIZE;
						end else begin
							read_command_edge_job_latched_S2.payload.command <= READ_CL_NA;
							read_command_edge_job_latched_S2.payload.size    <= cmd_size_calculate(edge_num_counter);
						end
					end
					else if (edge_num_counter <= CACHELINE_EDGE_NUM) begin
						edge_num_counter                                             <= 0;
						read_command_edge_job_latched_S2.payload.cmd.real_size       <= edge_num_counter;
						read_command_edge_job_latched_S2.payload.cmd.real_size_bytes <= edge_num_counter << $clog2(EDGE_SIZE) ;

						if (cu_configure_latched[8]) begin
							read_command_edge_job_latched_S2.payload.command <= READ_CL_S;
							read_command_edge_job_latched_S2.payload.size    <= CACHELINE_SIZE;
						end else begin
							read_command_edge_job_latched_S2.payload.command <= READ_PNA;
							read_command_edge_job_latched_S2.payload.size    <= cmd_size_calculate(edge_num_counter);
						end
					end

				end

				read_command_edge_job_latched_S2.payload.cmd.cacheline_offest <= (remainder >> $clog2(EDGE_SIZE));
				read_command_edge_job_latched_S2.payload.cmd.cu_id_x          <= CU_ID_X;
				read_command_edge_job_latched_S2.payload.cmd.cu_id_y          <= CU_ID_Y;
				read_command_edge_job_latched_S2.payload.cmd.cmd_type         <= CMD_READ;

				read_command_edge_job_latched_S2.payload.cmd.abt <= map_CABT(cu_configure_latched[5:7]);
				read_command_edge_job_latched_S2.payload.abt     <= map_CABT(cu_configure_latched[5:7]);

			end else begin
				read_command_edge_job_latched_S2.valid <= 0;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//Read Edge data into registers
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			reg_INV_EDGE_ARRAY_DEST_0 <= 0;
		end else begin
			if(read_data_0_in_latched.valid) begin
				case (read_data_0_in_latched.payload.cmd.array_struct)
					INV_EDGE_ARRAY_DEST : begin
						reg_INV_EDGE_ARRAY_DEST_0 <= read_data_0_in_latched.payload.data;
					end
				endcase
			end

			if(~switch_shift_hf && start_shift_hf_0) begin
				reg_INV_EDGE_ARRAY_DEST_0 <= {reg_INV_EDGE_ARRAY_DEST_0[EDGE_SIZE_BITS:(CACHELINE_SIZE_BITS_HF-1)],EDGE_NULL_BITS};
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			reg_INV_EDGE_ARRAY_DEST_1 <= 0;
		end else begin
			if( read_data_1_in_latched.valid) begin
				case (read_data_1_in_latched.payload.cmd.array_struct)
					INV_EDGE_ARRAY_DEST : begin
						reg_INV_EDGE_ARRAY_DEST_1 <= read_data_1_in_latched.payload.data;
					end
				endcase
			end

			if(switch_shift_hf && start_shift_hf_1) begin
				reg_INV_EDGE_ARRAY_DEST_1 <= {reg_INV_EDGE_ARRAY_DEST_1[EDGE_SIZE_BITS:(CACHELINE_SIZE_BITS_HF-1)],EDGE_NULL_BITS};
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			inverse_edge_array_dest_data_ready <= 0;
		end else begin
			if(read_response_in_latched.valid) begin
				case (read_response_in_latched.payload.cmd.array_struct)
					INV_EDGE_ARRAY_DEST : begin
						inverse_edge_array_dest_data_ready <= 1;
					end
				endcase
			end

			if(clear_data_ready) begin
				inverse_edge_array_dest_data_ready <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			shift_limit_0 <= 0;
			shift_limit_1 <= 0;
			shift_seek    <= 0;
			zero_pass     <= 0;
		end else begin
			if(read_response_in_latched.valid) begin
				if(~(|shift_limit_0) && ~shift_limit_clear) begin
					if((read_response_in_latched.payload.cmd.real_size+read_response_in_latched.payload.cmd.cacheline_offest) > CACHELINE_EDGE_NUM_HF) begin
						shift_limit_0 <= CACHELINE_EDGE_NUM_HF-1;
						shift_limit_1 <= (read_response_in_latched.payload.cmd.real_size+read_response_in_latched.payload.cmd.cacheline_offest) - CACHELINE_EDGE_NUM_HF-1;
						zero_pass     <= (((read_response_in_latched.payload.cmd.real_size+read_response_in_latched.payload.cmd.cacheline_offest) - CACHELINE_EDGE_NUM_HF) == 1);
					end else begin
						shift_limit_0 <= (read_response_in_latched.payload.cmd.real_size+read_response_in_latched.payload.cmd.cacheline_offest)-1;
						shift_limit_1 <= 0;
						zero_pass     <= 0;
					end

					shift_seek <= read_response_in_latched.payload.cmd.cacheline_offest;
				end
			end

			if(shift_limit_clear) begin
				shift_limit_0 <= 0;
				shift_limit_1 <= 0;
				shift_seek    <= 0;
				zero_pass     <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Read Edge registers into edge_job job queue
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Vertices
////////////////////////////////////////////////////////////////////////////

	assign send_request_ready   = read_buffer_status_internal.empty && edge_buffer_burst_status.empty  && (|edge_num_counter) && wed_request_in_latched.valid;
	assign fill_edge_job_buffer = inverse_edge_array_dest_data_ready;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_variable.valid <= 0;
			edge_id_counter     <= 0;
		end
		else begin
			if(push_shift) begin
				edge_id_counter     <= edge_id_counter+1;
				edge_variable.valid <= 1;
			end else begin
				edge_variable.valid <= 0;
			end

			if(done_vertex_edge_processing) begin
				edge_id_counter <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		edge_variable.payload.id   <= edge_id_counter;
		edge_variable.payload.src  <= vertex_job_latched.payload.id;
		edge_variable.payload.dest <= swap_endianness_edge_read(inverse_edge_array_dest_data);
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			inverse_edge_array_dest_data <= 0;
			push_shift                   <= 0;
			global_shift_counter         <= 0;
		end else begin
			if(~switch_shift_hf && start_shift_hf_0) begin
				global_shift_counter         <= global_shift_counter + 1;
				push_shift                   <= ((global_shift_counter) >= shift_seek);
				inverse_edge_array_dest_data <= reg_INV_EDGE_ARRAY_DEST_0[0:EDGE_SIZE_BITS-1];
			end else if(switch_shift_hf && start_shift_hf_1) begin
				global_shift_counter         <= global_shift_counter + 1;
				push_shift                   <= ((global_shift_counter) >= shift_seek);
				inverse_edge_array_dest_data <= reg_INV_EDGE_ARRAY_DEST_1[0:EDGE_SIZE_BITS-1];
			end else begin
				push_shift                   <= 0;
				inverse_edge_array_dest_data <= 0;
			end

			if(shift_limit_clear) begin
				global_shift_counter <= 0;
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
		
		.push    (edge_variable.valid            ),
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

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_bus_grant_latched <= 0;
			read_command_bus_request       <= 0;
		end else begin
			if(enabled_cmd) begin
				read_command_bus_grant_latched <= read_command_bus_grant && ~read_buffer_status.alfull ;
				read_command_bus_request       <= read_command_bus_request_latched;
			end
		end
	end

	assign read_command_bus_request_latched = ~read_buffer_status.alfull && ~read_buffer_status_internal.empty;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(16                      )
	) read_command_job_edge_burst_fifo_instant (
		.clock   (clock                              ),
		.rstn    (rstn                               ),
		
		.push    (read_command_edge_job_latched.valid),
		.data_in (read_command_edge_job_latched      ),
		.full    (read_buffer_status_internal.full   ),
		.alFull  (read_buffer_status_internal.alfull ),
		
		.pop     (read_command_bus_grant_latched     ),
		.valid   (read_buffer_status_internal.valid  ),
		.data_out(read_command_out_latched           ),
		.empty   (read_buffer_status_internal.empty  )
	);


endmodule