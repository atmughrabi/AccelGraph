import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;


module cu_control (
	input logic clock,    // Clock
	input logic rstn,
	input logic enabled,
	input WEDInterface wed_request_in,
	input ResponseBufferLine read_response_in,
	input ResponseBufferLine write_response_in,
	input ReadWriteDataLine read_data_0_in,
	input ReadWriteDataLine read_data_1_in,
	input BufferStatus read_buffer_status,
	output CommandBufferLine read_command_out,
	input BufferStatus write_buffer_status,
	output CommandBufferLine write_command_out,
	output ReadWriteDataLine write_data_0_out,
	output ReadWriteDataLine write_data_1_out
);

	// vertex control variables
	BufferStatus vertex_buffer_status_latched;
	BufferStatus read_command_vertex_buffer_latched;
	VertexInterface vertex_latched;
	logic vertex_request_latched;
	logic pop_read_command;

	//output latched
	CommandBufferLine write_command_out_latched;
	ReadWriteDataLine write_data_0_out_latched;
	ReadWriteDataLine write_data_1_out_latched;
	CommandBufferLine read_command_out_latched;

	CommandBufferLine read_command_out_vertex;
	CommandBufferLine read_command_vertex_buffer;

	//input lateched
	WEDInterface wed_request_in_latched;
	ResponseBufferLine read_response_in_latched;
	ResponseBufferLine write_response_in_latched;
	ReadWriteDataLine read_data_0_in_latched;
	ReadWriteDataLine read_data_1_in_latched;
	BufferStatus 	  read_buffer_status_latched;
	BufferStatus write_buffer_status_latched;


	assign vertex_request_latched = 0;

////////////////////////////////////////////////////////////////////////////
//Drive input out put
////////////////////////////////////////////////////////////////////////////

	assign write_command_out_latched = 0;
	assign write_data_0_out_latched  = 0;
	assign write_data_1_out_latched  = 0;
	assign read_command_out_latched  = read_command_vertex_buffer;

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
			read_command_out  <= read_command_out_latched;
		end
	end

	// drive inputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched		<= 0;
			read_response_in_latched	<= 0;
			write_response_in_latched	<= 0;
			read_data_0_in_latched		<= 0;
			read_data_1_in_latched		<= 0;
			read_buffer_status_latched	<= 0;
			write_buffer_status_latched	<= 0;
		end else begin
			wed_request_in_latched 		<= wed_request_in;
			read_response_in_latched	<= read_response_in;
			write_response_in_latched	<= write_response_in;
			read_data_0_in_latched		<= read_data_0_in;
			read_data_1_in_latched		<= read_data_1_in;
			read_buffer_status_latched	<= read_buffer_status;
			write_buffer_status_latched	<= write_buffer_status;
		end
	end

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control
////////////////////////////////////////////////////////////////////////////

	cu_vertex_control cu_vertex_control_instant(
		.clock               (clock),
		.rstn                (rstn),
		.enabled             (enabled),
		.wed_request_in      (wed_request_in_latched),
		.read_response_in    (read_response_in_latched),
		.read_data_0_in      (read_data_0_in_latched),
		.read_data_1_in      (read_data_1_in_latched),
		.read_buffer_status  (read_command_vertex_buffer_latched),
		.vertex_request      (vertex_request_latched),
		.read_command_out    (read_command_out_vertex),
		.vertex_buffer_status(vertex_buffer_status_latched),
		.vertex              (vertex_latched));

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control command buffer
////////////////////////////////////////////////////////////////////////////

assign pop_read_command = ~read_buffer_status_latched.empty;
	
	fifo  #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(64)
	)read_command_vertex_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_command_out_vertex.valid),
		.data_in(read_command_out_vertex),
		.full(read_command_vertex_buffer_latched.full),
		.alFull(read_command_vertex_buffer_latched.alfull),

		.pop(pop_read_command),
		.valid(read_command_vertex_buffer_latched.valid),
		.data_out(read_command_vertex_buffer),
		.empty(read_command_vertex_buffer_latched.empty)
	);

endmodule