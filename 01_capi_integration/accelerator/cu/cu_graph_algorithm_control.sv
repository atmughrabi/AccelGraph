import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_graph_algorithm_control #(parameter NUM_VERTEX_CU = NUM_VERTEX_CU_GLOBAL) (
	input logic clock,    // Clock
	input logic rstn,
	input logic enabled,
	input WEDInterface 		 wed_request_in,
	input ResponseBufferLine read_response_in,
	input ResponseBufferLine write_response_in,
	input ReadWriteDataLine  read_data_0_in,
	input ReadWriteDataLine  read_data_1_in,
	input BufferStatus 		 read_buffer_status,
	output CommandBufferLine read_command_out,
	input  BufferStatus 	 write_buffer_status,
	output CommandBufferLine write_command_out,
	output ReadWriteDataLine write_data_0_out,
	output ReadWriteDataLine write_data_1_out,
	input  BufferStatus 	 vertex_buffer_status,
	input  VertexInterface 	 vertex_job,
	output logic 			 vertex_job_request,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done,
	output logic [0:(VERTEX_SIZE_BITS-1)] edge_job_counter_done
);

// vertex control variables

	BufferStatus 	 vertex_buffer_status_internal;
	logic vertex_request_internal;
	logic vertex_job_request_latched;
	VertexInterface  vertex_job_latched;
	VertexInterface  vertex_job_arbiter_in;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_temp;

	logic [0:(VERTEX_SIZE_BITS-1)] edge_num_counter;
	logic [0:(VERTEX_SIZE_BITS-1)] edge_num_counter_temp;


	//output latched
	CommandBufferLine write_command_out_latched;
	ReadWriteDataLine write_data_0_out_latched;
	ReadWriteDataLine write_data_1_out_latched;
	CommandBufferLine read_command_out_latched;

	//input lateched
	WEDInterface wed_request_in_latched;
	ResponseBufferLine read_response_in_latched;
	ResponseBufferLine write_response_in_latched;
	ReadWriteDataLine read_data_0_in_latched;
	ReadWriteDataLine read_data_1_in_latched;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_cu [0:NUM_VERTEX_CU-1];
	logic [0:(VERTEX_SIZE_BITS-1)] edge_num_counter_cu [0:NUM_VERTEX_CU-1];

	CommandBufferLine read_command_cu       [0:NUM_VERTEX_CU-1];
	CommandBufferLine read_command_arbiter_cu       [0:NUM_VERTEX_CU-1];
	BufferStatus 	  read_command_buffer_states_cu  [0:NUM_VERTEX_CU-1];
	logic 				[NUM_VERTEX_CU-1:0] ready_read_command_cu;
	logic 			   	[NUM_VERTEX_CU-1:0] request_read_command_cu;

	CommandBufferLine write_command_cu 		[0:NUM_VERTEX_CU-1];
	CommandBufferLine write_command_arbiter_cu       [0:NUM_VERTEX_CU-1];
	BufferStatus 	  write_command_buffer_states_cu  [0:NUM_VERTEX_CU-1];
	logic 				[NUM_VERTEX_CU-1:0] ready_write_command_cu;
	logic 			   	[NUM_VERTEX_CU-1:0] request_write_command_cu;

	BufferStatus 	  	write_data_0_buffer_states_cu  [0:NUM_VERTEX_CU-1];
	BufferStatus 	 	write_data_1_buffer_states_cu  [0:NUM_VERTEX_CU-1];
	ReadWriteDataLine   write_data_0_arbiter_cu 	[0:NUM_VERTEX_CU-1];
	ReadWriteDataLine  	write_data_1_arbiter_cu 	[0:NUM_VERTEX_CU-1];
	ReadWriteDataLine   write_data_0_cu 	[0:NUM_VERTEX_CU-1];
	ReadWriteDataLine  	write_data_1_cu 	[0:NUM_VERTEX_CU-1];

	ResponseBufferLine  read_response_cu 	[0:NUM_VERTEX_CU-1];
	ResponseBufferLine  write_response_cu	[0:NUM_VERTEX_CU-1];
	ResponseBufferLine  read_response_cu_internal 		[0:NUM_VERTEX_CU-1];
	ResponseBufferLine  write_response_cu_internal		[0:NUM_VERTEX_CU-1];

	ReadWriteDataLine   read_data_0_cu 		[0:NUM_VERTEX_CU-1];
	ReadWriteDataLine   read_data_1_cu 		[0:NUM_VERTEX_CU-1];
	ReadWriteDataLine   read_data_0_cu_internal 		[0:NUM_VERTEX_CU-1];
	ReadWriteDataLine   read_data_1_cu_internal 		[0:NUM_VERTEX_CU-1];

	

	VertexInterface    	vertex_job_cu 		[0:NUM_VERTEX_CU-1];
	logic 			   	[NUM_VERTEX_CU-1:0] request_vertex_job_cu;
	logic 				[NUM_VERTEX_CU-1:0] ready_vertex_job_cu;

////////////////////////////////////////////////////////////////////////////
//Drive input out put
////////////////////////////////////////////////////////////////////////////
	
	assign vertex_job_request                               = vertex_job_request_latched;
	assign vertex_job_latched                               = vertex_job;
	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out     <= 0;
			write_data_0_out      <= 0;
			write_data_1_out      <= 0;
			read_command_out      <= 0;
			// vertex_job_request <= 0;
		end else begin
			write_command_out     <= write_command_out_latched;
			write_data_0_out      <= write_data_0_out_latched;
			write_data_1_out      <= write_data_1_out_latched;
			read_command_out      <= read_command_out_latched;
			// vertex_job_request <= vertex_job_request_latched;
		end
	end

	// drive inputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched        <= 0;
			read_response_in_latched      <= 0;
			write_response_in_latched     <= 0;
			read_data_0_in_latched        <= 0;
			read_data_1_in_latched        <= 0;
			// vertex_job_latched         <= 0;
		end else begin
			if(enabled)begin
				wed_request_in_latched    <= wed_request_in;
				read_response_in_latched  <= read_response_in;
				write_response_in_latched <= write_response_in;
				read_data_0_in_latched    <= read_data_0_in;
				read_data_1_in_latched    <= read_data_1_in;
				// vertex_job_latched     <= vertex_job;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	genvar i;
	integer j;
	integer k;
	integer ii;
	integer kk;
	integer jj;
	integer kkk;
	integer jjj;
	////////////////////////////////////////////////////////////////////////////
	// Vertex job request Arbitration
	////////////////////////////////////////////////////////////////////////////

	round_robin_priority_arbiter_1_input_N_ouput #(
		.NUM_REQUESTS(NUM_VERTEX_CU),
		.WIDTH       ($bits(VertexInterface))
	)round_robin_priority_arbiter_1_input_N_ouput_vertex_job
	(
		.clock      (clock),
		.rstn       (rstn),
		.enabled    (enabled),
		.buffer_in  (vertex_job_arbiter_in),
		.requests   (request_vertex_job_cu),
		.arbiter_out(vertex_job_cu),
		.ready      (ready_vertex_job_cu)
	);

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Read Command Arbitration
	////////////////////////////////////////////////////////////////////////////
	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_request_read_command_cu
			assign request_read_command_cu[i] = ~read_command_buffer_states_cu[i].empty && ~read_buffer_status.alfull;
		end
	endgenerate

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_VERTEX_CU),
		.WIDTH       ($bits(CommandBufferLine))
	)round_robin_priority_arbiter_N_input_1_ouput_read_command_cu
	(
		.clock      (clock),
		.rstn       (rstn),
		.enabled    (enabled),
		.buffer_in  (read_command_arbiter_cu),
		.requests   (request_read_command_cu),
		.arbiter_out(read_command_out_latched),
		.ready      (ready_read_command_cu));

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Write Command/ Write Data Arbitration
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_request_write_command_cu
			assign request_write_command_cu[i] = ~write_command_buffer_states_cu[i].empty && ~write_buffer_status.alfull;
		end
	endgenerate

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_VERTEX_CU),
		.WIDTH       ($bits(CommandBufferLine))
	)round_robin_priority_arbiter_N_input_1_ouput_write_command_cu
	(
		.clock      (clock),
		.rstn       (rstn),
		.enabled    (enabled),
		.buffer_in  (write_command_arbiter_cu),
		.requests   (request_write_command_cu),
		.arbiter_out(write_command_out_latched),
		.ready      (ready_write_command_cu));

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Write Command/ Write Data Arbitration
	////////////////////////////////////////////////////////////////////////////

	always_comb begin
		write_data_0_out_latched         = 0;
		write_data_1_out_latched         = 0;
		for (k = 0; k < NUM_VERTEX_CU; k++) begin
			if(ready_write_command_cu[k])begin
				write_data_0_out_latched = write_data_0_arbiter_cu[k];
				write_data_1_out_latched = write_data_1_arbiter_cu[k];
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Read Data Arbitration
	////////////////////////////////////////////////////////////////////////////

	always_comb  begin
		for (jjj = 0; jjj < NUM_VERTEX_CU; jjj++) begin
			if(read_data_0_in_latched.cmd.cu_id == jjj && enabled && read_data_0_in_latched.valid)begin
				read_data_0_cu_internal[jjj] = read_data_0_in_latched;
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
			if(read_data_1_in_latched.cmd.cu_id == kkk && enabled && read_data_1_in_latched.valid)begin
				read_data_1_cu_internal[kkk] = read_data_1_in_latched;
			end else begin
				read_data_1_cu_internal[kkk] = 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_data_1_cu <= read_data_1_cu_internal;
	end

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Response Arbitration
	////////////////////////////////////////////////////////////////////////////

	always_comb  begin
		for (jj = 0; jj < NUM_VERTEX_CU; jj++) begin
			if(read_response_in_latched.cmd.cu_id == jj && enabled && read_response_in_latched.valid)begin
				read_response_cu_internal[jj]  = read_response_in_latched;
			end else begin
				read_response_cu_internal[jj]  = 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_response_cu <= read_response_cu_internal;
	end

	always_comb  begin
		for (kk = 0; kk < NUM_VERTEX_CU; kk++) begin
			if(write_response_in_latched.cmd.cu_id == kk && enabled && write_response_in_latched.valid)begin
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
			cu_vertex_pagerank #(
				.PAGERANK_CU_ID(i))
			cu_vertex_pagerank_instant
				(
					.clock               (clock),
					.rstn                (rstn),
					.enabled             (enabled),
					.wed_request_in      (wed_request_in_latched),
					.read_response_in    (read_response_cu[i]),
					.write_response_in   (write_response_cu[i]),
					.read_data_0_in      (read_data_0_cu[i]),
					.read_data_1_in      (read_data_1_cu[i]),
					.read_buffer_status  (read_command_buffer_states_cu[i]),
					.read_command_out    (read_command_cu[i]),
					.write_buffer_status (write_command_buffer_states_cu[i]),
					.write_command_out   (write_command_cu[i]),
					.write_data_0_out    (write_data_0_cu[i]),
					.write_data_1_out    (write_data_1_cu[i]),
					.vertex_buffer_status(vertex_buffer_status_internal),
					.vertex_job          (vertex_job_cu[i]),
					.vertex_job_request  (request_vertex_job_cu[i]),
					.vertex_num_counter  (vertex_num_counter_cu[i]),
					.edge_num_counter    (edge_num_counter_cu[i]));
		end
	endgenerate
	
	////////////////////////////////////////////////////////////////////////////
	// Once processed all verticess edges send done signal
	////////////////////////////////////////////////////////////////////////////

	always_comb begin
		vertex_num_counter_temp         = 0;
		for (j = 0; j < NUM_VERTEX_CU; j++) begin
			vertex_num_counter_temp     = vertex_num_counter_temp + vertex_num_counter_cu[j];
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_num_counter          <= 0;
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
		edge_num_counter_temp         = 0;
		for (ii = 0; ii < NUM_VERTEX_CU; ii++) begin
			edge_num_counter_temp     = edge_num_counter_temp + edge_num_counter_cu[ii];
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_num_counter          <= 0;
		end else begin
			if(enabled)begin
				edge_job_counter_done <= edge_num_counter_temp;
			end
		end
	end


	////////////////////////////////////////////////////////////////////////////
	// Vertex Job Buffer
	////////////////////////////////////////////////////////////////////////////

	assign vertex_job_request_latched = (~vertex_buffer_status.empty) && (~vertex_buffer_status_internal.alfull);
	assign vertex_request_internal    = (|ready_vertex_job_cu);


	fifo  #(
		.WIDTH($bits(VertexInterface)),
		.DEPTH(256)
	)vertex_job_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(vertex_job_latched.valid),
		.data_in(vertex_job_latched),
		.full(vertex_buffer_status_internal.full),
		.alFull(vertex_buffer_status_internal.alfull),

		.pop(vertex_request_internal),
		.valid(vertex_buffer_status_internal.valid),
		.data_out(vertex_job_arbiter_in),
		.empty(vertex_buffer_status_internal.empty)
	);


	////////////////////////////////////////////////////////////////////////////
	// read command CU Buffers
	////////////////////////////////////////////////////////////////////////////
	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_read_command_cu
			fifo  #(
				.WIDTH($bits(CommandBufferLine)),
				.DEPTH((256))
			)read_command_cu_buffer_fifo_instant(
				.clock(clock),
				.rstn(rstn),

				.push(read_command_cu[i].valid),
				.data_in(read_command_cu[i]),
				.full(read_command_buffer_states_cu[i].full),
				.alFull(read_command_buffer_states_cu[i].alfull),

				.pop(ready_read_command_cu[i]),
				.valid(read_command_buffer_states_cu[i].valid),
				.data_out(read_command_arbiter_cu[i]),
				.empty(read_command_buffer_states_cu[i].empty)
			);
		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	// write command CU Buffers
	////////////////////////////////////////////////////////////////////////////
	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_write_command_cu
			fifo  #(
				.WIDTH($bits(CommandBufferLine)),
				.DEPTH((256))
			)write_command_cu_buffer_fifo_instant(
				.clock(clock),
				.rstn(rstn),

				.push(write_command_cu[i].valid),
				.data_in(write_command_cu[i]),
				.full(write_command_buffer_states_cu[i].full),
				.alFull(write_command_buffer_states_cu[i].alfull),

				.pop(ready_write_command_cu[i]),
				.valid(write_command_buffer_states_cu[i].valid),
				.data_out(write_command_arbiter_cu[i]),
				.empty(write_command_buffer_states_cu[i].empty)
			);
		end
	endgenerate

	////////////////////////////////////////////////////////////////////////////
	// write command CU DATA Buffers
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_write_data_0_cu
			fifo  #(
				.WIDTH($bits(ReadWriteDataLine)),
				.DEPTH(256)
			)write_data_cu_0_buffer_fifo_instant(
				.clock(clock),
				.rstn(rstn),

				.push(write_command_cu[i].valid),
				.data_in(write_data_0_cu[i]),
				.full(write_data_0_buffer_states_cu[i].full),
				.alFull(write_data_0_buffer_states_cu[i].alfull),

				.pop(ready_write_command_cu[i]),
				.valid(write_data_0_buffer_states_cu[i].valid),
				.data_out(write_data_0_arbiter_cu[i]),
				.empty(write_data_0_buffer_states_cu[i].empty)
			);
		end
	endgenerate


	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_write_data_1_cu
			fifo  #(
				.WIDTH($bits(ReadWriteDataLine)),
				.DEPTH(256)
			)write_data_cu_1_buffer_fifo_instant(
				.clock(clock),
				.rstn(rstn),

				.push(write_command_cu[i].valid),
				.data_in(write_data_1_cu[i]),
				.full(write_data_1_buffer_states_cu[i].full),
				.alFull(write_data_1_buffer_states_cu[i].alfull),

				.pop(ready_write_command_cu[i]),
				.valid(write_data_1_buffer_states_cu[i].valid),
				.data_out(write_data_1_arbiter_cu[i]),
				.empty(write_data_1_buffer_states_cu[i].empty)
			);
		end
	endgenerate

endmodule