import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_graph_algorithm_control #(parameter NUM_VERTEX_CU = 1) (
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
	output logic 			 done_graph_algorithm
);

// vertex control variables


	BufferStatus vertex_buffer_status_latched;
	logic vertex_job_request_latched;
	VertexInterface  vertex_job_latched;
	logic 			 done_graph_algorithm_latched;

	//output latched
	CommandBufferLine write_command_out_latched;
	ReadWriteDataLine write_data_0_out_latched;
	ReadWriteDataLine write_data_1_out_latched;
	CommandBufferLine read_command_out_latched;

	CommandBufferLine read_command_out_vertex;
	CommandBufferLine read_command_vertex_buffer;
	BufferStatus read_command_vertex_buffer_status;

	CommandBufferLine read_command_graph_algorithm_edge;
	CommandBufferLine read_command_graph_algorithm_buffer;
	BufferStatus read_command_graph_algorithm_buffer_status;

	//input lateched
	WEDInterface wed_request_in_latched;
	ResponseBufferLine read_response_in_latched;
	ResponseBufferLine write_response_in_latched;
	ReadWriteDataLine read_data_0_in_latched;
	ReadWriteDataLine read_data_1_in_latched;
	BufferStatus 	  read_buffer_status_latched;
	BufferStatus write_buffer_status_latched;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter;


	CommandBufferLine read_command_arbiter_out;
	CommandBufferLine write_command_arbiter_out;

	logic [NUM_VERTEX_CU-1:0] requests;
	logic [NUM_VERTEX_CU-1:0] ready;
	CommandBufferLine [NUM_VERTEX_CU-1:0] read_command_cu;
	CommandBufferLine [NUM_VERTEX_CU-1:0] write_command_cu;
	
	ResponseBufferLine [NUM_VERTEX_CU-1:0] read_response_cu;
	ResponseBufferLine [NUM_VERTEX_CU-1:0] write_response_cu;
	ReadWriteDataLine  [NUM_VERTEX_CU-1:0] read_data_0_cu;
	ReadWriteDataLine  [NUM_VERTEX_CU-1:0] read_data_1_cu;
	ReadWriteDataLine  [NUM_VERTEX_CU-1:0] write_data_0_cu;
	ReadWriteDataLine  [NUM_VERTEX_CU-1:0] write_data_1_cu;
	VertexInterface    [NUM_VERTEX_CU-1:0] vertex_job_cu;
	logic 			   [NUM_VERTEX_CU-1:0] vertex_job_request_cu;

////////////////////////////////////////////////////////////////////////////
//Drive input out put
////////////////////////////////////////////////////////////////////////////

	assign write_command_out_latched = 0;
	assign write_data_0_out_latched  = 0;
	assign write_data_1_out_latched  = 0;
	assign read_command_out_latched  = 0;

	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out  		<= 0;
			write_data_0_out   		<= 0;
			write_data_1_out   		<= 0;
			read_command_out   		<= 0;
			vertex_job_request 		<= 0;
			done_graph_algorithm 	<= 0;
		end else begin
			write_command_out 		<= write_command_out_latched;
			write_data_0_out  		<= write_data_0_out_latched;
			write_data_1_out  		<= write_data_1_out_latched;
			read_command_out  		<= read_command_out_latched;
			vertex_job_request 		<= vertex_job_request_latched;
			done_graph_algorithm 	<= done_graph_algorithm_latched;
		end
	end

	// drive inputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched		 <= 0;
			read_response_in_latched	 <= 0;
			write_response_in_latched	 <= 0;
			read_data_0_in_latched		 <= 0;
			read_data_1_in_latched		 <= 0;
			vertex_job_latched           <= 0;
			read_buffer_status_latched	 <= 4'b0001;
			write_buffer_status_latched	 <= 4'b0001;
			vertex_buffer_status_latched <= 4'b0001;
		end else begin
			if(enabled)begin
				wed_request_in_latched 		 <= wed_request_in;
				read_response_in_latched	 <= read_response_in;
				write_response_in_latched	 <= write_response_in;
				read_data_0_in_latched		 <= read_data_0_in;
				read_data_1_in_latched		 <= read_data_1_in;
				read_buffer_status_latched	 <= read_buffer_status;
				write_buffer_status_latched	 <= write_buffer_status;
				vertex_buffer_status_latched <= vertex_buffer_status;
				vertex_job_latched 			 <= vertex_job;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	genvar i;
	////////////////////////////////////////////////////////////////////////////
	// Vertex job request Arbitration
	////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Read Command Arbitration
	////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Write Command/ Write Data Arbitration
	////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Read Data Arbitration
	////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////
	// Vertex CU Response Arbitration
	////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////
	// Vertex-centric Algorithm Module Generate
	////////////////////////////////////////////////////////////////////////////
	generate
		for (i = 0; i < NUM_VERTEX_CU; i++) begin : generate_pagerank_cu
			cu_vertex_pagerank #(
				.PAGERANK_CU_ID(i))cu_vertex_pagerank_instant
			(
				.clock               (clock),
				.rstn                (rstn),
				.enabled             (enabled),
				.wed_request_in      (wed_request_in_latched),
				.read_response_in    (read_response_cu[i]),
				.write_response_in   (write_response_cu[i]),
				.read_data_0_in      (read_data_0_cu[i]),
				.read_data_1_in      (read_data_1_cu[i]),
				.read_buffer_status  (read_command_graph_algorithm_buffer_status),
				.read_command_out    (read_command_cu[i]),
				.write_buffer_status (write_buffer_status_latched),
				.write_command_out   (write_command_cu[i]),
				.write_data_0_out    (write_data_0_cu[i]),
				.write_data_1_out    (write_data_1_cu[i]),
				.vertex_buffer_status(vertex_buffer_status_latched),
				.vertex_job          (vertex_job_cu[i]),
				.vertex_job_request  (vertex_job_request_cu[i]));
		end
	endgenerate
	////////////////////////////////////////////////////////////////////////////
	// test vertex request
	////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_num_counter <= 0;
			vertex_job_request_latched <= 0;
		end else begin
			if(enabled)begin
				if(~vertex_buffer_status_latched.empty) begin
					vertex_job_request_latched <= 1;
				end
				if(vertex_job_latched.valid) begin
					vertex_num_counter <= vertex_num_counter + 1;
				end
			end
		end
	end

	always_comb begin
		done_graph_algorithm_latched = 0;
		if(wed_request_in_latched.valid)begin
			if(vertex_num_counter >= wed_request_in_latched.wed.num_vertices) begin
				done_graph_algorithm_latched = 1;
			end
		end
	end

endmodule