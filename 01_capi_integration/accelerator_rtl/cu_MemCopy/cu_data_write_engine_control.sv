// -----------------------------------------------------------------------------
//
//		"CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_data_write_engine_control.sv
// Create : 2019-11-18 16:55:32
// Revise : 2019-12-06 22:25:38
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;
import CREDIT_PKG::*;

module cu_data_write_engine_control #(parameter CU_WRITE_CONTROL_ID = DATA_WRITE_CONTROL_ID) (
	input  logic                         clock                         , // Clock
	input  logic                         rstn                          ,
	input  logic                         write_enabled_in              ,
	input  logic                         prefetch_enabled_in           ,
	input  WEDInterface                  wed_request_in                ,
	input  logic [                 0:63] cu_configure                  ,
	input  ResponseBufferLine            write_response_in             ,
	input  ReadWriteDataLine             write_data_0_in               ,
	input  ReadWriteDataLine             write_data_1_in               ,
	input  BufferStatus                  write_command_buffer_status   ,
	input  ResponseBufferLine            prefetch_response_in          ,
	input  BufferStatus                  prefetch_command_buffer_status,
	input  logic [                 0:63] tlb_size                      ,
	input  logic [                 0:63] max_tlb_cl_requests           ,
	output CommandBufferLine             prefetch_command_out          ,
	output BufferStatus                  write_data_in_buffer_status   ,
	output CommandBufferLine             write_command_out             ,
	output ReadWriteDataLine             write_data_0_out              ,
	output ReadWriteDataLine             write_data_1_out              ,
	output logic [0:(ARRAY_SIZE_BITS-1)] write_job_counter_done
);


	BufferStatus write_data_in_0_buffer_status;
	BufferStatus write_data_in_1_buffer_status;
	logic [0:63] next_offest                  ;
	logic        cmd_setup                    ;

	ResponseBufferLine            write_response_in_latched  ;
	logic                         enabled                    ;
	logic                         enabled_cmd                ;
	logic                         send_cmd_write             ;
	logic                         leave_cmd_write            ;
	logic [                 0:63] cu_configure_latched       ;
	ReadWriteDataLine             write_data_0_out_latched   ;
	ReadWriteDataLine             write_data_1_out_latched   ;
	CommandBufferLine             write_command_out_latched  ;
	WEDInterface                  wed_request_in_latched     ;
	ReadWriteDataLine             write_data_0_out_buffer    ;
	ReadWriteDataLine             write_data_1_out_buffer    ;
	logic                         write_data_buffer_pop      ;
	CommandTagLine                cmd                        ;
	logic [0:(ARRAY_SIZE_BITS-1)] write_job_resp_done_latched;
	logic [0:(ARRAY_SIZE_BITS-1)] write_job_send_done_latched;
	logic                         done_write_pending         ;

	CommandBufferLine             prefetch_command_out_latched ;
	WEDInterface                  wed_prefetch_in_latched      ;
	logic [0:(ARRAY_SIZE_BITS-1)] prefetch_counter_resp_latched;
	logic [0:(ARRAY_SIZE_BITS-1)] prefetch_counter_send_latched;
	logic [                 0:63] next_prefetch_offest         ;
	logic                         enabled_prefetch             ;
	ResponseBufferLine            prefetch_response_in_latched ;
	logic                         send_cmd_prefetch            ;
	logic                         done_prefetch_pending        ;
	logic                         leave_cmd_prefetch           ;

	logic [0:63] tlb_size_latched           ;
	logic [0:63] max_tlb_cl_requests_latched;

	assign write_data_in_buffer_status = write_data_in_0_buffer_status;

////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_data_0_out     <= 0;
			write_data_1_out     <= 0;
			write_command_out    <= 0;
			prefetch_command_out <= 0;
		end else begin
			if(enabled) begin
				write_data_0_out     <= write_data_0_out_latched;
				write_data_1_out     <= write_data_1_out_latched;
				write_command_out    <= write_command_out_latched;
				prefetch_command_out <= prefetch_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_response_in_latched    <= 0;
			prefetch_response_in_latched <= 0;
		end else begin
			if(enabled_cmd) begin
				write_response_in_latched    <= write_response_in;
				prefetch_response_in_latched <= prefetch_response_in;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cu_configure_latched <= 0;
		end else begin
			if(enabled) begin
				if((|cu_configure)) begin
					cu_configure_latched <= cu_configure;
				end
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			tlb_size_latched            <= 0;
			max_tlb_cl_requests_latched <= 0;
		end else begin
			tlb_size_latched            <= tlb_size;
			max_tlb_cl_requests_latched <= max_tlb_cl_requests;
		end
	end


////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled <= 0;
		end else begin
			enabled <= write_enabled_in;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled_cmd      <= 0;
			enabled_prefetch <= 0;
		end else begin
			enabled_cmd      <= enabled;
			enabled_prefetch <= prefetch_enabled_in;
		end
	end

////////////////////////////////////////////////////////////////////////////
//response tracking logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			write_job_counter_done <= 0;
		else begin
			if (write_response_in_latched.valid) begin
				write_job_counter_done <= write_job_counter_done + write_response_in_latched.cmd.real_size;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//edge_data_send
////////////////////////////////////////////////////////////////////////////

	always_comb begin
		cmd                  = 0;
		cmd.array_struct     = WRITE_DATA;
		cmd.cacheline_offest = write_data_0_out_buffer.cmd.cacheline_offest;
		cmd.address_offest   = write_data_0_out_buffer.cmd.address_offest;
		cmd.real_size        = write_data_0_out_buffer.cmd.real_size;
		cmd.cu_id            = CU_WRITE_CONTROL_ID;
		cmd.cmd_type         = CMD_WRITE;
		cmd.abt              = STRICT;
	end


////////////////////////////////////////////////////////////////////////////
//write prefetch dependence logic
////////////////////////////////////////////////////////////////////////////

	write_state current_state, next_state;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= WRITE_STREAM_RESET;
		else begin
			if(enabled)
				current_state <= next_state;
		end
	end// always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			WRITE_STREAM_RESET : begin
				next_state = WRITE_STREAM_IDLE;
			end
			WRITE_STREAM_IDLE : begin
				if(wed_request_in.valid && enabled_cmd)
					next_state = WRITE_STREAM_SET;
				else
					next_state = WRITE_STREAM_IDLE;
			end
			WRITE_STREAM_SET : begin
				if(wed_request_in_latched.valid && enabled_prefetch)
					next_state = PREFETCH_WRITE_STREAM_START;
				else if(wed_request_in_latched.valid)
					next_state = WRITE_STREAM_START;
				else
					next_state = WRITE_STREAM_SET;
			end
			PREFETCH_WRITE_STREAM_START : begin
				next_state = PREFETCH_WRITE_STREAM_REQ;
			end
			PREFETCH_WRITE_STREAM_REQ : begin
				if(leave_cmd_prefetch)
					next_state = PREFETCH_WRITE_STREAM_REQ;
				else
					next_state = WRITE_STREAM_START;
			end
			WRITE_STREAM_START : begin
				next_state = WRITE_STREAM_REQ;
			end
			WRITE_STREAM_REQ : begin
				if(leave_cmd_write)
					next_state = WRITE_STREAM_REQ;
				else
					next_state = WRITE_STREAM_PENDING;
			end
			WRITE_STREAM_PENDING : begin
				if(done_write_pending)
					next_state = WRITE_STREAM_DONE;
				else
					next_state = WRITE_STREAM_PENDING;
			end
			WRITE_STREAM_DONE : begin
				if((|wed_prefetch_in_latched.wed.size_recive) && enabled_prefetch)
					next_state = PREFETCH_WRITE_STREAM_START;
				else if((|wed_request_in_latched.wed.size_recive))
					next_state = WRITE_STREAM_START;
				else
					next_state = WRITE_STREAM_FINAL;
			end
			WRITE_STREAM_FINAL : begin
				next_state = WRITE_STREAM_FINAL;
			end
		endcase
	end

	always_ff @(posedge clock) begin
		case (current_state)
			WRITE_STREAM_RESET : begin
				send_cmd_write                <= 0;
				leave_cmd_write               <= 0;
				send_cmd_prefetch             <= 0;
				leave_cmd_prefetch            <= 0;
				cmd_setup                     <= 0;
				done_prefetch_pending         <= 0;
				done_write_pending            <= 0;
				write_job_resp_done_latched   <= 0;
				prefetch_counter_resp_latched <= 0;
			end
			WRITE_STREAM_IDLE : begin
				cmd_setup <= 0;
			end
			WRITE_STREAM_SET : begin
				cmd_setup <= 1;
			end
			PREFETCH_WRITE_STREAM_START : begin
				cmd_setup                     <= 0;
				send_cmd_prefetch             <= 0;
				leave_cmd_prefetch            <= 1;
				done_prefetch_pending         <= 0;
				prefetch_counter_resp_latched <= 0;
			end
			PREFETCH_WRITE_STREAM_REQ : begin
				done_prefetch_pending <= 0;
				if((prefetch_counter_send_latched >= (tlb_size_latched)) || ~(|wed_prefetch_in_latched.wed.size_recive))begin
					send_cmd_prefetch  <= 0;
					leave_cmd_prefetch <= 0;
				end else begin
					send_cmd_prefetch  <= 1;
					leave_cmd_prefetch <= 1;
				end
				prefetch_counter_resp_latched <= prefetch_counter_resp_latched + prefetch_response_in_latched.valid;
			end
			WRITE_STREAM_START : begin
				done_prefetch_pending         <= 0;
				cmd_setup                     <= 0;
				leave_cmd_write               <= 1;
				send_cmd_prefetch             <= 0;
				leave_cmd_prefetch            <= 0;
				send_cmd_write                <= 0;
				write_job_resp_done_latched   <= 0;
				done_write_pending            <= 0;
				prefetch_counter_resp_latched <= prefetch_counter_resp_latched + prefetch_response_in_latched.valid;
			end
			WRITE_STREAM_REQ : begin
				done_write_pending    <= 0;
				done_prefetch_pending <= 0;
				if((write_job_send_done_latched >= (max_tlb_cl_requests_latched)) || ~(|wed_request_in_latched.wed.size_recive))begin
					send_cmd_write  <= 0;
					leave_cmd_write <= 0;
				end else begin
					send_cmd_write  <= 1;
					leave_cmd_write <= 1;
				end
				prefetch_counter_resp_latched <= prefetch_counter_resp_latched + prefetch_response_in_latched.valid;
				write_job_resp_done_latched   <= write_job_resp_done_latched + write_response_in_latched.valid;
			end
			WRITE_STREAM_PENDING : begin
				send_cmd_write <= 0;
				if(write_job_send_done_latched == write_job_resp_done_latched)
					done_write_pending <= 1;
				else
					done_write_pending <= 0;

				if(prefetch_counter_send_latched == prefetch_counter_resp_latched)
					done_prefetch_pending <= 1;
				else
					done_prefetch_pending <= 0;

				prefetch_counter_resp_latched <= prefetch_counter_resp_latched + prefetch_response_in_latched.valid;
				write_job_resp_done_latched   <= write_job_resp_done_latched + write_response_in_latched.valid;
			end
			WRITE_STREAM_DONE : begin

			end
			WRITE_STREAM_FINAL : begin

			end
		endcase
	end

////////////////////////////////////////////////////////////////////////////
//write  logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out_latched   <= 0;
			write_data_0_out_latched    <= 0;
			write_data_1_out_latched    <= 0;
			next_offest                 <= 0;
			write_job_send_done_latched <= 0;
		end else begin

			if(cmd_setup)
				wed_request_in_latched <= wed_request_in;

			if (write_data_0_out_buffer.valid && write_data_1_out_buffer.valid && send_cmd_write)begin

				write_command_out_latched.valid <= write_data_0_out_buffer.valid;
				write_job_send_done_latched     <= write_job_send_done_latched + 1;

				write_command_out_latched.address <= wed_request_in_latched.wed.array_receive + write_data_0_out_buffer.cmd.address_offest;
				write_command_out_latched.size    <= cmd_size_calculate(write_data_0_out_buffer.cmd.real_size);
				write_command_out_latched.cmd     <= cmd;


				write_data_0_out_latched.valid <= write_data_0_out_buffer.valid;
				write_data_0_out_latched.cmd   <= cmd;
				write_data_0_out_latched.data  <= write_data_0_out_buffer.data ;

				write_data_1_out_latched.valid <= write_data_1_out_buffer.valid;
				write_data_1_out_latched.cmd   <= cmd;
				write_data_1_out_latched.data  <= write_data_1_out_buffer.data ;

				write_data_1_out_latched.cmd.abt  <= map_CABT(cu_configure_latched[5:7]);
				write_data_0_out_latched.cmd.abt  <= map_CABT(cu_configure_latched[5:7]);
				write_command_out_latched.cmd.abt <= map_CABT(cu_configure_latched[5:7]);
				write_command_out_latched.abt     <= map_CABT(cu_configure_latched[5:7]);

				if (cu_configure_latched[9]) begin
					write_command_out_latched.command <= WRITE_MS;
				end else begin
					write_command_out_latched.command <= WRITE_NA;
				end

				wed_request_in_latched.wed.size_recive <= wed_request_in_latched.wed.size_recive - write_data_0_out_buffer.cmd.real_size;

			end else begin
				write_command_out_latched <= 0;
				write_data_0_out_latched  <= 0;
				write_data_1_out_latched  <= 0;
			end

			if(done_write_pending)
				write_job_send_done_latched <= 0;

		end
	end

////////////////////////////////////////////////////////////////////////////
//prefetch logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_prefetch_in_latched       <= 0;
			prefetch_command_out_latched  <= 0;
			next_prefetch_offest          <= 0;
			prefetch_counter_send_latched <= 0;
		end else begin

			if(cmd_setup && enabled_prefetch) begin
				wed_prefetch_in_latched                   <= wed_request_in;
				wed_prefetch_in_latched.wed.array_receive <= (wed_request_in.wed.array_receive & ADDRESS_PAGE_ALIGN_MASK);
			end

			if (~prefetch_command_buffer_status.alfull && (|wed_prefetch_in_latched.wed.size_recive) && send_cmd_prefetch && enabled_prefetch) begin

				if(wed_prefetch_in_latched.wed.size_recive > PAGE_ARRAY_NUM)begin
					wed_prefetch_in_latched.wed.size_recive    <= wed_prefetch_in_latched.wed.size_recive - PAGE_ARRAY_NUM;
					prefetch_command_out_latched.cmd.real_size <= PAGE_ARRAY_NUM;
				end else if (wed_prefetch_in_latched.wed.size_recive <= PAGE_ARRAY_NUM) begin
					wed_prefetch_in_latched.wed.size_recive    <= 0;
					prefetch_command_out_latched.cmd.real_size <= wed_prefetch_in_latched.wed.size_recive;
				end

				prefetch_command_out_latched.command <= TOUCH_I;
				prefetch_command_out_latched.size    <= 12'h080;

				prefetch_command_out_latched.cmd.cu_id            <= CU_WRITE_CONTROL_ID;
				prefetch_command_out_latched.cmd.cmd_type         <= CMD_PREFETCH_WRITE;
				prefetch_command_out_latched.cmd.cacheline_offest <= 0;
				prefetch_command_out_latched.cmd.address_offest   <= next_prefetch_offest;
				prefetch_command_out_latched.cmd.array_struct     <= PREFETCH_DATA;

				prefetch_command_out_latched.cmd.abt <= STRICT;
				prefetch_command_out_latched.abt     <= STRICT;


				prefetch_command_out_latched.valid <= 1'b1;
				prefetch_counter_send_latched      <= prefetch_counter_send_latched +1;

				prefetch_command_out_latched.address <= wed_prefetch_in_latched.wed.array_receive  + next_prefetch_offest;

				next_prefetch_offest <= next_prefetch_offest + PAGE_SIZE;

			end else begin
				prefetch_command_out_latched <= 0;
			end

			if(done_prefetch_pending)
				prefetch_counter_send_latched <= 0;

		end
	end


////////////////////////////////////////////////////////////////////////////
//Buffers CU Write DATA
////////////////////////////////////////////////////////////////////////////

	assign write_data_buffer_pop = ~write_command_buffer_status.alfull && ~write_data_in_1_buffer_status.empty && ~write_data_in_0_buffer_status.empty && send_cmd_write;

	fifo #(
		.WIDTH   ($bits(ReadWriteDataLine)    ),
		.DEPTH   (WRITE_ENGINE_BUFFER_SIZE    ),
		.HEADROOM(WRITE_ENGINE_BUFFER_HEADROOM)
	) cu_write_data_0_buffer_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (write_data_0_in.valid               ),
		.data_in (write_data_0_in                     ),
		.full    (write_data_in_0_buffer_status.full  ),
		.alFull  (write_data_in_0_buffer_status.alfull),
		
		.pop     (write_data_buffer_pop               ),
		.valid   (write_data_in_0_buffer_status.valid ),
		.data_out(write_data_0_out_buffer             ),
		.empty   (write_data_in_0_buffer_status.empty )
	);


	fifo #(
		.WIDTH   ($bits(ReadWriteDataLine)    ),
		.DEPTH   (WRITE_ENGINE_BUFFER_SIZE    ),
		.HEADROOM(WRITE_ENGINE_BUFFER_HEADROOM)
	) cu_write_data_1_buffer_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (write_data_1_in.valid               ),
		.data_in (write_data_1_in                     ),
		.full    (write_data_in_1_buffer_status.full  ),
		.alFull  (write_data_in_1_buffer_status.alfull),
		
		.pop     (write_data_buffer_pop               ),
		.valid   (write_data_in_1_buffer_status.valid ),
		.data_out(write_data_1_out_buffer             ),
		.empty   (write_data_in_1_buffer_status.empty )
	);


endmodule