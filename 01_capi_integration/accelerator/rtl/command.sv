
import CAPI_PKG::*;
import CREDIT_PKG::*;
import COMMAND_PKG::*;
import CREDIT_PKG::*;

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
  	input BufferInterfaceInput buffer_in,

  	output ResponseBufferLine read_response_out,
	output ResponseBufferLine write_response_out,
	output ResponseBufferLine wed_response_out,
	output ResponseBufferLine restart_response_out,
 	
	output logic [0:6] command_response_error,

	output BufferInterfaceOutput buffer_out,

	output CommandInterfaceOutput command_out,
	output CommandBufferStatusInterfaceOut command_buffer_status,
	output ResponseBufferStatusInterfaceOut response_buffer_status
);

////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL 
////////////////////////////////////////////////////////////////////////////

CommandInterfaceInput 	command_in_latched;
ResponseInterface 		response_latched;
BufferInterfaceInput 	buffer_in_latched;


////////////////////////////////////////////////////////////////////////////
//Command 
////////////////////////////////////////////////////////////////////////////

	CommandBufferArbiterInterfaceIn command_arbiter_in;

	CommandBufferLine read_command_buffer_out;
	CommandBufferLine write_command_buffer_out;
	CommandBufferLine wed_command_buffer_out;
	CommandBufferLine restart_command_buffer_out;

	CommandBufferArbiterInterfaceOut command_arbiter_out;

	ResponseControlInterfaceOut response_control_out;
	logic wed_buffer_pop;
	logic read_buffer_pop;
	logic write_buffer_pop;
	logic restart_buffer_pop;
	//As long as there are commands in the fifo set it request for bus access / if there are credits

	CreditInterfaceOutput credits;
	logic valid_request;

	logic [0:7] command_tag;
	logic tag_buffer_ready;
	CommandTagLine response_tag_id;
////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL 
////////////////////////////////////////////////////////////////////////////

always_ff @(posedge clock) begin
	command_in_latched 	<= command_in;
	response_latched 	<= response;
	buffer_in_latched	<= buffer_in;
end

////////////////////////////////////////////////////////////////////////////
//command request logic
////////////////////////////////////////////////////////////////////////////

	assign command_arbiter_in.wed_request 		= ~command_buffer_status.wed_buffer.empty 	 && |credits.credits && tag_buffer_ready;
	assign command_arbiter_in.read_request 		= ~command_buffer_status.read_buffer.empty   && |credits.credits && tag_buffer_ready;
	assign command_arbiter_in.write_request 	= ~command_buffer_status.write_buffer.empty  && |credits.credits && tag_buffer_ready;
	assign command_arbiter_in.restart_request 	= ~command_buffer_status.restart_buffer.empty&&	|credits.credits && tag_buffer_ready;
	assign valid_request = |command_arbiter_in;

////////////////////////////////////////////////////////////////////////////
//Buffer arbitration logic
////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////
//command interface control logic
////////////////////////////////////////////////////////////////////////////

	command_control command_control_instant(
	.clock        (clock),
	.rstn         (rstn),
	.enabled      (enabled),
	.command_in             (command_in_latched),
	.command_arbiter_in     (command_arbiter_out),
	.command_tag_in			(command_tag),
	.command_out            (command_out)
	);

////////////////////////////////////////////////////////////////////////////
//Credit Tracking Logic
////////////////////////////////////////////////////////////////////////////

 	credit_control credit_control_instant(
      .clock         (clock),
      .rstn          (rstn),
      .credit_in     ({valid_request,response_latched.valid,response_latched.credits,command_in_latched}),
      .credit_out    (credits));

////////////////////////////////////////////////////////////////////////////
//response control 
////////////////////////////////////////////////////////////////////////////

	response_control response_control_instant(
      .clock         (clock),
      .rstn          (rstn),
      .enabled 		 (enabled),
      .response      (response_latched),
      .response_tag_id_in (response_tag_id),
      .response_error (command_response_error),
      .response_control_out    (response_control_out));

////////////////////////////////////////////////////////////////////////////
//tag control 
////////////////////////////////////////////////////////////////////////////


CommandTagLine read_tag_id;
CommandTagLine command_tag_id;


assign command_tag_id.cu_id = command_arbiter_out.command_buffer_out.cu_id;
assign command_tag_id.cmd_type = command_arbiter_out.command_buffer_out.cmd_type;

	tag_control tag_control_instant(
      	.clock         (clock),
      	.rstn          (rstn),
      	.enabled 		 (enabled),
		.tag_response_valid(response_latched.valid),
		.response_tag(response_latched.tag),
	  	.response_tag_id_out(response_tag_id),
	  	.data_read_tag(buffer_in_latched.write_tag), // reminder PSL sees read as write and opposite
	  	.data_read_tag_id_out(read_tag_id),
	  	.tag_command_valid(command_arbiter_out.command_buffer_out.valid),
	  	.tag_command_id(command_tag_id),
	  	.command_tag_out(command_tag),
	  	.tag_buffer_ready(tag_buffer_ready)
      );

////////////////////////////////////////////////////////////////////////////
//Buffer Read Commands
////////////////////////////////////////////////////////////////////////////

	fifo  #(
	    .WIDTH($bits(CommandBufferLine)),
	    .DEPTH(256)
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
	    .DEPTH(256)
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
//Buffers Restart Commands
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
	      .alFull(command_buffer_status.restart_buffer.alfull),

	      .pop(command_arbiter_out.restart_ready),
	      .valid(command_buffer_status.restart_buffer.valid),
	      .data_out(restart_command_buffer_out),
	      .empty(command_buffer_status.restart_buffer.empty)
	  );

////////////////////////////////////////////////////////////////////////////
//Response Buffers
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Write Responses
////////////////////////////////////////////////////////////////////////////

assign write_buffer_pop = ~response_buffer_status.write_buffer.empty;

	fifo  #(
	    .WIDTH($bits(ResponseBufferLine)),
	    .DEPTH(256)
	    )write_response_buffer_fifo_instant(
	      .clock(clock),
	      .rstn(rstn),
	      
	      .push(response_control_out.write_response),
	      .data_in(response_control_out.response),
	      .full(response_buffer_status.write_buffer.full),
	      .alFull(response_buffer_status.write_buffer.alfull),

	      .pop(write_buffer_pop),
	      .valid(response_buffer_status.write_buffer.valid),
	      .data_out(write_response_out),
	      .empty(response_buffer_status.write_buffer.empty)
	  );

////////////////////////////////////////////////////////////////////////////
//Buffers Read Responses
////////////////////////////////////////////////////////////////////////////

assign read_buffer_pop = ~response_buffer_status.read_buffer.empty;

	fifo  #(
	    .WIDTH($bits(ResponseBufferLine)),
	    .DEPTH(256)
	    )read_response_buffer_fifo_instant(
	      .clock(clock),
	      .rstn(rstn),
	      
	      .push(response_control_out.read_response),
	      .data_in(response_control_out.response),
	      .full(response_buffer_status.read_buffer.full),
	      .alFull(response_buffer_status.read_buffer.alfull),

	      .pop(read_buffer_pop),
	      .valid(response_buffer_status.read_buffer.valid),
	      .data_out(read_response_out),
	      .empty(response_buffer_status.read_buffer.empty)
	  );

////////////////////////////////////////////////////////////////////////////
//restart Read Responses
////////////////////////////////////////////////////////////////////////////

assign restart_buffer_pop = ~response_buffer_status.restart_buffer.empty;

	fifo  #(
	    .WIDTH($bits(ResponseBufferLine)),
	    .DEPTH(2)
	    )restart_response_buffer_fifo_instant(
	      .clock(clock),
	      .rstn(rstn),
	      
	      .push(response_control_out.restart_response),
	      .data_in(response_control_out.response),
	      .full(response_buffer_status.restart_buffer.full),
	      .alFull(response_buffer_status.restart_buffer.alfull),

	      .pop(restart_buffer_pop),
	      .valid(response_buffer_status.restart_buffer.valid),
	      .data_out(restart_response_out),
	      .empty(response_buffer_status.restart_buffer.empty)
	  );

////////////////////////////////////////////////////////////////////////////
//Buffers WED Responses
////////////////////////////////////////////////////////////////////////////

assign wed_buffer_pop = ~response_buffer_status.wed_buffer.empty;

	fifo  #(
	    .WIDTH($bits(ResponseBufferLine)),
	    .DEPTH(2)
	    )wed_response_buffer_fifo_instant(
	      .clock(clock),
	      .rstn(rstn),
	      
	      .push(response_control_out.wed_response),
	      .data_in(response_control_out.response),
	      .full(response_buffer_status.wed_buffer.full),
	      .alFull(response_buffer_status.wed_buffer.alfull),

	      .pop(wed_buffer_pop),
	      .valid(response_buffer_status.wed_buffer.valid),
	      .data_out(wed_response_out),
	      .empty(response_buffer_status.wed_buffer.empty)
	  );


endmodule





