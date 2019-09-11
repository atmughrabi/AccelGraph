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

	assign read_command_out_latched = 0;

// drive outputs
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

// drive inputs
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


endmodule