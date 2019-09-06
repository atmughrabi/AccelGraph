import CAPI_PKG::*;
import AFU_PKG::*;

module write_data_control (
  input logic clock,    // Clock
  input logic rstn,   
  input logic enabled, 
  input BufferInterfaceInput buffer_in,
  input logic [0:7] command_tag_in,
  input ReadWriteDataLine write_data_0_in,
  input ReadWriteDataLine write_data_1_in,
  output logic data_write_error,
  output BufferInterfaceOutput buffer_out
);

logic odd_parity;
logic tag_parity;
logic tag_parity_link;
logic [0:7] data_read_parity;
logic [0:7] data_read_parity_link;

logic enable_errors;
logic detected_errors;
logic tag_parity_error;

assign buffer_out.read_latency = 4'h1;
assign data_write_error = 1'b0;
assign odd_parity = 1'b1; // Odd parity
assign enable_errors    = 1'b1; // enable errors

endmodule