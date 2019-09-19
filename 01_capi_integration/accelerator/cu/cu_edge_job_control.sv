import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_job_control #(parameter CU_ID = 1)(
	input logic clock,    // Clock
	input logic rstn,
	input logic enabled,
	input WEDInterface 			wed_request_in,
	input ResponseBufferLine 	read_response_in,
	input ReadWriteDataLine 	read_data_0_in,
	input ReadWriteDataLine 	read_data_1_in,
	input BufferStatus 			read_buffer_status,
	input logic 				edge_request,
	input  VertexInterface 	 	vertex_job,
	output CommandBufferLine 	read_command_out,
	output BufferStatus 		edge_buffer_status,
	output EdgeInterface 		edge_job
);

	//output latched
	EdgeInterface edge_latched;
	CommandBufferLine read_command_out_latched;

	//input lateched
	WEDInterface wed_request_in_latched;
	ResponseBufferLine read_response_in_latched;
	ReadWriteDataLine read_data_0_in_latched;
	ReadWriteDataLine read_data_1_in_latched;
	BufferStatus 	  read_buffer_status_latched;
	logic edge_request_latched;

	// internal registers to track logic
	// Read/write commands require the size to be a power of 2 (1, 2, 4, 8, 16, 32,64, 128).
	logic [0:11] request_size;
	logic send_request_ready;
	logic fill_edge_buffer_pending;
	logic [0:7]  response_counter;
	logic [0:(EDGE_SIZE_BITS-1)] edge_next_offest;
	logic [0:(EDGE_SIZE_BITS-1)] edge_num_counter;
	logic [0:(EDGE_SIZE_BITS-1)] edge_id_counter;
	logic [0:7] edge_shift_counter;
	logic [0:7] request_real_size;
	logic [0:7] shift_seek;
	EdgeInterface edge_variable;

	logic fill_edge_buffer;
	VertexInterface 	 	vertex_job_latched;

	logic [0:63] aligend_base_address_inverse_src;
	logic [0:63] aligend_base_address_inverse_dest;
	logic [0:63] aligend_base_address_inverse_weight;

	logic [0:(CACHELINE_SIZE_BITS-1)] in_degree_cacheline;
	logic [0:(CACHELINE_SIZE_BITS-1)] out_degree_cacheline;
	logic [0:(CACHELINE_SIZE_BITS-1)] edges_idx_degree_cacheline;
	logic [0:(CACHELINE_SIZE_BITS-1)] src_cacheline;
	logic [0:(CACHELINE_SIZE_BITS-1)] dest_cacheline;
	logic [0:(CACHELINE_SIZE_BITS-1)] weight_cacheline;

	logic in_degree_cacheline_ready;
	logic out_degree_cacheline_ready;
	logic edges_idx_degree_cacheline_ready;
	logic src_cacheline_ready;
	logic dest_cacheline_ready;
	logic weight_cacheline_ready;
	logic push_edge;

	edge_struct_state current_state, next_state;

////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_job 	  		 <= 0;
			read_command_out  	 <= 0;
		end else begin
			if(enabled) begin
				edge_job 	  			<= edge_latched;
				read_command_out  		<= read_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched		<= 0;
			read_response_in_latched	<= 0;
			read_data_0_in_latched		<= 0;
			read_data_1_in_latched		<= 0;
			read_buffer_status_latched	<= 4'b0001;
			edge_request_latched		<= 0;
			vertex_job_latched			<= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched 		<= wed_request_in;
				read_response_in_latched	<= read_response_in;
				read_data_0_in_latched		<= read_data_0_in;
				read_data_1_in_latched		<= read_data_1_in;
				read_buffer_status_latched	<= read_buffer_status;
				edge_request_latched		<= edge_request;
				vertex_job_latched 			<= vertex_job;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//1. Generate Read Commands to obtain edge structural info
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= SEND_EDGE_RESET;
		else
			current_state <= next_state;
	end // always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			SEND_EDGE_RESET: begin
				if(vertex_job_latched.valid && wed_request_in_latched.valid)
					next_state = SEND_EDGE_INIT;
				else
					next_state = SEND_EDGE_RESET;
			end
			SEND_EDGE_INIT: begin
				next_state = SEND_EDGE_IDLE;
			end
			SEND_EDGE_IDLE: begin
				if(send_request_ready )
					next_state = CALC_EDGE_REQ_SIZE;
				else
					next_state = SEND_EDGE_IDLE;
			end
			CALC_EDGE_REQ_SIZE: begin
				next_state = SEND_EDGE_INV_SRC;
			end
			SEND_EDGE_INV_SRC: begin
				next_state = SEND_EDGE_INV_DEST;
			end
			SEND_EDGE_INV_DEST: begin
				next_state = SEND_EDGE_INV_WEIGHT;
			end
			SEND_EDGE_INV_WEIGHT: begin
				next_state = SEND_EDGE_IDLE;
			end
		endcase
	end // always_comb

	always_ff @(posedge clock) begin
		case (current_state)
			SEND_EDGE_RESET: begin
				read_command_out_latched.valid    <= 1'b0;
				read_command_out_latched.command  <= INVALID; // just zero it out
				read_command_out_latched.address  <= 64'h0000_0000_0000_0000;
				read_command_out_latched.size     <= 12'h000;
				read_command_out_latched.cmd 	  <= 0;
				request_size 			<= 	0;
				edge_next_offest  		<= 	0;
				edge_num_counter 		<=	0;
				shift_seek				<=  0;
				aligend_base_address_inverse_src <=  0;
				aligend_base_address_inverse_dest <=  0;
	 			aligend_base_address_inverse_weight <=  0;
			end
			SEND_EDGE_INIT: begin
				edge_num_counter <= vertex_job_latched.inverse_out_degree;
			end
			SEND_EDGE_IDLE: begin
				read_command_out_latched.valid    <= 1'b0;
				read_command_out_latched.command  <= INVALID; // just zero it out
				read_command_out_latched.address  <= 64'h0000_0000_0000_0000;
				read_command_out_latched.size     <= 12'h000;
				read_command_out_latched.cmd 	  <= 0;

				request_size <= 0;
			end
			CALC_EDGE_REQ_SIZE: begin
				request_size <= cmd_size_calculate(edge_num_counter);

				if(edge_num_counter >= CACHELINE_EDGE_NUM)begin
					edge_num_counter <= edge_num_counter - CACHELINE_EDGE_NUM;
					read_command_out_latched.cmd.real_size <= CACHELINE_EDGE_NUM;
				end
				else if (edge_num_counter < CACHELINE_EDGE_NUM) begin
					edge_num_counter <= 0;
					read_command_out_latched.cmd.real_size <= edge_num_counter;
				end
			end
			SEND_EDGE_INV_SRC: begin
				read_command_out_latched.valid    <= 1'b1;
				read_command_out_latched.command  <= READ_CL_NA; // just zero it out
				read_command_out_latched.address  <= aligend_base_address_inverse_src + edge_next_offest;
				read_command_out_latched.size     <= request_size;

				read_command_out_latched.cmd.cu_id    		<= CU_ID;
				read_command_out_latched.cmd.cmd_type 		<= CMD_READ;
				read_command_out_latched.cmd.vertex_struct 	<= INV_IN_DEGREE;
			end
			SEND_EDGE_INV_DEST: begin
				read_command_out_latched.valid    <= 1'b1;
				read_command_out_latched.command  <= READ_CL_NA; // just zero it out
				read_command_out_latched.address  <= aligend_base_address_inverse_dest + edge_next_offest;
				read_command_out_latched.size     <= request_size;

				read_command_out_latched.cmd.cu_id    		<= CU_ID;
				read_command_out_latched.cmd.cmd_type 		<= CMD_READ;
				read_command_out_latched.cmd.vertex_struct 	<= INV_OUT_DEGREE;
			end
			SEND_EDGE_INV_WEIGHT: begin
				read_command_out_latched.valid    <= 1'b1;
				read_command_out_latched.command  <= READ_CL_NA; // just zero it out
				read_command_out_latched.address  <= aligend_base_address_inverse_weight + edge_next_offest;
				read_command_out_latched.size     <= request_size;

				read_command_out_latched.cmd.cu_id    		<= CU_ID;
				read_command_out_latched.cmd.cmd_type 		<= CMD_READ;
				read_command_out_latched.cmd.vertex_struct 	<= INV_EDGES_IDX;

				edge_next_offest <= edge_next_offest + CACHELINE_SIZE;
			end
		endcase
	end // always_ff @(posedge clock)
////////////////////////////////////////////////////////////////////////////
//response tracking logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			response_counter  <= 0;
		else begin
			if ( read_command_out_latched.valid) begin
				response_counter  <= response_counter + 1;
			end else if (read_response_in_latched.valid) begin
				response_counter   <= response_counter - 1;
			end else begin
				response_counter  <= response_counter;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			request_real_size <= 0;
		else begin
			if (read_response_in_latched.valid) begin
				request_real_size <= read_response_in_latched.cmd.real_size;
			end else begin
				request_real_size  <= request_real_size;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//Read Vertex data into registers
////////////////////////////////////////////////////////////////////////////

	cu_cacheline_stream cu_cacheline_stream_inverse_src(
		.clock(clock),
		.rstn(rstn),
		.enabled         	(enabled),
		.fill_edge_buffer	(fill_edge_buffer),
		.read_data_0_in  (read_data_0_in_latched),
		.read_data_1_in  (read_data_1_in_latched),
		.read_response_in(read_response_in_latched),
		.vertex_struct   (INV_EDGE_ARRAY_SRC),
		.shift_limit     (request_real_size),
		.shift_seek      (shift_seek),
		.cacheline       (src_cacheline),
		.cacheline_ready (src_cacheline_ready)
	);

	cu_cacheline_stream cu_cacheline_stream_inverse_dest(
		.clock(clock),
		.rstn(rstn),
		.enabled         	(enabled),
		.fill_edge_buffer	(fill_edge_buffer),
		.read_data_0_in  (read_data_0_in_latched),
		.read_data_1_in  (read_data_1_in_latched),
		.read_response_in(read_response_in_latched),
		.vertex_struct   (INV_EDGE_ARRAY_DEST),
		.shift_limit     (request_real_size),
		.shift_seek      (shift_seek),
		.cacheline       (dest_cacheline),
		.cacheline_ready (dest_cacheline_ready)
	);

	cu_cacheline_stream cu_cacheline_stream_inverse_weight(
		.clock(clock),
		.rstn(rstn),
		.enabled         	(enabled),
		.fill_edge_buffer	(fill_edge_buffer),
		.read_data_0_in  (read_data_0_in_latched),
		.read_data_1_in  (read_data_1_in_latched),
		.read_response_in(read_response_in_latched),
		.vertex_struct   (INV_EDGE_ARRAY_WEIGHT),
		.shift_limit     (request_real_size),
		.shift_seek      (shift_seek),
		.cacheline       (weight_cacheline),
		.cacheline_ready (weight_cacheline_ready)
	);


////////////////////////////////////////////////////////////////////////////
//Read Vertex registers into edge job queue
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Vertices
////////////////////////////////////////////////////////////////////////////
	assign fill_edge_buffer_pending = src_cacheline_ready || dest_cacheline_ready || weight_cacheline_ready || (|response_counter);
	assign send_request_ready       = ~fill_edge_buffer_pending && ~edge_buffer_status.alfull && (|edge_num_counter) && ~(|response_counter) && wed_request_in_latched.valid;
	assign fill_edge_buffer         = src_cacheline_ready && dest_cacheline_ready && weight_cacheline_ready && ~(|response_counter);

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_variable    	 <= 0;
			edge_id_counter 	 <= 0;
			edge_shift_counter   <= 0;
		end
		else begin
			if(fill_edge_buffer && (edge_shift_counter < request_real_size)) begin
				edge_id_counter    <= edge_id_counter + 1;
				edge_shift_counter <= edge_shift_counter + 1;
				edge_variable.valid 		<= 1'b1;
				edge_variable.id 			<= edge_id_counter;
				edge_variable.src 	        <= src_cacheline[(CACHELINE_SIZE_BITS-EDGE_SIZE_BITS):(CACHELINE_SIZE_BITS-1)];
				edge_variable.dest 	        <= dest_cacheline[(CACHELINE_SIZE_BITS-EDGE_SIZE_BITS):(CACHELINE_SIZE_BITS-1)];
				edge_variable.weight 	    <= weight_cacheline[(CACHELINE_SIZE_BITS-EDGE_SIZE_BITS):(CACHELINE_SIZE_BITS-1)];

			end else begin
				edge_variable  <= 0;
				edge_shift_counter <= 0;
			end
		end
	end

	// if the edge has no in/out neighbors don't schedule it
	assign push_edge = (edge_variable.valid);

	fifo  #(
		.WIDTH($bits(EdgeInterface)),
		.DEPTH((2*CACHELINE_EDGE_NUM))
	)edge_job_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(push_edge),
		.data_in(edge_variable),
		.full(edge_buffer_status.full),
		.alFull(edge_buffer_status.alfull),

		.pop(edge_request_latched),
		.valid(edge_buffer_status.valid),
		.data_out(edge_latched),
		.empty(edge_buffer_status.empty)
	);



endmodule