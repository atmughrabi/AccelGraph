import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_control (
	input logic clock,    // Clock
	input logic rstn,
	input logic enabled,
	input WEDInterface 	wed_request_in,
	input ResponseBufferLine read_response_in,
	input ReadWriteDataLine read_data_0_in,
	input ReadWriteDataLine read_data_1_in,
	input BufferStatus read_buffer_status,
	input logic vertex_request,
	output CommandBufferLine read_command_out,
	output BufferStatus vertex_buffer_status,
	output VertexInterface vertex
);

	//output latched
	BufferStatus vertex_buffer_status_latched;
	VertexInterface vertex_latched;
	CommandBufferLine read_command_out_latched;

	//input lateched
	WEDInterface wed_request_in_latched;
	ResponseBufferLine read_response_in_latched;
	ReadWriteDataLine read_data_0_in_latched;
	ReadWriteDataLine read_data_1_in_latched;
	BufferStatus 	  read_buffer_status_latched;
	logic vertex_request_latched;

	// internal registers to track logic
	logic [0:8] response_counter;
	logic [0:32] vertex_num_counter;
	logic [0:32] vertex_id_counter;
	VertexInterface vertex_variable;

	logic fill_vertex_buffer;
	logic in_degree_ready;
	logic out_degree_ready;
	logic edge_idx_ready;
	logic inverse_in_degree_ready;
	logic inverse_out_degree_ready;
	logic inverse_edge_idx_ready;


	assign read_command_out_latched = 0;

////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_buffer_status <= 0;
			vertex 	  			 <= 0;
			read_command_out  	 <= 0;
		end else begin
			vertex_buffer_status 	<= vertex_buffer_status_latched;
			vertex 	  			 	<= vertex_latched;
			read_command_out  		<= read_command_out_latched;
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched		<= 0;
			read_response_in_latched	<= 0;
			read_data_0_in_latched		<= 0;
			read_data_1_in_latched		<= 0;
			read_buffer_status_latched	<= 0;
			vertex_request_latched		<= 0;
		end else begin
			wed_request_in_latched 		<= wed_request_in;
			read_response_in_latched	<= read_response_in;
			read_data_0_in_latched		<= read_data_0_in;
			read_data_1_in_latched		<= read_data_1_in;
			read_buffer_status_latched	<= read_buffer_status;
			vertex_request_latched		<= vertex_request;
		end
	end

////////////////////////////////////////////////////////////////////////////
//vertex job buffer filling logic
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Vertcies
////////////////////////////////////////////////////////////////////////////

	fifo  #(
		.WIDTH($bits(VertexInterface)),
		.DEPTH((2 << CACHELINE_VERTEX_NUM))
	)read_response_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(fill_vertex_buffer),
		.data_in(vertex_variable),
		.full(vertex_buffer_status_latched.full),
		.alFull(vertex_buffer_status_latched.alfull),

		.pop(vertex_request_latched),
		.valid(vertex_buffer_status_latched.valid),
		.data_out(vertex_latched),
		.empty(vertex_buffer_status_latched.empty)
	);



endmodule