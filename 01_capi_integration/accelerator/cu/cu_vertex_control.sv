import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_control (
	input logic clock,    // Clock
	input logic rstn,
	input logic enabled,
	input WEDInterface 	wed_request_in,
	input ResponseBufferLine read_response_in,
	input ReadWriteDataLine read_data_0_in,
	input ReadWriteDataLine read_data_1_in,
	input BufferStatus read_buffer_status,
	input logic vertex_request,
	output CommandBufferLine read_command_out,
	output BufferStatus vertex_buffer_status,
	output VertexInterface vertex
);

	//output latched
	BufferStatus vertex_buffer_status_latched;
	VertexInterface vertex_latched;
	CommandBufferLine read_command_out_latched;

	//input lateched
	WEDInterface wed_request_in_latched;
	ResponseBufferLine read_response_in_latched;
	ReadWriteDataLine read_data_0_in_latched;
	ReadWriteDataLine read_data_1_in_latched;
	BufferStatus 	  read_buffer_status_latched;
	logic vertex_request_latched;

	// internal registers to track logic
	logic [0:11] request_size;
	logic send_request_ready;
	logic [0:7]  response_counter;
	logic [0:31] vertex_next_offest;
	logic [0:31] vertex_num_counter;
	logic [0:31] vertex_id_counter;
	VertexInterface vertex_variable;

	logic fill_vertex_buffer;
	logic in_degree_ready;
	logic out_degree_ready;
	logic edge_idx_ready;
	logic inverse_in_degree_ready;
	logic inverse_out_degree_ready;
	logic inverse_edge_idx_ready;

	logic [0:1023] in_degree_cacheline;
	logic [0:1023] out_degree_cacheline;
	logic [0:1023] edges_idx_degree_cacheline;
	logic [0:1023] inverse_in_degree_cacheline;
	logic [0:1023] inverse_out_degree_cacheline;
	logic [0:1023] inverse_edges_idx_degree_cacheline;

	logic in_degree_cacheline_ready;
	logic out_degree_cacheline_ready;
	logic edges_idx_degree_cacheline_ready;
	logic inverse_in_degree_cacheline_ready;
	logic inverse_out_degree_cacheline_ready;
	logic inverse_edges_idx_degree_cacheline_ready;

	vertex_struct_state current_state, next_state;

////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_buffer_status <= 4'b0001;
			vertex 	  			 <= 0;
			read_command_out  	 <= 0;
		end else begin
			vertex_buffer_status 	<= vertex_buffer_status_latched;
			vertex 	  			 	<= vertex_latched;
			read_command_out  		<= read_command_out_latched;
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
			read_buffer_status_latched	<= 0;
			vertex_request_latched		<= 0;
		end else begin
			wed_request_in_latched 		<= wed_request_in;
			read_response_in_latched	<= read_response_in;
			read_data_0_in_latched		<= read_data_0_in;
			read_data_1_in_latched		<= read_data_1_in;
			read_buffer_status_latched	<= read_buffer_status;
			vertex_request_latched		<= vertex_request;
		end
	end

////////////////////////////////////////////////////////////////////////////
//1. Generate Read Commands to obtain vertex structural info
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= SEND_VERTEX_RESET;
		else
			current_state <= next_state;
	end // always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			SEND_VERTEX_RESET: begin
				if(wed_request_in_latched.valid)
					next_state = SEND_VERTEX_INIT;
				else
					next_state = SEND_VERTEX_RESET;
			end
			SEND_VERTEX_INIT: begin
				next_state = SEND_VERTEX_IDLE;
			end
			SEND_VERTEX_IDLE: begin
				if(send_request_ready )
					next_state = CALC_VERTEX_REQ_SIZE;
				else
					next_state = SEND_VERTEX_IDLE;
			end
			CALC_VERTEX_REQ_SIZE: begin
				next_state = SEND_VERTEX_IN_DEGREE;
			end
			SEND_VERTEX_IN_DEGREE: begin
				next_state = SEND_VERTEX_OUT_DEGREE;
			end
			SEND_VERTEX_OUT_DEGREE: begin
				next_state = SEND_VERTEX_EDGES_IDX;
			end
			SEND_VERTEX_EDGES_IDX: begin
				next_state = SEND_VERTEX_INV_IN_DEGREE;
			end
			SEND_VERTEX_INV_IN_DEGREE: begin
				next_state = SEND_VERTEX_INV_OUT_DEGREE;
			end
			SEND_VERTEX_INV_OUT_DEGREE: begin
				next_state = SEND_VERTEX_INV_EDGES_IDX;
			end
			SEND_VERTEX_INV_EDGES_IDX: begin
				next_state = SEND_VERTEX_IDLE;
			end
		endcase
	end // always_comb

	always_ff @(posedge clock) begin
		case (current_state)
			SEND_VERTEX_RESET: begin
				read_command_out_latched.valid    <= 1'b0;
				read_command_out_latched.command  <= INVALID; // just zero it out
				read_command_out_latched.address  <= 64'h0000_0000_0000_0000;
				read_command_out_latched.size     <= 12'h000;

				read_command_out_latched.cmd.cu_id    <= INVALID_ID;
				read_command_out_latched.cmd.cmd_type <= CMD_INVALID;
				read_command_out_latched.cmd.vertex_struct <= STRUCT_INVALID;

				request_size 			<= 0;
				vertex_next_offest  	<= 0;
			end
			SEND_VERTEX_INIT: begin
				vertex_num_counter <= wed_request_in_latched.wed.num_vertices;
			end
			SEND_VERTEX_IDLE: begin
				read_command_out_latched.valid    <= 1'b0;
				read_command_out_latched.command  <= INVALID; // just zero it out
				read_command_out_latched.address  <= 64'h0000_0000_0000_0000;
				read_command_out_latched.size     <= 12'h000;

				read_command_out_latched.cmd.cu_id    <= INVALID_ID;
				read_command_out_latched.cmd.cmd_type <= CMD_INVALID;
				read_command_out_latched.cmd.vertex_struct <= STRUCT_INVALID;

				request_size <= 0;
			end
			CALC_VERTEX_REQ_SIZE: begin
				if(vertex_num_counter >= CACHELINE_VERTEX_NUM)begin
					request_size <= 128;
					vertex_num_counter <= vertex_num_counter - CACHELINE_VERTEX_NUM;
				end
				else if (vertex_num_counter < CACHELINE_VERTEX_NUM) begin
					request_size <= (vertex_num_counter << $clog2(VERTEX_SIZE));
					vertex_num_counter <= 0;
				end
			end
			SEND_VERTEX_IN_DEGREE: begin
			
				read_command_out_latched.valid    <= 1'b1;
				read_command_out_latched.command  <= READ_CL_NA; // just zero it out
				read_command_out_latched.address  <= wed_request_in_latched.wed.vertex_in_degree + vertex_next_offest;
				read_command_out_latched.size     <= request_size;

				read_command_out_latched.cmd.cu_id    		<= VERTEX_CONTROL_ID;
				read_command_out_latched.cmd.cmd_type 		<= CMD_READ;
				read_command_out_latched.cmd.vertex_struct 	<= IN_DEGREE;
			end
			SEND_VERTEX_OUT_DEGREE: begin
				read_command_out_latched.valid    <= 1'b1;
				read_command_out_latched.command  <= READ_CL_NA; // just zero it out
				read_command_out_latched.address  <= wed_request_in_latched.wed.vertex_out_degree + vertex_next_offest;
				read_command_out_latched.size     <= request_size;

				read_command_out_latched.cmd.cu_id    		<= VERTEX_CONTROL_ID;
				read_command_out_latched.cmd.cmd_type 		<= CMD_READ;
				read_command_out_latched.cmd.vertex_struct 	<= OUT_DEGREE;
			end
			SEND_VERTEX_EDGES_IDX: begin
				read_command_out_latched.valid    <= 1'b1;
				read_command_out_latched.command  <= READ_CL_NA; // just zero it out
				read_command_out_latched.address  <= wed_request_in_latched.wed.vertex_edges_idx + vertex_next_offest;
				read_command_out_latched.size     <= request_size;

				read_command_out_latched.cmd.cu_id    		<= VERTEX_CONTROL_ID;
				read_command_out_latched.cmd.cmd_type 		<= CMD_READ;
				read_command_out_latched.cmd.vertex_struct 	<= EDGES_IDX;
			end
			SEND_VERTEX_INV_IN_DEGREE: begin
				read_command_out_latched.valid    <= 1'b1;
				read_command_out_latched.command  <= READ_CL_NA; // just zero it out
				read_command_out_latched.address  <= wed_request_in_latched.wed.inverse_vertex_in_degree + vertex_next_offest;
				read_command_out_latched.size     <= request_size;

				read_command_out_latched.cmd.cu_id    		<= VERTEX_CONTROL_ID;
				read_command_out_latched.cmd.cmd_type 		<= CMD_READ;
				read_command_out_latched.cmd.vertex_struct 	<= INV_IN_DEGREE;
			end
			SEND_VERTEX_INV_OUT_DEGREE: begin
				read_command_out_latched.valid    <= 1'b1;
				read_command_out_latched.command  <= READ_CL_NA; // just zero it out
				read_command_out_latched.address  <= wed_request_in_latched.wed.inverse_vertex_out_degree + vertex_next_offest;
				read_command_out_latched.size     <= request_size;

				read_command_out_latched.cmd.cu_id    		<= VERTEX_CONTROL_ID;
				read_command_out_latched.cmd.cmd_type 		<= CMD_READ;
				read_command_out_latched.cmd.vertex_struct 	<= INV_OUT_DEGREE;
			end
			SEND_VERTEX_INV_EDGES_IDX: begin
				read_command_out_latched.valid    <= 1'b1;
				read_command_out_latched.command  <= READ_CL_NA; // just zero it out
				read_command_out_latched.address  <= wed_request_in_latched.wed.inverse_vertex_edges_idx + vertex_next_offest;
				read_command_out_latched.size     <= request_size;

				read_command_out_latched.cmd.cu_id    		<= VERTEX_CONTROL_ID;
				read_command_out_latched.cmd.cmd_type 		<= CMD_READ;
				read_command_out_latched.cmd.vertex_struct 	<= INV_EDGES_IDX;

				vertex_next_offest <= vertex_next_offest + CACHELINE_SIZE;
			end
		endcase
	end // always_ff @(posedge clock)
////////////////////////////////////////////////////////////////////////////
//response tracking logic
////////////////////////////////////////////////////////////////////////////
	
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			response_counter <= 0;
		else begin
			if ( read_command_out_latched.valid) begin
				response_counter  <= response_counter + 1;
			end else if (read_response_in.valid) begin
				response_counter  <= response_counter - 1;
			end else begin
				response_counter  <= response_counter;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//Read Vertex data into registers
////////////////////////////////////////////////////////////////////////////



	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			in_degree_cacheline <= 0;
		else begin
			if (read_data_0_in.cmd.vertex_struct == IN_DEGREE) begin
				in_degree_cacheline [0:511]   <= read_data_0_in.data;
			end
			if (read_data_1_in.cmd.vertex_struct == IN_DEGREE) begin
				in_degree_cacheline[512:1023] <= read_data_1_in.data;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			out_degree_cacheline <= 0;
		else begin
			if (read_data_0_in.cmd.vertex_struct == OUT_DEGREE) begin
				out_degree_cacheline [0:511]   <= read_data_0_in.data;
			end
			if (read_data_1_in.cmd.vertex_struct == OUT_DEGREE) begin
				out_degree_cacheline[512:1023] <= read_data_1_in.data;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			edges_idx_degree_cacheline <= 0;
		else begin
			if (read_data_0_in.cmd.vertex_struct == EDGES_IDX) begin
				edges_idx_degree_cacheline [0:511]   <= read_data_0_in.data;
			end
			if (read_data_1_in.cmd.vertex_struct == EDGES_IDX) begin
				edges_idx_degree_cacheline[512:1023] <= read_data_1_in.data;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			inverse_in_degree_cacheline <= 0;
		else begin
			if (read_data_0_in.cmd.vertex_struct == INV_IN_DEGREE) begin
				inverse_in_degree_cacheline [0:511]   <= read_data_0_in.data;
			end
			if (read_data_1_in.cmd.vertex_struct == INV_IN_DEGREE) begin
				inverse_in_degree_cacheline[512:1023] <= read_data_1_in.data;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			inverse_out_degree_cacheline <= 0;
		else begin
			if (read_data_0_in.cmd.vertex_struct == INV_OUT_DEGREE) begin
				inverse_out_degree_cacheline [0:511]   <= read_data_0_in.data;
			end
			if (read_data_1_in.cmd.vertex_struct == INV_OUT_DEGREE) begin
				inverse_out_degree_cacheline[512:1023] <= read_data_1_in.data;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			inverse_edges_idx_degree_cacheline <= 0;
		else begin
			if (read_data_0_in.cmd.vertex_struct == INV_EDGES_IDX) begin
				inverse_edges_idx_degree_cacheline [0:511]   <= read_data_0_in.data;
			end
			if (read_data_1_in.cmd.vertex_struct == INV_EDGES_IDX) begin
				inverse_edges_idx_degree_cacheline[512:1023] <= read_data_1_in.data;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Read Vertex registers into vertex
////////////////////////////////////////////////////////////////////////////

	assign in_degree_cacheline_ready = (|in_degree_cacheline [0:511]) && (|in_degree_cacheline[512:1023]);
	assign out_degree_cacheline_ready  = (|out_degree_cacheline [0:511]) && (|out_degree_cacheline[512:1023]);
	assign edges_idx_degree_cacheline_ready = (|edges_idx_degree_cacheline [0:511]) && (|edges_idx_degree_cacheline[512:1023]);
	assign inverse_in_degree_cacheline_ready  = (|inverse_in_degree_cacheline [0:511]) && (|inverse_in_degree_cacheline[512:1023]);
	assign inverse_out_degree_cacheline_ready  = (|inverse_out_degree_cacheline [0:511]) && (|inverse_out_degree_cacheline[512:1023]);
	assign inverse_edges_idx_degree_cacheline_ready  = (|inverse_edges_idx_degree_cacheline [0:511]) && (|inverse_edges_idx_degree_cacheline[512:1023]);

////////////////////////////////////////////////////////////////////////////
//Buffers Vertcies
////////////////////////////////////////////////////////////////////////////

	assign send_request_ready = vertex_buffer_status_latched.empty && (|vertex_num_counter) && ~(|response_counter) && wed_request_in_latched.valid;
	assign fill_vertex_buffer = 0;

	fifo  #(
		.WIDTH($bits(VertexInterface)),
		.DEPTH((CACHELINE_VERTEX_NUM))
	)read_response_buffer_fifo_instant(
		.clock(clock),
		.rstn(rstn),

		.push(fill_vertex_buffer),
		.data_in(vertex_variable),
		.full(vertex_buffer_status_latched.full),
		.alFull(vertex_buffer_status_latched.alfull),

		.pop(vertex_request_latched),
		.valid(vertex_buffer_status_latched.valid),
		.data_out(vertex_latched),
		.empty(vertex_buffer_status_latched.empty)
	);



endmodule