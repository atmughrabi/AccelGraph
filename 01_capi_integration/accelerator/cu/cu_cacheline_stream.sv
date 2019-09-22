import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_cacheline_stream (
	input logic clock,    // Clock
	input logic rstn,
	input logic enabled,
	input logic start_shift,
	input ReadWriteDataLine 	read_data_0_in,
	input ReadWriteDataLine 	read_data_1_in,
	input vertex_struct_type	vertex_struct,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex,
	output logic pending,
	output logic valid
);

	logic [0:CACHELINE_INT_COUNTER_BITS]  shift_limit;
	logic [0:CACHELINE_INT_COUNTER_BITS-1] addr_counter;
	logic [0:CACHELINE_INT_COUNTER_BITS] shift_counter;
	logic [0:CACHELINE_INT_COUNTER_BITS] shift_seek_latched;
	logic [0:CACHELINE_INT_COUNTER_BITS]  shift_limit_latched;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_latched;
	logic address;
	logic we;
	logic valid_internal;
	logic pending_latched;
	logic [0:511] read_data_in;

	assign vertex         = swap_endianness_word(vertex_latched);
	assign valid_internal = (shift_counter < shift_limit) && start_shift && enabled;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			shift_counter 	<= 0;
			addr_counter    <= 0;
			shift_limit     <= 0;
			pending     	<= 0;
		end
		else begin
			if(enabled)begin

				valid <= valid_internal;
				if(we)begin
					shift_counter <= 0;
					addr_counter  <= shift_seek_latched;
					shift_limit   <= shift_limit_latched;
					pending 	  <= pending_latched;
				end

				if(valid)begin
					if((shift_counter >= shift_limit)) begin
						pending 	  <= 0;
					end
				end

				if(valid_internal)begin
					if((shift_counter < shift_limit)) begin
						shift_counter 	<= shift_counter + 1;
						addr_counter    <= addr_counter + 1;
					end else begin
						pending 	  <= 0;
						shift_counter <= 0;
						addr_counter  <= 0;
						shift_limit   <= 0;
					end
				end

			end else begin
				shift_counter <= 0;
				addr_counter  <= 0;
				shift_limit   <= 0;
				pending 	  <= 0;
			end
		end
	end

	always_comb begin
		we = 0;
		address = 0;
		read_data_in = 0;
		shift_seek_latched = 0;
		shift_limit_latched = 0;
		pending_latched	= 0;
		if((read_data_0_in.cmd.vertex_struct == vertex_struct) && read_data_0_in.valid)begin
			we = 1;
			address = 0;
			read_data_in = read_data_0_in.data;
			shift_seek_latched = read_data_0_in.cmd.cacheline_offest;
			shift_limit_latched = read_data_0_in.cmd.real_size;
			pending_latched = 1;
		end else if((read_data_1_in.cmd.vertex_struct == vertex_struct) && read_data_1_in.valid)begin
			we = 1;
			address = 1;
			read_data_in = read_data_1_in.data;
			shift_seek_latched = read_data_1_in.cmd.cacheline_offest;
			shift_limit_latched = read_data_1_in.cmd.real_size;
			pending_latched = 1;
		end
	end

	mixed_width_ram #(
		.WORDS(2),
		.WW(CACHELINE_SIZE_BITS/2),
		.RW(VERTEX_SIZE_BITS)
	)cacheline_instant
	(
		.clock( clock ),
		.we( we ),
		.wr_addr(address),
		.data_in(read_data_in),

		.rd_addr(addr_counter),
		.data_out(vertex_latched)
	);

endmodule