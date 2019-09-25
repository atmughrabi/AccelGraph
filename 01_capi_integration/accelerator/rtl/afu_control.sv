import GLOBALS_PKG::*;
import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;


module afu_control  #(parameter NUM_REQUESTS = 4)(
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
	output CommandBufferStatusInterface command_buffer_status,
	output ResponseBufferStatusInterface response_buffer_status,
	output DataBufferStatusInterface read_data_buffer_status,
	output DataBufferStatusInterface wed_data_buffer_status,
	output DataBufferStatusInterface write_data_buffer_status
);


////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL
////////////////////////////////////////////////////////////////////////////

	CommandInterfaceInput 	command_in_latched;
	ResponseInterface 		response_latched;

	ReadDataControlInterface read_buffer_in;
	WriteDataControlInterface write_buffer_in;

////////////////////////////////////////////////////////////////////////////
//Command
////////////////////////////////////////////////////////////////////////////

	ReadWriteDataLine write_data_0;
	ReadWriteDataLine write_data_1;

	CommandBufferLine read_command_buffer_out;
	CommandBufferLine write_command_buffer_out;
	CommandBufferLine wed_command_buffer_out;
	CommandBufferLine restart_command_buffer_out;


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
	
	logic [0:7] write_tag;
	logic [0:7] command_tag;

	logic tag_buffer_ready;
	CommandTagLine response_tag_id;
	CommandTagLine read_tag_id;
	CommandTagLine command_tag_id;

	CommandBufferLine command_arbiter_out;
	logic [NUM_REQUESTS-1:0] requests;
	logic [NUM_REQUESTS-1:0] ready;
	CommandBufferLine [NUM_REQUESTS-1:0] command_buffer_in;
	logic valid_request;

	logic request_pulse;

////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock) begin
		command_in_latched              <= command_in;
		response_latched                <= response;

		write_tag                       <= buffer_in.write_tag;

		read_buffer_in.write_valid      <= buffer_in.write_valid;         
        read_buffer_in.write_tag        <= buffer_in.write_tag;     
        read_buffer_in.write_tag_parity <= buffer_in.write_tag_parity;    
        read_buffer_in.write_address    <= buffer_in.write_address; 
        read_buffer_in.write_data       <= buffer_in.write_data;   
        read_buffer_in.write_parity     <= buffer_in.write_parity;   

	    write_buffer_in.read_valid      <= buffer_in.read_valid;       
		write_buffer_in.read_tag        <= buffer_in.read_tag;     
	    write_buffer_in.read_tag_parity <= buffer_in.read_tag_parity;      
	    write_buffer_in.read_address    <= buffer_in.read_address;  
	end

////////////////////////////////////////////////////////////////////////////
//command request logic
////////////////////////////////////////////////////////////////////////////

always_ff @(posedge clock or negedge rstn) begin 
	if(~rstn) begin
		request_pulse <= 0;
	end else begin
		request_pulse <= request_pulse + 1;
	end
end

	assign requests[0]   = ~command_buffer_status.restart_buffer.empty 	 &&	|credits.credits && tag_buffer_ready && ~(|request_pulse);
	assign requests[1]   = ~command_buffer_status.wed_buffer.empty 		 && |credits.credits && tag_buffer_ready && ~(|request_pulse);
	assign requests[2]   = ~command_buffer_status.write_buffer.empty  	 && |credits.credits && tag_buffer_ready && ~(|request_pulse);
	assign requests[3]   = ~command_buffer_status.read_buffer.empty   	 && |credits.credits && tag_buffer_ready && ~(|request_pulse);
	assign valid_request = |requests;

	assign command_buffer_in[0] = restart_command_buffer_out;
	assign command_buffer_in[1] = wed_command_buffer_out;
	assign command_buffer_in[2] = write_command_buffer_out;
	assign command_buffer_in[3] = read_command_buffer_out;


////////////////////////////////////////////////////////////////////////////
//Buffer arbitration logic
////////////////////////////////////////////////////////////////////////////

	command_buffer_arbiter#(
		.NUM_REQUESTS(NUM_REQUESTS)
	)command_buffer_arbiter_instant(
		.clock      (clock),
		.rstn       (rstn),
		.enabled    (enabled),
		.requests 	(requests),
		.command_buffer_in 			(command_buffer_in),
		.command_arbiter_out 		(command_arbiter_out),
		.ready              		(ready));

////////////////////////////////////////////////////////////////////////////
//command interface control logic
////////////////////////////////////////////////////////////////////////////

	command_control command_control_instant(
		.clock        (clock),
		.rstn         (rstn),
		.enabled      (enabled),
		.command_arbiter_in     (command_arbiter_out),
		.ready             		(ready),
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
		.buffer_in            (read_buffer_in),
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
		.buffer_in            (write_buffer_in),
		.command_write_valid  (ready[2]),
		.command_tag_in  (command_tag),
		.write_data_0_in (write_data_0),
		.write_data_1_in (write_data_1),
		.data_write_error(data_write_error),
		.buffer_out      (buffer_out)
	);


////////////////////////////////////////////////////////////////////////////
//tag control
////////////////////////////////////////////////////////////////////////////


	assign command_tag_id         = command_arbiter_out.cmd;

	tag_control tag_control_instant(
		.clock         (clock),
		.rstn          (rstn),
		.enabled 		 (enabled),
		.tag_response_valid(response_latched.valid),
		.response_tag(response_latched.tag),
		.response_tag_id_out(response_tag_id),
		.data_read_tag(write_tag), // reminder PSL sees read as write and opposite
		.data_read_tag_id_out(read_tag_id),
		.tag_command_valid(command_arbiter_out.valid),
		.tag_command_id(command_tag_id),
		.command_tag_out(command_tag),
		.tag_buffer_ready(tag_buffer_ready)
	);

////////////////////////////////////////////////////////////////////////////
//Buffer Read Commands
////////////////////////////////////////////////////////////////////////////

	fifo  #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE)
	)read_command_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_command_in.valid),
		.data_in(read_command_in),
		.full(command_buffer_status.read_buffer.full),
		.alFull(command_buffer_status.read_buffer.alfull),

		.pop(ready[3]),
		.valid(command_buffer_status.read_buffer.valid),
		.data_out(read_command_buffer_out),
		.empty(command_buffer_status.read_buffer.empty)
	);

////////////////////////////////////////////////////////////////////////////
//Buffers Write Commands
////////////////////////////////////////////////////////////////////////////
	fifo  #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(WRITE_CMD_BUFFER_SIZE)
	)write_command_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(write_command_in.valid),
		.data_in(write_command_in),
		.full(command_buffer_status.write_buffer.full),
		.alFull(command_buffer_status.write_buffer.alfull),

		.pop(ready[2]),
		.valid(command_buffer_status.write_buffer.valid),
		.data_out(write_command_buffer_out),
		.empty(command_buffer_status.write_buffer.empty)
	);

////////////////////////////////////////////////////////////////////////////
//Buffers WED Commands
////////////////////////////////////////////////////////////////////////////
	fifo  #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(WED_CMD_BUFFER_SIZE)
	)wed_command_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(wed_command_in.valid),
		.data_in(wed_command_in),
		.full(command_buffer_status.wed_buffer.full),
		.alFull(command_buffer_status.wed_buffer.alfull),

		.pop(ready[1]),
		.valid(command_buffer_status.wed_buffer.valid),
		.data_out(wed_command_buffer_out),
		.empty(command_buffer_status.wed_buffer.empty)
	);


////////////////////////////////////////////////////////////////////////////
//Buffers Restart Commands
////////////////////////////////////////////////////////////////////////////
	fifo  #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(RESTART_CMD_BUFFER_SIZE)
	)restart_command_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(restart_command_in.valid),
		.data_in(restart_command_in),
		.full(command_buffer_status.restart_buffer.full),
		.alFull(command_buffer_status.restart_buffer.alfull),

		.pop(ready[0]),
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
		.DEPTH(WRITE_RSP_BUFFER_SIZE)
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
		.DEPTH(READ_RSP_BUFFER_SIZE)
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
		.DEPTH(RESTART_RSP_BUFFER_SIZE)
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
		.DEPTH(WED_RSP_BUFFER_SIZE)
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
		.DEPTH(WED_DATA_BUFFER_SIZE)
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
		.DEPTH(WED_DATA_BUFFER_SIZE)
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
		.DEPTH(READ_DATA_BUFFER_SIZE)
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
		.DEPTH(READ_DATA_BUFFER_SIZE)
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
		.DEPTH(WRITE_DATA_BUFFER_SIZE)
	)cu_write_data_0_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(write_command_in.valid),
		.data_in(write_data_0_in),
		.full(write_data_buffer_status.buffer_0.full),
		.alFull(write_data_buffer_status.buffer_0.alfull),

		.pop(ready[2]),
		.valid(write_data_buffer_status.buffer_0.valid),
		.data_out(write_data_0),
		.empty(write_data_buffer_status.buffer_0.empty)
	);


	fifo  #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WRITE_DATA_BUFFER_SIZE)
	)cu_write_data_1_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(write_command_in.valid),
		.data_in(write_data_1_in),
		.full(write_data_buffer_status.buffer_1.full),
		.alFull(write_data_buffer_status.buffer_1.alfull),

		.pop(ready[2]),
		.valid(write_data_buffer_status.buffer_1.valid),
		.data_out(write_data_1),
		.empty(write_data_buffer_status.buffer_1.empty)
	);

endmodule





