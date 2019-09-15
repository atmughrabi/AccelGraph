import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_graph_algorithm_control (
	input logic clock,    // Clock
	input logic rstn,
	input logic enabled,
	input WEDInterface 			wed_request_in,
	input ResponseBufferLine 	read_response_in,
	input ReadWriteDataLine 	read_data_0_in,
	input ReadWriteDataLine 	read_data_1_in,
	input BufferStatus read_buffer_status,
	input logic edge_request,
	output CommandBufferLine read_command_out,
	output BufferStatus edge_buffer_status
);






endmodule