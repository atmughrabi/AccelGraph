// -----------------------------------------------------------------------------
//
//		"CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_data_read_engine_control.sv
// Create : 2019-11-18 16:39:26
// Revise : 2019-12-07 04:48:38
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_data_read_engine_control #(parameter CU_READ_CONTROL_ID = DATA_READ_CONTROL_ID) (
	input  logic                         clock                         , // Clock
	input  logic                         rstn                          ,
	input  logic                         read_enabled_in               ,
	input  logic                         prefetch_enabled_in           ,
	input  WEDInterface                  wed_request_in                ,
	input  logic [                 0:63] cu_configure                  ,
	input  ResponseBufferLine            read_response_in              ,
	input  ReadWriteDataLine             read_data_0_in                ,
	input  ReadWriteDataLine             read_data_1_in                ,
	input  BufferStatus                  read_command_buffer_status    ,
	input  BufferStatus                  read_data_out_buffer_status   ,
	input  ResponseBufferLine            prefetch_response_in          ,
	input  BufferStatus                  prefetch_command_buffer_status,
	input  logic [                 0:63] tlb_size                      ,
	input  logic [                 0:63] max_tlb_cl_requests           ,
	output CommandBufferLine             prefetch_command_out          ,
	output CommandBufferLine             read_command_out              ,
	output ReadWriteDataLine             read_data_0_out               ,
	output ReadWriteDataLine             read_data_1_out               ,
	output logic [0:(ARRAY_SIZE_BITS-1)] read_job_counter_done
);

	//output latched
	CommandBufferLine read_command_out_latched;
	logic             cmd_setup               ;
	//input lateched
	WEDInterface                  wed_request_in_latched       ;
	ResponseBufferLine            read_response_in_latched     ;
	logic                         send_cmd_read                ;
	logic                         leave_cmd_read               ;
	ReadWriteDataLine             read_data_0_in_latched       ;
	ReadWriteDataLine             read_data_1_in_latched       ;
	logic [                 0:63] cu_configure_latched         ;
	logic                         send_to_write_engine         ;
	logic [0:(ARRAY_SIZE_BITS-1)] read_job_counter_done_latched;
	logic [0:(ARRAY_SIZE_BITS-1)] read_job_resp_done_latched   ;
	logic [0:(ARRAY_SIZE_BITS-1)] read_job_send_done_latched   ;
	logic                         enabled                      ;
	logic                         enabled_cmd                  ;
	logic [                 0:63] next_offest                  ;
	logic                         done_read_pending            ;


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

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled <= 0;
		end else begin
			enabled <= read_enabled_in;
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
//Drive output
////////////////////////////////////////////////////////////////////////////


	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_out      <= 0;
			read_job_counter_done <= 0;
			read_data_0_out       <= 0;
			read_data_1_out       <= 0;
			prefetch_command_out  <= 0;
		end else begin
			if(enabled)begin
				read_command_out      <= read_command_out_latched;
				read_job_counter_done <= read_job_counter_done_latched;
				read_data_0_out       <= read_data_0_in_latched;
				read_data_1_out       <= read_data_1_in_latched;
				prefetch_command_out  <= prefetch_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_in_latched     <= 0;
			read_data_0_in_latched       <= 0;
			read_data_1_in_latched       <= 0;
			prefetch_response_in_latched <= 0;
		end else begin
			if(enabled_cmd)begin
				read_response_in_latched     <= read_response_in;
				read_data_0_in_latched       <= read_data_0_in;
				read_data_1_in_latched       <= read_data_1_in;
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
//response tracking logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			read_job_counter_done_latched <= 0;
		else begin
			if (read_response_in_latched.valid) begin
				read_job_counter_done_latched <= read_job_counter_done_latched + read_response_in_latched.cmd.real_size;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//read commands sending logic this signal makes sure you don't send anymore read command while the write buffers are full
////////////////////////////////////////////////////////////////////////////

	assign send_to_write_engine = (~read_data_out_buffer_status.alfull && cu_configure_latched[22]) ||  cu_configure_latched[21] || ~(cu_configure_latched[22] || cu_configure_latched[21]);

////////////////////////////////////////////////////////////////////////////
//read prefetch dependence state machine
////////////////////////////////////////////////////////////////////////////

	read_state current_state, next_state;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= READ_STREAM_RESET;
		else begin
			if(enabled)
				current_state <= next_state;
		end
	end// always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			READ_STREAM_RESET : begin
				next_state = READ_STREAM_IDLE;
			end
			READ_STREAM_IDLE : begin
				if(wed_request_in.valid && enabled_cmd)
					next_state = READ_STREAM_SET;
				else
					next_state = READ_STREAM_IDLE;
			end
			READ_STREAM_SET : begin
				if(wed_request_in_latched.valid && enabled_prefetch)
					next_state = PREFETCH_READ_STREAM_START;
				else if(wed_request_in_latched.valid)
					next_state = READ_STREAM_START;
				else
					next_state = READ_STREAM_SET;
			end
			PREFETCH_READ_STREAM_START : begin
				next_state = PREFETCH_READ_STREAM_REQ;
			end
			PREFETCH_READ_STREAM_REQ : begin
				if(leave_cmd_prefetch)
					next_state = PREFETCH_READ_STREAM_REQ;
				else
					next_state = READ_STREAM_START;
			end
			READ_STREAM_START : begin
				next_state = READ_STREAM_REQ;
			end
			READ_STREAM_REQ : begin
				if(leave_cmd_read)
					next_state = READ_STREAM_REQ;
				else
					next_state = READ_STREAM_PENDING;
			end
			READ_STREAM_PENDING : begin
				if(done_read_pending)
					next_state = READ_STREAM_DONE;
				else
					next_state = READ_STREAM_PENDING;
			end
			READ_STREAM_DONE : begin
				if((|wed_prefetch_in_latched.wed.size_send) && enabled_prefetch)
					next_state = PREFETCH_READ_STREAM_START;
				else if((|wed_request_in_latched.wed.size_send))
					next_state = READ_STREAM_START;
				else
					next_state = READ_STREAM_FINAL;
			end
			READ_STREAM_FINAL : begin
				next_state = READ_STREAM_FINAL;
			end
		endcase
	end

	always_ff @(posedge clock) begin
		case (current_state)
			READ_STREAM_RESET : begin
				send_cmd_read                 <= 0;
				leave_cmd_read                <= 0;
				send_cmd_prefetch             <= 0;
				leave_cmd_prefetch            <= 0;
				cmd_setup                     <= 0;
				done_prefetch_pending         <= 0;
				done_read_pending             <= 0;
				read_job_resp_done_latched    <= 0;
				prefetch_counter_resp_latched <= 0;
			end
			READ_STREAM_IDLE : begin
				cmd_setup <= 0;
			end
			READ_STREAM_SET : begin
				cmd_setup <= 1;
			end
			PREFETCH_READ_STREAM_START : begin
				cmd_setup                     <= 0;
				send_cmd_prefetch             <= 0;
				leave_cmd_prefetch            <= 1;
				done_prefetch_pending         <= 0;
				prefetch_counter_resp_latched <= 0;
			end
			PREFETCH_READ_STREAM_REQ : begin
				done_prefetch_pending <= 0;
				if((prefetch_counter_send_latched >= (tlb_size_latched)) || ~(|wed_prefetch_in_latched.wed.size_send))begin
					send_cmd_prefetch  <= 0;
					leave_cmd_prefetch <= 0;
				end else begin
					send_cmd_prefetch  <= 1;
					leave_cmd_prefetch <= 1;
				end
				prefetch_counter_resp_latched <= prefetch_counter_resp_latched + prefetch_response_in_latched.valid;
			end
			READ_STREAM_START : begin
				done_prefetch_pending      <= 0;
				cmd_setup                  <= 0;
				send_cmd_prefetch          <= 0;
				leave_cmd_prefetch         <= 0;
				send_cmd_read              <= 0;
				leave_cmd_read             <= 1;
				read_job_resp_done_latched <= 0;
				done_read_pending          <= 0;
				prefetch_counter_resp_latched <= prefetch_counter_resp_latched + prefetch_response_in_latched.valid;
			end
			READ_STREAM_REQ : begin
				done_read_pending <= 0;
				done_prefetch_pending      <= 0;
				if((read_job_send_done_latched >= (max_tlb_cl_requests_latched)) || ~(|wed_request_in_latched.wed.size_send)) begin
					send_cmd_read  <= 0;
					leave_cmd_read <= 0;
				end else begin
					send_cmd_read  <= 1;
					leave_cmd_read <= 1;
				end

				prefetch_counter_resp_latched <= prefetch_counter_resp_latched + prefetch_response_in_latched.valid;
				read_job_resp_done_latched <= read_job_resp_done_latched + read_response_in_latched.valid;
			end
			READ_STREAM_PENDING : begin
				send_cmd_read <= 0;
				if(read_job_send_done_latched == read_job_resp_done_latched)
					done_read_pending <= 1;
				else
					done_read_pending <= 0;

				if(prefetch_counter_send_latched == prefetch_counter_resp_latched)
					done_prefetch_pending <= 1;
				else
					done_prefetch_pending <= 0;

				prefetch_counter_resp_latched <= prefetch_counter_resp_latched + prefetch_response_in_latched.valid;
				read_job_resp_done_latched <= read_job_resp_done_latched + read_response_in_latched.valid;
			end
			READ_STREAM_DONE : begin

			end
			READ_STREAM_FINAL : begin

			end
		endcase
	end


////////////////////////////////////////////////////////////////////////////
//read  logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_out_latched   <= 0;
			next_offest                <= 0;
			wed_request_in_latched     <= 0;
			read_job_send_done_latched <= 0;
		end else begin

			if(cmd_setup)
				wed_request_in_latched <= wed_request_in;

			if (~read_command_buffer_status.alfull && send_to_write_engine && (|wed_request_in_latched.wed.size_send) && send_cmd_read)begin

				if(wed_request_in_latched.wed.size_send > CACHELINE_ARRAY_NUM)begin
					wed_request_in_latched.wed.size_send   <= wed_request_in_latched.wed.size_send - CACHELINE_ARRAY_NUM;
					read_command_out_latched.cmd.real_size <= CACHELINE_ARRAY_NUM;

					if (cu_configure_latched[3]) begin
						read_command_out_latched.command <= READ_CL_S;
						read_command_out_latched.size    <= 12'h080;
					end else begin
						read_command_out_latched.size    <= cmd_size_calculate(wed_request_in_latched.wed.size_send);
						read_command_out_latched.command <= READ_CL_NA;
					end

				end else if (wed_request_in_latched.wed.size_send <= CACHELINE_ARRAY_NUM) begin
					wed_request_in_latched.wed.size_send   <= 0;
					read_command_out_latched.cmd.real_size <= wed_request_in_latched.wed.size_send;

					if (cu_configure_latched[3]) begin
						read_command_out_latched.command <= READ_CL_S;
						read_command_out_latched.size    <= 12'h080;
					end else begin
						read_command_out_latched.size    <= cmd_size_calculate(wed_request_in_latched.wed.size_send);
						read_command_out_latched.command <= READ_PNA;
					end

				end

				read_command_out_latched.cmd.cu_id            <= CU_READ_CONTROL_ID;
				read_command_out_latched.cmd.cmd_type         <= CMD_READ;
				read_command_out_latched.cmd.cacheline_offest <= 0;
				read_command_out_latched.cmd.address_offest   <= next_offest;
				read_command_out_latched.cmd.array_struct     <= READ_DATA;

				read_command_out_latched.cmd.abt <= map_CABT(cu_configure_latched[0:2]);
				read_command_out_latched.abt     <= map_CABT(cu_configure_latched[0:2]);

				read_command_out_latched.valid <= 1'b1;
				read_job_send_done_latched     <= read_job_send_done_latched + 1;

				read_command_out_latched.address <= wed_request_in_latched.wed.array_send + next_offest;

				next_offest <= next_offest + CACHELINE_SIZE;

			end else begin
				read_command_out_latched <= 0;
			end

			if(done_read_pending)
				read_job_send_done_latched <= 0;

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
				wed_prefetch_in_latched                <= wed_request_in;
				wed_prefetch_in_latched.wed.array_send <= (wed_request_in.wed.array_send & ADDRESS_PAGE_ALIGN_MASK);
			end

			if (~prefetch_command_buffer_status.alfull && (|wed_prefetch_in_latched.wed.size_send) && send_cmd_prefetch && enabled_prefetch) begin

				if(wed_prefetch_in_latched.wed.size_send > PAGE_ARRAY_NUM)begin
					wed_prefetch_in_latched.wed.size_send      <= wed_prefetch_in_latched.wed.size_send - PAGE_ARRAY_NUM;
					prefetch_command_out_latched.cmd.real_size <= PAGE_ARRAY_NUM;
				end else if (wed_prefetch_in_latched.wed.size_send <= PAGE_ARRAY_NUM) begin
					wed_prefetch_in_latched.wed.size_send      <= 0;
					prefetch_command_out_latched.cmd.real_size <= wed_prefetch_in_latched.wed.size_send;
				end

				prefetch_command_out_latched.command <= TOUCH_I;
				prefetch_command_out_latched.size    <= 12'h080;

				prefetch_command_out_latched.cmd.cu_id            <= CU_READ_CONTROL_ID;
				prefetch_command_out_latched.cmd.cmd_type         <= CMD_PREFETCH_READ;
				prefetch_command_out_latched.cmd.cacheline_offest <= 0;
				prefetch_command_out_latched.cmd.address_offest   <= next_prefetch_offest;
				prefetch_command_out_latched.cmd.array_struct     <= PREFETCH_DATA;

				prefetch_command_out_latched.cmd.abt <= STRICT;
				prefetch_command_out_latched.abt     <= STRICT;


				prefetch_command_out_latched.valid <= 1'b1;
				prefetch_counter_send_latched      <= prefetch_counter_send_latched +1;

				prefetch_command_out_latched.address <= wed_prefetch_in_latched.wed.array_send  + next_prefetch_offest;

				next_prefetch_offest <= next_prefetch_offest + PAGE_SIZE;

			end else begin
				prefetch_command_out_latched <= 0;
			end

			if(done_prefetch_pending)
				prefetch_counter_send_latched <= 0;

		end
	end

endmodule