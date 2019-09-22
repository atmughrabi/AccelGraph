import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_pagerank #(
	parameter NUM_EDGE_CU = 1,
	parameter PAGERANK_CU_ID = 1
) (
	input logic clock,    // Clock
	input logic rstn,
	input logic enabled,
	input WEDInterface 		 wed_request_in,
	input ResponseBufferLine read_response_in,
	input ResponseBufferLine write_response_in,
	input ReadWriteDataLine  read_data_0_in,
	input ReadWriteDataLine  read_data_1_in,
	input BufferStatus 		 read_buffer_status,
	output CommandBufferLine read_command_out,
	input  BufferStatus 	 write_buffer_status,
	output CommandBufferLine write_command_out,
	output ReadWriteDataLine write_data_0_out,
	output ReadWriteDataLine write_data_1_out,
	input  BufferStatus 	 vertex_buffer_status,
	input  VertexInterface 	 vertex_job,
	output logic 			 vertex_job_request,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter
);

// vertex control variables
	logic vertex_job_request_send;
	logic vertex_job_request_latched;
	VertexInterface  vertex_job_latched;


	//output latched
	CommandBufferLine write_command_out_latched;
	ReadWriteDataLine write_data_0_out_latched;
	ReadWriteDataLine write_data_1_out_latched;
	CommandBufferLine read_command_out_latched;

	//input lateched
	WEDInterface wed_request_in_latched;
	ResponseBufferLine read_response_in_latched;
	ResponseBufferLine write_response_in_latched;
	ReadWriteDataLine read_data_0_in_latched;
	ReadWriteDataLine read_data_1_in_latched;


	ResponseBufferLine read_response_in_edge_job;
	ReadWriteDataLine  read_data_0_in_edge_job;
	ReadWriteDataLine  read_data_1_in_edge_job;

	ResponseBufferLine read_response_in_edge_data;
	ReadWriteDataLine  read_data_0_in_edge_data;
	ReadWriteDataLine  read_data_1_in_edge_data;


	BufferStatus 	 read_data_0_buffer_status;
	BufferStatus 	 read_data_1_buffer_status;
	BufferStatus 	 read_response_buffer_status;
	BufferStatus 	 write_response_buffer_status;

	ReadWriteDataLine read_data_cu_0_buffer;
	ReadWriteDataLine read_data_cu_1_buffer;
	logic read_data_cu_0_pop;
	logic read_data_cu_1_pop;
	logic read_data_buffer_request;

	logic read_response_buffer_pop;
	logic write_response_buffer_pop;
	ResponseBufferLine read_response_buffer;
	ResponseBufferLine write_response_buffer;

	logic edge_request;
	logic edge_request_internal;
	EdgeInterface 		edge_job;
	BufferStatus edge_buffer_status;
	logic processing_vertex;


////////////////////////////////////////////////////////////////////////////
//Drive input out put
////////////////////////////////////////////////////////////////////////////

	assign write_command_out_latched = 0;
	assign write_data_0_out_latched  = 0;
	assign write_data_1_out_latched  = 0;

	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out  		<= 0;
			write_data_0_out   		<= 0;
			write_data_1_out   		<= 0;
			read_command_out   		<= 0;
			vertex_job_request 		<= 0;
		end else begin
			write_command_out 		<= write_command_out_latched;
			write_data_0_out  		<= write_data_0_out_latched;
			write_data_1_out  		<= write_data_1_out_latched;
			read_command_out  		<= read_command_out_latched;
			vertex_job_request 		<= vertex_job_request_send;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// drive inputs
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched		 <= 0;
			read_response_in_latched	 <= 0;
			write_response_in_latched	 <= 0;
			read_data_0_in_latched		 <= 0;
			read_data_1_in_latched		 <= 0;
		end else begin
			if(enabled)begin
				wed_request_in_latched 		 <= wed_request_in;
				read_response_in_latched	 <= read_response_in;
				write_response_in_latched	 <= write_response_in;
				read_data_0_in_latched		 <= read_data_0_in;
				read_data_1_in_latched		 <= read_data_1_in;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// count complete vertex request
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_latched <= 0;
		end else begin
			if(enabled)begin
				if(vertex_job.valid && ~processing_vertex) begin
					vertex_job_latched <= vertex_job;
				end
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// count complete vertex request
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_num_counter <= 0;
		end else begin
			if(enabled)begin
				if(vertex_job.valid && ~processing_vertex) begin
					vertex_num_counter <= vertex_num_counter + 1;
				end
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// If a vertex job is recieved set flag
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			processing_vertex <= 0;
		end else begin
			if(enabled)begin
				if(vertex_job.valid && ~processing_vertex) begin
					processing_vertex <= 1;
				end 
				// else if (vertex_job_request_latched) begin
				// 	processing_vertex <= 0;
				// end
			end
		end
	end

	assign vertex_job_request_send = ~processing_vertex & vertex_job_request_latched & (~vertex_buffer_status.empty);

	////////////////////////////////////////////////////////////////////////////
	// Edge job control
	////////////////////////////////////////////////////////////////////////////

	assign edge_request = 1;

	assign edge_request_internal = edge_request;

	cu_edge_job_control #(
		.CU_ID(PAGERANK_CU_ID)
	)cu_edge_job_control_instant(
		.clock             (clock),
		.rstn              (rstn),
		.enabled           (enabled),
		.wed_request_in    (wed_request_in_latched),
		.read_response_in  (read_response_in_edge_job),
		.read_data_0_in    (read_data_0_in_edge_job),
		.read_data_1_in    (read_data_1_in_edge_job),
		.read_buffer_status(read_buffer_status),
		.edge_request      (edge_request_internal),
		.vertex_job        (vertex_job_latched),
		.read_command_out  (read_command_out_latched),
		.edge_buffer_status(edge_buffer_status),
		.edge_job          (edge_job),
		.vertex_job_request(vertex_job_request_latched));


////////////////////////////////////////////////////////////////////////////
//read response arbitration logic - input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_in_edge_job 	<= 0;
			read_response_in_edge_data 	<= 0;
		end else begin
			if(enabled && read_response_buffer.valid) begin
				case (read_response_buffer.cmd.vertex_struct)
					INV_EDGE_ARRAY_SRC,INV_EDGE_ARRAY_DEST,INV_EDGE_ARRAY_WEIGHT, EDGE_ARRAY_SRC, EDGE_ARRAY_DEST, EDGE_ARRAY_WEIGHT: begin
						read_response_in_edge_job 	<= read_response_buffer;
						read_response_in_edge_data 	<= 0;
					end
					GRAPH_DATA: begin
						read_response_in_edge_job 	<= 0;
						read_response_in_edge_data 	<= read_response_buffer;
					end
					default : begin
						read_response_in_edge_job 	<= 0;
						read_response_in_edge_data 	<= 0;
					end
				endcase
			end else begin
				read_response_in_edge_job 	<= 0;
				read_response_in_edge_data 	<= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//read data request logic - input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_0_in_edge_job 	<= 0;
			read_data_0_in_edge_data 	<= 0;
		end else begin
			if(enabled && read_data_cu_0_buffer.valid) begin
				case (read_data_cu_0_buffer.cmd.vertex_struct)
					INV_EDGE_ARRAY_SRC,INV_EDGE_ARRAY_DEST,INV_EDGE_ARRAY_WEIGHT,EDGE_ARRAY_SRC, EDGE_ARRAY_DEST, EDGE_ARRAY_WEIGHT: begin
						read_data_0_in_edge_job 	<= read_data_cu_0_buffer;
						read_data_0_in_edge_data 	<= 0;
					end
					GRAPH_DATA: begin
						read_data_0_in_edge_job 	<= 0;
						read_data_0_in_edge_data 	<= read_data_cu_0_buffer;
					end
					default : begin
						read_data_0_in_edge_job 	<= 0;
						read_data_0_in_edge_data 	<= 0;
					end
				endcase
			end else begin
				read_data_0_in_edge_job 	<= 0;
				read_data_0_in_edge_data 	<= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_1_in_edge_job 	<= 0;
			read_data_1_in_edge_data 	<= 0;
		end else begin
			if(enabled && read_data_cu_1_buffer.valid) begin
				case (read_data_cu_1_buffer.cmd.vertex_struct)
					INV_EDGE_ARRAY_SRC,INV_EDGE_ARRAY_DEST,INV_EDGE_ARRAY_WEIGHT,EDGE_ARRAY_SRC, EDGE_ARRAY_DEST, EDGE_ARRAY_WEIGHT: begin
						read_data_1_in_edge_job 	<= read_data_cu_1_buffer;
						read_data_1_in_edge_data 	<= 0;
					end
					GRAPH_DATA: begin
						read_data_1_in_edge_job 	<= 0;
						read_data_1_in_edge_data 	<= read_data_cu_1_buffer;
					end
					default : begin
						read_data_1_in_edge_job 	<= 0;
						read_data_1_in_edge_data 	<= 0;
					end
				endcase
			end else begin
				read_data_1_in_edge_job 	<= 0;
				read_data_1_in_edge_data 	<= 0;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Read DATA Buffers
	////////////////////////////////////////////////////////////////////////////

	assign read_data_buffer_request = 1'b1;
	assign read_data_cu_0_pop       = ~read_data_0_buffer_status.empty && read_data_buffer_request;
	assign read_data_cu_1_pop       = ~read_data_1_buffer_status.empty && read_data_buffer_request;

	fifo  #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(256)
	)read_data_cu_0_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_data_0_in_latched.valid),
		.data_in(read_data_0_in_latched),
		.full(read_data_0_buffer_status.full),
		.alFull(read_data_0_buffer_status.alfull),

		.pop(read_data_cu_0_pop),
		.valid(read_data_0_buffer_status.valid),
		.data_out(read_data_cu_0_buffer),
		.empty(read_data_0_buffer_status.empty));


	fifo  #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(256)
	)read_data_cu_1_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_data_1_in_latched.valid),
		.data_in(read_data_1_in_latched),
		.full(read_data_1_buffer_status.full),
		.alFull(read_data_1_buffer_status.alfull),

		.pop(read_data_cu_1_pop),
		.valid(read_data_1_buffer_status.valid),
		.data_out(read_data_cu_1_buffer),
		.empty(read_data_1_buffer_status.empty));

	////////////////////////////////////////////////////////////////////////////
	// Read/Write Response Buffers
	////////////////////////////////////////////////////////////////////////////

	assign read_response_buffer_pop  = ~read_response_buffer_status.empty;
	assign write_response_buffer_pop = 0;

	fifo  #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(256)
	)read_response_cu_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(read_response_in_latched.valid),
		.data_in(read_response_in_latched),
		.full(read_response_buffer_status.full),
		.alFull(read_response_buffer_status.alfull),

		.pop(read_response_buffer_pop),
		.valid(read_response_buffer_status.valid),
		.data_out(read_response_buffer),
		.empty(read_response_buffer_status.empty));

	fifo  #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(256)
	)write_response_cu_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(write_response_in_latched.valid),
		.data_in(write_response_in_latched),
		.full(write_response_buffer_status.full),
		.alFull(write_response_buffer_status.alfull),

		.pop(write_response_buffer_pop),
		.valid(write_response_buffer_status.valid),
		.data_out(write_response_buffer),
		.empty(write_response_buffer_status.empty));





endmodule