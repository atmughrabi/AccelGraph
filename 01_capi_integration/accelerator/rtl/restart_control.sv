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
// Revise : 2019-11-06 19:35:39
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_PKG::*;
import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module restart_control (
	input                     clock                  , // Clock
	input                     enabled_in             ,
	input                     rstn                   , // Asynchronous reset active low
	input  CommandBufferLine  command_outstanding_in ,
	input  logic [0:7]        command_tag_in         ,
	input  ResponseBufferLine restart_response_in    ,
	input  ResponseInterface  response               ,
	input  logic [0:7]        credits_in             ,
	output logic              ready_restart_issue    ,
	output CommandBufferLine  restart_command_out    ,
	output logic              restart_command_flushed,
	output logic              restart_pending
);


	logic             enabled                     ;
	logic [0:7]       credits_total               ;
	CommandBufferLine command_outstanding_data_in ;
	CommandBufferLine command_outstanding_data_out;
	logic             command_outstanding_we      ;
	logic             command_outstanding_rd      ;
	logic             command_outstanding_rd_S2   ;
	logic [0:7]       command_outstanding_wr_addr ;
	logic [0:7]       command_outstanding_rd_addr ;

	logic             restart_command_send                  ;
	logic             restart_command_sent                  ;
	logic             restart_command_buffer_push           ;
	logic             restart_command_buffer_pop            ;
	CommandBufferLine restart_command_buffer_out            ;
	CommandBufferLine restart_command_buffer_in             ;
	BufferStatus      restart_command_buffer_status_internal;
	psl_response_t    response_type_latched                 ;

	restart_state current_state, next_state;

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
	//record outstanding commands write
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			command_outstanding_we      <= 0;
			command_outstanding_wr_addr <= 0;
			command_outstanding_data_in <= 0;
		end else begin
			if(enabled) begin
				command_outstanding_we              <= command_outstanding_in.valid;
				command_outstanding_wr_addr         <= command_tag_in;
				command_outstanding_data_in         <= command_outstanding_in;
				command_outstanding_data_in.cmd.tag <= command_tag_in;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//push restarted commands to queue
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			command_outstanding_rd_addr <= 0;
			command_outstanding_rd      <= 0;
			command_outstanding_rd_S2   <= 0;
			response_type_latched       <= DONE;
		end else begin
			if(enabled) begin
				command_outstanding_rd_addr <= response.tag;
				command_outstanding_rd      <= response.valid;
				response_type_latched       <= response.response;
				command_outstanding_rd_S2   <= command_outstanding_rd;
			end
		end
	end

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
	//credit counter
	////////////////////////////////////////////////////////////////////////////

	always @(posedge clock or negedge rstn) begin
		if (~rstn) begin
			credits_total <= 0;
		end else begin
			if(enabled)begin
				credits_total <= credits_in;
			end else begin
				credits_total <= 0;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//Restart State Machine
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= RESTART_RESET;
		else begin
			if(enabled)
				current_state <= next_state;
		end
	end// always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			RESTART_RESET : begin
				next_state = RESTART_IDLE;
			end
			RESTART_IDLE : begin
				if(response.valid)
					next_state = RESTART_INIT;
				else
					next_state = RESTART_IDLE;
			end
			RESTART_INIT : begin
				if(response_type_latched == PAGED)
					next_state = RESTART_SEND_CMD;
				else
					next_state = RESTART_SEND_CMD_FLUSHED;
			end
			RESTART_INIT : begin
				next_state = RESTART_SEND_CMD;
			end
			RESTART_SEND_CMD : begin
				next_state = RESTART_RESP_WAIT;
			end
			RESTART_RESP_WAIT : begin
				if(restart_response_in.valid || (command_outstanding_rd_S2 && command_outstanding_data_out.cmd.cmd_type == CMD_RESTART && command_outstanding_data_out.cmd.cu_id == RESTART_ID))
					next_state = RESTART_SEND_CMD_FLUSHED;
				else
					next_state = RESTART_RESP_WAIT;
			end
			RESTART_SEND_CMD_FLUSHED : begin
				if(restart_command_buffer_status_internal.empty && (credits_total == CREDITS_TOTAL))begin
					if(response.valid  && response.response == PAGED)
						next_state = RESTART_INIT;
					else
						next_state = RESTART_DONE;
				end
				else begin
					if(response.valid && response.response == PAGED)
						next_state = RESTART_INIT;
					else
						next_state = RESTART_SEND_CMD_FLUSHED;
				end
			end
			RESTART_DONE : begin
				if(response.valid  && response.response == PAGED)
					next_state = RESTART_INIT;
				else
					next_state = RESTART_IDLE;

			end
		endcase
	end

	always_ff @(posedge clock) begin
		case (current_state)
			RESTART_RESET : begin
				ready_restart_issue     <= 0;
				restart_command_out     <= 0;
				restart_pending         <= 0;
				restart_command_send    <= 0;
				restart_command_flushed <= 0;
			end
			RESTART_IDLE : begin
				ready_restart_issue     <= 0;
				restart_command_out     <= 0;
				restart_pending         <= 0;
				restart_command_send    <= 0;
				restart_command_flushed <= 0;
			end
			RESTART_INIT : begin
				ready_restart_issue     <= 1;
				restart_pending         <= 1;
				restart_command_flushed <= 0;
				restart_command_send    <= 0;
			end
			RESTART_SEND_CMD : begin
				restart_command_out              <= command_outstanding_data_out;
				restart_command_out.command      <= RESTART;
				restart_command_out.abt          <= STRICT;
				restart_command_out.cmd.cmd_type <= CMD_RESTART;
				restart_command_out.cmd.cu_id    <= RESTART_ID;
			end
			RESTART_RESP_WAIT : begin
				restart_command_out <= 0;
			end
			RESTART_SEND_CMD_FLUSHED : begin
				if(~restart_command_buffer_status_internal.empty) begin
					restart_command_out     <= restart_command_buffer_out;
					restart_command_out.abt <= STRICT;
					restart_command_flushed <= 1;
					restart_command_send    <= 1;
				end else begin
					restart_command_out     <= 0;
					restart_command_flushed <= 0;
					restart_command_send    <= 0;
				end
			end
			RESTART_DONE : begin
				restart_command_out  <= 0;
				restart_command_send <= 0;
			end
		endcase
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

	assign restart_command_buffer_pop = ~restart_command_buffer_status_internal.empty && restart_pending && restart_command_send;

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