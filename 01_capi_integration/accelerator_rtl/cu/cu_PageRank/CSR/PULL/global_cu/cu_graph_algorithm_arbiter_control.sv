// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_graph_algorithm_arbiter_control.sv
// Create : 2020-03-03 19:58:21
// Revise : 2020-03-04 09:25:11
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_graph_algorithm_arbiter_control #(
	parameter NUM_GRAPH_CU  = NUM_GRAPH_CU_GLOBAL ,
	parameter NUM_VERTEX_CU = NUM_VERTEX_CU_GLOBAL
) (
	input  logic                          clock                                            , // Clock
	input  logic                          rstn                                             ,
	output logic                          cu_rstn_out [0:NUM_GRAPH_CU-1]                   ,
	input  logic                          enabled_in                                       ,
	output logic [      NUM_GRAPH_CU-1:0] enable_cu_out                                    ,
	input  logic [                  0:63] cu_configure                                     ,
	output logic [                  0:63] cu_configure_out [0:NUM_GRAPH_CU-1]              ,
	input  WEDInterface                   wed_request_in                                   ,
	output WEDInterface                   cu_wed_request_out  [0:NUM_GRAPH_CU-1]           ,
	input  ResponseBufferLine             read_response_in                                 ,
	output ResponseBufferLine             read_response_cu_out [0:NUM_GRAPH_CU-1]          ,
	input  ResponseBufferLine             write_response_in                                ,
	output ResponseBufferLine             write_response_cu_out [0:NUM_GRAPH_CU-1]         ,
	input  ReadWriteDataLine              read_data_0_in                                   ,
	input  ReadWriteDataLine              read_data_1_in                                   ,
	output ReadWriteDataLine              read_data_0_cu_out [0:NUM_GRAPH_CU-1]            ,
	output ReadWriteDataLine              read_data_1_cu_out [0:NUM_GRAPH_CU-1]            ,
	input  BufferStatus                   read_buffer_status                               ,
	output BufferStatus                   read_buffer_status_cu_out [0:NUM_GRAPH_CU-1]     ,
	input  BufferStatus                   write_buffer_status                              ,
	output BufferStatus                   write_buffer_status_cu_out [0:NUM_GRAPH_CU-1]    ,
	input  logic                          read_command_bus_grant                           ,
	output logic                          read_command_bus_grant_cu_out [0:NUM_GRAPH_CU-1] ,
	output logic                          read_command_bus_request                         ,
	input  logic                          read_command_bus_request_cu_in [0:NUM_GRAPH_CU-1],
	output CommandBufferLine              read_command_out                                 ,
	input  CommandBufferLine              read_command_out_cu_in [0:NUM_GRAPH_CU-1]        ,
	output CommandBufferLine              write_command_out                                ,
	input  CommandBufferLine              write_command_out_cu_in [0:NUM_GRAPH_CU-1]       ,
	output ReadWriteDataLine              write_data_0_out                                 ,
	output ReadWriteDataLine              write_data_1_out                                 ,
	input  ReadWriteDataLine              write_data_0_out_cu_in [0:NUM_GRAPH_CU-1]        ,
	input  ReadWriteDataLine              write_data_1_out_cu_in [0:NUM_GRAPH_CU-1]        ,
	input  VertexInterface                vertex_job                                       ,
	output VertexInterface                vertex_job_cu_out [0:NUM_GRAPH_CU-1]             ,
	output logic                          vertex_job_request                               ,
	input  logic                          vertex_job_request_cu_in [0:NUM_GRAPH_CU-1]      ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done                          ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done                            ,
	input  logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_cu_in [0:NUM_GRAPH_CU-1] ,
	input  logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_cu_in [0:NUM_GRAPH_CU-1]
);

	logic                          enabled                                                 ;
	logic                          cu_rstn_out_latched                   [0:NUM_GRAPH_CU-1];
	logic [      NUM_GRAPH_CU-1:0] enable_cu_out_latched                                   ;
	logic [                  0:63] cu_configure_latched                                    ;
	logic [                  0:63] cu_configure_out_latched              [0:NUM_GRAPH_CU-1];
	WEDInterface                   wed_request_in_latched                                  ;
	WEDInterface                   cu_wed_request_out_latched            [0:NUM_GRAPH_CU-1];
	ResponseBufferLine             read_response_in_latched                                ;
	ResponseBufferLine             read_response_cu_out_latched          [0:NUM_GRAPH_CU-1];
	ResponseBufferLine             read_response_cu_out_internal         [0:NUM_GRAPH_CU-1];
	logic                          read_response_cu_out_internal_valid   [0:NUM_GRAPH_CU-1];
	ResponseBufferLine             write_response_in_latched                               ;
	ResponseBufferLine             write_response_cu_out_latched         [0:NUM_GRAPH_CU-1];
	ResponseBufferLine             write_response_cu_out_internal        [0:NUM_GRAPH_CU-1];
	logic                          write_response_cu_out_internal_valid  [0:NUM_GRAPH_CU-1];
	ReadWriteDataLine              read_data_0_in_latched                                  ;
	ReadWriteDataLine              read_data_1_in_latched                                  ;
	ReadWriteDataLine              read_data_0_cu_out_latched            [0:NUM_GRAPH_CU-1];
	ReadWriteDataLine              read_data_1_cu_out_latched            [0:NUM_GRAPH_CU-1];
	BufferStatus                   read_buffer_status_latched                              ;
	BufferStatus                   read_buffer_status_cu_out_latched     [0:NUM_GRAPH_CU-1];
	BufferStatus                   write_buffer_status_latched                             ;
	BufferStatus                   write_buffer_status_cu_out_latched    [0:NUM_GRAPH_CU-1];
	logic                          read_command_bus_grant_latched                          ;
	logic                          read_command_bus_grant_cu_out_latched [0:NUM_GRAPH_CU-1];
	logic                          read_command_bus_request_latched                        ;
	logic                          read_command_bus_request_cu_in_latched[0:NUM_GRAPH_CU-1];
	CommandBufferLine              read_command_out_latched                                ;
	CommandBufferLine              read_command_out_cu_in_latched        [0:NUM_GRAPH_CU-1];
	CommandBufferLine              write_command_out_latched                               ;
	CommandBufferLine              write_command_out_cu_in_latched       [0:NUM_GRAPH_CU-1];
	ReadWriteDataLine              write_data_0_out_latched                                ;
	ReadWriteDataLine              write_data_1_out_latched                                ;
	ReadWriteDataLine              write_data_0_out_cu_in_latched        [0:NUM_GRAPH_CU-1];
	ReadWriteDataLine              write_data_1_out_cu_in_latched        [0:NUM_GRAPH_CU-1];
	VertexInterface                vertex_job_latched                                      ;
	VertexInterface                vertex_job_cu_out_latched             [0:NUM_GRAPH_CU-1];
	logic                          vertex_job_request_latched                              ;
	logic                          vertex_job_request_cu_in_latched      [0:NUM_GRAPH_CU-1];
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_latched                         ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_latched                           ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_cu_in_latched [0:NUM_GRAPH_CU-1];
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_cu_in_latched   [0:NUM_GRAPH_CU-1];


	genvar i;
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
	//Drive output
	////////////////////////////////////////////////////////////////////////////

	generate
		for ( i = 0; i < (NUM_GRAPH_CU); i++) begin : generate_cu_graph_algorithm_output_reset_logic
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					cu_wed_request_out[i].valid <= 0;
					read_response_cu_out[i].valid <= 0;
					write_response_cu_out[i].valid <= 0;
					read_data_0_cu_out[i].valid <= 0;
					read_data_1_cu_out[i].valid <= 0;
					vertex_job_cu_out[i].valid <= 0;
					cu_configure_out[i]<=0;
					read_command_bus_grant_cu_out[i] <= 0;
					read_buffer_status_cu_out[i] <= 0;
					read_buffer_status_cu_out[i].empty <= 1;
					write_buffer_status_cu_out[i] <= 0;
					write_buffer_status_cu_out[i].empty <= 1;
				end else begin
					cu_wed_request_out[i].valid <= cu_wed_request_out_latched[i].valid;
					read_response_cu_out[i].valid <= read_response_cu_out_latched[i].valid;
					write_response_cu_out[i].valid <= write_response_cu_out_latched[i].valid;
					read_data_0_cu_out[i].valid <= read_data_0_cu_out_latched[i].valid;
					read_data_1_cu_out[i].valid <= read_data_1_cu_out_latched[i].valid;
					vertex_job_cu_out[i].valid <= vertex_job_cu_out_latched[i].valid;
					cu_configure_out[i]<=cu_configure_out_latched[i];
					read_command_bus_grant_cu_out[i] <= read_command_bus_grant_cu_out_latched[i];
					read_buffer_status_cu_out[i] <= read_buffer_status_cu_out_latched[i];
					write_buffer_status_cu_out[i] <= write_buffer_status_cu_out_latched[i];
				end
			end
		end
	endgenerate

	generate
		for ( i = 0; i < (NUM_GRAPH_CU); i++) begin : generate_cu_graph_algorithm_output_logic
			always_ff @(posedge clock) begin
				cu_wed_request_out[i].payload <= cu_wed_request_out_latched[i].payload;
				read_response_cu_out[i].payload <= read_response_cu_out_latched[i].payload;
				write_response_cu_out[i].payload <= write_response_cu_out_latched[i].payload;
				read_data_0_cu_out[i].payload <= read_data_0_cu_out_latched[i].payload;
				read_data_1_cu_out[i].payload <= read_data_1_cu_out_latched[i].payload;
				vertex_job_cu_out[i].payload <= vertex_job_cu_out_latched[i].payload;
			end
		end
	endgenerate

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_request       <= 0;
			read_command_bus_request <= 0;
			enable_cu_out            <= 0;
			vertex_job_counter_done  <= 0;
			edge_job_counter_done    <= 0;
			read_command_out.valid   <= 0;
			write_command_out.valid  <= 0;
			write_data_0_out.valid   <= 0;
			write_data_1_out.valid   <= 0;
		end else begin
			vertex_job_request       <= vertex_job_request_latched;
			read_command_bus_request <= read_command_bus_request_latched;
			enable_cu_out            <= enable_cu_out_latched;
			vertex_job_counter_done  <= vertex_job_counter_done_latched;
			edge_job_counter_done    <= edge_job_counter_done_latched;
			read_command_out.valid   <= read_command_out_latched.valid;
			write_command_out.valid  <= write_command_out_latched.valid;
			write_data_0_out.valid   <= write_data_0_out_latched.valid;
			write_data_1_out.valid   <= write_data_1_out_latched.valid;
		end
	end

	always_ff @(posedge clock) begin
		read_command_out.payload  <= read_command_out_latched.payload;
		write_command_out.payload <= write_command_out_latched.payload;
		write_data_0_out.payload  <= write_data_0_out_latched.payload;
		write_data_1_out.payload  <= write_data_1_out_latched.payload;
	end

	////////////////////////////////////////////////////////////////////////////
	//Drive input
	////////////////////////////////////////////////////////////////////////////

	generate
		for ( i = 0; i < (NUM_GRAPH_CU); i++) begin : generate_cu_graph_algorithm_input_reset_logic
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					read_command_bus_request_cu_in_latched[i] <= 0;
					vertex_job_request_cu_in_latched[i] <= 0;
					vertex_job_counter_done_cu_in_latched[i] <= 0;
					edge_job_counter_done_cu_in_latched[i] <= 0;
					read_command_out_cu_in_latched[i].valid <= 0;
					write_command_out_cu_in_latched[i].valid <= 0;
					write_data_0_out_cu_in_latched[i].valid <= 0;
					write_data_1_out_cu_in_latched[i].valid <= 0;
				end else begin
					read_command_bus_request_cu_in_latched[i] <= read_command_bus_request_cu_in[i];
					vertex_job_request_cu_in_latched[i] <= 	vertex_job_request_cu_in[i];
					vertex_job_counter_done_cu_in_latched[i] <= 	vertex_job_counter_done_cu_in[i];
					edge_job_counter_done_cu_in_latched[i] <= 	edge_job_counter_done_cu_in[i];
					read_command_out_cu_in_latched[i].valid <= 	read_command_out_cu_in[i].valid;
					write_command_out_cu_in_latched[i].valid <= 	write_command_out_cu_in[i].valid;
					write_data_0_out_cu_in_latched[i].valid <= 	write_data_0_out_cu_in[i].valid;
					write_data_1_out_cu_in_latched[i].valid <= 	write_data_1_out_cu_in[i].valid;
				end
			end
		end
	endgenerate

	generate
		for ( i = 0; i < (NUM_GRAPH_CU); i++) begin : generate_cu_graph_algorithm_input_logic
			always_ff @(posedge clock) begin
				read_command_out_cu_in_latched[i].payload <= 	read_command_out_cu_in[i].payload;
				write_command_out_cu_in_latched[i].payload <= 	write_command_out_cu_in[i].payload;
				write_data_0_out_cu_in_latched[i].payload <= 	write_data_0_out_cu_in[i].payload;
				write_data_1_out_cu_in_latched[i].payload <= 	write_data_1_out_cu_in[i].payload;
			end
		end
	endgenerate

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_buffer_status_latched        <= 0;
			read_buffer_status_latched.empty  <= 1;
			write_buffer_status_latched       <= 0;
			write_buffer_status_latched.empty <= 1;
			read_command_bus_grant_latched    <= 0;
			vertex_job_latched.valid          <= 0;
			wed_request_in_latched.valid      <= 0;
			read_response_in_latched.valid    <= 0;
			write_response_in_latched.valid   <= 0;
			read_data_0_in_latched.valid      <= 0;
			read_data_1_in_latched.valid      <= 0;
			cu_configure_latched              <= 0;
		end else begin
			read_buffer_status_latched      <= read_buffer_status;
			write_buffer_status_latched     <= write_buffer_status;
			read_command_bus_grant_latched  <= read_command_bus_grant;
			vertex_job_latched.valid        <= vertex_job.valid;
			wed_request_in_latched.valid    <= wed_request_in.valid;
			read_response_in_latched.valid  <= read_response_in.valid;
			write_response_in_latched.valid <= write_response_in.valid;
			read_data_0_in_latched.valid    <= read_data_0_in.valid;
			read_data_1_in_latched.valid    <= read_data_1_in.valid;
			if((|cu_configure))
				cu_configure_latched <= cu_configure;
		end
	end

	always_ff @(posedge clock) begin
		vertex_job_latched.payload        <= vertex_job.payload;
		wed_request_in_latched.payload    <= wed_request_in.payload;
		read_response_in_latched.payload  <= read_response_in.payload;
		write_response_in_latched.payload <= write_response_in.payload;
		read_data_0_in_latched.payload    <= read_data_0_in.payload;
		read_data_1_in_latched.payload    <= read_data_1_in.payload;
	end

	////////////////////////////////////////////////////////////////////////////
	// Reset/Enable logic
	////////////////////////////////////////////////////////////////////////////


	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_enable_cu
			always_ff @(posedge clock) begin
				enable_cu_out_latched[i] <= ((i*NUM_VERTEX_CU) < cu_configure_latched[32:63]);
			end
		end
	endgenerate


	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_cu_configure
			always_ff @(posedge clock) begin
				cu_configure_out_latched[i] <= cu_configure_latched;
			end
		end
	endgenerate

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_rstn
			always_ff @(posedge clock) begin
				cu_rstn_out_latched[i] <= rstn;
			end
		end
	endgenerate

	always_ff @(posedge clock) begin
		cu_rstn_out <= cu_rstn_out_latched;
	end

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_cu_wed_request_out
			always_ff @(posedge clock) begin
				cu_wed_request_out_latched[i] = wed_request_in_latched;
			end
		end
	endgenerate


	////////////////////////////////////////////////////////////////////////////
	//Read/wrote Response Arbitration
	////////////////////////////////////////////////////////////////////////////

	demux_bus #(
		.DATA_WIDTH($bits(ResponseBufferLine)),
		.BUS_WIDTH(NUM_GRAPH_CU)
	) read_response_demux_bus_instant (
		.clock         (clock),
		.rstn          (rstn),
		.sel_in        (read_response_in_latched.payload.cmd.cu_id_y[CU_ID_RANGE-$clog2(NUM_GRAPH_CU):CU_ID_RANGE-1]),
		.data_in       (read_response_in_latched),
		.data_in_valid (read_response_in_latched.valid),
		.data_out      (read_response_cu_out_internal),
		.data_out_valid(read_response_cu_out_internal_valid)
	);

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_read_response_demux
			always_ff @(posedge clock) begin
				read_response_cu_out_latched[i].valid    <= read_response_cu_out_internal_valid[i];
				read_response_cu_out_latched[i].payload <= read_response_cu_out_internal[i].payload;
			end
		end
	endgenerate


	demux_bus #(
		.DATA_WIDTH($bits(ResponseBufferLine)),
		.BUS_WIDTH(NUM_GRAPH_CU)
	) write_response_demux_bus_instant (
		.clock         (clock),
		.rstn          (rstn),
		.sel_in        (write_response_in_latched.payload.cmd.cu_id_y[CU_ID_RANGE-$clog2(NUM_GRAPH_CU):CU_ID_RANGE-1]),
		.data_in       (write_response_in_latched),
		.data_in_valid (write_response_in_latched.valid),
		.data_out      (write_response_cu_internal),
		.data_out_valid(write_response_cu_internal_valid)
	);

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_write_response_demux
			always_ff @(posedge clock) begin
				write_response_cu_out_latched[i].valid   <= write_response_cu_out_internal_valid[i];
				write_response_cu_out_latched[i].payload <= write_response_cu_out_internal[i].payload;
			end
		end
	endgenerate




endmodule

