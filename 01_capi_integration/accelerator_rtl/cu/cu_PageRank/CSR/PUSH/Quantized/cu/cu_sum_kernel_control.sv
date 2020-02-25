// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_sum_kernel_fp_control.sv
// Create : 2019-09-26 15:19:17
// Revise : 2019-11-03 12:38:39
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_sum_kernel_control #(
	parameter CU_ID    = 1
) (
	input  logic                          clock                           , // Clock
	input  logic                          rstn                            ,
	input  logic                          enabled_in                      ,
	input  WEDInterface                   wed_request_in                  ,
	input  ResponseBufferLine             write_response_in               ,
	input  BufferStatus                   write_buffer_status             ,
	input  EdgeDataRead                   edge_data                       ,
	input  BufferStatus                   data_buffer_status              ,
	input  logic                          edge_data_write_bus_grant       ,
	output logic                          edge_data_write_bus_request     ,
	output logic                          edge_data_request               ,
	output EdgeDataWrite                  edge_data_write_out             ,
	input  VertexInterface                vertex_job                      ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_resp         ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum         ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum_internal
);


	ResponseBufferLine           write_response_in_latched                    ;
	EdgeDataRead                 edge_data_latched                            ;
	EdgeDataWrite                edge_data_accumulator_latch                  ;
	EdgeDataWrite                edge_data_accumulator_latch_issue            ;
	EdgeDataWrite                edge_data_accumulator_latch_NLOCK            ;
	EdgeDataWrite                edge_data_accumulator_burst_out_latched_NLOCK;
	logic                        edge_data_accumulator_bus_grant_latched_NLOCK;
	logic                        enabled                                      ;
	VertexInterface              vertex_job_latched                           ;
	WEDInterface                 wed_request_in_latched                       ;
	BufferStatus                 edge_data_write_buffer_status                ;
	EdgeDataWrite                edge_data_write_buffer                       ;
	logic                        edge_data_write_bus_grant_latched            ;
	logic                        edge_data_write_bus_request_latched          ;
	BufferStatus                 data_buffer_status_latch                     ;
	BufferStatus                 edge_data_NLOCK_status_internal_NLOCK        ;
	logic [0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum_latched              ;
	logic [                 0:3] accum_delay                                  ;
	logic                        new_vertex                                   ;

	logic [ 0:(DATA_SIZE_READ_BITS-1)] input_value_1                      ;
	logic [0:(DATA_SIZE_WRITE_BITS-1)] input_value_2                      ;
	logic                              valid_value                        ;
	logic                              rstp                               ;
	logic [      0:(EDGE_SIZE_BITS-1)] dest_id_latched                    ;

	// assign input_value = 32'h 3f800000;
	// assign valid_value = vertex_job_latched.valid;
	always_ff @(posedge clock) begin
		rstp <= ~rstn;
	end

////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_write_out <= 0;
			edge_data_request   <= 0;
		end else begin
			if(enabled) begin
				edge_data_write_out <= edge_data_write_buffer;
				edge_data_request   <= ~data_buffer_status_latch.empty && ~edge_data_write_buffer_status.alfull;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_latched             <= 0;
			wed_request_in_latched         <= 0;
			data_buffer_status_latch       <= 0;
			data_buffer_status_latch.empty <= 1;
			write_response_in_latched      <= 0;
		end else begin
			if(enabled) begin
				vertex_job_latched        <= vertex_job;
				wed_request_in_latched    <= wed_request_in;
				data_buffer_status_latch  <= data_buffer_status;
				write_response_in_latched <= write_response_in;
			end
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
//edge_data_latched
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_latched <= 0;
		end else begin
			if (enabled) begin
				if(edge_data.valid)
					edge_data_latched <= edge_data;
				else
					edge_data_latched <= 0;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//edge_data_accumulate
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_counter_accum_internal <= 0;
			edge_data_accumulator_latch      <= 0;
			input_value_1                    <= 0;
			input_value_2                    <= 0;
			edge_data_counter_accum_latched  <= 0;
			accum_delay                      <= 0;
			dest_id_latched                  <= 0;
			valid_value                      <= 0;
		end else begin
			if (enabled && vertex_job_latched.valid) begin

				if(write_response_in_latched.valid && write_response_in_latched.response != NLOCK)
					edge_data_counter_accum_latched <= edge_data_counter_accum_latched + 1;

				if(edge_data_latched.valid)begin
					input_value_1   <= vertex_job_latched.data;
					input_value_2   <= edge_data_latched.data;
					dest_id_latched <= edge_data_latched.id;
					valid_value     <= 1;
				end else begin
					valid_value     <= 0;
					input_value_1   <= 0;
					input_value_2   <= 0;
					dest_id_latched <= 0;
				end

				if((edge_data_counter_accum_latched == vertex_job_latched.out_degree) && (accum_delay == 4'h F)) begin
					accum_delay                      <= 0;
					edge_data_counter_accum_internal <= edge_data_counter_accum_latched;
					edge_data_counter_accum_latched  <= 0;
				end else if(edge_data_counter_accum_latched == vertex_job_latched.out_degree) begin
					accum_delay <= accum_delay + 1;
				end

				if(edge_data_counter_accum_internal == vertex_job_latched.out_degree )begin
					edge_data_counter_accum_internal <= 0;
				end
			end
		end
	end



////////////////////////////////////////////////////////////////////////////
//Output Delay
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_accumulator_latch <= 0;
		end else begin
			if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
				edge_data_accumulator_latch.valid <= valid_value;
				edge_data_accumulator_latch.index <= dest_id_latched;
				edge_data_accumulator_latch.cu_id <= CU_ID;
				edge_data_accumulator_latch.data  <= input_value_1 + input_value_2;
			end else begin
				edge_data_accumulator_latch <= 0;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//counter trackings
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_counter_accum <= 0;
		end else begin
			if (enabled) begin
				if(write_response_in_latched.valid && write_response_in_latched.response != NLOCK) begin
					edge_data_counter_accum <= edge_data_counter_accum + 1;
				end
			end
		end
	end


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_num_counter_resp <= 0;
			new_vertex              <= 0;
		end else begin
			if (enabled) begin
				if(vertex_job_latched.valid && ~new_vertex) begin
					new_vertex              <= 1;
					vertex_num_counter_resp <= vertex_num_counter_resp + 1;
				end else if(~vertex_job_latched.valid)  begin
					new_vertex <= 0;
				end
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// write Edge DATA CU Buffers
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_write_bus_grant_latched <= 0;
			edge_data_write_bus_request       <= 0;
		end else begin
			if(enabled) begin
				edge_data_write_bus_grant_latched <= edge_data_write_bus_grant;
				edge_data_write_bus_request       <= edge_data_write_bus_request_latched;
			end
		end
	end

	assign edge_data_write_bus_request_latched = ~edge_data_write_buffer_status.empty && ~write_buffer_status.alfull && edge_data_NLOCK_status_internal_NLOCK.empty;

	////////////////////////////////////////////////////////////////////////////
	// single percision floating point add module
	////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(EdgeDataWrite) ),
		.DEPTH(WRITE_CMD_BUFFER_SIZE)
	) edge_data_write_buffer_fifo_instant (
		.clock   (clock                                  ),
		.rstn    (rstn                                   ),
		
		.push    (edge_data_accumulator_latch_issue.valid),
		.data_in (edge_data_accumulator_latch_issue      ),
		.full    (edge_data_write_buffer_status.full     ),
		.alFull  (edge_data_write_buffer_status.alfull   ),
		
		.pop     (edge_data_write_bus_grant_latched      ),
		.valid   (edge_data_write_buffer_status.valid    ),
		.data_out(edge_data_write_buffer                 ),
		.empty   (edge_data_write_buffer_status.empty    )
	);


///////////////////////////////////////////////////////////////////////////
//Response Managment NLOCK
///////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_accumulator_latch_NLOCK <= 0;
		end else begin
			if(write_response_in_latched.valid && write_response_in_latched.response == NLOCK) begin
				edge_data_accumulator_latch_NLOCK.valid <= 1;
				edge_data_accumulator_latch_NLOCK.index <= write_response_in_latched.cmd.address_offest[(64-EDGE_SIZE_BITS):63];
				edge_data_accumulator_latch_NLOCK.cu_id <= CU_ID;
				edge_data_accumulator_latch_NLOCK.data  <= write_response_in_latched.cmd.aux_data[(64-DATA_SIZE_WRITE_BITS):63];
			end else begin
				edge_data_accumulator_latch_NLOCK <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_accumulator_latch_issue <= 0;
		end else begin
			if(edge_data_accumulator_burst_out_latched_NLOCK.valid && ~edge_data_accumulator_latch.valid)
				edge_data_accumulator_latch_issue <= edge_data_accumulator_burst_out_latched_NLOCK;
			else
				edge_data_accumulator_latch_issue <= edge_data_accumulator_latch;
		end
	end

	assign edge_data_accumulator_bus_grant_latched_NLOCK = ~edge_data_write_buffer_status.alfull && ~edge_data_NLOCK_status_internal_NLOCK.empty && ~edge_data_accumulator_latch.valid;

	fifo #(
		.WIDTH($bits(EdgeDataWrite) ),
		.DEPTH(WRITE_CMD_BUFFER_SIZE)
	) edge_data_accumulator_NLOCK_edge_data_burst_fifo_instant (
		.clock   (clock                                        ),
		.rstn    (rstn                                         ),
		
		.push    (edge_data_accumulator_latch_NLOCK.valid      ),
		.data_in (edge_data_accumulator_latch_NLOCK            ),
		.full    (edge_data_NLOCK_status_internal_NLOCK.full   ),
		.alFull  (edge_data_NLOCK_status_internal_NLOCK.alfull ),
		
		.pop     (edge_data_accumulator_bus_grant_latched_NLOCK),
		.valid   (edge_data_NLOCK_status_internal_NLOCK.valid  ),
		.data_out(edge_data_accumulator_burst_out_latched_NLOCK),
		.empty   (edge_data_NLOCK_status_internal_NLOCK.empty  )
	);

endmodule