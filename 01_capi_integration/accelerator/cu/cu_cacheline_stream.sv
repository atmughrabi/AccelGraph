import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_cacheline_stream (
	input logic clock,    // Clock
	input logic rstn,
	input logic enabled,
	input logic fill_vertex_buffer,
	input ReadWriteDataLine 	read_data_0_in,
	input ReadWriteDataLine 	read_data_1_in,
	input ResponseBufferLine 	read_response_in,
	input vertex_struct_type	vertex_struct,
	input logic [0:7]  shift_limit,
	output logic [0:(CACHELINE_SIZE_BITS-1)] cacheline,
	output logic cacheline_ready
);

	logic [0:7] vertex_shift_counter;
	logic seek_flag;
	logic [0:7] shift_seek;


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cacheline <= 0;
			cacheline_ready <= 1'b0;
			vertex_shift_counter <= 0;
			seek_flag <= 1'b0;
			shift_seek <= 0;
		end
		else begin
			if(enabled)begin
				if (read_data_0_in.cmd.vertex_struct == vertex_struct && read_data_0_in.valid) begin
					cacheline [0:511]	<= read_data_0_in.data;
					shift_seek			<= read_data_0_in.cmd.cacheline_offest;
				end

				if (read_data_1_in.cmd.vertex_struct == vertex_struct && read_data_1_in.valid) begin
					cacheline[512:(CACHELINE_SIZE_BITS-1)]	<= read_data_1_in.data;
					shift_seek								<= read_data_0_in.cmd.cacheline_offest;
				end

				if(fill_vertex_buffer && (vertex_shift_counter < shift_limit))begin
					vertex_shift_counter 	<= vertex_shift_counter + 1;
					cacheline 				<= {{VERTEX_SIZE_BITS{1'b0}},cacheline[0:(CACHELINE_SIZE_BITS-1-VERTEX_SIZE_BITS)]};
				end

				if (vertex_shift_counter >= shift_limit) begin
					cacheline <= 0;
					cacheline_ready <= 1'b0;
					vertex_shift_counter <= 0;
				end

				if (read_response_in.valid && read_response_in.cmd.vertex_struct == vertex_struct)begin
					seek_flag 		<= 1'b1;
					cacheline 	   	<= swap_endianness_full_cacheline128(cacheline);
				end

				if(seek_flag) begin
					seek_flag  			<= 1'b0;
					cacheline_ready 	<= 1'b1;
					shift_seek			<= 0;
					cacheline 	   		<= seek_cacheline(shift_seek, cacheline);
				end

			end else begin
				cacheline <= 0;
				cacheline_ready <= 1'b0;
				vertex_shift_counter <= 0;
				seek_flag <= 1'b0;
				shift_seek			<= 0;
			end
		end
	end

endmodule