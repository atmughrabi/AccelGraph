// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : restart_control.sv
// Create : 2019-11-05 08:05:09
// Revise : 2019-11-05 10:59:34
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_PKG::*;
import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module restart_control (
	input                     clock                 , // Clock
	input                     enabled_in            ,
	input                     rstn                  , // Asynchronous reset active low
	input  CommandBufferLine  command_outstanding_in,
	input  logic [0:7]        command_tag_in        ,
	input  ResponseBufferLine restart_response_in   ,
	input  ResponseInterface  response              ,
	input  logic [0:7]        credits_in            ,
	input  logic              ready_issue           ,
	output CommandBufferLine  restart_command_out   ,
	output logic              restart_pending
);

	logic             enabled                     ;
	logic [0:7]       credits_partial             ;
	logic [0:7]       credits_total               ;
	logic             restart_pending_internal    ;
	CommandBufferLine command_outstanding_data_in ;
	CommandBufferLine command_outstanding_data_out;
	logic             command_outstanding_we      ;
	logic             command_outstanding_rd      ;
	logic             command_outstanding_rd_S2   ;
	logic [0:7]       command_outstanding_wr_addr ;
	logic [0:7]       command_outstanding_rd_addr ;

	logic             restart_command_buffer_push           ;
	logic             restart_command_buffer_pop            ;
	CommandBufferLine restart_command_buffer_out            ;
	CommandBufferLine restart_command_buffer_in             ;
	BufferStatus      restart_command_buffer_status_internal;

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
			restart_pending <= 0;
		end else begin
			restart_pending <= restart_pending_internal && (credits_total == CREDITS_TOTAL);
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			restart_command_out <= 0;
		end else begin
			restart_command_out <= restart_command_buffer_out;
		end
	end

////////////////////////////////////////////////////////////////////////////
//record outstanding commands write
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			command_outstanding_we      <= 0;
			command_outstanding_wr_addr <= 0;
			command_outstanding_data_in <= 0;
		end else begin
			if(enabled) begin
				command_outstanding_we          <= command_outstanding_in.valid;
				command_outstanding_wr_addr     <= command_outstanding_in.cmd.tag;
				command_outstanding_data_in     <= command_outstanding_in;
				command_outstanding_data_in.abt <= STRICT;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			command_outstanding_rd_addr <= 0;
			command_outstanding_rd      <= 0;
			command_outstanding_rd_S2   <= 0;
			credits_partial             <= 0;
		end else begin
			if(enabled) begin
				command_outstanding_rd_addr <= response.tag;
				command_outstanding_rd      <= response.valid;
				command_outstanding_rd_S2   <= command_outstanding_rd;

				credits_partial <= credits_partial + command_outstanding_rd;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			credits_total <= 0;
		end else begin
			if(enabled) begin
				credits_total <= credits_partial + credits_total;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//push restarted commands to queue
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			restart_command_buffer_push <= 0;
			restart_command_buffer_in   <= 0;
		end else begin
			if(enabled) begin

				restart_command_buffer_push <= command_outstanding_rd_S2;
				restart_command_buffer_in   <= command_outstanding_data_out;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//restart pending
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			restart_pending_internal <= 0;
		end else begin
			if(enabled && response.valid && ~restart_pending_internal) begin
				case (response.response)
					PAGED : begin
						restart_pending_internal <= 1;
					end
				endcase
			end

			if(restart_response_in.valid && restart_response_in.response == DONE) begin
				restart_pending_internal <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
// Tag -> CU bookeeping for outstanding commands in PSL
////////////////////////////////////////////////////////////////////////////

	ram #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(TAG_COUNT               )
	) outstanding_cmds_ram_instant (
		.clock   (clock                       ),
		.we      (command_outstanding_we      ),
		.wr_addr (command_outstanding_wr_addr ),
		.data_in (command_outstanding_data_in ),
		.rd_addr (command_outstanding_rd_addr ),
		.data_out(command_outstanding_data_out)
	);

////////////////////////////////////////////////////////////////////////////
//Buffer restart Commands
////////////////////////////////////////////////////////////////////////////

	assign restart_command_buffer_pop = ~restart_command_buffer_status_internal.empty && restart_pending;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(CREDITS_TOTAL           )
	) restart_command_buffer_fifo_instant (
		.clock   (clock                                        ),
		.rstn    (rstn                                         ),
		
		.push    (restart_command_buffer_push                  ),
		.data_in (restart_command_buffer_in                    ),
		.full    (restart_command_buffer_status_internal.full  ),
		.alFull  (restart_command_buffer_status_internal.alfull),
		
		.pop     (restart_command_buffer_pop                   ),
		.valid   (restart_command_buffer_status_internal.valid ),
		.data_out(restart_command_buffer_out                   ),
		.empty   (restart_command_buffer_status_internal.empty )
	);

endmodule