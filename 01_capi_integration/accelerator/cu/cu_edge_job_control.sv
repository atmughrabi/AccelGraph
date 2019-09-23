import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_job_control #(parameter CU_ID = 1) (
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
	output EdgeInterface 		edge_job,
	output logic [0:(EDGE_SIZE_BITS-1)] edge_job_counter_pushed
);

	//output latched
	EdgeInterface edge_latched;
	CommandBufferLine read_command_out_latched;

	//input lateched
	WEDInterface wed_request_in_latched;
	ResponseBufferLine read_response_in_latched;
	ReadWriteDataLine read_data_0_in_latched;
	ReadWriteDataLine read_data_1_in_latched;
	logic edge_request_latched;

	// internal registers to track logic
	// Read/write commands require the size to be a power of 2 (1, 2, 4, 8, 16, 32,64, 128).
	logic [0:11] request_size;
	logic send_request_ready;
	logic fill_edge_buffer_pending;
	logic [0:7]  response_counter;
	logic [0:63] edge_next_offest;

	logic [0:(EDGE_SIZE_BITS-1)] edge_num_counter;
	logic [0:(EDGE_SIZE_BITS-1)] edge_id_counter;
	logic [0:7] shift_seek;
	logic [0:7] remainder;
	logic [0:63] aligned;
	EdgeInterface edge_variable;

	logic fill_edge_buffer;
	VertexInterface 	 	vertex_job_latched;
	logic [0:(EDGE_SIZE_BITS-1)] src_cacheline;
	logic [0:(EDGE_SIZE_BITS-1)] dest_cacheline;
	logic [0:(EDGE_SIZE_BITS-1)] weight_cacheline;

	logic src_cacheline_pending;
	logic dest_cacheline_pending;
	logic weight_cacheline_pending;

	logic src_cacheline_ready;
	logic dest_cacheline_ready;
	logic weight_cacheline_ready;

	logic src_cacheline_sent;
	logic dest_cacheline_sent;
	logic weight_cacheline_sent;

	logic start_shift;
	logic push_edge;
	
	edge_struct_state current_state, next_state;



////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_job 	  		 		<= 0;
			read_command_out  	 		<= 0;
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
			edge_request_latched		<= 0;
			vertex_job_latched			<= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched 		<= wed_request_in;
				read_response_in_latched	<= read_response_in;
				read_data_0_in_latched		<= read_data_0_in;
				read_data_1_in_latched		<= read_data_1_in;
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
			SEND_EDGE_RESET : begin
				if(vertex_job_latched.valid && wed_request_in_latched.valid)
					next_state = SEND_EDGE_INIT;
				else
					next_state = SEND_EDGE_RESET;
			end
			SEND_EDGE_INIT : begin
				if(|edge_num_counter)
					next_state = SEND_EDGE_WAIT;
				else
					next_state = SEND_EDGE_INIT;
			end
			SEND_EDGE_WAIT : begin
				if(send_request_ready)
					next_state = CALC_EDGE_REQ_SIZE;
				else
					next_state = SEND_EDGE_WAIT;
			end
			CALC_EDGE_REQ_SIZE : begin
				next_state = SEND_EDGE_IDLE;
			end
			SEND_EDGE_IDLE : begin
				if(~read_buffer_status.alfull)
					next_state = SEND_EDGE_INV_SRC;
				else
					next_state = SEND_EDGE_IDLE;
			end
			SEND_EDGE_INV_SRC : begin
				if(~read_buffer_status.alfull)
					next_state = SEND_EDGE_INV_DEST;
				else
					next_state = SEND_EDGE_INV_SRC;
			end
			SEND_EDGE_INV_DEST : begin
				if(~read_buffer_status.alfull)
					next_state = SEND_EDGE_INV_WEIGHT;
				else
					next_state = SEND_EDGE_INV_DEST;
			end
			SEND_EDGE_INV_WEIGHT : begin
				if(|edge_num_counter)
					next_state = SEND_EDGE_WAIT;
				else
					next_state = SEND_EDGE_INIT;
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
				remainder 				<=  0;
				aligned					<=  0;
				src_cacheline_sent		<=  0;
				dest_cacheline_sent		<=  0;
				weight_cacheline_sent	<=  0;
			end
			SEND_EDGE_INIT: begin
				edge_num_counter <= vertex_job_latched.inverse_out_degree;
				edge_next_offest <= (vertex_job_latched.inverse_edges_idx << $clog2(EDGE_SIZE));
			end
			SEND_EDGE_WAIT: begin
				read_command_out_latched.valid    <= 1'b0;
				read_command_out_latched.command  <= INVALID; // just zero it out
				read_command_out_latched.address  <= 64'h0000_0000_0000_0000;
				read_command_out_latched.size     <= 12'h000;
				read_command_out_latched.cmd 	  <= 0;
				src_cacheline_sent		<=  0;
				dest_cacheline_sent		<=  0;
				weight_cacheline_sent	<=  0;
				request_size <= 0;
				remainder <= (edge_next_offest & ADDRESS_MOD_MASK);
				aligned	  <= (edge_next_offest & ADDRESS_ALIGN_MASK);
			end
			CALC_EDGE_REQ_SIZE: begin
				if(|remainder) begin // misaligned access
					request_size <= CACHELINE_SIZE; // bring the whole cacheline

					if(edge_num_counter >= ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE))) begin
						edge_num_counter <= edge_num_counter - ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE));
						read_command_out_latched.cmd.real_size <= ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE));
					end
					else if (edge_num_counter < ((CACHELINE_SIZE - remainder) >> $clog2(EDGE_SIZE))) begin
						edge_num_counter <= 0;
						read_command_out_latched.cmd.real_size <= edge_num_counter;
					end
				end else begin
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

				read_command_out_latched.cmd.cacheline_offest <= (remainder >> $clog2(EDGE_SIZE));
				read_command_out_latched.cmd.cu_id    		<= CU_ID;
				read_command_out_latched.cmd.cmd_type 		<= CMD_READ;
			end
			SEND_EDGE_IDLE: begin
			end
			SEND_EDGE_INV_SRC: begin
				if(~src_cacheline_sent) begin
					src_cacheline_sent		<=  1;

					read_command_out_latched.valid    <= 1'b1;
					read_command_out_latched.command  <= READ_CL_NA; // just zero it out
					read_command_out_latched.address  <= wed_request_in_latched.wed.inverse_edges_array_src + aligned;
					read_command_out_latched.size     <= request_size;

					read_command_out_latched.cmd.vertex_struct 	<= INV_EDGE_ARRAY_SRC;
				end
			end
			SEND_EDGE_INV_DEST: begin
				if(~dest_cacheline_sent) begin
					dest_cacheline_sent		<=  1;

					read_command_out_latched.valid    <= 1'b1;
					read_command_out_latched.command  <= READ_CL_NA; // just zero it out
					read_command_out_latched.address  <= wed_request_in_latched.wed.inverse_edges_array_dest + aligned;
					read_command_out_latched.size     <= request_size;

					read_command_out_latched.cmd.vertex_struct 	<= INV_EDGE_ARRAY_DEST;
				end
			end
			SEND_EDGE_INV_WEIGHT: begin
				if(~weight_cacheline_sent) begin
					weight_cacheline_sent		<=  1;

					read_command_out_latched.valid    <= 1'b1;
					read_command_out_latched.command  <= READ_CL_NA; // just zero it out
					read_command_out_latched.address  <= wed_request_in_latched.wed.inverse_edges_array_weight + aligned;
					read_command_out_latched.size     <= request_size;

					read_command_out_latched.cmd.vertex_struct 	<= INV_EDGE_ARRAY_WEIGHT;

					if(|remainder)
						edge_next_offest <= edge_next_offest + (CACHELINE_SIZE-remainder);
					else
						edge_next_offest <= edge_next_offest + CACHELINE_SIZE;
				end
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

////////////////////////////////////////////////////////////////////////////
//Read Vertex data into registers
////////////////////////////////////////////////////////////////////////////

	cu_cacheline_stream cu_cacheline_stream_inverse_src(
		.clock(clock),
		.rstn(rstn),
		.enabled         (enabled),
		.start_shift	 (start_shift),
		.read_data_0_in  (read_data_0_in_latched),
		.read_data_1_in  (read_data_1_in_latched),
		.vertex_struct   (INV_EDGE_ARRAY_SRC),
		.vertex       (src_cacheline),
		.pending      (src_cacheline_pending),
		.valid		  (src_cacheline_ready)
	);

	cu_cacheline_stream cu_cacheline_stream_inverse_dest(
		.clock(clock),
		.rstn(rstn),
		.enabled         (enabled),
		.start_shift	 (start_shift),
		.read_data_0_in  (read_data_0_in_latched),
		.read_data_1_in  (read_data_1_in_latched),
		.vertex_struct   (INV_EDGE_ARRAY_DEST),
		.vertex       	(dest_cacheline),
		.pending      	(dest_cacheline_pending),
		.valid 			(dest_cacheline_ready)
	);

	cu_cacheline_stream cu_cacheline_stream_inverse_weight(
		.clock(clock),
		.rstn(rstn),
		.enabled         	(enabled),
		.start_shift	(start_shift),
		.read_data_0_in  (read_data_0_in_latched),
		.read_data_1_in  (read_data_1_in_latched),
		.vertex_struct   (INV_EDGE_ARRAY_WEIGHT),
		.vertex       (weight_cacheline),
		.pending      (weight_cacheline_pending),
		.valid 		  (weight_cacheline_ready)
	);


////////////////////////////////////////////////////////////////////////////
//Read Vertex registers into edge job queue
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Vertices
////////////////////////////////////////////////////////////////////////////
	assign fill_edge_buffer_pending = src_cacheline_pending || dest_cacheline_pending || weight_cacheline_pending;
	assign send_request_ready       = ~read_buffer_status.alfull && ~fill_edge_buffer_pending && ~edge_buffer_status.alfull && (|edge_num_counter) && ~(|response_counter)
		&& wed_request_in_latched.valid && vertex_job_latched.valid;
	assign fill_edge_buffer = src_cacheline_ready && dest_cacheline_ready && weight_cacheline_ready;
	assign start_shift      = fill_edge_buffer_pending && ~(|response_counter);


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_variable    	 <= 0;
			edge_id_counter 	 <= 0;
		end
		else begin
			if(fill_edge_buffer) begin
				edge_id_counter    			<= edge_id_counter + 1;
				edge_variable.valid 		<= fill_edge_buffer;
				edge_variable.id 			<= edge_id_counter;
				edge_variable.src 	        <= src_cacheline;
				edge_variable.dest 	        <= dest_cacheline;
				edge_variable.weight 	    <= weight_cacheline;

			end else begin
				edge_variable  <= 0;
			end
		end
	end

	// if the edge has no in/out neighbors don't schedule it
	assign push_edge = (edge_variable.valid);

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_job_counter_pushed <= 0;
		end else begin
			if(vertex_job_latched.valid)begin
				if(push_edge)begin
					edge_job_counter_pushed <= edge_job_counter_pushed + 1;
				end
				if(edge_job_counter_pushed == vertex_job_latched.inverse_out_degree)begin
					edge_job_counter_pushed <= 0;
				end
			end
		end
	end

	fifo  #(
		.WIDTH($bits(EdgeInterface)),
		.DEPTH((256))
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