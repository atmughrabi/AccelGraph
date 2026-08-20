// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_edge_data_read_control.sv
// Create : 2019-10-31 12:13:26
// Revise : 2019-11-03 13:06:08
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_data_read_extract_control #(
	parameter CU_ID_X = 1,
	parameter CU_ID_Y = 1
) (
	input  logic             clock         , // Clock
	input  logic             rstn          ,
	input  logic             enabled_in    ,
	input  ReadWriteDataLine read_data_0_in,
	input  ReadWriteDataLine read_data_1_in,
	output EdgeDataRead      edge_data
);

	//output latched
	EdgeDataRead edge_data_variable    ;
	EdgeDataRead edge_data_variable_reg;
	logic        enabled;

	// Hold the current pair and the next tag during the one-cycle half skew.
	localparam PAIR_BUFFER_SIZE = 2;

	ReadWriteDataLinePayload read_data_0_buffer[0:PAIR_BUFFER_SIZE-1];
	ReadWriteDataLinePayload read_data_1_buffer[0:PAIR_BUFFER_SIZE-1];
	logic [             0:7] read_data_buffer_tag[0:PAIR_BUFFER_SIZE-1];
	logic                   read_data_0_ready [0:PAIR_BUFFER_SIZE-1];
	logic                   read_data_1_ready [0:PAIR_BUFFER_SIZE-1];

	integer pair_emit_index;
	integer read_data_0_buffer_index;
	integer read_data_1_buffer_index;
	integer i;

///////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled <= 0;
		end else begin
			enabled <= enabled_in;
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data.valid <= 0;
		end else begin
			if(enabled) begin
				edge_data.valid <= edge_data_variable.valid;
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_data.payload <= edge_data_variable.payload;
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_variable.valid <= 0;
		end else begin
			if(edge_data_variable_reg.valid)begin
				edge_data_variable.valid <= edge_data_variable_reg.valid;
			end else begin
				edge_data_variable.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_data_variable.payload.cu_id_x <= edge_data_variable_reg.payload.cu_id_x;
		edge_data_variable.payload.cu_id_y <= edge_data_variable_reg.payload.cu_id_y;
		edge_data_variable.payload.data    <= swap_endianness_data_read(edge_data_variable_reg.payload.data);
		edge_data_variable.payload.src     <= edge_data_variable_reg.payload.src;
		edge_data_variable.payload.dest    <= edge_data_variable_reg.payload.dest;
	end


////////////////////////////////////////////////////////////////////////////
//data extracton logic
////////////////////////////////////////////////////////////////////////////

	always_comb begin
		pair_emit_index = -1;
		for (i = PAIR_BUFFER_SIZE-1; i >= 0; i--) begin
			if(read_data_0_ready[i] && read_data_1_ready[i])
				pair_emit_index = i;
		end

		read_data_0_buffer_index = -1;
		if(read_data_0_in.valid) begin
			for (i = PAIR_BUFFER_SIZE-1; i >= 0; i--) begin
				if((read_data_0_ready[i] || read_data_1_ready[i]) &&
					(read_data_buffer_tag[i] == read_data_0_in.payload.cmd.tag))
					read_data_0_buffer_index = i;
			end
			if(read_data_0_buffer_index < 0) begin
				if((~read_data_0_ready[1] && ~read_data_1_ready[1]) ||
					(pair_emit_index == 1))
					read_data_0_buffer_index = 1;
				if((~read_data_0_ready[0] && ~read_data_1_ready[0]) ||
					(pair_emit_index == 0))
					read_data_0_buffer_index = 0;
			end
		end

		read_data_1_buffer_index = -1;
		if(read_data_1_in.valid) begin
			if(read_data_0_in.valid &&
				(read_data_0_in.payload.cmd.tag == read_data_1_in.payload.cmd.tag)) begin
				read_data_1_buffer_index = read_data_0_buffer_index;
			end else begin
				for (i = PAIR_BUFFER_SIZE-1; i >= 0; i--) begin
					if((read_data_0_ready[i] || read_data_1_ready[i]) &&
						(read_data_buffer_tag[i] == read_data_1_in.payload.cmd.tag) &&
						~(read_data_0_in.valid && (i == read_data_0_buffer_index)))
						read_data_1_buffer_index = i;
				end
				if(read_data_1_buffer_index < 0) begin
					if(((~read_data_0_ready[1] && ~read_data_1_ready[1]) ||
						(pair_emit_index == 1)) &&
						~(read_data_0_in.valid && (read_data_0_buffer_index == 1)))
						read_data_1_buffer_index = 1;
					if(((~read_data_0_ready[0] && ~read_data_1_ready[0]) ||
						(pair_emit_index == 0)) &&
						~(read_data_0_in.valid && (read_data_0_buffer_index == 0)))
						read_data_1_buffer_index = 0;
				end
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_variable_reg.valid <= 0;
			for (i = 0; i < PAIR_BUFFER_SIZE; i++) begin
				read_data_0_buffer[i] <= 0;
				read_data_1_buffer[i] <= 0;
				read_data_buffer_tag[i] <= 0;
				read_data_0_ready[i] <= 0;
				read_data_1_ready[i] <= 0;
			end
		end else begin
			edge_data_variable_reg.valid <= 0;

			if(enabled && (pair_emit_index >= 0)) begin
				edge_data_variable_reg.valid <= 1;
				for (i = 0; i < CACHELINE_DATA_READ_NUM_HF; i++) begin
					if(read_data_0_buffer[pair_emit_index].cmd.cacheline_offset == i)
						edge_data_variable_reg.payload.data <= read_data_0_buffer[pair_emit_index].data[DATA_SIZE_READ_BITS*i +: DATA_SIZE_READ_BITS];
				end
				for (i = 0; i < CACHELINE_DATA_READ_NUM_HF; i++) begin
					if(read_data_0_buffer[pair_emit_index].cmd.cacheline_offset == (i+CACHELINE_DATA_READ_NUM_HF))
						edge_data_variable_reg.payload.data <= read_data_1_buffer[pair_emit_index].data[DATA_SIZE_READ_BITS*i +: DATA_SIZE_READ_BITS];
				end
				edge_data_variable_reg.payload.cu_id_x <= read_data_0_buffer[pair_emit_index].cmd.cu_id_x;
				edge_data_variable_reg.payload.cu_id_y <= read_data_0_buffer[pair_emit_index].cmd.cu_id_y;
				edge_data_variable_reg.payload.dest <= read_data_0_buffer[pair_emit_index].cmd.address_offset;
				edge_data_variable_reg.payload.src <= read_data_0_buffer[pair_emit_index].cmd.aux_data;
				read_data_0_ready[pair_emit_index] <= 0;
				read_data_1_ready[pair_emit_index] <= 0;
			end

			if(enabled && read_data_0_in.valid && (read_data_0_buffer_index >= 0)) begin
				read_data_0_buffer[read_data_0_buffer_index] <= read_data_0_in.payload;
				read_data_buffer_tag[read_data_0_buffer_index] <= read_data_0_in.payload.cmd.tag;
				read_data_0_ready[read_data_0_buffer_index] <= 1;
			end

			if(enabled && read_data_1_in.valid && (read_data_1_buffer_index >= 0)) begin
				read_data_1_buffer[read_data_1_buffer_index] <= read_data_1_in.payload;
				read_data_buffer_tag[read_data_1_buffer_index] <= read_data_1_in.payload.cmd.tag;
				read_data_1_ready[read_data_1_buffer_index] <= 1;
			end
		end
	end

endmodule