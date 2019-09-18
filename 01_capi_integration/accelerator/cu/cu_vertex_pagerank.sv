import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_pagerank #(parameter NUM_EDGE_CU = 1,
							parameter PAGERANK_CU_ID = 1) (
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
	output logic 			 vertex_job_request
);

// vertex control variables


	BufferStatus vertex_buffer_status_latched;
	logic vertex_job_request_latched;
	VertexInterface  vertex_job_latched;


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


	CommandBufferLine command_arbiter_out;
	logic [NUM_EDGE_CU-1:0] requests;
	logic [NUM_EDGE_CU-1:0] ready;
	CommandBufferLine [NUM_EDGE_CU-1:0] read_command_buffer;
	CommandBufferLine [NUM_EDGE_CU-1:0] write_command_buffer;
	VertexInterface   [NUM_EDGE_CU-1:0] vertex_job_rcv;

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
		end else begin
			write_command_out 		<= write_command_out_latched;
			write_data_0_out  		<= write_data_0_out_latched;
			write_data_1_out  		<= write_data_1_out_latched;
			read_command_out  		<= read_command_out_latched;
			vertex_job_request 		<= vertex_job_request_latched;
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


endmodule