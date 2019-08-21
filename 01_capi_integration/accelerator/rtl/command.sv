
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
 
	output CommandInterfaceOutput command_out,
	output CommandBufferStatusInterfaceOut command_buffer_status
);

////////////////////////////////////////////////////////////////////////////
//Command 
////////////////////////////////////////////////////////////////////////////

	CommandBufferArbiterInterfaceIn command_arbiter_in;

	CommandBufferLine read_command_buffer_out;
	CommandBufferLine write_command_buffer_out;
	CommandBufferLine wed_command_buffer_out;
	CommandBufferLine restart_command_buffer_out;

	CommandBufferArbiterInterfaceOut command_arbiter_out;

	//As long as there are commands in the fifo set it request for bus access

	assign command_arbiter_in.wed_request 		= ~command_buffer_status.wed_buffer.empty;
	assign command_arbiter_in.read_request 		= ~command_buffer_status.read_buffer.empty;
	assign command_arbiter_in.write_request 	= ~command_buffer_status.write_buffer.empty;
	assign command_arbiter_in.restart_request 	= ~command_buffer_status.restart_buffer.empty;

	command_buffer_arbiter command_buffer_arbiter_instant(
	.clock      (clock),
	.rstn       (rstn),
	.enabled    (enabled),
	.command_arbiter_in         (command_arbiter_in),
	.read_command_buffer_in     (read_command_buffer_out),
	.write_command_buffer_in    (write_command_buffer_out),
	.wed_command_buffer_in      (wed_command_buffer_out),
	.restart_command_buffer_in  (restart_command_buffer_out),
	.command_arbiter_out 		(command_arbiter_out));

	command_control command_control_instant(
	.clock        (clock),
	.rstn         (rstn),
	.enabled      (enabled),
	.command_in             (command_in),
	.command_arbiter_in     (command_arbiter_out),
	.response               (response),
	.command_out            (command_out)
	);

////////////////////////////////////////////////////////////////////////////
//Buffer Read Commands
////////////////////////////////////////////////////////////////////////////
	fifo  #(
	    .WIDTH($bits(CommandBufferLine)),
	    .DEPTH(32)
	    )read_command_buffer_fifo_instant(
	      .clock(clock),
	      .rstn(rstn),
	      
	      .push(read_command_in.valid),
	      .data_in(read_command_in),
	      .full(command_buffer_status.read_buffer.full),
	      .alFull(command_buffer_status.read_buffer.alfull),

	      .pop(command_arbiter_out.read_ready),
	      .valid(command_buffer_status.read_buffer.valid),
	      .data_out(read_command_buffer_out),
	      .empty(command_buffer_status.read_buffer.empty)
	  );

////////////////////////////////////////////////////////////////////////////
//Buffers Write Commands
////////////////////////////////////////////////////////////////////////////
	fifo  #(
	    .WIDTH($bits(CommandBufferLine)),
	    .DEPTH(32)
	    )write_command_buffer_fifo_instant(
	      .clock(clock),
	      .rstn(rstn),
	      
	      .push(write_command_in.valid),
	      .data_in(write_command_in),
	      .full(command_buffer_status.write_buffer.full),
	      .alFull(command_buffer_status.write_buffer.alfull),

	      .pop(command_arbiter_out.write_ready),
	      .valid(command_buffer_status.write_buffer.valid),
	      .data_out(write_command_buffer_out),
	      .empty(command_buffer_status.write_buffer.empty)
	  );

////////////////////////////////////////////////////////////////////////////
//Buffers WED Commands
////////////////////////////////////////////////////////////////////////////
	fifo  #(
	    .WIDTH($bits(CommandBufferLine)),
	    .DEPTH(2)
	    )wed_command_buffer_fifo_instant(
	      .clock(clock),
	      .rstn(rstn),
	      
	      .push(wed_command_in.valid),
	      .data_in(wed_command_in),
	      .full(command_buffer_status.wed_buffer.full),
	      .alFull(command_buffer_status.wed_buffer.alfull),

	      .pop(command_arbiter_out.wed_ready),
	      .valid(command_buffer_status.wed_buffer.valid),
	      .data_out(wed_command_buffer_out),
	      .empty(command_buffer_status.wed_buffer.empty)
	  );


////////////////////////////////////////////////////////////////////////////
//restart Read Commands
////////////////////////////////////////////////////////////////////////////
	fifo  #(
	    .WIDTH($bits(CommandBufferLine)),
	    .DEPTH(2)
	    )restart_command_buffer_fifo_instant(
	      .clock(clock),
	      .rstn(rstn),
	      
	      .push(restart_command_in.valid),
	      .data_in(restart_command_in),
	      .full(command_buffer_status.restart_buffer.full),
	      .alFull(command_buffer_status.read_buffer.alfull),

	      .pop(command_arbiter_out.restart_ready),
	      .valid(command_buffer_status.restart_buffer.valid),
	      .data_out(restart_command_buffer_out),
	      .empty(command_buffer_status.restart_buffer.empty)
	  );


endmodule





