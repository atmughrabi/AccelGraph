// -----------------------------------------------------------------------------
//
//		"CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : tag_control.sv
// Create : 2019-09-26 15:25:10
// Revise : 2019-12-05 23:51:49
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import AFU_PKG::*;

module tag_control (
	input  logic          clock               , // Clock
	input  logic          rstn                ,
	input  logic          enabled_in          ,
	input  logic          tag_response_valid  ,
	input  logic [0:7]    response_tag        ,
	output CommandTagLine response_tag_id_out ,
	input  logic [0:7]    data_read_tag       ,
	output CommandTagLine data_read_tag_id_out,
	input  logic          tag_command_valid   ,
	input  CommandTagLine tag_command_id      ,
	output logic [0:7]    command_tag_out     ,
	output logic          tag_buffer_ready
);


// reset state machine
// reset signal
// start state empty tag fifo
// push tags to fifo till full
// ready signal tag fifo is not empty and full
	CommandTagLine response_tag_id ;
	CommandTagLine data_read_tag_id;
	logic [0:7]    command_tag     ;
	logic          enabled         ;

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
// Tag Initialization Flush logic.
////////////////////////////////////////////////////////////////////////////
// if tag fifo is ready and not empty you can send tags other wise command buffer need to stall.

	tag_buffer_state current_state, next_state;
	logic            tag_init_flag;

	logic       tag_buffer_push;
	logic [0:7] tag_fifo_input ;

	logic tag_buffer_pop;

	logic       tag_counter_valid;
	logic       tag_counter_pop  ;
	logic [0:7] tag_counter      ;

	BufferStatus tag_buffer;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= TAG_BUFFER_RESET;
		else begin
			if (enabled)
				current_state <= next_state;
			else
				current_state <= TAG_BUFFER_RESET;
		end
	end// always_ff @(posedge clock)


	always_comb begin
		next_state = current_state;
		case (current_state)
			TAG_BUFFER_RESET : begin
				next_state = TAG_BUFFER_INIT;
			end
			TAG_BUFFER_INIT : begin
				if(tag_buffer.alfull)
					next_state = TAG_BUFFER_READY;
			end
			TAG_BUFFER_POP : begin
				if(tag_buffer.empty)
					next_state = TAG_BUFFER_READY;
			end
			TAG_BUFFER_READY : begin
				next_state = TAG_BUFFER_READY;
			end
		endcase
	end

	always_ff @(posedge clock) begin
		case (current_state)
			TAG_BUFFER_RESET : begin
				tag_counter <= 8'h00;
			end
			TAG_BUFFER_INIT : begin
				if(~tag_buffer.alfull) begin
					tag_counter <= tag_counter + 1'b1;
				end
			end
			TAG_BUFFER_READY : begin
				tag_counter <= 8'b0;
			end
		endcase
	end

	always_comb begin
		case (current_state)
			TAG_BUFFER_RESET : begin
				tag_init_flag     = 1'b1;
				tag_counter_valid = 1'b0;
				tag_counter_pop   = 1'b0;
			end
			TAG_BUFFER_INIT : begin
				tag_init_flag   = 1'b1;
				tag_counter_pop = 1'b0;

				if(~tag_buffer.alfull) begin
					tag_counter_valid = 1'b1;
				end
				else begin
					tag_counter_valid = 1'b0;
				end
			end
			TAG_BUFFER_POP : begin
				tag_counter_valid = 1'b0;
				tag_init_flag     = 1'b1;

				if(~tag_buffer.empty && tag_buffer.valid) begin
					tag_counter_pop = 1'b1;
				end
				else begin
					tag_counter_pop = 1'b0;
				end
			end
			TAG_BUFFER_READY : begin
				tag_init_flag     = 1'b0;
				tag_counter_valid = 1'b0;
				tag_counter_pop   = 1'b0;
			end
		endcase
	end

	always_comb begin
		if(tag_init_flag) begin
			tag_buffer_push = tag_counter_valid;
			tag_fifo_input  = tag_counter;
			tag_buffer_pop  = 1'b0;
		end else begin
			tag_buffer_push = tag_response_valid;
			tag_fifo_input  = response_tag;
			tag_buffer_pop  = tag_command_valid;
		end
	end


// always_ff @(posedge clock or negedge rstn) begin
// 	if(~rstn) begin
// 		tag_buffer_ready 		<= 	1'b0;
// 		response_tag_id_out 	<= 	0;
// 		data_read_tag_id_out 	<= 	0;
// 		command_tag_out 		<= 	0;
// 	end else if (enabled) begin
// 		tag_buffer_ready 		<= ~tag_buffer.empty & tag_buffer.valid & ~tag_init_flag;
// 		response_tag_id_out 	<= 	response_tag_id;
// 		data_read_tag_id_out 	<= 	data_read_tag_id;
// 		command_tag_out 		<= 	command_tag;
// 	end
// end // always_ff @(posedge clock)

	assign tag_buffer_ready     = ~tag_buffer.empty & tag_buffer.valid & ~tag_init_flag;
	assign response_tag_id_out  = response_tag_id;
	assign data_read_tag_id_out = data_read_tag_id;
	assign command_tag_out      = command_tag;
////////////////////////////////////////////////////////////////////////////
// Tag -> CU bookeeping for response/read buffer interface
////////////////////////////////////////////////////////////////////////////

// we keep each tag associated with the command type and CU ID so we send the response to the right compute unite

	ram_2xrd #(
		.WIDTH($bits(CommandTagLine)),
		.DEPTH(TAG_COUNT            )
	) tag_ram_instant (
		.clock    (clock            ),
		.we       (tag_command_valid),
		.wr_addr  (command_tag      ),
		.data_in  (tag_command_id   ),
		
		.rd_addr1 (response_tag     ),
		.data_out1(response_tag_id  ),
		
		.rd_addr2 (data_read_tag    ),
		.data_out2(data_read_tag_id )
	);


////////////////////////////////////////////////////////////////////////////
// Tag fifo
////////////////////////////////////////////////////////////////////////////

// The PSL porvided 256 tags so we keem them in a fifo structure as a ticket to be issued and returned

	fifo #(
		.WIDTH(8        ),
		.DEPTH(TAG_COUNT)
	) tag_buffer_fifo_instant (
		.clock   (clock            ),
		.rstn    (rstn             ),
		
		.push    (tag_buffer_push  ),
		.data_in (tag_fifo_input   ),
		.full    (tag_buffer.full  ),
		.alFull  (tag_buffer.alfull),
		
		.pop     (tag_buffer_pop   ),
		.valid   (tag_buffer.valid ),
		.data_out(command_tag      ),
		.empty   (tag_buffer.empty )
	);

endmodule