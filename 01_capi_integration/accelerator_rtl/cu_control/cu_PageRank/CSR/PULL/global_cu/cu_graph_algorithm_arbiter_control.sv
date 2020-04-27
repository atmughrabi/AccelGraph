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
// Revise : 2020-03-17 01:27:33
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
	input  logic                          clock                                           , // Clock
	input  logic                          rstn_in                                         ,
	input  logic                          enabled_in                                      ,
	output logic [      NUM_GRAPH_CU-1:0] enable_cu_out                                   ,
	input  logic [                  0:63] cu_configure                                    ,
	output logic [                  0:63] cu_configure_out [0:NUM_GRAPH_CU-1]             ,
	input  WEDInterface                   wed_request_in                                  ,
	output WEDInterface                   cu_wed_request_out  [0:NUM_GRAPH_CU-1]          ,
	input  ResponseBufferLine             read_response_in                                ,
	output ResponseBufferLine             read_response_cu_out [0:NUM_GRAPH_CU-1]         ,
	input  ResponseBufferLine             write_response_in                               ,
	output ResponseBufferLine             write_response_cu_out [0:NUM_GRAPH_CU-1]        ,
	input  ReadWriteDataLine              read_data_0_in                                  ,
	input  ReadWriteDataLine              read_data_1_in                                  ,
	output ReadWriteDataLine              read_data_0_cu_out [0:NUM_GRAPH_CU-1]           ,
	output ReadWriteDataLine              read_data_1_cu_out [0:NUM_GRAPH_CU-1]           ,
	input  BufferStatus                   read_buffer_status                              ,
	output BufferStatus                   read_buffer_status_cu_out [0:NUM_GRAPH_CU-1]    ,
	input  BufferStatus                   write_buffer_status                             ,
	output BufferStatus                   write_buffer_status_cu_out [0:NUM_GRAPH_CU-1]   ,
	input  logic                          read_command_bus_grant                          ,
	output logic [      NUM_GRAPH_CU-1:0] read_command_bus_grant_cu_out                   ,
	output logic                          read_command_bus_request                        ,
	input  logic [      NUM_GRAPH_CU-1:0] read_command_bus_request_cu_in                  ,
	output CommandBufferLine              read_command_out                                ,
	input  CommandBufferLine              read_command_out_cu_in [0:NUM_GRAPH_CU-1]       ,
	input  logic                          write_command_bus_grant                         ,
	output logic [      NUM_GRAPH_CU-1:0] write_command_bus_grant_cu_out                  ,
	output logic                          write_command_bus_request                       ,
	input  logic [      NUM_GRAPH_CU-1:0] write_command_bus_request_cu_in                 ,
	input  EdgeDataWrite                  edge_data_write_cu_in [0:NUM_GRAPH_CU-1]        ,
	output EdgeDataWrite                  edge_data_write_out                             ,
	input  VertexInterface                vertex_job                                      ,
	output VertexInterface                vertex_job_cu_out [0:NUM_GRAPH_CU-1]            ,
	output logic                          vertex_job_request                              ,
	input  logic [      NUM_GRAPH_CU-1:0] vertex_job_request_cu_in                        ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done                         ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done                           ,
	input  logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_cu_in [0:NUM_GRAPH_CU-1],
	input  logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_cu_in [0:NUM_GRAPH_CU-1]
);

	logic                    rstn                                                  ;
	logic                    enabled                                               ;
	logic [NUM_GRAPH_CU-1:0] enable_cu_out_latched                                 ;
	logic [            0:63] cu_configure_latched                                  ;
	logic [            0:63] cu_configure_out_latched            [0:NUM_GRAPH_CU-1];
	WEDInterface             wed_request_in_latched                                ;
	WEDInterface             cu_wed_request_out_latched          [0:NUM_GRAPH_CU-1];
	ResponseBufferLine       read_response_in_latched                              ;
	ResponseBufferLine       read_response_cu_out_latched        [0:NUM_GRAPH_CU-1];
	ResponseBufferLine       read_response_cu_out_internal       [0:NUM_GRAPH_CU-1];
	logic                    read_response_cu_out_internal_valid [0:NUM_GRAPH_CU-1];
	ResponseBufferLine       write_response_in_latched                             ;
	ResponseBufferLine       write_response_cu_out_latched       [0:NUM_GRAPH_CU-1];
	ResponseBufferLine       write_response_cu_out_internal      [0:NUM_GRAPH_CU-1];
	logic                    write_response_cu_out_internal_valid[0:NUM_GRAPH_CU-1];
	ReadWriteDataLine        read_data_0_in_latched                                ;
	ReadWriteDataLine        read_data_1_in_latched                                ;
	ReadWriteDataLine        read_data_0_cu_out_latched          [0:NUM_GRAPH_CU-1];
	ReadWriteDataLine        read_data_1_cu_out_latched          [0:NUM_GRAPH_CU-1];
	ReadWriteDataLine        read_data_0_cu_out_internal         [0:NUM_GRAPH_CU-1];
	ReadWriteDataLine        read_data_1_cu_out_internal         [0:NUM_GRAPH_CU-1];
	logic                    read_data_0_cu_out_internal_valid   [0:NUM_GRAPH_CU-1];
	logic                    read_data_1_cu_out_internal_valid   [0:NUM_GRAPH_CU-1];




	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_latched                        ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_latched                          ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_cu_in_latched[0:NUM_GRAPH_CU-1];
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_cu_in_latched  [0:NUM_GRAPH_CU-1];


	BufferStatus             read_buffer_status_latched                              ;
	BufferStatus             read_buffer_status_cu_out_latched     [0:NUM_GRAPH_CU-1];
	BufferStatus             read_buffer_status_cu_out_internal                      ;
	logic                    read_command_bus_grant_latched                          ;
	logic [NUM_GRAPH_CU-1:0] read_command_bus_grant_cu_out_latched                   ;
	logic                    read_command_bus_request_latched                        ;
	logic [NUM_GRAPH_CU-1:0] read_command_bus_request_cu_in_latched                  ;
	CommandBufferLine        read_command_out_latched                                ;
	CommandBufferLine        read_command_out_internal                               ;
	CommandBufferLine        read_command_out_cu_in_latched        [0:NUM_GRAPH_CU-1];
	logic [NUM_GRAPH_CU-1:0] read_command_out_cu_in_latched_submit                   ;


	BufferStatus             write_buffer_status_latched                              ;
	BufferStatus             write_buffer_status_cu_out_latched     [0:NUM_GRAPH_CU-1];
	logic                    write_command_bus_grant_latched                          ;
	logic [NUM_GRAPH_CU-1:0] write_command_bus_grant_cu_out_latched                   ;
	logic                    write_command_bus_request_latched                        ;
	logic [NUM_GRAPH_CU-1:0] write_command_bus_request_cu_in_latched                  ;


	BufferStatus             burst_edge_data_write_cu_buffer_states_cu                  ;
	EdgeDataWrite            burst_edge_data_buffer_out                                 ;
	EdgeDataWrite            edge_data_write_arbiter_out                                ;
	EdgeDataWrite            edge_data_write_arbiter_out_latched                        ;
	EdgeDataWrite            edge_data_write_cu_in_latched            [0:NUM_GRAPH_CU-1];
	logic [NUM_GRAPH_CU-1:0] edge_data_write_arbiter_cu_submit                          ;


	BufferStatus             vertex_buffer_status_internal                     ;
	VertexInterface          vertex_job_buffer_out                             ;
	VertexInterface          vertex_job_arbiter_in                             ;
	logic [NUM_GRAPH_CU-1:0] ready_vertex_job_cu                               ;
	logic                    vertex_request_internal                           ;
	logic [NUM_GRAPH_CU-1:0] request_vertex_job_cu_internal                    ;
	VertexInterface          vertex_job_latched                                ;
	VertexInterface          vertex_job_cu_out_latched       [0:NUM_GRAPH_CU-1];
	logic                    vertex_job_request_latched                        ;
	logic [NUM_GRAPH_CU-1:0] vertex_job_request_cu_in_latched                  ;


	logic read_command_bus_request_pop ;
	logic write_command_bus_request_pop;


	genvar i;
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
					write_command_bus_grant_cu_out[i] <= 0;
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
					read_command_bus_grant_cu_out[i] <= read_command_bus_grant_cu_out_latched[i] && ~read_buffer_status_cu_out_latched[i].alfull;
					write_command_bus_grant_cu_out[i] <= write_command_bus_grant_cu_out_latched[i] && ~write_buffer_status_cu_out_latched[i].alfull;
					read_buffer_status_cu_out[i] <= read_buffer_status_cu_out_latched[i];
					write_buffer_status_cu_out[i] <= write_buffer_status_cu_out_latched[i];

				end
			end
		end
	endgenerate

	generate
		for ( i = 0; i < (NUM_GRAPH_CU); i++) begin : generate_cu_graph_algorithm_output_logic
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					cu_wed_request_out[i].payload <=0;
					read_response_cu_out[i].payload <= 0;
					write_response_cu_out[i].payload <=0;
					read_data_0_cu_out[i].payload <= 0;
					read_data_1_cu_out[i].payload <= 0;
					vertex_job_cu_out[i].payload <= 0;
				end else begin
					cu_wed_request_out[i].payload <= cu_wed_request_out_latched[i].payload;
					read_response_cu_out[i].payload <= read_response_cu_out_latched[i].payload;
					write_response_cu_out[i].payload <= write_response_cu_out_latched[i].payload;
					read_data_0_cu_out[i].payload <= read_data_0_cu_out_latched[i].payload;
					read_data_1_cu_out[i].payload <= read_data_1_cu_out_latched[i].payload;
					vertex_job_cu_out[i].payload <= vertex_job_cu_out_latched[i].payload;
				end
			end
		end
	endgenerate

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_request        <= 0;
			enable_cu_out             <= 0;
			vertex_job_counter_done   <= 0;
			edge_job_counter_done     <= 0;
			read_command_out.valid    <= 0;
			edge_data_write_out.valid <= 0;
		end else begin
			vertex_job_request        <= vertex_job_request_latched;
			enable_cu_out             <= enable_cu_out_latched;
			vertex_job_counter_done   <= vertex_job_counter_done_latched;
			edge_job_counter_done     <= edge_job_counter_done_latched;
			read_command_out.valid    <= read_command_out_latched.valid;
			edge_data_write_out.valid <= burst_edge_data_buffer_out.valid;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_out.payload    <= 0;
			edge_data_write_out.payload <= 0;
		end else begin
			read_command_out.payload    <= read_command_out_latched.payload;
			edge_data_write_out.payload <= burst_edge_data_buffer_out.payload;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//Drive input
	////////////////////////////////////////////////////////////////////////////

	generate
		for ( i = 0; i < (NUM_GRAPH_CU); i++) begin : generate_cu_graph_algorithm_input_reset_logic
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					read_command_bus_request_cu_in_latched[i]  <= 0;
					write_command_bus_request_cu_in_latched[i] <= 0;
					vertex_job_request_cu_in_latched[i]        <= 0;
					vertex_job_counter_done_cu_in_latched[i]   <= 0;
					edge_job_counter_done_cu_in_latched[i]     <= 0;
					read_command_out_cu_in_latched[i].valid <= 0;
					edge_data_write_cu_in_latched[i].valid	<=  0;

				end else begin
					read_command_bus_request_cu_in_latched[i]  <= read_command_bus_request_cu_in[i];
					write_command_bus_request_cu_in_latched[i] <= write_command_bus_request_cu_in[i];
					vertex_job_request_cu_in_latched[i]        <= vertex_job_request_cu_in[i];
					vertex_job_counter_done_cu_in_latched[i]   <= vertex_job_counter_done_cu_in[i];
					edge_job_counter_done_cu_in_latched[i]     <= edge_job_counter_done_cu_in[i];
					read_command_out_cu_in_latched[i].valid <= 	read_command_out_cu_in[i].valid;
					edge_data_write_cu_in_latched[i].valid	<=  edge_data_write_cu_in[i].valid;
				end
			end
		end
	endgenerate

	generate
		for ( i = 0; i < (NUM_GRAPH_CU); i++) begin : generate_cu_graph_algorithm_input_logic
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					read_command_out_cu_in_latched[i].payload <= 	0;
					edge_data_write_cu_in_latched[i].payload	<=  0;
				end else begin
					read_command_out_cu_in_latched[i].payload <= 	read_command_out_cu_in[i].payload;
					edge_data_write_cu_in_latched[i].payload	<=  edge_data_write_cu_in[i].payload;
				end
			end
		end
	endgenerate

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_buffer_status_latched        <= 0;
			read_buffer_status_latched.empty  <= 1;
			write_buffer_status_latched       <= 0;
			write_buffer_status_latched.empty <= 1;
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

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_latched.payload        <= 0;
			wed_request_in_latched.payload    <= 0;
			read_response_in_latched.payload  <= 0;
			write_response_in_latched.payload <= 0;
			read_data_0_in_latched.payload    <= 0;
			read_data_1_in_latched.payload    <= 0;
		end else begin
			vertex_job_latched.payload        <= vertex_job.payload;
			wed_request_in_latched.payload    <= wed_request_in.payload;
			read_response_in_latched.payload  <= read_response_in.payload;
			write_response_in_latched.payload <= write_response_in.payload;
			read_data_0_in_latched.payload    <= read_data_0_in.payload;
			read_data_1_in_latched.payload    <= read_data_1_in.payload;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Reset/Enable logic
	////////////////////////////////////////////////////////////////////////////


	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_enable_cu
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					enable_cu_out_latched[i] <= 0;
				end else begin
					enable_cu_out_latched[i] <= ((i*NUM_VERTEX_CU) < cu_configure_latched[32:63]);
				end
			end
		end
	endgenerate


	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_cu_configure
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					cu_configure_out_latched[i] <= 0;
				end else begin
					cu_configure_out_latched[i] <= cu_configure_latched;
				end
			end
		end
	endgenerate

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_cu_wed_request_out
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					cu_wed_request_out_latched[i] <= 0;
				end else begin
					cu_wed_request_out_latched[i] <= wed_request_in_latched;
				end
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
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					read_response_cu_out_latched[i].valid    <= 0;
					read_response_cu_out_latched[i].payload <= 0;
				end else begin
					read_response_cu_out_latched[i].valid    <= read_response_cu_out_internal_valid[i];
					read_response_cu_out_latched[i].payload <= read_response_cu_out_internal[i].payload;
				end
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
		.data_out      (write_response_cu_out_internal),
		.data_out_valid(write_response_cu_out_internal_valid)
	);

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_write_response_demux
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					write_response_cu_out_latched[i].valid   <= 0;
					write_response_cu_out_latched[i].payload <= 0;
				end else begin
					write_response_cu_out_latched[i].valid   <= write_response_cu_out_internal_valid[i];
					write_response_cu_out_latched[i].payload <= write_response_cu_out_internal[i].payload;
				end
			end
		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	//read data demux - input
	////////////////////////////////////////////////////////////////////////////

	demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH(NUM_GRAPH_CU)
	) read_data_0_demux_bus_instant (
		.clock         (clock),
		.rstn          (rstn),
		.sel_in        (read_data_0_in_latched.payload.cmd.cu_id_y[CU_ID_RANGE-$clog2(NUM_GRAPH_CU):CU_ID_RANGE-1]),
		.data_in       (read_data_0_in_latched),
		.data_in_valid (read_data_0_in_latched.valid),
		.data_out      (read_data_0_cu_out_internal),
		.data_out_valid(read_data_0_cu_out_internal_valid)
	);

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_read_data_0_demux
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					read_data_0_cu_out_latched[i].valid    <= 0;
					read_data_0_cu_out_latched[i].payload <= 0;
				end else begin
					read_data_0_cu_out_latched[i].valid    <= read_data_0_cu_out_internal_valid[i];
					read_data_0_cu_out_latched[i].payload <= read_data_0_cu_out_internal[i].payload;
				end
			end
		end
	endgenerate

	demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH(NUM_GRAPH_CU)
	) read_data_1_demux_bus_instant (
		.clock         (clock),
		.rstn          (rstn),
		.sel_in        (read_data_1_in_latched.payload.cmd.cu_id_y[CU_ID_RANGE-$clog2(NUM_GRAPH_CU):CU_ID_RANGE-1]),
		.data_in       (read_data_1_in_latched),
		.data_in_valid (read_data_1_in_latched.valid),
		.data_out      (read_data_1_cu_out_internal),
		.data_out_valid(read_data_1_cu_out_internal_valid)
	);

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_read_data_1_demux
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					read_data_1_cu_out_latched[i].valid    <= 0;
					read_data_1_cu_out_latched[i].payload <= 0;
				end else begin
					read_data_1_cu_out_latched[i].valid    <= read_data_1_cu_out_internal_valid[i];
					read_data_1_cu_out_latched[i].payload <= read_data_1_cu_out_internal[i].payload;
				end
			end
		end
	endgenerate


	////////////////////////////////////////////////////////////////////////////
	//read/write arbitration - input
	////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////
	// Read Command Arbitration
	////////////////////////////////////////////////////////////////////////////

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_GRAPH_CU            ),
		.WIDTH       ($bits(CommandBufferLine))
	) round_robin_priority_arbiter_N_input_1_ouput_read_command_cu (
		.clock      (clock                                 ),
		.rstn       (rstn                                  ),
		.enabled    (enabled                               ),
		.buffer_in  (read_command_out_cu_in_latched        ),
		.submit     (read_command_out_cu_in_latched_submit ),
		.requests   (read_command_bus_request_cu_in_latched),
		.arbiter_out(read_command_out_internal             ),
		.ready      (read_command_bus_grant_cu_out_latched )
	);

	////////////////////////////////////////////////////////////////////////////
	// read command CU Buffers
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_read_command_arbiter_cu_submit
			assign read_command_out_cu_in_latched_submit[i] = read_command_out_cu_in_latched[i].valid;
		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	// Burst Buffer Read Commands
	////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_bus_grant_latched <= 0;
			read_command_bus_request       <= 0;
		end else begin
			if(enabled) begin
				read_command_bus_grant_latched <= read_command_bus_grant;
				read_command_bus_request       <= read_command_bus_request_latched;
			end
		end
	end

	assign read_command_bus_request_latched = ~read_buffer_status_cu_out_internal.empty && ~read_buffer_status_latched.alfull;
	assign read_command_bus_request_pop     = read_command_bus_grant_latched && ~read_buffer_status_latched.alfull;



	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) burst_read_command_buffer_fifo_instant (
		.clock   (clock                                    ),
		.rstn    (rstn                                     ),
		
		.push    (read_command_out_internal.valid          ),
		.data_in (read_command_out_internal                ),
		.full    (read_buffer_status_cu_out_internal.full  ),
		.alFull  (read_buffer_status_cu_out_internal.alfull),
		
		.pop     (read_command_bus_request_pop             ),
		.valid   (read_buffer_status_cu_out_internal.valid ),
		.data_out(read_command_out_latched                 ),
		.empty   (read_buffer_status_cu_out_internal.empty )
	);

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_burst_read_command_buffer_states_cu
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					read_buffer_status_cu_out_latched[i] <= 0;
					read_buffer_status_cu_out_latched[i].empty <= 1;
				end else begin
					read_buffer_status_cu_out_latched[i] <= read_buffer_status_cu_out_internal;
				end
			end
		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Write Command/Data Arbitration
	////////////////////////////////////////////////////////////////////////////

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_GRAPH_CU       ),
		.WIDTH       ($bits(EdgeDataWrite))
	) round_robin_priority_arbiter_N_input_1_ouput_edge_data_write_cu (
		.clock      (clock                            ),
		.rstn       (rstn                             ),
		.enabled    (enabled                          ),
		.buffer_in  (edge_data_write_cu_in_latched    ),
		.submit     (edge_data_write_arbiter_cu_submit),
		.requests   (write_command_bus_request_cu_in_latched       ),
		.arbiter_out(edge_data_write_arbiter_out      ),
		.ready      (write_command_bus_grant_cu_out_latched         )
	);

	////////////////////////////////////////////////////////////////////////////
	// write command CU Buffers
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_edge_data_write_arbiter_cu
			assign edge_data_write_arbiter_cu_submit[i] = edge_data_write_cu_in_latched[i].valid;
		end
	endgenerate


	////////////////////////////////////////////////////////////////////////////
	// Burst Buffer Write Commands
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_bus_grant_latched <= 0;
			write_command_bus_request       <= 0;
		end else begin
			if(enabled) begin
				write_command_bus_grant_latched <= write_command_bus_grant;
				write_command_bus_request       <= write_command_bus_request_latched;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_write_arbiter_out_latched.valid <= 0;
		end else begin
			if(enabled) begin
				edge_data_write_arbiter_out_latched.valid <= edge_data_write_arbiter_out.valid;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_write_arbiter_out_latched.payload <= 0;
		end else begin
			edge_data_write_arbiter_out_latched.payload <= edge_data_write_arbiter_out.payload;
		end
	end

	assign write_command_bus_request_latched = ~burst_edge_data_write_cu_buffer_states_cu.empty && ~write_buffer_status_latched.alfull;
	assign write_command_bus_request_pop     = write_command_bus_grant_latched && ~write_buffer_status_latched.alfull;

	fifo #(
		.WIDTH($bits(EdgeDataWrite) ),
		.DEPTH(WRITE_CMD_BUFFER_SIZE)
	) burst_edge_data_write_buffer_fifo_instant (
		.clock   (clock                                           ),
		.rstn    (rstn                                            ),
		
		.push    (edge_data_write_arbiter_out_latched.valid       ),
		.data_in (edge_data_write_arbiter_out_latched             ),
		.full    (burst_edge_data_write_cu_buffer_states_cu.full  ),
		.alFull  (burst_edge_data_write_cu_buffer_states_cu.alfull),
		
		.pop     (write_command_bus_grant_latched                 ),
		.valid   (burst_edge_data_write_cu_buffer_states_cu.valid ),
		.data_out(burst_edge_data_buffer_out                      ),
		.empty   (burst_edge_data_write_cu_buffer_states_cu.empty )
	);

	generate
		for (i = 0; i < NUM_GRAPH_CU; i++) begin : generate_burst_edge_data_write_cu_buffer_states_cu
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					write_buffer_status_cu_out_latched[i] <= 0;
					write_buffer_status_cu_out_latched[i].empty   <= 1;
				end else begin
					write_buffer_status_cu_out_latched[i] <= burst_edge_data_write_cu_buffer_states_cu;
				end
			end
		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	// Vertex Job Buffer
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_request_latched     <= 0;
			vertex_request_internal        <= 0;
			vertex_job_arbiter_in.valid    <= 0;
			request_vertex_job_cu_internal <= 0;
		end else begin
			if(enabled) begin
				vertex_job_request_latched     <= (~vertex_buffer_status_internal.alfull);
				vertex_request_internal        <= (|vertex_job_request_cu_in_latched);
				vertex_job_arbiter_in.valid    <= vertex_job_buffer_out.valid;
				request_vertex_job_cu_internal <= vertex_job_request_cu_in_latched;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			vertex_job_arbiter_in.payload <= 0;
		else
			vertex_job_arbiter_in.payload <= vertex_job_buffer_out.payload;
	end

	fifo #(
		.WIDTH($bits(VertexInterface)   ),
		.DEPTH(CU_VERTEX_JOB_BUFFER_SIZE)
	) vertex_job_buffer_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (vertex_job_latched.valid            ),
		.data_in (vertex_job_latched                  ),
		.full    (vertex_buffer_status_internal.full  ),
		.alFull  (vertex_buffer_status_internal.alfull),
		
		.pop     (vertex_request_internal             ),
		.valid   (vertex_buffer_status_internal.valid ),
		.data_out(vertex_job_buffer_out               ),
		.empty   (vertex_buffer_status_internal.empty )
	);


	////////////////////////////////////////////////////////////////////////////
	// Vertex job request Arbitration
	////////////////////////////////////////////////////////////////////////////


	round_robin_priority_arbiter_1_input_N_ouput #(
		.NUM_REQUESTS(NUM_GRAPH_CU          ),
		.WIDTH       ($bits(VertexInterface))
	) round_robin_priority_arbiter_1_input_N_ouput_vertex_job (
		.clock      (clock                         ),
		.rstn       (rstn                          ),
		.enabled    (enabled                       ),
		.buffer_in  (vertex_job_arbiter_in         ),
		.requests   (request_vertex_job_cu_internal),
		.arbiter_out(vertex_job_cu_out_latched     ),
		.ready      (ready_vertex_job_cu           )
	);

	////////////////////////////////////////////////////////////////////////////
	// Once processed all verticess edges send done signal
	////////////////////////////////////////////////////////////////////////////

	sum_reduce #(
		.DATA_WIDTH_IN (VERTEX_SIZE_BITS),
		.DATA_WIDTH_OUT(VERTEX_SIZE_BITS),
		.BUS_WIDTH     (NUM_GRAPH_CU    )
	) vertex_job_counter_sum_reduce_instant (
		.clock          (clock                                ),
		.rstn           (rstn                                 ),
		.enabled_in     (enabled                              ),
		.partial_sums_in(vertex_job_counter_done_cu_in_latched),
		.total_sum_out  (vertex_job_counter_done_latched      )
	);

	////////////////////////////////////////////////////////////////////////////
	// Once processed all edges send done signal
	////////////////////////////////////////////////////////////////////////////

	sum_reduce #(
		.DATA_WIDTH_IN (EDGE_SIZE_BITS),
		.DATA_WIDTH_OUT(EDGE_SIZE_BITS),
		.BUS_WIDTH     (NUM_GRAPH_CU  )
	) edge_job_counter_sum_reduce_instant (
		.clock          (clock                              ),
		.rstn           (rstn                               ),
		.enabled_in     (enabled                            ),
		.partial_sums_in(edge_job_counter_done_cu_in_latched),
		.total_sum_out  (edge_job_counter_done_latched      )
	);




endmodule

