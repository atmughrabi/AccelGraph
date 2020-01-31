// -----------------------------------------------------------------------------
//
//		"CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : done_control.sv
// Create : 2019-09-26 15:21:03
// Revise : 2019-12-05 23:51:49
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import AFU_PKG::*;

module done_control (
	input  logic                      clock                     , // Clock
	input  logic                      rstn                      ,
	input  logic                      soft_rstn                 ,
	input  logic                      enabled_in                ,
	input  cu_return_type             cu_return                 ,
	input  ResponseStatistcsInterface response_statistics       ,
	input  logic                      cu_done                   ,
	input  logic                      cu_return_done_ack        ,
	output logic                      reset_done                ,
	output logic [0:63]               cu_return_done            ,
	output ResponseStatistcsInterface report_response_statistics
);


	done_state                 current_state, next_state;
	logic                      done_flag                         ;
	logic                      enabled                           ;
	logic [0:63]               cu_return_done_latched            ;
	logic                      prev_soft_rstn                    ;
	logic                      next_soft_rstn                    ;
	logic                      done_soft_rstn                    ;
	ResponseStatistcsInterface report_response_statistics_latched;

	assign done_flag = cu_done;


	////////////////////////////////////////////////////////////////////////////
	//soft reset done logic
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			next_soft_rstn <= 0;
			prev_soft_rstn <= 0;
			done_soft_rstn <= 0;
		end else begin
			next_soft_rstn <= soft_rstn;
			prev_soft_rstn <= next_soft_rstn;
			done_soft_rstn <= ~prev_soft_rstn && next_soft_rstn;
		end
	end

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
	//DONE State Machine
	////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= DONE_RESET;
		else begin
			if(enabled)
				current_state <= next_state;
		end
	end// always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			DONE_RESET : begin
				next_state = DONE_IDLE;
			end
			DONE_IDLE : begin
				if(done_flag)
					next_state = DONE_RESET_REQ;
				else
					next_state = DONE_IDLE;
			end
			DONE_RESET_REQ : begin
				next_state = DONE_RESET_PENDING;
			end
			DONE_RESET_PENDING : begin
				if(done_soft_rstn)
					next_state = DONE_MMIO_REQ;
				else
					next_state = DONE_RESET_PENDING;
			end
			DONE_MMIO_REQ : begin
				if(cu_return_done_ack)
					next_state = DONE_IDLE;
				else
					next_state = DONE_MMIO_REQ;
			end

		endcase
	end

	always_ff @(posedge clock) begin
		case (current_state)
			DONE_RESET : begin
				cu_return_done                     <= 64'b0;
				cu_return_done_latched             <= 64'b0;
				report_response_statistics_latched <= 0;
				report_response_statistics         <= 0;
				reset_done                         <= 1'b1;
			end
			DONE_IDLE : begin
				cu_return_done                     <= 64'b0;
				report_response_statistics         <= 0;
				cu_return_done_latched             <= cu_return.var1;
				report_response_statistics_latched <= response_statistics;
				reset_done                         <= 1'b1;
			end
			DONE_RESET_REQ : begin
				reset_done <= 1'b0;
			end
			DONE_RESET_PENDING : begin
				reset_done <= 1'b1;
			end
			DONE_MMIO_REQ : begin
				cu_return_done             <= cu_return_done_latched;
				report_response_statistics <= report_response_statistics_latched;
			end

		endcase
	end


endmodule