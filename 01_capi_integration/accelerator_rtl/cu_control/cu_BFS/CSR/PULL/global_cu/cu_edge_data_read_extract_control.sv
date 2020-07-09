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
	//input lateched
	ReadWriteDataLine read_data_0_in_latched   ;
	ReadWriteDataLine read_data_0_in_latched_S2;
	ReadWriteDataLine read_data_1_in_latched   ;
	logic [ 0:7]      offset_data_0            ;
	cu_id_t           cu_id_x                  ;
	cu_id_t           cu_id_y                  ;
	logic             enabled                  ;
	logic [0:63]      address_offset           ;

	logic [           0:CACHELINE_SIZE_BITS-1] read_data_in;
	logic [0:(CACHELINE_DATA_READ_NUM_BITS-1)] address_rd  ;

	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_DATA_VARIABLE_0      ;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_DATA_VARIABLE_1      ;
	logic                                reg_DATA_VARIABLE_0_ready;
	logic                                reg_DATA_VARIABLE_1_ready;
	logic                                reg_DATA_VARIABLE_ready  ;

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
//drive inputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_0_in_latched.valid    <= 0;
			read_data_0_in_latched_S2.valid <= 0;
			read_data_1_in_latched.valid    <= 0;
		end else begin
			if(enabled) begin
				read_data_0_in_latched_S2.valid <= read_data_0_in.valid;
				read_data_0_in_latched.valid    <= read_data_0_in_latched_S2.valid;
				read_data_1_in_latched.valid    <= read_data_1_in.valid;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_data_0_in_latched_S2.payload <= read_data_0_in.payload;
		read_data_0_in_latched.payload    <= read_data_0_in_latched_S2.payload;
		read_data_1_in_latched.payload    <= read_data_1_in.payload;
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

////////////////////////////////////////////////////////////////////////////
//data request read logic
////////////////////////////////////////////////////////////////////////////

	assign offset_data_0 = read_data_0_in_latched.payload.cmd.cacheline_offset;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_in   <= 0;
			address_rd     <= 0;
			cu_id_x        <= 0;
			cu_id_y        <= 0;
			address_offset <= 0;
		end else begin
			if(enabled) begin
				if(read_data_0_in_latched.valid && read_data_1_in_latched.valid)begin
					read_data_in[0:CACHELINE_SIZE_BITS_HF-1]                   <= read_data_0_in_latched.payload.data;
					read_data_in[CACHELINE_SIZE_BITS_HF:CACHELINE_SIZE_BITS-1] <= read_data_1_in_latched.payload.data;
					cu_id_x                                                    <= read_data_0_in_latched.payload.cmd.cu_id_x;
					cu_id_y                                                    <= read_data_0_in_latched.payload.cmd.cu_id_y;
					address_rd                                                 <= offset_data_0;
					address_offset                                             <= read_data_0_in_latched.payload.cmd.address_offset;
				end else begin
					read_data_in   <= 0;
					address_rd     <= 0;
					cu_id_x        <= 0;
					cu_id_y        <= 0;
					address_offset <= 0;
				end
			end
		end
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
		edge_data_variable.payload.dest    <= edge_data_variable_reg.payload.dest;
	end


////////////////////////////////////////////////////////////////////////////
//data extracton logic
////////////////////////////////////////////////////////////////////////////

	assign reg_DATA_VARIABLE_ready = reg_DATA_VARIABLE_0_ready && reg_DATA_VARIABLE_1_ready;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			reg_DATA_VARIABLE_0          <= 0;
			reg_DATA_VARIABLE_0_ready    <= 0;
			reg_DATA_VARIABLE_1          <= 0;
			reg_DATA_VARIABLE_1_ready    <= 0;
			edge_data_variable_reg.valid <= 0;
		end else begin
			if(read_data_0_in_latched.valid) begin
				reg_DATA_VARIABLE_0       <= read_data_0_in_latched.payload.data;
				reg_DATA_VARIABLE_0_ready <= 1;
			end

			if(read_data_1_in_latched.valid) begin
				reg_DATA_VARIABLE_1       <= read_data_1_in_latched.payload.data;
				reg_DATA_VARIABLE_1_ready <= 1;
			end

			if(reg_DATA_VARIABLE_ready)begin
				edge_data_variable_reg.valid <= reg_DATA_VARIABLE_ready;

				if(~read_data_0_in_latched.valid)
					reg_DATA_VARIABLE_0_ready <= 0;

				if(~read_data_1_in_latched.valid)
					reg_DATA_VARIABLE_1_ready <= 0;

			end else begin
				edge_data_variable_reg.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		for (i = 0; i < CACHELINE_DATA_READ_NUM_HF; i++) begin
			if(address_rd == i)begin
				edge_data_variable_reg.payload.data <= reg_DATA_VARIABLE_0[DATA_SIZE_READ_BITS*i +: DATA_SIZE_READ_BITS];
			end
		end
		for (i = 0; i < CACHELINE_DATA_READ_NUM_HF; i++) begin
			if(address_rd == (i+CACHELINE_DATA_READ_NUM_HF))begin
				edge_data_variable_reg.payload.data <= reg_DATA_VARIABLE_1[DATA_SIZE_READ_BITS*i +: DATA_SIZE_READ_BITS];
			end
		end
		edge_data_variable_reg.payload.cu_id_x <= cu_id_x;
		edge_data_variable_reg.payload.cu_id_y <= cu_id_y;
		edge_data_variable_reg.payload.dest    <= address_offset;
	end

endmodule