// -----------------------------------------------------------------------------
//
//		"CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_prefetch_stream_engine_control.sv
// Create : 2019-12-06 12:11:16
// Revise : 2019-12-07 18:24:08
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_prefetch_stream_engine_control #(parameter CU_PREFETCH_CONTROL_ID = PREFETCH_READ_CONTROL_ID) (
	input  logic                         clock                         , // Clock
	input  logic                         rstn                          ,
	input  logic                         enabled_in                    ,
	input  logic [                 0:63] base_address                  ,
	input  logic [                 0:63] total_size                    ,
	input  logic                         total_size_valid              ,
	input  logic [                 0:63] offset_size                   ,
	input  logic [                  0:6] offset_start                  , // where to start prefetching shift address
	input  logic [                 0:63] array_line_size               ,
	input  command_type                  cu_command_type               ,
	input  afu_command_t                 transaction_type              ,
	input  trans_order_behavior_t        commmand_abt                  ,
	input  ResponseBufferLine            prefetch_response_in          ,
	input  BufferStatus                  prefetch_command_buffer_status,
	output CommandBufferLine             prefetch_command_out          ,
	output logic [0:(ARRAY_SIZE_BITS-1)] prefetch_job_counter_done
);


	//output latched
	CommandBufferLine prefetch_command_out_latched;

	//input lateched
	ResponseBufferLine     prefetch_response_in_latched;
	logic [0:63]           base_address_latched        ;
	logic [0:63]           total_size_latched          ;
	logic                  total_size_valid_latched    ;
	logic [0:63]           offset_size_latched         ;
	logic [ 0:6]           offset_start_latched        ;
	afu_command_t          transaction_type_latched    ;
	command_type           cu_commmand_type_latched    ;
	trans_order_behavior_t commmand_abt_latched        ;

	logic [0:(ARRAY_SIZE_BITS-1)] prefetch_job_counter_done_latched;
	logic                         enabled                          ;
	logic                         enabled_cmd                      ;
	logic [                 0:63] next_offest                      ;



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

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled_cmd <= 0;
		end else begin
			enabled_cmd <= enabled_in;
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive output
////////////////////////////////////////////////////////////////////////////


	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_command_out      <= 0;
			prefetch_job_counter_done <= 0;
		end else begin
			prefetch_command_out      <= prefetch_command_out_latched;
			prefetch_job_counter_done <= prefetch_job_counter_done_latched;
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_response_in_latched <= 0;
			base_address_latched         <= 0;
			offset_start_latched         <= 0;
			offset_size_latched          <= 0;
			cu_commmand_type_latched     <= CMD_INVALID;
			commmand_abt_latched         <= STRICT;
			transaction_type_latched     <= TOUCH_I;
		end else begin
			if(enabled)begin
				prefetch_response_in_latched <= prefetch_response_in;
				base_address_latched         <= base_address;
				offset_start_latched         <= offset_start;
				offset_size_latched          <= offset_size;
				cu_commmand_type_latched     <= cu_command_type;
				commmand_abt_latched         <= commmand_abt;
				transaction_type_latched     <= transaction_type;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//response tracking logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			prefetch_job_counter_done_latched <= 0;
		else begin
			if (prefetch_response_in_latched.valid) begin
				prefetch_job_counter_done_latched <= prefetch_job_counter_done_latched + prefetch_response_in_latched.cmd.real_size;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//read commands sending logic
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_command_out_latched <= 0;
			next_offest                  <= 0;
			total_size_latched           <= 0;
			total_size_valid_latched     <= 0;
		end
		else begin

			if(~total_size_valid_latched && enabled_cmd) begin

				if(total_size >= (array_line_size << offset_start_latched))begin
					total_size_latched <= total_size - (array_line_size << offset_start_latched);
					next_offest        <= next_offest + (offset_size_latched << offset_start_latched);
				end else if (total_size < (array_line_size << offset_start_latched)) begin
					total_size_latched <= 0;
					next_offest        <= next_offest + (offset_size_latched << offset_start_latched);
				end

				total_size_valid_latched <= total_size_valid;
			end

			if (total_size_valid_latched && ~prefetch_command_buffer_status.alfull && (|total_size_latched) && enabled_cmd) begin

				if(total_size_latched >= array_line_size)begin
					total_size_latched                         <= total_size_latched - array_line_size;
					prefetch_command_out_latched.cmd.real_size <= array_line_size;
				end else if (total_size_latched < array_line_size) begin
					total_size_latched                         <= 0;
					prefetch_command_out_latched.cmd.real_size <= total_size_latched;
				end

				prefetch_command_out_latched.command <= transaction_type_latched;
				prefetch_command_out_latched.size    <= 12'h080;

				prefetch_command_out_latched.cmd.cu_id            <= CU_PREFETCH_CONTROL_ID;
				prefetch_command_out_latched.cmd.cmd_type         <= cu_commmand_type_latched;
				prefetch_command_out_latched.cmd.cacheline_offest <= 0;
				prefetch_command_out_latched.cmd.address_offest   <= next_offest;
				prefetch_command_out_latched.cmd.array_struct     <= PREFETCH_DATA;

				prefetch_command_out_latched.cmd.abt <= commmand_abt_latched;
				prefetch_command_out_latched.abt     <= commmand_abt_latched;


				prefetch_command_out_latched.valid <= 1'b1;

				prefetch_command_out_latched.address <= base_address_latched + next_offest;

				next_offest <= next_offest + offset_size_latched;

			end else begin
				prefetch_command_out_latched <= 0;
			end
		end
	end





endmodule