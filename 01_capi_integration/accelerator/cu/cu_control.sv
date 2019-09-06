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

	input BufferStatus read_buffer_status,
	output CommandBufferLine read_command_out,
	
	input BufferStatus write_buffer_status,
	output CommandBufferLine      write_command_out,
	output ReadWriteDataLine   write_data_out
);


  assign read_command_out  = 0;
  assign write_command_out = 0;
  assign write_data_out    = 0;

endmodule