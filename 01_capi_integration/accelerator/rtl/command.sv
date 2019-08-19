
import CAPI_PKG::*;
import CREDIT_PKG::*;
import COMMAND_PKG::*;


module command (
	input logic clock,    // Clock
	input logic rstn, 	
	input logic enabled, 	
	input CommandBufferLine read_command_in,
	input CommandBufferLine write_command_in,
	input CommandBufferLine wed_command_in,
	input CommandBufferLine restart_command_in,

	input CommandInterfaceInput command_in,
  	input ResponseInterface response,
 
	output CommandInterfaceOutput command_out
);

////////////////////////////////////////////////////////////////////////////
//Command 
////////////////////////////////////////////////////////////////////////////

  CommandBufferArbiterInterfaceIn command_arbiter_in;

  CommandBufferLine read_command_buffer_in;
  CommandBufferLine write_command_buffer_in;
  CommandBufferLine wed_command_buffer_in;
  CommandBufferLine restart_command_buffer_in;

  CommandBufferArbiterInterfaceOut command_arbiter_out;

  assign command_arbiter_in 		= 0; // get it from fifo
  assign read_command_buffer_in 	= read_command_in;
  assign write_command_buffer_in 	= write_command_in;
  assign wed_command_buffer_in 		= wed_command_in;
  assign restart_command_buffer_in 	= restart_command_in;

  command_buffer_arbiter command_buffer_arbiter_instant(
    .clock      (clock),
    .rstn       (reset_afu),
    .enabled    (enabled),
    .command_arbiter_in         (command_arbiter_in),
    .read_command_buffer_in     (read_command_buffer_in),
    .write_command_buffer_in    (write_command_buffer_in),
    .wed_command_buffer_in      (wed_command_buffer_in),
    .restart_command_buffer_in  (restart_command_buffer_in),
    .command_arbiter_out(command_arbiter_out));
  
  command_control command_control_instant(
    .clock        (clock),
    .rstn         (reset_afu),
    .enabled      (enabled),
    .command_in             (command_in),
    .command_arbiter_in     (command_arbiter_out),
    .response               (response),
    .command_out            (command_out)
    );

endmodule





