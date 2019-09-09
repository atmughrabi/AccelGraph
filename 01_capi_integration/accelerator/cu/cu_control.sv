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



	CommandBufferLine write_command_out_latched;
	ReadWriteDataLine write_data_0_out_latched;
	ReadWriteDataLine write_data_1_out_latched;
	logic send_test;

	assign read_command_out = 0;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out <= 0;
			write_data_0_out  <= 0;
			write_data_1_out  <= 0;
		end else begin
			write_command_out <= write_command_out_latched;
			write_data_0_out  <= write_data_0_out_latched;
			write_data_1_out  <= write_data_1_out_latched;
		end
	end


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out_latched.valid    <= 1'b0;
			write_command_out_latched.command  <= INVALID; // just zero it out
			write_command_out_latched.address  <= 64'h0000_0000_0000_0000;
			write_command_out_latched.size     <= 12'h000;
			write_command_out_latched.cu_id    <= INVALID_ID;
			write_command_out_latched.cmd_type <= CMD_INVALID;
			write_data_1_out_latched <= 0;
			write_data_0_out_latched <= 0;
			send_test <= 1'b0;
		end else begin
			if (wed_request_in.valid && ~send_test) begin
				write_command_out_latched.valid    <= 1'b1;
				write_command_out_latched.size     <= 12'h001;
				write_command_out_latched.command  <= WRITE_MS;
				write_command_out_latched.address  <= (wed_request_in.address + 108);
				write_command_out_latched.cu_id    <= 8'h02;
				write_command_out_latched.cmd_type <= CMD_WRITE;
				write_data_1_out_latched.cu_id     <= 8'h02;
				write_data_1_out_latched.cmd_type  <= CMD_WRITE;
				write_data_0_out_latched.cu_id     <= 8'h02;
				write_data_0_out_latched.cmd_type  <= CMD_WRITE;
				write_data_1_out_latched.data[352:359]  <= 8'b01;
				write_data_0_out_latched.data[352:359]  <= 8'b01;
				send_test <= 1'b1;
			end else begin
				write_command_out_latched.valid    <= 1'b0;
				write_command_out_latched.command  <= INVALID; // just zero it out
				write_command_out_latched.address  <= 64'h0000_0000_0000_0000;
				write_command_out_latched.size     <= 12'h000;
				write_command_out_latched.cu_id    <= INVALID_ID;
				write_command_out_latched.cmd_type <= CMD_INVALID;
				write_data_1_out_latched <= 0;
				write_data_0_out_latched <= 0;
				send_test <= send_test;
			end
		end
	end


endmodule