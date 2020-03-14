// -----------------------------------------------------------------------------
//
//		"CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : restart_control.sv
// Create : 2019-11-05 08:05:09
// Revise : 2019-12-06 04:36:34
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module restart_control #(parameter CREDIT_HEADROOM = 4) (
	input                     clock                    , // Clock
	input                     enabled_in               ,
	input                     rstn_in                  , // Asynchronous reset active low
	input  CommandBufferLine  command_outstanding_in   ,
	input  logic [0:7]        command_tag_in           ,
	input  ResponseBufferLine restart_response_in      ,
	input  ResponseInterface  response_in              ,
	input  CommandTagLine     response_tag_id_in       ,
	input  logic [0:7]        credits_in               ,
	input  logic [0:7]        total_credits            ,
	output logic              ready_restart_issue      ,
	output CommandBufferLine  restart_command_issue_out,
	output logic              restart_command_flushed  ,
	output logic              restart_pending
);

	ResponseInterface response                    ;
	logic             enabled                     ;
	logic [0:7]       total_credit_count          ;
	logic [0:7]       outstanding_restart_commands;
	CommandBufferLine command_outstanding_data_in ;
	CommandBufferLine command_outstanding_data_out;
	logic             command_outstanding_we      ;
	logic             command_outstanding_rd      ;
	logic             command_outstanding_rd_S2   ;
	logic [0:7]       command_outstanding_wr_addr ;
	logic [0:7]       command_outstanding_rd_addr ;

	logic                    restart_command_send                  ;
	logic                    restart_command_flag                  ;
	logic                    restart_command_flag_latched          ;
	logic                    restart_command_buffer_push           ;
	logic                    restart_command_buffer_pop            ;
	CommandBufferLine        restart_command_buffer_out            ;
	CommandBufferLine        restart_command_buffer_in             ;
	CommandBufferLineRestart restart_command_out                   ;
	CommandBufferLineRestart restart_command_issue_buffer_out      ;
	BufferStatus             restart_command_buffer_status_internal;
	psl_response_t           response_type_latched                 ;

	BufferStatus restart_command_issue_buffer_status_internal;
	logic        restart_command_issue_buffer_pop            ;

	restart_state current_state, next_state;

	logic       is_restart_cmd      ;
	logic       is_restart_rsp_done ;
	logic       is_restart_rsp_flush;
	logic [0:2] counter_state       ;
	logic       rstn                ;


	////////////////////////////////////////////////////////////////////////////
	//enable logic
	////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn_in) begin
		if(~rstn_in) begin
			rstn <= 0;
		end else begin
			rstn <= rstn_in;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled <= 0;
		end else begin
			enabled <= enabled_in;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//drive input
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			response <= 0;
		end else begin
			if(enabled)
				response <= response_in;
			else
				response <= 0;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			restart_command_issue_out.valid <= 0;
			restart_command_flushed         <= 0;
		end else begin
			restart_command_issue_out.valid <= restart_command_issue_buffer_out.cmd.valid;
			restart_command_flushed         <= restart_command_issue_buffer_out.flushed;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			restart_command_issue_out.payload <= 0;
		else
			restart_command_issue_out.payload <= restart_command_issue_buffer_out.cmd.payload;
	end

	////////////////////////////////////////////////////////////////////////////
	//keep in check outstanding restart commands send;
	////////////////////////////////////////////////////////////////////////////

	assign is_restart_cmd       = (restart_command_out.cmd.valid && restart_command_out.cmd.payload.cmd.cmd_type == CMD_RESTART);
	assign is_restart_rsp_done  = (restart_response_in.valid);
	assign is_restart_rsp_flush = (command_outstanding_rd_S2 && command_outstanding_data_out.payload.cmd.cmd_type == CMD_RESTART && command_outstanding_data_out.payload.cmd.cu_id_x == RESTART_ID);

	assign counter_state[0] = is_restart_cmd;
	assign counter_state[1] = is_restart_rsp_done ;
	assign counter_state[2] = is_restart_rsp_flush;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			outstanding_restart_commands <= 0;
		end else begin
			case (counter_state)
				3'b100 : begin
					outstanding_restart_commands <= outstanding_restart_commands + 1;
				end
				3'b110 : begin
					outstanding_restart_commands <= outstanding_restart_commands;
				end
				3'b101 : begin
					outstanding_restart_commands <= outstanding_restart_commands;
				end
				3'b111 : begin
					outstanding_restart_commands <= outstanding_restart_commands - 1;
				end
				3'b011 : begin
					outstanding_restart_commands <= outstanding_restart_commands - 2;
				end
				3'b001 : begin
					outstanding_restart_commands <= outstanding_restart_commands - 1;
				end
				3'b010 : begin
					outstanding_restart_commands <= outstanding_restart_commands - 1;
				end
				3'b000 : begin
					outstanding_restart_commands <= outstanding_restart_commands;
				end
				default : outstanding_restart_commands <= outstanding_restart_commands ;
			endcase
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
				command_outstanding_we                      <= command_outstanding_in.valid;
				command_outstanding_wr_addr                 <= command_tag_in;
				command_outstanding_data_in                 <= command_outstanding_in;
				command_outstanding_data_in.payload.cmd.tag <= command_tag_in;
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
			total_credit_count <= 0;
		end else begin
			if(enabled)begin
				total_credit_count <= credits_in;
			end else begin
				total_credit_count <= 0;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//credit counter
	////////////////////////////////////////////////////////////////////////////

	always @(posedge clock or negedge rstn) begin
		if (~rstn) begin
			restart_command_flag_latched <= 0;
		end else begin
			if(enabled)begin
				restart_command_flag_latched <= restart_command_flag;
			end else
			restart_command_flag_latched <= 0;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//Restart State Machine
	////////////////////////////////////////////////////////////////////////////

	// assign restart_command_flag = response.valid && (response.response == PAGED || response.response == AERROR || response.response == DERROR) && (response_tag_id_in.abt == STRICT || response_tag_id_in.abt == PAGE);
	// assign restart_command_flag = (response.response == PAGED);
	assign restart_command_flag = response.valid && (response.response == PAGED || response.response == AERROR || response.response == DERROR) && (response_tag_id_in.abt == STRICT || response_tag_id_in.abt == PAGE || response_tag_id_in.abt == SPEC || response_tag_id_in.abt == PREF);


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
				if(restart_command_flag_latched)
					next_state = RESTART_SEND_CMD;
				else
					next_state = RESTART_SEND_CMD_FLUSHED;
			end
			RESTART_SEND_CMD : begin
				if (restart_command_flag_latched)
					next_state = RESTART_SEND_CMD;
				else if(restart_command_flag)
					next_state = RESTART_INIT;
				else
					next_state = RESTART_RESP_WAIT;
			end
			RESTART_RESP_WAIT : begin
				if(restart_command_flag)
					next_state = RESTART_INIT;
				else if(~restart_command_out.cmd.valid && ~(|outstanding_restart_commands))
					next_state = RESTART_SEND_CMD_FLUSHED;
				else
					next_state = RESTART_RESP_WAIT;
			end
			RESTART_SEND_CMD_FLUSHED : begin
				if(restart_command_buffer_status_internal.empty && (total_credit_count == total_credits))begin
					if(restart_command_flag)
						next_state = RESTART_INIT;
					else
						next_state = RESTART_DONE;
				end
				else begin
					if(restart_command_flag)
						next_state = RESTART_INIT;
					else
						next_state = RESTART_SEND_CMD_FLUSHED;
				end
			end
			RESTART_DONE : begin
				if(response.valid)
					next_state = RESTART_INIT;
				else
					next_state = RESTART_IDLE;

			end
		endcase
	end

	always_ff @(posedge clock) begin
		case (current_state)
			RESTART_RESET : begin
				ready_restart_issue           <= 0;
				restart_command_out.cmd.valid <= 0;
				restart_pending               <= 0;
				restart_command_send          <= 0;
				restart_command_out.flushed   <= 0;
			end
			RESTART_IDLE : begin
				ready_restart_issue           <= 0;
				restart_command_out.cmd.valid <= 0;
				restart_pending               <= 0;
				restart_command_send          <= 0;
				restart_command_out.flushed   <= 0;
			end
			RESTART_INIT : begin
				ready_restart_issue  <= 1;
				restart_pending      <= 1;
				restart_command_send <= 0;

				if(restart_command_buffer_out.valid) begin
					restart_command_out.cmd                 <= restart_command_buffer_out;
					restart_command_out.cmd.payload.abt     <= STRICT;
					restart_command_out.cmd.payload.cmd.abt <= STRICT;
					restart_command_out.flushed             <= restart_command_buffer_out.valid;
				end else begin
					restart_command_out.cmd.valid <= 0;
					restart_command_out.flushed   <= 0;
				end

			end
			RESTART_SEND_CMD : begin
				restart_command_out.cmd                      <= command_outstanding_data_out;
				restart_command_out.cmd.payload.command      <= RESTART;
				restart_command_out.cmd.payload.abt          <= STRICT;
				restart_command_out.cmd.payload.cmd.abt      <= STRICT;
				restart_command_out.cmd.payload.cmd.cmd_type <= CMD_RESTART;
				restart_command_out.cmd.payload.cmd.cu_id_x  <= RESTART_ID;
				restart_command_out.cmd.payload.cmd.cu_id_y  <= RESTART_ID;
				restart_command_out.flushed                  <= 0;
				restart_command_send                         <= 0;
			end
			RESTART_RESP_WAIT : begin
				restart_command_out.cmd.valid <= 0;
				restart_command_out.flushed   <= 0;
			end
			RESTART_SEND_CMD_FLUSHED : begin
				if(~restart_command_buffer_status_internal.empty) begin
					restart_command_out.cmd             <= restart_command_buffer_out;
					restart_command_out.cmd.payload.abt <= STRICT;
					restart_command_out.flushed         <= restart_command_buffer_out.valid;
					restart_command_send                <= 1;
				end else begin
					restart_command_out.cmd.valid <= 0;
					restart_command_out.flushed   <= 0;
					restart_command_send          <= 0;
				end
			end
			RESTART_DONE : begin
				restart_command_out.cmd.valid <= 0;
				restart_command_send          <= 0;
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

	assign restart_command_issue_buffer_pop = ~restart_command_issue_buffer_status_internal.empty && restart_pending && (total_credit_count > CREDIT_HEADROOM);

	fifo #(
		.WIDTH($bits(CommandBufferLineRestart)),
		.DEPTH(CREDITS_TOTAL                  )
	) restart_command_issue_buffer_fifo_instant (
		.clock   (clock                                              ),
		.rstn    (rstn                                               ),
		
		.push    (restart_command_out.cmd.valid                      ),
		.data_in (restart_command_out                                ),
		.full    (restart_command_issue_buffer_status_internal.full  ),
		.alFull  (restart_command_issue_buffer_status_internal.alfull),
		
		.pop     (restart_command_issue_buffer_pop                   ),
		.valid   (restart_command_issue_buffer_status_internal.valid ),
		.data_out(restart_command_issue_buffer_out                   ),
		.empty   (restart_command_issue_buffer_status_internal.empty )
	);

endmodule