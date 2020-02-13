// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_vertex_pagerank_arbiter_control.sv
// Create : 2019-09-26 15:19:08
// Revise : 2019-11-07 18:11:05
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_pagerank_arbiter_control #(parameter NUM_VERTEX_CU = NUM_VERTEX_CU_GLOBAL) (
	input  logic                          clock                   , // Clock
	input  logic                          rstn                    ,
	input  logic                          enabled_in              ,
	input  logic [                  0:63] cu_configure            ,
	input  WEDInterface                   wed_request_in          ,
	input  ResponseBufferLine             read_response_in        ,
	input  ResponseBufferLine             write_response_in       ,
	input  ReadWriteDataLine              read_data_0_in          ,
	input  ReadWriteDataLine              read_data_1_in          ,
	input  BufferStatus                   read_buffer_status      ,
	input  logic                          read_command_bus_grant  ,
	output logic                          read_command_bus_request,
	output CommandBufferLine              read_command_out        ,
	input  BufferStatus                   write_buffer_status     ,
	output CommandBufferLine              write_command_out       ,
	output ReadWriteDataLine              write_data_0_out        ,
	output ReadWriteDataLine              write_data_1_out        ,
	input  VertexInterface                vertex_job              ,
	output logic                          vertex_job_request      ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done
);

	logic read_command_bus_grant_latched  ;
	logic read_command_bus_request_latched;

// vertex control variables

	BufferStatus                   vertex_buffer_status_internal;
	logic                          vertex_request_internal      ;
	logic                          vertex_job_request_latched   ;
	VertexInterface                vertex_job_latched           ;
	VertexInterface                vertex_job_arbiter_in        ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_temp      ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_num_counter_temp        ;


	//output latched
	ReadWriteDataLine write_data_0_out_latched ;
	ReadWriteDataLine write_data_1_out_latched ;
	CommandBufferLine write_command_out_latched;
	CommandBufferLine read_command_out_latched ;

	//input lateched
	WEDInterface       wed_request_in_latched    ;
	ResponseBufferLine read_response_in_latched  ;
	ResponseBufferLine read_response_in_edge_data;
	ResponseBufferLine read_response_in_edge_job ;
	ResponseBufferLine write_response_in_latched ;
	ReadWriteDataLine  read_data_0_in_latched    ;
	ReadWriteDataLine  read_data_1_in_latched    ;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_cu[0:NUM_VERTEX_CU-1];
	logic [  0:(EDGE_SIZE_BITS-1)] edge_num_counter_cu  [0:NUM_VERTEX_CU-1];

	CommandBufferLine         read_command_cu               [0:NUM_VERTEX_CU-1];
	BufferStatus              read_command_buffer_states_cu [0:NUM_VERTEX_CU-1];
	logic [NUM_VERTEX_CU-1:0] ready_read_command_cu                            ;
	logic [NUM_VERTEX_CU-1:0] request_read_command_cu                          ;
	logic [NUM_VERTEX_CU-1:0] read_command_arbiter_cu_submit                   ;

	EdgeDataWrite             edge_data_write_cu                 [0:NUM_VERTEX_CU-1];
	BufferStatus              edge_data_write_cu_buffer_states_cu[0:NUM_VERTEX_CU-1];
	logic [NUM_VERTEX_CU-1:0] ready_edge_data_write_cu                              ;
	logic [NUM_VERTEX_CU-1:0] request_edge_data_write_cu                            ;
	logic [NUM_VERTEX_CU-1:0] enable_cu                                             ;
	logic [NUM_VERTEX_CU-1:0] enable_cu_latched                                     ;
	logic [NUM_VERTEX_CU-1:0] edge_data_write_arbiter_cu_submit                     ;


	ResponseBufferLine read_response_cu          [0:NUM_VERTEX_CU-1];
	ResponseBufferLine write_response_cu         [0:NUM_VERTEX_CU-1];
	ResponseBufferLine read_response_cu_internal [0:NUM_VERTEX_CU-1];
	ResponseBufferLine write_response_cu_internal[0:NUM_VERTEX_CU-1];

	ReadWriteDataLine read_data_0_cu         [0:NUM_VERTEX_CU-1];
	ReadWriteDataLine read_data_1_cu         [0:NUM_VERTEX_CU-1];
	ReadWriteDataLine read_data_0_cu_internal[0:NUM_VERTEX_CU-1];
	ReadWriteDataLine read_data_1_cu_internal[0:NUM_VERTEX_CU-1];


	VertexInterface           vertex_job_cu        [0:NUM_VERTEX_CU-1];
	logic [NUM_VERTEX_CU-1:0] request_vertex_job_cu                   ;
	logic [NUM_VERTEX_CU-1:0] ready_vertex_job_cu                     ;
	logic                     enabled                                 ;
	logic [             0:63] cu_configure_latched                    ;

	BufferStatus      burst_read_command_buffer_states_cu;
	CommandBufferLine burst_read_command_buffer_out      ;

	BufferStatus  burst_edge_data_write_cu_buffer_states_cu;
	logic         burst_edge_data_write_buffer_pop         ;
	EdgeDataWrite burst_edge_data_buffer_out               ;
	EdgeDataWrite edge_data_write_arbiter_out              ;

	ReadWriteDataLine read_data_0_in_edge_job                      ;
	ReadWriteDataLine read_data_1_in_edge_job                      ;
	ReadWriteDataLine read_data_0_in_edge_data                     ;
	ReadWriteDataLine read_data_1_in_edge_data                     ;
	EdgeDataRead      edge_data_read_cu         [0:NUM_VERTEX_CU-1];
	EdgeDataRead      edge_data_read_cu_internal[0:NUM_VERTEX_CU-1];
	EdgeDataRead      edge_data_variable                           ;

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

	assign vertex_job_request = vertex_job_request_latched;
	assign vertex_job_latched = vertex_job;
	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out <= 0;
			write_data_0_out  <= 0;
			write_data_1_out  <= 0;
			read_command_out  <= 0;
		end else begin
			write_command_out <= write_command_out_latched;
			write_data_0_out  <= write_data_0_out_latched;
			write_data_1_out  <= write_data_1_out_latched;
			read_command_out  <= burst_read_command_buffer_out;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//Drive input
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched    <= 0;
			read_response_in_latched  <= 0;
			write_response_in_latched <= 0;
			read_data_0_in_latched    <= 0;
			read_data_1_in_latched    <= 0;
			cu_configure_latched      <= 0;
		end else begin
			if(enabled)begin
				wed_request_in_latched    <= wed_request_in;
				read_response_in_latched  <= read_response_in;
				write_response_in_latched <= write_response_in;
				read_data_0_in_latched    <= read_data_0_in;
				read_data_1_in_latched    <= read_data_1_in;
				if((|cu_configure))
					cu_configure_latched <= cu_configure;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	genvar  i  ;
	integer j  ;
	integer z  ;
	integer ii ;
	integer kk ;
	integer jj ;
	integer kkk;
	integer jjj;
	integer iii;


	////////////////////////////////////////////////////////////////////////////
	// Enable logic
	////////////////////////////////////////////////////////////////////////////

	always_comb  begin
		for (iii = 0; iii < NUM_VERTEX_CU; iii++) begin
			if((iii < cu_configure_latched[32:63]))
				enable_cu_latched[iii] = 1;
			else
				enable_cu_latched[iii] = 0;
		end
	end

	always_ff @(posedge clock) begin
		if(~rstn) begin
			enable_cu <= 0;
		end else begin
			if(enabled)begin
				enable_cu <= enable_cu_latched;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Vertex job request Arbitration
	////////////////////////////////////////////////////////////////////////////


	round_robin_priority_arbiter_1_input_N_ouput #(
		.NUM_REQUESTS(NUM_VERTEX_CU         ),
		.WIDTH       ($bits(VertexInterface))
	) round_robin_priority_arbiter_1_input_N_ouput_vertex_job (
		.clock      (clock                ),
		.rstn       (rstn                 ),
		.enabled    (enabled              ),
		.buffer_in  (vertex_job_arbiter_in),
		.requests   (request_vertex_job_cu),
		.arbiter_out(vertex_job_cu        ),
		.ready      (ready_vertex_job_cu  )
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

	assign read_command_bus_request_latched = ~burst_read_command_buffer_states_cu.empty && ~read_buffer_status.alfull;

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
	// Burst Buffer Write Commands
	////////////////////////////////////////////////////////////////////////////

	assign burst_edge_data_write_buffer_pop = ~burst_edge_data_write_cu_buffer_states_cu.empty && ~write_buffer_status.alfull;

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

	////////////////////////////////////////////////////////////////////////////
	// Write command CU Generatrion
	////////////////////////////////////////////////////////////////////////////

	cu_edge_data_write_control cu_edge_data_write_control_instant (
		.clock            (clock                     ),
		.rstn             (rstn                      ),
		.enabled_in       (enabled                   ),
		.cu_configure     (cu_configure_latched      ),
		.wed_request_in   (wed_request_in_latched    ),
		.edge_data_write  (burst_edge_data_buffer_out),
		.write_data_0_out (write_data_0_out_latched  ),
		.write_data_1_out (write_data_1_out_latched  ),
		.write_command_out(write_command_out_latched )
	);


	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Read Data Arbitration
	////////////////////////////////////////////////////////////////////////////

	always_comb  begin
		for (jjj = 0; jjj < NUM_VERTEX_CU; jjj++) begin
			if(read_data_0_in_edge_job.cmd.cu_id == jjj && enable_cu[jjj] && read_data_0_in_edge_job.valid)begin
				read_data_0_cu_internal[jjj] = read_data_0_in_edge_job;
			end else begin
				read_data_0_cu_internal[jjj] = 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_data_0_cu <= read_data_0_cu_internal;
	end

	always_comb  begin
		for (kkk = 0; kkk < NUM_VERTEX_CU; kkk++) begin
			if(read_data_1_in_edge_job.cmd.cu_id == kkk && enable_cu[kkk] && read_data_1_in_edge_job.valid)begin
				read_data_1_cu_internal[kkk] = read_data_1_in_edge_job;
			end else begin
				read_data_1_cu_internal[kkk] = 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_data_1_cu <= read_data_1_cu_internal;
	end

	////////////////////////////////////////////////////////////////////////////
	//read data request logic - input
	////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_0_in_edge_job  <= 0;
			read_data_0_in_edge_data <= 0;
		end else begin
			if(enabled && read_data_0_in_latched.valid) begin
				case (read_data_0_in_latched.cmd.array_struct)
					INV_EDGE_ARRAY_SRC,INV_EDGE_ARRAY_DEST,INV_EDGE_ARRAY_WEIGHT,EDGE_ARRAY_SRC, EDGE_ARRAY_DEST, EDGE_ARRAY_WEIGHT: begin
						read_data_0_in_edge_job  <= read_data_0_in_latched;
						read_data_0_in_edge_data <= 0;
					end
					READ_GRAPH_DATA : begin
						read_data_0_in_edge_job  <= 0;
						read_data_0_in_edge_data <= read_data_0_in_latched;
					end
					default : begin
						read_data_0_in_edge_job  <= 0;
						read_data_0_in_edge_data <= 0;
					end
				endcase
			end else begin
				read_data_0_in_edge_job  <= 0;
				read_data_0_in_edge_data <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_1_in_edge_job  <= 0;
			read_data_1_in_edge_data <= 0;
		end else begin
			if(enabled && read_data_1_in_latched.valid) begin
				case (read_data_1_in_latched.cmd.array_struct)
					INV_EDGE_ARRAY_SRC,INV_EDGE_ARRAY_DEST,INV_EDGE_ARRAY_WEIGHT,EDGE_ARRAY_SRC, EDGE_ARRAY_DEST, EDGE_ARRAY_WEIGHT: begin
						read_data_1_in_edge_job  <= read_data_1_in_latched;
						read_data_1_in_edge_data <= 0;
					end
					READ_GRAPH_DATA : begin
						read_data_1_in_edge_job  <= 0;
						read_data_1_in_edge_data <= read_data_1_in_latched;
					end
					default : begin
						read_data_1_in_edge_job  <= 0;
						read_data_1_in_edge_data <= 0;
					end
				endcase
			end else begin
				read_data_1_in_edge_job  <= 0;
				read_data_1_in_edge_data <= 0;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//data request read logic
	////////////////////////////////////////////////////////////////////////////

	always_comb  begin
		for (z = 0; z < NUM_VERTEX_CU; z++) begin
			if(edge_data_variable.cu_id == z && enable_cu[z] && edge_data_variable.valid)begin
				edge_data_read_cu_internal[z] = edge_data_variable;
			end else begin
				edge_data_read_cu_internal[z] = 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_data_read_cu <= edge_data_read_cu_internal;
	end

	cu_edge_data_read_control cu_edge_data_read_control_instant (
		.clock           (clock                     ),
		.rstn            (rstn                      ),
		.enabled_in      (enabled                   ),
		.read_response_in(read_response_in_edge_data),
		.read_data_0_in  (read_data_0_in_edge_data  ),
		.read_data_1_in  (read_data_1_in_edge_data  ),
		.edge_data       (edge_data_variable        )
	);

	////////////////////////////////////////////////////////////////////////////
	//read data response logic - input
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_in_edge_job  <= 0;
			read_response_in_edge_data <= 0;
		end else begin
			if(enabled && read_response_in_latched.valid) begin
				case (read_response_in_latched.cmd.array_struct)
					INV_EDGE_ARRAY_SRC,INV_EDGE_ARRAY_DEST,INV_EDGE_ARRAY_WEIGHT,EDGE_ARRAY_SRC, EDGE_ARRAY_DEST, EDGE_ARRAY_WEIGHT: begin
						read_response_in_edge_job  <= read_response_in_latched;
						read_response_in_edge_data <= 0;
					end
					READ_GRAPH_DATA : begin
						read_response_in_edge_job  <= 0;
						read_response_in_edge_data <= read_response_in_latched;
					end
					default : begin
						read_response_in_edge_job  <= 0;
						read_response_in_edge_data <= 0;
					end
				endcase
			end else begin
				read_response_in_edge_job  <= 0;
				read_response_in_edge_data <= 0;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Response Arbitration
	////////////////////////////////////////////////////////////////////////////

	always_comb  begin
		for (jj = 0; jj < NUM_VERTEX_CU; jj++) begin
			if(read_response_in_edge_job.cmd.cu_id == jj && enable_cu[jj] && read_response_in_edge_job.valid)begin
				read_response_cu_internal[jj] = read_response_in_edge_job;
			end else begin
				read_response_cu_internal[jj] = 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_response_cu <= read_response_cu_internal;
	end

	always_comb  begin
		for (kk = 0; kk < NUM_VERTEX_CU; kk++) begin
			if(write_response_in_latched.cmd.cu_id == kk && enable_cu[kk] && write_response_in_latched.valid)begin
				write_response_cu_internal[kk] = write_response_in_latched;
			end else begin
				write_response_cu_internal[kk] = 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		write_response_cu <= write_response_cu_internal;
	end

	////////////////////////////////////////////////////////////////////////////
	// Vertex-centric Algorithm Module Generate
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_pagerank_cu
			cu_vertex_pagerank #(.PAGERANK_CU_ID(i)) cu_vertex_pagerank_instant (
				.clock                      (clock                                    ),
				.rstn                       (rstn                                     ),
				.enabled_in                 (enable_cu[i]                             ),
				.wed_request_in             (wed_request_in_latched                   ),
				.cu_configure               (cu_configure_latched                     ),
				.read_response_in           (read_response_cu[i]                      ),
				.write_response_in          (write_response_cu[i]                     ),
				.read_command_bus_grant     (ready_read_command_cu[i]                 ),
				.read_command_bus_request   (request_read_command_cu[i]               ),
				.edge_data_write_bus_grant  (ready_edge_data_write_cu[i]              ),
				.edge_data_write_bus_request(request_edge_data_write_cu[i]            ),
				.read_data_0_in             (read_data_0_cu[i]                        ),
				.read_data_1_in             (read_data_1_cu[i]                        ),
				.edge_data_read_in          (edge_data_read_cu[i]                     ),
				.read_buffer_status         (burst_read_command_buffer_states_cu      ),
				.read_command_out           (read_command_cu[i]                       ),
				.write_buffer_status        (burst_edge_data_write_cu_buffer_states_cu),
				.edge_data_write_out        (edge_data_write_cu[i]                    ),
				.vertex_job                 (vertex_job_cu[i]                         ),
				.vertex_job_request         (request_vertex_job_cu[i]                 ),
				.vertex_num_counter         (vertex_num_counter_cu[i]                 ),
				.edge_num_counter           (edge_num_counter_cu[i]                   )
			);
		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	// Once processed all verticess edges send done signal
	////////////////////////////////////////////////////////////////////////////

	always_comb begin
		vertex_num_counter_temp = 0;
		for (j = 0; j < NUM_VERTEX_CU; j++) begin
			vertex_num_counter_temp = vertex_num_counter_temp + vertex_num_counter_cu[j];
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_counter_done <= 0;
		end else begin
			if(enabled)begin
				vertex_job_counter_done <= vertex_num_counter_temp;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Once processed all edges send done signal
	////////////////////////////////////////////////////////////////////////////

	always_comb begin
		edge_num_counter_temp = 0;
		for (ii = 0; ii < NUM_VERTEX_CU; ii++) begin
			edge_num_counter_temp = edge_num_counter_temp + edge_num_counter_cu[ii];
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_job_counter_done <= 0;
		end else begin
			if(enabled)begin
				edge_job_counter_done <= edge_num_counter_temp;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Vertex Job Buffer
	////////////////////////////////////////////////////////////////////////////

	assign vertex_job_request_latched = (~vertex_buffer_status_internal.alfull);
	assign vertex_request_internal    = (|ready_vertex_job_cu);

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
		.data_out(vertex_job_arbiter_in               ),
		.empty   (vertex_buffer_status_internal.empty )
	);


	////////////////////////////////////////////////////////////////////////////
	// read command CU Buffers
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_read_command_cu

			assign read_command_arbiter_cu_submit[i] = read_command_cu[i].valid;

		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	// write command CU Buffers
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_edge_data_write_cu

			assign edge_data_write_arbiter_cu_submit[i] = edge_data_write_cu[i].valid;

		end
	endgenerate




endmodule