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
	VertexInterface vertex_latched;
	logic vertex_request_latched;
	logic send_test;

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
	BufferStatus 	  read_buffer_status_latched;
	BufferStatus write_buffer_status_latched;

	assign read_command_out_latched = 0;

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


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out_latched.valid    <= 1'b0;
			write_command_out_latched.command  <= INVALID; // just zero it out
			write_command_out_latched.address  <= 64'h0000_0000_0000_0000;
			write_command_out_latched.size     <= 12'h000;
			
			write_command_out_latched.cmd.cu_id    <= INVALID_ID;
			write_command_out_latched.cmd.cmd_type <= CMD_INVALID;
			write_command_out_latched.cmd.vertex_struct <= STRUCT_INVALID;
			
			write_data_1_out_latched <= 0;
			write_data_0_out_latched <= 0;
			send_test <= 1'b0;
		end else begin
			if (wed_request_in_latched.valid && ~send_test) begin
				write_command_out_latched.valid    <= 1'b1;
				write_command_out_latched.size     <= 12'h001;
				write_command_out_latched.command  <= WRITE_MS;
				write_command_out_latched.address  <= (wed_request_in_latched.address + 108);
				
				write_command_out_latched.cmd.cu_id    <= 8'h02;
				write_command_out_latched.cmd.cmd_type <= CMD_WRITE;
				write_command_out_latched.cmd.vertex_struct <= STRUCT_INVALID;
			
				write_data_1_out_latched.cmd.cu_id     <= 8'h02;
				write_data_1_out_latched.cmd.cmd_type  <= CMD_WRITE;
				write_data_1_out_latched.cmd.vertex_struct <= STRUCT_INVALID;
				
				write_data_0_out_latched.cmd.cu_id     <= 8'h02;
				write_data_0_out_latched.cmd.cmd_type  <= CMD_WRITE;
				write_data_0_out_latched.cmd.vertex_struct <= STRUCT_INVALID;
			
				write_data_1_out_latched.data[352:359]  <= 8'b01;
				write_data_0_out_latched.data[352:359]  <= 8'b01;
				send_test <= 1'b1;
			end else begin
				write_command_out_latched.valid    <= 1'b0;
				write_command_out_latched.command  <= INVALID; // just zero it out
				write_command_out_latched.address  <= 64'h0000_0000_0000_0000;
				write_command_out_latched.size     <= 12'h000;
				
				write_command_out_latched.cmd.cu_id    <= INVALID_ID;
				write_command_out_latched.cmd.cmd_type <= CMD_INVALID;
				write_command_out_latched.cmd.vertex_struct <= STRUCT_INVALID;
				
				write_data_1_out_latched <= 0;
				write_data_0_out_latched <= 0;
				send_test <= send_test;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//vertex job buffer/control
////////////////////////////////////////////////////////////////////////////

cu_vertex_control cu_vertex_control_instant(
	.clock               (clock),
	.rstn                (rstn),
	.enabled             (enabled),
	.wed_request_in      (wed_request_in_latched),
	.read_response_in    (read_response_in_latched),
	.read_data_0_in      (read_data_0_in_latched),
	.read_data_1_in      (read_data_1_in_latched),
	.read_buffer_status  (read_buffer_status_latched),
	.vertex_request      (vertex_request_latched),
	.read_command_out    (read_command_out_latched),
	.vertex_buffer_status(vertex_buffer_status_latched),
	.vertex              (vertex_latched));

endmodule