import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;


module cu_control #(parameter NUM_REQUESTS = 2) (
	input logic clock,    // Clock
	input logic rstn,
	input logic enabled,
	input WEDInterface wed_request_in,
	input ResponseBufferLine read_response_in,
	input ResponseBufferLine write_response_in,
	input ReadWriteDataLine read_data_0_in,
	input ReadWriteDataLine read_data_1_in,
	input BufferStatus 		read_buffer_status,
	output logic [0:63] 	algorithm_status,
	input  logic [0:63] 	algorithm_requests,
	output CommandBufferLine read_command_out,
	input  BufferStatus 		write_buffer_status,
	output CommandBufferLine write_command_out,
	output ReadWriteDataLine write_data_0_out,
	output ReadWriteDataLine write_data_1_out
);

	// vertex control variables


	BufferStatus vertex_buffer_status;
	VertexInterface vertex_job;
	logic vertex_job_request;

	//output latched
	CommandBufferLine write_command_out_latched;
	ReadWriteDataLine write_data_0_out_latched;
	ReadWriteDataLine write_data_1_out_latched;
	CommandBufferLine read_command_out_latched;

	CommandBufferLine read_command_out_vertex;
	CommandBufferLine read_command_vertex_buffer;
	BufferStatus read_command_vertex_buffer_status;

	CommandBufferLine read_command_graph_algorithm;
	CommandBufferLine read_command_graph_algorithm_buffer;
	BufferStatus read_command_graph_algorithm_buffer_status;

	//input lateched
	WEDInterface wed_request_in_latched;
	ResponseBufferLine read_response_in_latched;
	ResponseBufferLine read_response_vertex_job;
	ResponseBufferLine read_response_graph_algorithm;

	ResponseBufferLine write_response_in_latched;
	ReadWriteDataLine read_data_0_in_latched;
	ReadWriteDataLine read_data_1_in_latched;
	ReadWriteDataLine read_data_0_vertex_job;
	ReadWriteDataLine read_data_1_vertex_job;
	ReadWriteDataLine read_data_0_graph_algorithm;
	ReadWriteDataLine read_data_1_graph_algorithm;

	CommandBufferLine command_arbiter_out;
	logic [NUM_REQUESTS-1:0] requests;
	logic [NUM_REQUESTS-1:0] ready;
	CommandBufferLine [NUM_REQUESTS-1:0] command_buffer_in;

	logic [0:63] 	algorithm_status_latched;
	logic [0:63] 	algorithm_requests_latched;
	logic done_graph_algorithm;
	logic cu_vertex_job_control_done;


	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_pushed;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done;

////////////////////////////////////////////////////////////////////////////
//Done signal
////////////////////////////////////////////////////////////////////////////

	assign read_command_out_latched = command_arbiter_out;

	always_comb begin : proc_done
		algorithm_status_latched = 0;
		if(wed_request_in_latched.valid)begin
			if(wed_request_in_latched.wed.num_vertices == (vertex_job_counter_filtered+vertex_job_counter_done))begin
				algorithm_status_latched = 1;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input out put
////////////////////////////////////////////////////////////////////////////

	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out <= 0;
			write_data_0_out  <= 0;
			write_data_1_out  <= 0;
			read_command_out  <= 0;
			algorithm_status  <= 0;
		end else begin
			if(enabled)begin
				write_command_out <= write_command_out_latched;
				write_data_0_out  <= write_data_0_out_latched;
				write_data_1_out  <= write_data_1_out_latched;
				read_command_out  <= read_command_out_latched;
				algorithm_status  <= algorithm_status_latched;
			end
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
			algorithm_requests_latched  <= 0;
		end else begin
			if(enabled)begin
				wed_request_in_latched 		<= wed_request_in;
				read_response_in_latched	<= read_response_in;
				write_response_in_latched	<= write_response_in;
				read_data_0_in_latched		<= read_data_0_in;
				read_data_1_in_latched		<= read_data_1_in;
				algorithm_requests_latched  <= algorithm_requests;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//read command request logic - output
////////////////////////////////////////////////////////////////////////////

	assign requests[0] = ~read_command_vertex_buffer_status.empty && ~read_buffer_status.alfull;
	assign requests[1] = ~read_command_graph_algorithm_buffer_status.empty && ~read_buffer_status.alfull;

	assign command_buffer_in[0] = read_command_vertex_buffer;
	assign command_buffer_in[1] = read_command_graph_algorithm_buffer;

////////////////////////////////////////////////////////////////////////////
//Buffer arbitration logic
////////////////////////////////////////////////////////////////////////////

	command_buffer_arbiter#(
		.NUM_REQUESTS(NUM_REQUESTS)
	)read_command_buffer_arbiter_instant(
		.clock      (clock),
		.rstn       (rstn),
		.enabled    (enabled),
		.requests 	(requests),
		.command_buffer_in 			(command_buffer_in),
		.command_arbiter_out 		(command_arbiter_out),
		.ready              		(ready));

////////////////////////////////////////////////////////////////////////////
//read response arbitration logic - input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_vertex_job  <= 0;
			read_response_graph_algorithm <= 0;
		end else begin
			if(enabled && read_response_in_latched.valid) begin
				case (read_response_in_latched.cmd.cu_id)
					VERTEX_CONTROL_ID: begin
						read_response_vertex_job <= read_response_in_latched;
						read_response_graph_algorithm <= 0;
					end
					default : begin
						read_response_graph_algorithm <= read_response_in_latched;
						read_response_vertex_job  <= 0;
					end
				endcase
			end else begin
				read_response_vertex_job  <= 0;
				read_response_graph_algorithm <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//read data request logic - input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_0_vertex_job  <= 0;
			read_data_0_graph_algorithm <= 0;
		end else begin
			if(enabled && read_data_0_in_latched.valid) begin
				case (read_data_0_in_latched.cmd.cu_id)
					VERTEX_CONTROL_ID: begin
						read_data_0_vertex_job <= read_data_0_in_latched;
						read_data_0_graph_algorithm <= 0;
					end
					default : begin
						read_data_0_graph_algorithm <= read_data_0_in_latched;
						read_data_0_vertex_job  <= 0;
					end
				endcase
			end else begin
				read_data_0_vertex_job  <= 0;
				read_data_0_graph_algorithm <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_1_vertex_job  <= 0;
			read_data_1_graph_algorithm <= 0;
		end else begin
			if(enabled && read_data_1_in_latched.valid) begin
				case (read_data_1_in_latched.cmd.cu_id)
					VERTEX_CONTROL_ID: begin
						read_data_1_vertex_job <= read_data_1_in_latched;
						read_data_1_graph_algorithm <= 0;
					end
					default : begin
						read_data_1_graph_algorithm <= read_data_1_in_latched;
						read_data_1_vertex_job  <= 0;
					end
				endcase
			end else begin
				read_data_1_vertex_job  <= 0;
				read_data_1_graph_algorithm <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control - vertex job queue
////////////////////////////////////////////////////////////////////////////

	cu_vertex_job_control cu_vertex_job_control_instant(
		.clock               (clock),
		.rstn                (rstn),
		.enabled             (enabled),
		.wed_request_in      (wed_request_in_latched),
		.read_response_in    (read_response_vertex_job),
		.read_data_0_in      (read_data_0_vertex_job),
		.read_data_1_in      (read_data_1_vertex_job),
		.read_buffer_status  (read_command_vertex_buffer_status),
		.vertex_request      (vertex_job_request),
		.read_command_out    (read_command_out_vertex),
		.vertex_buffer_status(vertex_buffer_status),
		.vertex              (vertex_job),
		.vertex_job_counter_pushed  (vertex_job_counter_pushed),
		.vertex_job_counter_filtered(vertex_job_counter_filtered));

////////////////////////////////////////////////////////////////////////////
//graph algorithm control - graph algorithm CU - edge processing
////////////////////////////////////////////////////////////////////////////

	cu_graph_algorithm_control cu_graph_algorithm_control_instant(
		.clock               (clock),
		.rstn                (rstn),
		.enabled             (enabled),
		.wed_request_in      (wed_request_in_latched),
		.read_response_in    (read_response_graph_algorithm),
		.write_response_in   (write_response_in_latched),
		.read_data_0_in      (read_data_0_graph_algorithm),
		.read_data_1_in      (read_data_1_graph_algorithm),
		.read_buffer_status  (read_command_graph_algorithm_buffer_status),
		.read_command_out    (read_command_graph_algorithm),
		.write_buffer_status (write_buffer_status),
		.write_command_out   (write_command_out_latched),
		.write_data_0_out    (write_data_0_out_latched),
		.write_data_1_out    (write_data_1_out_latched),
		.vertex_buffer_status(vertex_buffer_status),
		.vertex_job          (vertex_job),
		.vertex_job_request  (vertex_job_request),
		.vertex_job_counter_done(vertex_job_counter_done));

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control command buffer
////////////////////////////////////////////////////////////////////////////

	fifo  #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(64)
	)read_command_job_vertex_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_command_out_vertex.valid),
		.data_in(read_command_out_vertex),
		.full(read_command_vertex_buffer_status.full),
		.alFull(read_command_vertex_buffer_status.alfull),

		.pop(ready[0]),
		.valid(read_command_vertex_buffer_status.valid),
		.data_out(read_command_vertex_buffer),
		.empty(read_command_vertex_buffer_status.empty));

////////////////////////////////////////////////////////////////////////////
//cu_vertex_control command buffer
////////////////////////////////////////////////////////////////////////////

	fifo  #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(256)
	)read_command_graph_algorithm_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_command_graph_algorithm.valid),
		.data_in(read_command_graph_algorithm),
		.full(read_command_graph_algorithm_buffer_status.full),
		.alFull(read_command_graph_algorithm_buffer_status.alfull),

		.pop(ready[1]),
		.valid(read_command_graph_algorithm_buffer_status.valid),
		.data_out(read_command_graph_algorithm_buffer),
		.empty(read_command_graph_algorithm_buffer_status.empty));

endmodule