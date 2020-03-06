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
	parameter CU_ID_X = 1,
	parameter CU_ID_Y = 1
) (
	input  logic                          clock                               , // Clock
	input  logic                          rstn                                ,
	input  logic                          enabled_in                          ,
	input  ResponseBufferLine             write_response_in                   ,
	input  BufferStatus                   write_buffer_status                 ,
	input  EdgeDataRead                   edge_data                           ,
	input  BufferStatus                   data_buffer_status                  ,
	input  logic                          edge_data_write_bus_grant           ,
	output logic                          edge_data_write_bus_request         ,
	output logic                          edge_data_request                   ,
	output EdgeDataWrite                  edge_data_write_out                 ,
	input  VertexInterface                vertex_job                          ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_resp_out         ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum_out         ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum_internal_out
);


	EdgeDataRead                 edge_data_latched                  ;
	EdgeDataWrite                edge_data_accumulator              ;
	EdgeDataWrite                edge_data_accumulator_latch        ;
	logic                        enabled                            ;
	VertexInterface              vertex_job_latched                 ;
	WEDInterface                 wed_request_in_latched             ;
	BufferStatus                 edge_data_write_buffer_status      ;
	EdgeDataWrite                edge_data_write_buffer             ;
	logic                        edge_data_write_bus_grant_latched  ;
	logic                        edge_data_write_bus_request_latched;
	BufferStatus                 data_buffer_status_latch           ;
	logic [0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum_latched    ;
	logic [                 0:3] accum_delay                        ;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_resp         ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum         ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum_internal;

	logic [ 0:(DATA_SIZE_READ_BITS-1)] input_value    ;
	logic                              valid_value    ;
	logic                              valid_stream   ;
	logic [0:(DATA_SIZE_WRITE_BITS-1)] running_value  ;
	logic                              overflow_x     ;
	logic                              underflow_x    ;
	logic                              overflow_accume;
	logic                              rstp           ;

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
			edge_data_write_out.valid            <= 0;
			edge_data_request                    <= 0;
			vertex_num_counter_resp_out          <= 0;
			edge_data_counter_accum_out          <= 0;
			edge_data_counter_accum_internal_out <= 0;
		end else begin
			if(enabled) begin
				edge_data_write_out.valid            <= edge_data_write_buffer.valid;
				edge_data_request                    <= ~data_buffer_status_latch.empty && ~edge_data_write_buffer_status.alfull;
				vertex_num_counter_resp_out          <= vertex_num_counter_resp;
				edge_data_counter_accum_out          <= edge_data_counter_accum;
				edge_data_counter_accum_internal_out <= edge_data_counter_accum_internal;
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_data_write_out.payload <= edge_data_write_buffer.payload;
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_latched.valid       <= 0;
			data_buffer_status_latch       <= 0;
			data_buffer_status_latch.empty <= 1;

		end else begin
			if(enabled) begin
				vertex_job_latched.valid <= vertex_job.valid;
				data_buffer_status_latch <= data_buffer_status;
			end
		end
	end

	always_ff @(posedge clock) begin
		vertex_job_latched.payload <= vertex_job.payload;
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
			edge_data_latched.valid <= 0;
		end else begin
			if (enabled) begin
				edge_data_latched.valid <= edge_data.valid;
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_data_latched.payload <= edge_data.payload;
	end


////////////////////////////////////////////////////////////////////////////
//edge_data_accumulate
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_accumulator             <= 0;
			edge_data_counter_accum_internal  <= 0;
			edge_data_accumulator_latch.valid <= 0;
			input_value                       <= 0;
			edge_data_counter_accum_latched   <= 0;
			valid_stream                      <= 0;
			accum_delay                       <= 0;
		end else begin
			if (enabled && vertex_job_latched.valid) begin
				if(edge_data_latched.valid)begin
					edge_data_counter_accum_latched <= edge_data_counter_accum_latched + 1;
					input_value                     <= edge_data_latched.payload.data;

					if(~valid_stream)begin
						valid_value  <= 1;
						valid_stream <= 1;
					end else begin
						valid_value <= 0;
					end

				end else begin
					valid_value <= 0;
					input_value <= 0;
				end

				if((edge_data_counter_accum_latched == vertex_job_latched.payload.inverse_out_degree) && (accum_delay == 4'h F)) begin
					accum_delay                           <= 0;
					edge_data_counter_accum_internal      <= edge_data_counter_accum_latched;
					edge_data_counter_accum_latched       <= 0;
					edge_data_accumulator.valid           <= 1;
					edge_data_accumulator.payload.index   <= vertex_job_latched.payload.id;
					edge_data_accumulator.payload.cu_id_x <= CU_ID_X;
					edge_data_accumulator.payload.cu_id_y <= CU_ID_Y;
					edge_data_accumulator.payload.data    <= running_value;
				end else if(edge_data_counter_accum_latched == vertex_job_latched.payload.inverse_out_degree) begin
					accum_delay <= accum_delay + 1;
				end

				if(edge_data_counter_accum_internal == vertex_job_latched.payload.inverse_out_degree )begin
					edge_data_accumulator            <= 0;
					edge_data_counter_accum_internal <= 0;
					edge_data_accumulator_latch      <= edge_data_accumulator;
					valid_stream                     <= 0;
				end else begin
					edge_data_accumulator_latch.valid <= 0;
				end
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
				if(edge_data_latched.valid) begin
					edge_data_counter_accum <= edge_data_counter_accum + 1;
				end
			end
		end
	end


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_num_counter_resp <= 0;
		end else begin
			if (enabled) begin
				if(write_response_in.valid) begin
					vertex_num_counter_resp <= vertex_num_counter_resp + 1;
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
				edge_data_write_bus_grant_latched <= edge_data_write_bus_grant && ~write_buffer_status.alfull;
				edge_data_write_bus_request       <= edge_data_write_bus_request_latched;
			end
		end
	end

	assign edge_data_write_bus_request_latched = ~edge_data_write_buffer_status.empty && ~write_buffer_status.alfull;


	////////////////////////////////////////////////////////////////////////////
	// single percision floating point add accume module
	////////////////////////////////////////////////////////////////////////////

	fp_single_add_acc fp_single_add_acc_instant (
		.clk   (clock          ),
		.areset(rstp           ),
		.x     (input_value    ),
		.n     (valid_value    ),
		.r     (running_value  ),
		.xo    (overflow_x     ),
		.xu    (underflow_x    ),
		.ao    (overflow_accume),
		.en    (enabled        )
	);


	fifo #(
		.WIDTH($bits(EdgeDataWrite) ),
		.DEPTH(WRITE_CMD_BUFFER_SIZE)
	) edge_data_write_buffer_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (edge_data_accumulator_latch.valid   ),
		.data_in (edge_data_accumulator_latch         ),
		.full    (edge_data_write_buffer_status.full  ),
		.alFull  (edge_data_write_buffer_status.alfull),
		
		.pop     (edge_data_write_bus_grant_latched   ),
		.valid   (edge_data_write_buffer_status.valid ),
		.data_out(edge_data_write_buffer              ),
		.empty   (edge_data_write_buffer_status.empty )
	);

endmodule