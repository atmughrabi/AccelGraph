
import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;

module afu_control (
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
	input ReadWriteDataLine write_data_0_in,
	input ReadWriteDataLine write_data_1_in,
	output ReadWriteDataLine wed_data_0_out,
	output ReadWriteDataLine wed_data_1_out,
	output ReadWriteDataLine read_data_0_out,
	output ReadWriteDataLine read_data_1_out,
	output ResponseBufferLine read_response_out,
	output ResponseBufferLine write_response_out,
	output ResponseBufferLine wed_response_out,
	output ResponseBufferLine restart_response_out,
	output logic [0:6] command_response_error,
	output logic [0:1] data_read_error,
	output logic data_write_error,
	output BufferInterfaceOutput buffer_out,
	output CommandInterfaceOutput command_out,
	output CommandBufferStatusInterface command_buffer_status
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

	ResponseBufferStatusInterface response_buffer_status;
	DataBufferStatusInterface read_data_buffer_status;
	DataBufferStatusInterface wed_data_buffer_status;
	DataBufferStatusInterface write_data_buffer_status;

	ReadWriteDataLine write_data_0;
	ReadWriteDataLine write_data_1;

	CommandBufferArbiterInterfaceIn command_arbiter_in;

	CommandBufferLine read_command_buffer_out;
	CommandBufferLine write_command_buffer_out;
	CommandBufferLine wed_command_buffer_out;
	CommandBufferLine restart_command_buffer_out;

	CommandBufferArbiterInterfaceOut command_arbiter_out;

	ResponseControlInterfaceOut response_control_out;
	logic wed_response_buffer_pop;
	logic read_response_buffer_pop;
	logic write_response_buffer_pop;
	logic restart_response_buffer_pop;

	DataControlInterfaceOut read_data_control_out_0;
	DataControlInterfaceOut read_data_control_out_1;
	logic wed_read_data_0_buffer_pop;
	logic wed_read_data_1_buffer_pop;
	logic read_data_0_buffer_pop;
	logic read_data_1_buffer_pop;

	//As long as there are commands in the FIFO set it request for bus access / if there are credits

	CreditInterfaceOutput credits;
	logic valid_request;

	logic [0:7] command_tag;
	logic tag_buffer_ready;
	CommandTagLine response_tag_id;
	CommandTagLine read_tag_id;
	CommandTagLine command_tag_id;

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

	assign command_arbiter_in.wed_request     = ~command_buffer_status.wed_buffer.empty 	 && |credits.credits && tag_buffer_ready;
	assign command_arbiter_in.read_request    = ~command_buffer_status.read_buffer.empty   && |credits.credits && tag_buffer_ready;
	assign command_arbiter_in.write_request   = ~command_buffer_status.write_buffer.empty  && |credits.credits && tag_buffer_ready;
	assign command_arbiter_in.restart_request = ~command_buffer_status.restart_buffer.empty&&	|credits.credits && tag_buffer_ready;
	assign valid_request                      = |command_arbiter_in;

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
//read data control
////////////////////////////////////////////////////////////////////////////


	read_data_control read_data_control_instant(
		.clock                (clock),
		.rstn                 (rstn),
		.enabled              (enabled),
		.buffer_in            (buffer_in_latched),
		.data_read_tag_id_in  (read_tag_id),
		.data_read_error      (data_read_error),
		.read_data_control_out_0(read_data_control_out_0),
		.read_data_control_out_1(read_data_control_out_1)
	);

////////////////////////////////////////////////////////////////////////////
//write data control
////////////////////////////////////////////////////////////////////////////


	write_data_control write_data_control_instant(
		.clock                (clock),
		.rstn                 (rstn),
		.enabled              (enabled),
		.buffer_in            (buffer_in_latched),
		.command_write_valid  (command_arbiter_out.write_ready),
		.command_tag_in  (command_tag),
		.write_data_0_in (write_data_0),
		.write_data_1_in (write_data_1),
		.data_write_error(data_write_error),
		.buffer_out      (buffer_out)
	);


////////////////////////////////////////////////////////////////////////////
//tag control
////////////////////////////////////////////////////////////////////////////


	assign command_tag_id.cu_id    = command_arbiter_out.command_buffer_out.cu_id;
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

	assign write_response_buffer_pop = ~response_buffer_status.write_buffer.empty;

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

		.pop(write_response_buffer_pop),
		.valid(response_buffer_status.write_buffer.valid),
		.data_out(write_response_out),
		.empty(response_buffer_status.write_buffer.empty)
	);

////////////////////////////////////////////////////////////////////////////
//Buffers Read Responses
////////////////////////////////////////////////////////////////////////////

	assign read_response_buffer_pop = ~response_buffer_status.read_buffer.empty;

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

		.pop(read_response_buffer_pop),
		.valid(response_buffer_status.read_buffer.valid),
		.data_out(read_response_out),
		.empty(response_buffer_status.read_buffer.empty)
	);

////////////////////////////////////////////////////////////////////////////
//restart Read Responses
////////////////////////////////////////////////////////////////////////////

	assign restart_response_buffer_pop = ~response_buffer_status.restart_buffer.empty;

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

		.pop(restart_response_buffer_pop),
		.valid(response_buffer_status.restart_buffer.valid),
		.data_out(restart_response_out),
		.empty(response_buffer_status.restart_buffer.empty)
	);

////////////////////////////////////////////////////////////////////////////
//Buffers WED Responses
////////////////////////////////////////////////////////////////////////////

	assign wed_response_buffer_pop = ~response_buffer_status.wed_buffer.empty;

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

		.pop(wed_response_buffer_pop),
		.valid(response_buffer_status.wed_buffer.valid),
		.data_out(wed_response_out),
		.empty(response_buffer_status.wed_buffer.empty)
	);

////////////////////////////////////////////////////////////////////////////
//Buffers WED Read Data
////////////////////////////////////////////////////////////////////////////

	assign wed_read_data_0_buffer_pop = ~wed_data_buffer_status.buffer_0.empty;

	fifo  #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(2)
	)wed_read_data_0_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_data_control_out_0.wed_data),
		.data_in(read_data_control_out_0.line),
		.full(wed_data_buffer_status.buffer_0.full),
		.alFull(wed_data_buffer_status.buffer_0.alfull),

		.pop(wed_read_data_0_buffer_pop),
		.valid(wed_data_buffer_status.buffer_0.valid),
		.data_out(wed_data_0_out),
		.empty(wed_data_buffer_status.buffer_0.empty)
	);

	assign wed_read_data_1_buffer_pop = ~wed_data_buffer_status.buffer_1.empty;

	fifo  #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(2)
	)wed_read_data_1_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_data_control_out_1.wed_data),
		.data_in(read_data_control_out_1.line),
		.full(wed_data_buffer_status.buffer_1.full),
		.alFull(wed_data_buffer_status.buffer_1.alfull),

		.pop(wed_read_data_1_buffer_pop),
		.valid(wed_data_buffer_status.buffer_1.valid),
		.data_out(wed_data_1_out),
		.empty(wed_data_buffer_status.buffer_1.empty)
	);


////////////////////////////////////////////////////////////////////////////
//Buffers CU Read Data
////////////////////////////////////////////////////////////////////////////

	assign read_data_0_buffer_pop = ~read_data_buffer_status.buffer_0.empty;

	fifo  #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(256)
	)cu_read_data_0_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_data_control_out_0.read_data),
		.data_in(read_data_control_out_0.line),
		.full(read_data_buffer_status.buffer_0.full),
		.alFull(read_data_buffer_status.buffer_0.alfull),

		.pop(read_data_0_buffer_pop),
		.valid(read_data_buffer_status.buffer_0.valid),
		.data_out(read_data_0_out),
		.empty(read_data_buffer_status.buffer_0.empty)
	);

	assign read_data_1_buffer_pop = ~read_data_buffer_status.buffer_1.empty;

	fifo  #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(256)
	)cu_read_data_1_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_data_control_out_1.read_data),
		.data_in(read_data_control_out_1.line),
		.full(read_data_buffer_status.buffer_1.full),
		.alFull(read_data_buffer_status.buffer_1.alfull),

		.pop(read_data_1_buffer_pop),
		.valid(read_data_buffer_status.buffer_1.valid),
		.data_out(read_data_1_out),
		.empty(read_data_buffer_status.buffer_1.empty)
	);

////////////////////////////////////////////////////////////////////////////
//Buffers CU Write DATA
////////////////////////////////////////////////////////////////////////////

	fifo  #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(256)
	)cu_write_data_0_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(write_command_in.valid),
		.data_in(write_data_0_in),
		.full(write_data_buffer_status.buffer_0.full),
		.alFull(write_data_buffer_status.buffer_0.alfull),

		.pop(command_arbiter_out.write_ready),
		.valid(write_data_buffer_status.buffer_0.valid),
		.data_out(write_data_0),
		.empty(write_data_buffer_status.buffer_0.empty)
	);


	fifo  #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(256)
	)cu_write_data_1_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(write_command_in.valid),
		.data_in(write_data_1_in),
		.full(write_data_buffer_status.buffer_1.full),
		.alFull(write_data_buffer_status.buffer_1.alfull),

		.pop(command_arbiter_out.write_ready),
		.valid(write_data_buffer_status.buffer_1.valid),
		.data_out(write_data_1),
		.empty(write_data_buffer_status.buffer_1.empty)
	);

endmodule





