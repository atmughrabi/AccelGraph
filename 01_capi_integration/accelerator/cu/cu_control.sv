// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_control.sv
// Create : 2019-09-26 15:18:39
// Revise : 2019-11-05 06:01:03
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;


module cu_control #(parameter NUM_REQUESTS = 2) (
	input  logic              clock              , // Clock
	input  logic              rstn               ,
	input  logic              enabled_in         ,
	input  WEDInterface       wed_request_in     ,
	input  ResponseBufferLine read_response_in   ,
	input  ResponseBufferLine write_response_in  ,
	input  ReadWriteDataLine  read_data_0_in     ,
	input  ReadWriteDataLine  read_data_1_in     ,
	input  BufferStatus       read_buffer_status ,
	output logic [0:63]       algorithm_status   ,
	input  logic [0:63]       algorithm_requests ,
	output CommandBufferLine  read_command_out   ,
	input  BufferStatus       write_buffer_status,
	output CommandBufferLine  write_command_out  ,
	output ReadWriteDataLine  write_data_0_out   ,
	output ReadWriteDataLine  write_data_1_out
);

	// vertex control variables


	BufferStatus    vertex_buffer_status;
	VertexInterface vertex_job          ;
	logic           vertex_job_request  ;

	//output latched
	CommandBufferLine write_command_out_latched;
	ReadWriteDataLine write_data_0_out_latched ;
	ReadWriteDataLine write_data_1_out_latched ;
	CommandBufferLine read_command_out_latched ;

	CommandBufferLine read_command_out_vertex          ;
	CommandBufferLine read_command_vertex_buffer       ;
	BufferStatus      read_command_vertex_buffer_status;

	CommandBufferLine read_command_graph_algorithm              ;
	CommandBufferLine read_command_graph_algorithm_buffer       ;
	BufferStatus      read_command_graph_algorithm_buffer_status;

	//input lateched
	WEDInterface       wed_request_in_latched       ;
	ResponseBufferLine read_response_in_latched     ;
	ResponseBufferLine read_response_vertex_job     ;
	ResponseBufferLine read_response_graph_algorithm;

	ResponseBufferLine write_response_in_latched  ;
	ReadWriteDataLine  read_data_0_in_latched     ;
	ReadWriteDataLine  read_data_1_in_latched     ;
	ReadWriteDataLine  read_data_0_vertex_job     ;
	ReadWriteDataLine  read_data_1_vertex_job     ;
	ReadWriteDataLine  read_data_0_graph_algorithm;
	ReadWriteDataLine  read_data_1_graph_algorithm;

	CommandBufferLine                    command_arbiter_out;
	logic             [NUM_REQUESTS-1:0] requests           ;
	logic             [NUM_REQUESTS-1:0] ready              ;
	CommandBufferLine [NUM_REQUESTS-1:0] command_buffer_in  ;

	logic [0:63] algorithm_status_latched  ;
	logic [0:63] algorithm_requests_latched;
	logic        done_graph_algorithm      ;


	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done    ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done      ;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered_latched;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_latched    ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_latched      ;

	CommandBufferLine write_command_cu              ;
	BufferStatus      write_command_buffer_states_cu;

	BufferStatus      write_data_0_buffer_states_cu;
	BufferStatus      write_data_1_buffer_states_cu;
	ReadWriteDataLine write_data_0_cu              ;
	ReadWriteDataLine write_data_1_cu              ;
	logic             ready_write_command_cu       ;

	logic enabled;

	BufferStatus      burst_command_buffer_states_cu;
	logic             burst_command_buffer_pop      ;
	CommandBufferLine burst_command_buffer_out      ;
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
//Done signal
////////////////////////////////////////////////////////////////////////////a

	assign done_graph_algorithm = (wed_request_in_latched.wed.num_vertices == (vertex_job_counter_filtered_latched+vertex_job_counter_done_latched)) &&
		(wed_request_in_latched.wed.num_edges == edge_job_counter_done_latched);

	always_comb begin
		algorithm_status_latched = 0;
		if(wed_request_in_latched.valid)begin
			if(done_graph_algorithm)begin
				algorithm_status_latched = {edge_job_counter_done,(vertex_job_counter_filtered+vertex_job_counter_done)};
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input output
////////////////////////////////////////////////////////////////////////////

	assign read_command_out_latched = burst_command_buffer_out;

	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out                   <= 0;
			write_data_0_out                    <= 0;
			write_data_1_out                    <= 0;
			read_command_out                    <= 0;
			algorithm_status                    <= 0;
			vertex_job_counter_filtered_latched <= 0;
			vertex_job_counter_done_latched     <= 0;
			edge_job_counter_done_latched       <= 0;
		end else begin
			if(enabled)begin
				write_command_out                   <= write_command_out_latched;
				write_data_0_out                    <= write_data_0_out_latched;
				write_data_1_out                    <= write_data_1_out_latched;
				read_command_out                    <= read_command_out_latched;
				algorithm_status                    <= algorithm_status_latched;
				vertex_job_counter_filtered_latched <= vertex_job_counter_filtered;
				vertex_job_counter_done_latched     <= vertex_job_counter_done;
				edge_job_counter_done_latched       <= edge_job_counter_done;
			end
		end
	end

	// drive inputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched     <= 0;
			read_response_in_latched   <= 0;
			write_response_in_latched  <= 0;
			read_data_0_in_latched     <= 0;
			read_data_1_in_latched     <= 0;
			algorithm_requests_latched <= 0;
		end else begin
			if(enabled)begin
				wed_request_in_latched    <= wed_request_in;
				read_response_in_latched  <= read_response_in;
				write_response_in_latched <= write_response_in;
				read_data_0_in_latched    <= read_data_0_in;
				read_data_1_in_latched    <= read_data_1_in;
				if((|algorithm_requests))
					algorithm_requests_latched <= algorithm_requests;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//read command request logic - output
////////////////////////////////////////////////////////////////////////////

	assign requests[0] = ~read_command_vertex_buffer_status.empty && ~read_buffer_status.alfull && ~burst_command_buffer_states_cu.alfull;
	assign requests[1] = ~read_command_graph_algorithm_buffer_status.empty && ~read_buffer_status.alfull && ~burst_command_buffer_states_cu.alfull;

	assign command_buffer_in[0] = read_command_vertex_buffer;
	assign command_buffer_in[1] = read_command_graph_algorithm_buffer;

////////////////////////////////////////////////////////////////////////////
//Buffer arbitration logic
////////////////////////////////////////////////////////////////////////////

	command_buffer_arbiter #(.NUM_REQUESTS(NUM_REQUESTS)) read_command_buffer_arbiter_instant (
		.clock              (clock              ),
		.rstn               (rstn               ),
		.enabled_in         (enabled            ),
		.requests           (requests           ),
		.command_buffer_in  (command_buffer_in  ),
		.command_arbiter_out(command_arbiter_out),
		.ready              (ready              )
	);

////////////////////////////////////////////////////////////////////////////
//read response arbitration logic - input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_vertex_job      <= 0;
			read_response_graph_algorithm <= 0;
		end else begin
			if(enabled && read_response_in_latched.valid) begin
				case (read_response_in_latched.cmd.cu_id)
					VERTEX_CONTROL_ID : begin
						read_response_vertex_job      <= read_response_in_latched;
						read_response_graph_algorithm <= 0;
					end
					default : begin
						read_response_graph_algorithm <= read_response_in_latched;
						read_response_vertex_job      <= 0;
					end
				endcase
			end else begin
				read_response_vertex_job      <= 0;
				read_response_graph_algorithm <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//read data request logic - input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_0_vertex_job      <= 0;
			read_data_0_graph_algorithm <= 0;
		end else begin
			if(enabled && read_data_0_in_latched.valid) begin
				case (read_data_0_in_latched.cmd.cu_id)
					VERTEX_CONTROL_ID : begin
						read_data_0_vertex_job      <= read_data_0_in_latched;
						read_data_0_graph_algorithm <= 0;
					end
					default : begin
						read_data_0_graph_algorithm <= read_data_0_in_latched;
						read_data_0_vertex_job      <= 0;
					end
				endcase
			end else begin
				read_data_0_vertex_job      <= 0;
				read_data_0_graph_algorithm <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_1_vertex_job      <= 0;
			read_data_1_graph_algorithm <= 0;
		end else begin
			if(enabled && read_data_1_in_latched.valid) begin
				case (read_data_1_in_latched.cmd.cu_id)
					VERTEX_CONTROL_ID : begin
						read_data_1_vertex_job      <= read_data_1_in_latched;
						read_data_1_graph_algorithm <= 0;
					end
					default : begin
						read_data_1_graph_algorithm <= read_data_1_in_latched;
						read_data_1_vertex_job      <= 0;
					end
				endcase
			end else begin
				read_data_1_vertex_job      <= 0;
				read_data_1_graph_algorithm <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control - vertex job queue
////////////////////////////////////////////////////////////////////////////

	cu_vertex_job_control cu_vertex_job_control_instant (
		.clock                      (clock                            ),
		.rstn                       (rstn                             ),
		.enabled_in                 (enabled                          ),
		.algorithm_requests         (algorithm_requests_latched       ),
		.wed_request_in             (wed_request_in_latched           ),
		.read_response_in           (read_response_vertex_job         ),
		.read_data_0_in             (read_data_0_vertex_job           ),
		.read_data_1_in             (read_data_1_vertex_job           ),
		.read_buffer_status         (read_command_vertex_buffer_status),
		.vertex_request             (vertex_job_request               ),
		.read_command_out           (read_command_out_vertex          ),
		.vertex_buffer_status       (vertex_buffer_status             ),
		.vertex                     (vertex_job                       ),
		.vertex_job_counter_filtered(vertex_job_counter_filtered      )
	);

////////////////////////////////////////////////////////////////////////////
//graph algorithm control - graph algorithm CU - edge processing
////////////////////////////////////////////////////////////////////////////

	cu_graph_algorithm_control #(.NUM_VERTEX_CU(NUM_VERTEX_CU_GLOBAL)) cu_graph_algorithm_control_instant (
		.clock                  (clock                                     ),
		.rstn                   (rstn                                      ),
		.enabled_in             (enabled                                   ),
		.algorithm_requests     (algorithm_requests_latched                ),
		.wed_request_in         (wed_request_in_latched                    ),
		.read_response_in       (read_response_graph_algorithm             ),
		.write_response_in      (write_response_in_latched                 ),
		.read_data_0_in         (read_data_0_graph_algorithm               ),
		.read_data_1_in         (read_data_1_graph_algorithm               ),
		.read_buffer_status     (read_command_graph_algorithm_buffer_status),
		.read_command_out       (read_command_graph_algorithm              ),
		.write_buffer_status    (write_command_buffer_states_cu            ),
		.write_command_out      (write_command_cu                          ),
		.write_data_0_out       (write_data_0_cu                           ),
		.write_data_1_out       (write_data_1_cu                           ),
		.vertex_buffer_status   (vertex_buffer_status                      ),
		.vertex_job             (vertex_job                                ),
		.vertex_job_request     (vertex_job_request                        ),
		.vertex_job_counter_done(vertex_job_counter_done                   ),
		.edge_job_counter_done  (edge_job_counter_done                     )
	);

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control command buffer
////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_command_job_vertex_buffer_fifo_instant (
		.clock   (clock                                   ),
		.rstn    (rstn                                    ),
		
		.push    (read_command_out_vertex.valid           ),
		.data_in (read_command_out_vertex                 ),
		.full    (read_command_vertex_buffer_status.full  ),
		.alFull  (read_command_vertex_buffer_status.alfull),
		
		.pop     (ready[0]                                ),
		.valid   (read_command_vertex_buffer_status.valid ),
		.data_out(read_command_vertex_buffer              ),
		.empty   (read_command_vertex_buffer_status.empty )
	);

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control command buffer
////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_command_graph_algorithm_buffer_fifo_instant (
		.clock   (clock                                            ),
		.rstn    (rstn                                             ),
		
		.push    (read_command_graph_algorithm.valid               ),
		.data_in (read_command_graph_algorithm                     ),
		.full    (read_command_graph_algorithm_buffer_status.full  ),
		.alFull  (read_command_graph_algorithm_buffer_status.alfull),
		
		.pop     (ready[1]                                         ),
		.valid   (read_command_graph_algorithm_buffer_status.valid ),
		.data_out(read_command_graph_algorithm_buffer              ),
		.empty   (read_command_graph_algorithm_buffer_status.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Burst Buffer Read Commands
////////////////////////////////////////////////////////////////////////////

	assign burst_command_buffer_pop = ~burst_command_buffer_states_cu.empty && ~read_buffer_status.alfull;

	fifo #(
		.WIDTH   ($bits(CommandBufferLine)),
		.DEPTH   (16                      ),
		.HEADROOM(8                       )
	) burst_command_buffer_fifo_instant (
		.clock   (clock                                ),
		.rstn    (rstn                                 ),
		
		.push    (command_arbiter_out.valid            ),
		.data_in (command_arbiter_out                  ),
		.full    (burst_command_buffer_states_cu.full  ),
		.alFull  (burst_command_buffer_states_cu.alfull),
		
		.pop     (burst_command_buffer_pop             ),
		.valid   (burst_command_buffer_states_cu.valid ),
		.data_out(burst_command_buffer_out             ),
		.empty   (burst_command_buffer_states_cu.empty )
	);

	////////////////////////////////////////////////////////////////////////////
	// write command CU Buffers
	////////////////////////////////////////////////////////////////////////////

	assign ready_write_command_cu = ~write_command_buffer_states_cu.empty && ~write_buffer_status.alfull &&
		~write_data_0_buffer_states_cu.empty && ~write_data_1_buffer_states_cu.empty;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(WRITE_CMD_BUFFER_SIZE   )
	) write_command_graph_algorithm_buffer_fifo_instant (
		.clock   (clock                                ),
		.rstn    (rstn                                 ),
		
		.push    (write_command_cu.valid               ),
		.data_in (write_command_cu                     ),
		.full    (write_command_buffer_states_cu.full  ),
		.alFull  (write_command_buffer_states_cu.alfull),
		
		.pop     (ready_write_command_cu               ),
		.valid   (write_command_buffer_states_cu.valid ),
		.data_out(write_command_out_latched            ),
		.empty   (write_command_buffer_states_cu.empty )
	);


	////////////////////////////////////////////////////////////////////////////
	// write command CU DATA Buffers
	////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WRITE_CMD_BUFFER_SIZE   )
	) write_data_graph_algorithm_0_buffer_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (write_data_0_cu.valid               ),
		.data_in (write_data_0_cu                     ),
		.full    (write_data_0_buffer_states_cu.full  ),
		.alFull  (write_data_0_buffer_states_cu.alfull),
		
		.pop     (ready_write_command_cu              ),
		.valid   (write_data_0_buffer_states_cu.valid ),
		.data_out(write_data_0_out_latched            ),
		.empty   (write_data_0_buffer_states_cu.empty )
	);

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WRITE_CMD_BUFFER_SIZE   )
	) write_data_graph_algorithm_1_buffer_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (write_data_1_cu.valid               ),
		.data_in (write_data_1_cu                     ),
		.full    (write_data_1_buffer_states_cu.full  ),
		.alFull  (write_data_1_buffer_states_cu.alfull),
		
		.pop     (ready_write_command_cu              ),
		.valid   (write_data_1_buffer_states_cu.valid ),
		.data_out(write_data_1_out_latched            ),
		.empty   (write_data_1_buffer_states_cu.empty )
	);


endmodule