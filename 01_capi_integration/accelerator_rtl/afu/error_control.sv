// -----------------------------------------------------------------------------
//
//		"CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : error_control.sv
// Create : 2019-09-26 15:21:03
// Revise : 2019-12-05 23:51:49
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import AFU_PKG::*;

module error_control (
	input  logic        clock            , // Clock
	input  logic        rstn             ,
	input  logic        enabled_in       ,
	input  logic [0:63] external_errors  ,
	input  logic        report_errors_ack,
	output logic        reset_error      ,
	output logic [0:63] report_errors
);


	error_state current_state, next_state;
	logic       error_flag   ;
	logic       enabled      ;

	assign error_flag = |external_errors;

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
	//Error State Machine
	////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= ERROR_RESET;
		else begin
			if(enabled)
				current_state <= next_state;
		end
	end// always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			ERROR_RESET : begin
				next_state = ERROR_IDLE;
			end
			ERROR_IDLE : begin
				if(error_flag)
					next_state = ERROR_MMIO_REQ;
				else
					next_state = ERROR_IDLE;
			end
			ERROR_MMIO_REQ : begin
				if(report_errors_ack)
					next_state = ERROR_RESET_REQ;
				else
					next_state = ERROR_MMIO_REQ;
			end
			ERROR_RESET_REQ : begin
				next_state = ERROR_RESET_PENDING;
			end
			ERROR_RESET_PENDING : begin
				next_state = ERROR_IDLE;
			end
		endcase
	end

	always_ff @(posedge clock) begin
		case (current_state)
			ERROR_RESET : begin
				report_errors <= 64'b0;
				reset_error   <= 1'b1;
			end
			ERROR_IDLE : begin
				report_errors <= external_errors;
				reset_error   <= 1'b1;
			end
			ERROR_MMIO_REQ : begin

			end
			ERROR_RESET_REQ : begin
				reset_error <= 1'b0;
			end
			ERROR_RESET_PENDING : begin
				reset_error <= 1'b1;
			end
		endcase
	end


endmodule