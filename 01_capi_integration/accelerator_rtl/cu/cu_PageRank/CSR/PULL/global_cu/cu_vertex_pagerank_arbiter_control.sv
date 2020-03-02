// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_vertex_pagerank_arbiter_control.sv
// Create : 2020-02-21 19:15:46
// Revise : 2020-03-02 06:37:33
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_pagerank_arbiter_control #(parameter NUM_VERTEX_CU = NUM_VERTEX_CU_GLOBAL) (
	input  logic                          clock                                                            , // Clock
	input  logic                          rstn                                                             ,
	output logic                          cu_rstn_out [0:NUM_VERTEX_CU-1]                                  ,
	input  logic                          enabled_in                                                       ,
	input  WEDInterface                   wed_request_in                                                   ,
	output WEDInterface                   cu_wed_request_out  [0:NUM_VERTEX_CU-1]                          ,
	output logic [     NUM_VERTEX_CU-1:0] enable_cu_out                                                    ,
	input  logic [                  0:63] cu_configure                                                     ,
	output logic [                  0:63] cu_configure_out [0:NUM_VERTEX_CU-1]                             ,
	input  ResponseBufferLine             read_response_in                                                 ,
	input  ReadWriteDataLine              read_data_0_in                                                   ,
	input  ReadWriteDataLine              read_data_1_in                                                   ,
	input  BufferStatus                   read_buffer_status                                               ,
	input  BufferStatus                   write_buffer_status                                              ,
	input  logic                          read_command_bus_grant                                           ,
	output logic                          read_command_bus_request                                         ,
	output ResponseBufferLine             read_response_cu_out [0:NUM_VERTEX_CU-1]                         ,
	input  ResponseBufferLine             write_response_in                                                ,
	output ResponseBufferLine             write_response_cu_out [0:NUM_VERTEX_CU-1]                        ,
	input  CommandBufferLine              read_command_cu_in [0:NUM_VERTEX_CU-1]                           ,
	input  logic [     NUM_VERTEX_CU-1:0] request_read_command_cu_in                                       ,
	output logic [     NUM_VERTEX_CU-1:0] ready_read_command_cu_out                                        ,
	output CommandBufferLine              read_command_out                                                 ,
	input  EdgeDataWrite                  edge_data_write_cu_in [0:NUM_VERTEX_CU-1]                        ,
	input  logic [     NUM_VERTEX_CU-1:0] request_edge_data_write_cu_in                                    ,
	output logic [     NUM_VERTEX_CU-1:0] ready_edge_data_write_cu_out                                     ,
	output EdgeDataWrite                  burst_edge_data_out                                              ,
	output ReadWriteDataLine              read_data_0_cu_out [0:NUM_VERTEX_CU-1]                           ,
	output ReadWriteDataLine              read_data_1_cu_out [0:NUM_VERTEX_CU-1]                           ,
	output EdgeDataRead                   edge_data_read_cu_out         [0:NUM_VERTEX_CU-1]                ,
	output BufferStatus                   burst_read_command_buffer_states_cu_out      [0:NUM_VERTEX_CU-1] ,
	output BufferStatus                   burst_edge_data_write_cu_buffer_states_cu_out [0:NUM_VERTEX_CU-1],
	output VertexInterface                vertex_job_cu_out [0:NUM_VERTEX_CU-1]                            ,
	input  logic [     NUM_VERTEX_CU-1:0] request_vertex_job_cu_in                                         ,
	input  VertexInterface                vertex_job                                                       ,
	input  logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_cu_in[0:NUM_VERTEX_CU-1]                      ,
	input  logic [  0:(EDGE_SIZE_BITS-1)] edge_num_counter_cu_in  [0:NUM_VERTEX_CU-1]                      ,
	output logic                          vertex_job_request                                               ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_out                                      ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_out
);

	logic read_command_bus_grant_latched  ;
	logic read_command_bus_request_latched;

	WEDInterface wed_request_in_latched                       ;
	WEDInterface wed_request_in_internal                      ;
	WEDInterface cu_wed_request_out_latched[0:NUM_VERTEX_CU-1];

	BufferStatus read_buffer_status_latched ;
	BufferStatus write_buffer_status_latched;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done                    ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done                      ;
	logic [                  0:63] cu_configure_out_latched[0:NUM_VERTEX_CU-1];
	logic                          cu_rstn_out_latched     [0:NUM_VERTEX_CU-1];
// vertex control variables

	BufferStatus    vertex_buffer_status_internal;
	logic           vertex_request_internal      ;
	logic           vertex_job_request_latched   ;
	VertexInterface vertex_job_latched           ;
	VertexInterface vertex_job_buffer_out        ;
	VertexInterface vertex_job_arbiter_in        ;

	//output latched
	CommandBufferLine read_command_out_latched;

	//input lateched
	ResponseBufferLine read_response_in_latched ;
	ResponseBufferLine write_response_in_latched;
	ReadWriteDataLine  read_data_0_in_latched   ;
	ReadWriteDataLine  read_data_1_in_latched   ;

	ResponseBufferLine read_response_in_internal ;
	ResponseBufferLine write_response_in_internal;
	ReadWriteDataLine  read_data_0_in_internal   ;
	ReadWriteDataLine  read_data_1_in_internal   ;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_cu[0:NUM_VERTEX_CU-1];
	logic [  0:(EDGE_SIZE_BITS-1)] edge_num_counter_cu  [0:NUM_VERTEX_CU-1];

	CommandBufferLine         read_command_cu               [0:NUM_VERTEX_CU-1];
	logic [NUM_VERTEX_CU-1:0] ready_read_command_cu                            ;
	logic [NUM_VERTEX_CU-1:0] request_read_command_cu                          ;
	logic [NUM_VERTEX_CU-1:0] read_command_arbiter_cu_submit                   ;

	EdgeDataWrite edge_data_write_cu[0:NUM_VERTEX_CU-1];

	logic [NUM_VERTEX_CU-1:0] ready_edge_data_write_cu         ;
	logic [NUM_VERTEX_CU-1:0] request_edge_data_write_cu       ;
	logic [NUM_VERTEX_CU-1:0] enable_cu                        ;
	logic [NUM_VERTEX_CU-1:0] enable_cu_latched                ;
	logic [NUM_VERTEX_CU-1:0] edge_data_write_arbiter_cu_submit;


	ResponseBufferLine read_response_cu [0:NUM_VERTEX_CU-1];
	ResponseBufferLine write_response_cu[0:NUM_VERTEX_CU-1];

	ResponseBufferLine read_response_cu_latched       [0:NUM_VERTEX_CU-1];
	logic              read_response_cu_latched_valid [0:NUM_VERTEX_CU-1];
	ResponseBufferLine write_response_cu_latched      [0:NUM_VERTEX_CU-1];
	logic              write_response_cu_latched_valid[0:NUM_VERTEX_CU-1];

	ReadWriteDataLine read_data_0_cu[0:NUM_VERTEX_CU-1];
	ReadWriteDataLine read_data_1_cu[0:NUM_VERTEX_CU-1];

	ReadWriteDataLine read_data_0_cu_latched[0:NUM_VERTEX_CU-1];
	ReadWriteDataLine read_data_1_cu_latched[0:NUM_VERTEX_CU-1];

	logic read_data_0_cu_latched_valid[0:NUM_VERTEX_CU-1];
	logic read_data_1_cu_latched_valid[0:NUM_VERTEX_CU-1];

	VertexInterface           vertex_job_cu                 [0:NUM_VERTEX_CU-1];
	logic [NUM_VERTEX_CU-1:0] request_vertex_job_cu                            ;
	logic [NUM_VERTEX_CU-1:0] request_vertex_job_cu_internal                   ;
	logic [NUM_VERTEX_CU-1:0] ready_vertex_job_cu                              ;
	logic                     enabled                                          ;
	logic [             0:63] cu_configure_latched                             ;

	BufferStatus      burst_read_command_buffer_states_cu                               ;
	BufferStatus      burst_read_command_buffer_states_cu_out_latched[0:NUM_VERTEX_CU-1];
	CommandBufferLine burst_read_command_buffer_out                                     ;

	BufferStatus burst_edge_data_write_cu_buffer_states_cu                               ;
	BufferStatus burst_edge_data_write_cu_buffer_states_cu_out_latched[0:NUM_VERTEX_CU-1];

	logic         burst_edge_data_write_buffer_pop;
	EdgeDataWrite burst_edge_data_buffer_out      ;
	EdgeDataWrite edge_data_write_arbiter_out     ;

	ReadWriteDataLine read_data_0_in_edge_job ;
	ReadWriteDataLine read_data_1_in_edge_job ;
	ReadWriteDataLine read_data_0_in_edge_data;
	ReadWriteDataLine read_data_1_in_edge_data;

	EdgeDataRead edge_data_read_cu              [0:NUM_VERTEX_CU-1];
	EdgeDataRead edge_data_read_cu_latched      [0:NUM_VERTEX_CU-1];
	logic        edge_data_read_cu_latched_valid[0:NUM_VERTEX_CU-1];
	EdgeDataRead edge_data_variable                                ;

	ReadWriteDataLine read_data_0_data_out[0:1];
	ReadWriteDataLine read_data_1_data_out[0:1];

	ReadWriteDataLine read_data_0_data_out_latched[0:1];
	ReadWriteDataLine read_data_1_data_out_latched[0:1];

	logic read_data_0_data_out_latched_valid[0:1];
	logic read_data_1_data_out_latched_valid[0:1];

	////////////////////////////////////////////////////////////////////////////
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
		for ( i = 0; i < (NUM_VERTEX_CU); i++) begin : generate_cu_vertex_pagerank_output_reset_logic
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					read_response_cu_out[i].valid <= 0;
					write_response_cu_out[i].valid <= 0;
					read_data_0_cu_out[i].valid <= 0;
					read_data_1_cu_out[i].valid <= 0;
					edge_data_read_cu_out[i].valid <= 0;
					vertex_job_cu_out[i].valid <= 0;
				end else begin
					read_response_cu_out[i].valid <= read_response_cu[i].valid ;
					write_response_cu_out[i].valid <= write_response_cu[i].valid ;
					read_data_0_cu_out[i].valid <= read_data_0_cu[i].valid ;
					read_data_1_cu_out[i].valid <= read_data_1_cu[i].valid ;
					edge_data_read_cu_out[i].valid <= edge_data_read_cu[i].valid ;
					vertex_job_cu_out[i].valid <= vertex_job_cu[i].valid ;
				end
			end
		end
	endgenerate

	generate
		for ( i = 0; i < (NUM_VERTEX_CU); i++) begin : generate_cu_vertex_pagerank_output_logic
			always_ff @(posedge clock) begin
				read_response_cu_out[i].payload <= read_response_cu[i].payload ;
				write_response_cu_out[i].payload <= write_response_cu[i].payload ;
				read_data_0_cu_out[i].payload <= read_data_0_cu[i].payload ;
				read_data_1_cu_out[i].payload <= read_data_1_cu[i].payload ;
				edge_data_read_cu_out[i].payload <= edge_data_read_cu[i].payload ;
				vertex_job_cu_out[i].payload <= vertex_job_cu[i].payload ;
			end
		end
	endgenerate

	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_out.valid       <= 0;
			burst_edge_data_out.valid    <= 0;
			enable_cu_out                <= 0;
			ready_read_command_cu_out    <= 0;
			ready_edge_data_write_cu_out <= 0;
			vertex_job_counter_done_out  <= 0;
			edge_job_counter_done_out    <= 0;
			vertex_job_request           <= 0;
		end else begin
			read_command_out.valid       <= burst_read_command_buffer_out.valid;
			burst_edge_data_out.valid    <= burst_edge_data_buffer_out.valid;
			enable_cu_out                <= enable_cu;
			ready_read_command_cu_out    <= ready_read_command_cu;
			vertex_job_counter_done_out  <= vertex_job_counter_done;
			edge_job_counter_done_out    <= edge_job_counter_done;
			ready_edge_data_write_cu_out <= ready_edge_data_write_cu;
			vertex_job_request           <= vertex_job_request_latched;
		end
	end

	// drive outputs
	always_ff @(posedge clock) begin
		read_command_out.payload    <= burst_read_command_buffer_out.payload;
		burst_edge_data_out.payload <= burst_edge_data_buffer_out.payload;
	end

	////////////////////////////////////////////////////////////////////////////
	//Drive input
	////////////////////////////////////////////////////////////////////////////

	generate
		for ( i = 0; i < (NUM_VERTEX_CU); i++) begin : generate_cu_vertex_pagerank_input_reset_logic
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					read_command_cu[i].valid <= 0;
					edge_data_write_cu[i].valid <= 0;
				end else begin
					read_command_cu[i].valid <= read_command_cu_in[i].valid ;
					edge_data_write_cu[i].valid <= edge_data_write_cu_in[i].valid ;
				end
			end
		end
	endgenerate

	generate
		for ( i = 0; i < (NUM_VERTEX_CU); i++) begin : generate_cu_vertex_pagerank_input_logic
			always_ff @(posedge clock) begin
				read_command_cu[i].payload <= read_command_cu_in[i].payload ;
				edge_data_write_cu[i].payload <= edge_data_write_cu_in[i].payload ;
			end
		end
	endgenerate

	always_ff @(posedge clock) begin
		vertex_num_counter_cu <= vertex_num_counter_cu_in;
		edge_num_counter_cu   <= edge_num_counter_cu_in;
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			request_read_command_cu    <= 0;
			request_edge_data_write_cu <= 0;
			request_vertex_job_cu      <= 0;
			vertex_job_latched         <= 0;

		end else begin
			request_read_command_cu    <= request_read_command_cu_in;
			request_edge_data_write_cu <= request_edge_data_write_cu_in;
			request_vertex_job_cu      <= request_vertex_job_cu_in;
			vertex_job_latched         <= vertex_job;

		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_in_internal.valid   <= 0;
			write_response_in_internal.valid  <= 0;
			read_data_0_in_internal.valid     <= 0;
			read_data_1_in_internal.valid     <= 0;
			wed_request_in_internal.valid     <= 0;
			cu_configure_latched              <= 0;
			read_buffer_status_latched        <= 0;
			read_buffer_status_latched.empty  <= 1;
			write_buffer_status_latched       <= 0;
			write_buffer_status_latched.empty <= 1;
		end else begin
			if(enabled)begin
				read_response_in_internal.valid  <= read_response_in.valid;
				write_response_in_internal.valid <= write_response_in.valid;
				read_data_0_in_internal.valid    <= read_data_0_in.valid;
				read_data_1_in_internal.valid    <= read_data_1_in.valid;
				wed_request_in_internal.valid    <= wed_request_in.valid;
				read_buffer_status_latched       <= read_buffer_status;
				write_buffer_status_latched      <= write_buffer_status;
				if((|cu_configure))
					cu_configure_latched <= cu_configure;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_response_in_internal.payload  <= read_response_in.payload;
		write_response_in_internal.payload <= write_response_in.payload;
		read_data_0_in_internal.payload    <= read_data_0_in.payload;
		read_data_1_in_internal.payload    <= read_data_1_in.payload;
		wed_request_in_internal.payload    <= wed_request_in.payload;
	end

	always_ff @(posedge clock) begin
		read_response_in_latched  <= read_response_in_internal;
		write_response_in_latched <= write_response_in_internal;
		read_data_0_in_latched    <= read_data_0_in_internal;
		read_data_1_in_latched    <= read_data_1_in_internal;
		wed_request_in_latched    <= wed_request_in_internal;
	end

	////////////////////////////////////////////////////////////////////////////
	// Reset/Enable logic
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_enable_cu
			assign enable_cu_latched[i] = (i < cu_configure_latched[32:63]);
		end
	endgenerate

	always_ff @(posedge clock) begin
		enable_cu <= enable_cu_latched;
	end

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_cu_configure
			assign cu_configure_out_latched[i] = cu_configure_latched;
		end
	endgenerate

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cu_configure_out <= '{default:0};
		end else begin
			cu_configure_out <= cu_configure_out_latched;
		end
	end

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_rstn
			assign cu_rstn_out_latched[i] = rstn;
		end
	endgenerate

	always_ff @(posedge clock) begin
		cu_rstn_out <= cu_rstn_out_latched;
	end

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_cu_wed_request_out
			assign cu_wed_request_out_latched[i] = wed_request_in_latched;
		end
	endgenerate

	always_ff @(posedge clock) begin
		cu_wed_request_out <= cu_wed_request_out_latched;
	end
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
			vertex_job_request_latched     <= (~vertex_buffer_status_internal.alfull);
			vertex_request_internal        <= (|request_vertex_job_cu);
			vertex_job_arbiter_in.valid    <= vertex_job_buffer_out.valid;
			request_vertex_job_cu_internal <= request_vertex_job_cu;
		end
	end

	always_ff @(posedge clock) begin
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
		.NUM_REQUESTS(NUM_VERTEX_CU         ),
		.WIDTH       ($bits(VertexInterface))
	) round_robin_priority_arbiter_1_input_N_ouput_vertex_job (
		.clock      (clock                         ),
		.rstn       (rstn                          ),
		.enabled    (enabled                       ),
		.buffer_in  (vertex_job_arbiter_in         ),
		.requests   (request_vertex_job_cu_internal),
		.arbiter_out(vertex_job_cu                 ),
		.ready      (ready_vertex_job_cu           )
	);


	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Read Command Arbitration
	////////////////////////////////////////////////////////////////////////////


	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_VERTEX_CU           ),
		.WIDTH       ($bits(CommandBufferLine))
	) round_robin_priority_arbiter_N_input_1_ouput_read_command_cu (
		.clock      (clock                         ),
		.rstn       (rstn                          ),
		.enabled    (enabled                       ),
		.buffer_in  (read_command_cu               ),
		.submit     (read_command_arbiter_cu_submit),
		.requests   (request_read_command_cu       ),
		.arbiter_out(read_command_out_latched      ),
		.ready      (ready_read_command_cu         )
	);

	////////////////////////////////////////////////////////////////////////////
	// read command CU Buffers
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_read_command_arbiter_cu_submit
			assign read_command_arbiter_cu_submit[i] = read_command_cu[i].valid;
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

	assign read_command_bus_request_latched = ~burst_read_command_buffer_states_cu.empty && ~read_buffer_status_latched.alfull;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) burst_read_command_buffer_fifo_instant (
		.clock   (clock                                     ),
		.rstn    (rstn                                      ),
		
		.push    (read_command_out_latched.valid            ),
		.data_in (read_command_out_latched                  ),
		.full    (burst_read_command_buffer_states_cu.full  ),
		.alFull  (burst_read_command_buffer_states_cu.alfull),
		
		.pop     (read_command_bus_grant_latched            ),
		.valid   (burst_read_command_buffer_states_cu.valid ),
		.data_out(burst_read_command_buffer_out             ),
		.empty   (burst_read_command_buffer_states_cu.empty )
	);

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_burst_read_command_buffer_states_cu
			assign burst_read_command_buffer_states_cu_out_latched[i] = burst_read_command_buffer_states_cu;
		end
	endgenerate

	always_ff @(posedge clock) begin
		burst_read_command_buffer_states_cu_out <= burst_read_command_buffer_states_cu_out_latched;
	end



	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Write Command/Data Arbitration
	////////////////////////////////////////////////////////////////////////////

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_VERTEX_CU       ),
		.WIDTH       ($bits(EdgeDataWrite))
	) round_robin_priority_arbiter_N_input_1_ouput_edge_data_write_cu (
		.clock      (clock                            ),
		.rstn       (rstn                             ),
		.enabled    (enabled                          ),
		.buffer_in  (edge_data_write_cu               ),
		.submit     (edge_data_write_arbiter_cu_submit),
		.requests   (request_edge_data_write_cu       ),
		.arbiter_out(edge_data_write_arbiter_out      ),
		.ready      (ready_edge_data_write_cu         )
	);

	////////////////////////////////////////////////////////////////////////////
	// write command CU Buffers
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_edge_data_write_arbiter_cu
			assign edge_data_write_arbiter_cu_submit[i] = edge_data_write_cu[i].valid;
		end
	endgenerate


	////////////////////////////////////////////////////////////////////////////
	// Burst Buffer Write Commands
	////////////////////////////////////////////////////////////////////////////

	assign burst_edge_data_write_buffer_pop = ~burst_edge_data_write_cu_buffer_states_cu.empty && ~write_buffer_status_latched.alfull;

	fifo #(
		.WIDTH($bits(EdgeDataWrite) ),
		.DEPTH(WRITE_CMD_BUFFER_SIZE)
	) burst_edge_data_write_buffer_fifo_instant (
		.clock   (clock                                           ),
		.rstn    (rstn                                            ),
		
		.push    (edge_data_write_arbiter_out.valid               ),
		.data_in (edge_data_write_arbiter_out                     ),
		.full    (burst_edge_data_write_cu_buffer_states_cu.full  ),
		.alFull  (burst_edge_data_write_cu_buffer_states_cu.alfull),
		
		.pop     (burst_edge_data_write_buffer_pop                ),
		.valid   (burst_edge_data_write_cu_buffer_states_cu.valid ),
		.data_out(burst_edge_data_buffer_out                      ),
		.empty   (burst_edge_data_write_cu_buffer_states_cu.empty )
	);

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_burst_edge_data_write_cu_buffer_states_cu
			assign burst_edge_data_write_cu_buffer_states_cu_out_latched[i] = burst_edge_data_write_cu_buffer_states_cu;
		end
	endgenerate

	always_ff @(posedge clock) begin
		burst_edge_data_write_cu_buffer_states_cu_out <= burst_read_command_buffer_states_cu_out_latched;
	end

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Read Data Arbitration
	////////////////////////////////////////////////////////////////////////////

	demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH (NUM_VERTEX_CU           )
	) read_data_0_cu_demux_bus_instant (
		.clock         (clock                                                                                     ),
		.rstn          (rstn                                                                                      ),
		.sel_in        (read_data_0_in_edge_job.payload.cmd.cu_id[CU_ID_RANGE-$clog2(NUM_VERTEX_CU):CU_ID_RANGE-1]),
		.data_in       (read_data_0_in_edge_job                                                                   ),
		.data_in_valid (read_data_0_in_edge_job.valid                                                             ),
		.data_out      (read_data_0_cu_latched                                                                    ),
		.data_out_valid(read_data_0_cu_latched_valid                                                              )
	);

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_read_data_0_cu_demux
			always_ff @(posedge clock) begin
				read_data_0_cu[i].valid <= read_data_0_cu_latched_valid[i];
				read_data_0_cu[i].payload <= read_data_0_cu_latched[i].payload;
			end
		end
	endgenerate

	demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH(NUM_VERTEX_CU)
	) read_data_1_cu_demux_bus_instant (
		.clock         (clock),
		.rstn          (rstn),
		.sel_in        (read_data_1_in_edge_job.payload.cmd.cu_id[CU_ID_RANGE-$clog2(NUM_VERTEX_CU):CU_ID_RANGE-1]),
		.data_in       (read_data_1_in_edge_job),
		.data_in_valid (read_data_1_in_edge_job.valid),
		.data_out      (read_data_1_cu_latched),
		.data_out_valid(read_data_1_cu_latched_valid)
	);

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_read_data_1_cu_demux
			always_ff @(posedge clock) begin
				read_data_1_cu[i].valid <= read_data_1_cu_latched_valid[i];
				read_data_1_cu[i].payload <= read_data_1_cu_latched[i].payload;
			end
		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	//data request read logic extract single edgedata from cacheline
	////////////////////////////////////////////////////////////////////////////

	cu_edge_data_read_control cu_edge_data_read_control_instant (
		.clock         (clock                   ),
		.rstn          (rstn                    ),
		.enabled_in    (enabled                 ),
		.read_data_0_in(read_data_0_in_edge_data),
		.read_data_1_in(read_data_1_in_edge_data),
		.edge_data     (edge_data_variable      )
	);

	////////////////////////////////////////////////////////////////////////////
	//read data request logic - input
	////////////////////////////////////////////////////////////////////////////

	array_struct_type_demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH (2                       )
	) read_data_0_array_struct_type_demux_bus_instant (
		.clock         (clock                                          ),
		.rstn          (rstn                                           ),
		.sel_in        (read_data_0_in_latched.payload.cmd.array_struct),
		.data_in       (read_data_0_in_latched                         ),
		.data_in_valid (read_data_0_in_latched.valid                   ),
		.data_out      (read_data_0_data_out_latched                   ),
		.data_out_valid(read_data_0_data_out_latched_valid             )
	);

	always_ff @(posedge clock) begin
		read_data_0_data_out[0].valid <= read_data_0_data_out_latched_valid[0];
		read_data_0_data_out[1].valid <= read_data_0_data_out_latched_valid[1];
		read_data_0_data_out[0].payload <= read_data_0_data_out_latched[0].payload;
		read_data_0_data_out[1].payload <= read_data_0_data_out_latched[1].payload;
	end

	assign read_data_0_in_edge_job  = read_data_0_data_out[0];
	assign read_data_0_in_edge_data = read_data_0_data_out[1];

	array_struct_type_demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH (2                       )
	) read_data_1_array_struct_type_demux_bus_instant (
		.clock         (clock                                          ),
		.rstn          (rstn                                           ),
		.sel_in        (read_data_1_in_latched.payload.cmd.array_struct),
		.data_in       (read_data_1_in_latched                         ),
		.data_in_valid (read_data_1_in_latched.valid                   ),
		.data_out      (read_data_1_data_out_latched                   ),
		.data_out_valid(read_data_1_data_out_latched_valid             )
	);

	always_ff @(posedge clock) begin
		read_data_1_data_out[0].valid <= read_data_1_data_out_latched_valid[0];
		read_data_1_data_out[1].valid <= read_data_1_data_out_latched_valid[1];
		read_data_1_data_out[0].payload <= read_data_1_data_out_latched[0].payload;
		read_data_1_data_out[1].payload <= read_data_1_data_out_latched[1].payload;
	end

	assign read_data_1_in_edge_job  = read_data_1_data_out[0];
	assign read_data_1_in_edge_data = read_data_1_data_out[1];

	////////////////////////////////////////////////////////////////////////////
	//data request read logic
	////////////////////////////////////////////////////////////////////////////

	demux_bus #(
		.DATA_WIDTH($bits(EdgeDataRead)),
		.BUS_WIDTH (NUM_VERTEX_CU      )
	) edge_data_read_cu_demux_bus_instant (
		.clock         (clock                                                                            ),
		.rstn          (rstn                                                                             ),
		.sel_in        (edge_data_variable.payload.cu_id[CU_ID_RANGE-$clog2(NUM_VERTEX_CU):CU_ID_RANGE-1]),
		.data_in       (edge_data_variable                                                               ),
		.data_in_valid (edge_data_variable.valid                                                         ),
		.data_out      (edge_data_read_cu_latched                                                        ),
		.data_out_valid(edge_data_read_cu_latched_valid                                                  )
	);

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_edge_data_read_cu_demux
			always_ff @(posedge clock) begin
				edge_data_read_cu[i].valid <= edge_data_read_cu_latched_valid[i];
				edge_data_read_cu[i].payload <= edge_data_read_cu_latched[i].payload;
			end
		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Response Arbitration
	////////////////////////////////////////////////////////////////////////////

	demux_bus #(
		.DATA_WIDTH($bits(ResponseBufferLine)),
		.BUS_WIDTH(NUM_VERTEX_CU)
	) read_response_demux_bus_instant (
		.clock         (clock),
		.rstn          (rstn),
		.sel_in        (read_response_in_latched.payload.cmd.cu_id[CU_ID_RANGE-$clog2(NUM_VERTEX_CU):CU_ID_RANGE-1]),
		.data_in       (read_response_in_latched),
		.data_in_valid (read_response_in_latched.valid),
		.data_out      (read_response_cu_latched),
		.data_out_valid(read_response_cu_latched_valid)
	);

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_read_response_demux
			always_ff @(posedge clock) begin
				read_response_cu[i].valid <= read_response_cu_latched_valid[i];
				read_response_cu[i].payload <= read_response_cu_latched[i].payload;
			end
		end
	endgenerate


	demux_bus #(
		.DATA_WIDTH($bits(ResponseBufferLine)),
		.BUS_WIDTH(NUM_VERTEX_CU)
	) write_response_demux_bus_instant (
		.clock         (clock),
		.rstn          (rstn),
		.sel_in        (write_response_in_latched.payload.cmd.cu_id[CU_ID_RANGE-$clog2(NUM_VERTEX_CU):CU_ID_RANGE-1]),
		.data_in       (write_response_in_latched),
		.data_in_valid (write_response_in_latched.valid),
		.data_out      (write_response_cu_latched),
		.data_out_valid(write_response_cu_latched_valid)
	);

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_write_response_demux
			always_ff @(posedge clock) begin
				write_response_cu[i].valid <= write_response_cu_latched_valid[i];
				write_response_cu[i].payload <= write_response_cu_latched[i].payload;
			end
		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	// Once processed all verticess edges send done signal
	////////////////////////////////////////////////////////////////////////////

	sum_reduce #(
		.DATA_WIDTH_IN (VERTEX_SIZE_BITS),
		.DATA_WIDTH_OUT(VERTEX_SIZE_BITS),
		.BUS_WIDTH     (NUM_VERTEX_CU   )
	) vertex_job_counter_sum_reduce_instant (
		.clock          (clock                  ),
		.rstn           (rstn                   ),
		.enabled_in     (enabled                ),
		.partial_sums_in(vertex_num_counter_cu  ),
		.total_sum_out  (vertex_job_counter_done)
	);

	////////////////////////////////////////////////////////////////////////////
	// Once processed all edges send done signal
	////////////////////////////////////////////////////////////////////////////

	sum_reduce #(
		.DATA_WIDTH_IN (EDGE_SIZE_BITS),
		.DATA_WIDTH_OUT(EDGE_SIZE_BITS),
		.BUS_WIDTH     (NUM_VERTEX_CU )
	) edge_job_counter_sum_reduce_instant (
		.clock          (clock                ),
		.rstn           (rstn                 ),
		.enabled_in     (enabled              ),
		.partial_sums_in(edge_num_counter_cu  ),
		.total_sum_out  (edge_job_counter_done)
	);



endmodule