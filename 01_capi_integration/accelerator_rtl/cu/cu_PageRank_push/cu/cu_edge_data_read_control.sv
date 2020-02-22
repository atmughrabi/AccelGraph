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

module cu_edge_data_read_control #(parameter CU_ID = 1) (
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
	ReadWriteDataLine            read_data_0_in_latched   ;
	ReadWriteDataLine            read_data_0_in_latched_S2;
	ReadWriteDataLine            read_data_1_in_latched   ;
	logic [                 0:7] offset_data_0            ;
	logic [0:(EDGE_SIZE_BITS-1)] dest_id                  ;
	cu_id_t                      cu_id                    ;
	logic                        enabled                  ;

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
			read_data_0_in_latched    <= 0;
			read_data_0_in_latched_S2 <= 0;
			read_data_1_in_latched    <= 0;
		end else begin
			if(enabled) begin
				read_data_0_in_latched_S2 <= read_data_0_in;
				read_data_0_in_latched    <= read_data_0_in_latched_S2;
				read_data_1_in_latched    <= read_data_1_in;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data <= 0;
		end else begin
			if(enabled) begin
				edge_data <= edge_data_variable;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//data request read logic
////////////////////////////////////////////////////////////////////////////

	assign offset_data_0 = read_data_0_in_latched.cmd.cacheline_offest;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_in <= 0;
			address_rd   <= 0;
			cu_id        <= 0;
			dest_id      <= 0;
		end else begin
			if(enabled) begin
				if(read_data_0_in_latched.valid && read_data_1_in_latched.valid)begin
					read_data_in[0:CACHELINE_SIZE_BITS_HF-1]                   <= read_data_0_in_latched.data;
					read_data_in[CACHELINE_SIZE_BITS_HF:CACHELINE_SIZE_BITS-1] <= read_data_1_in_latched.data;
					dest_id                                                    <= read_data_0_in_latched.cmd.address_offest[(64-EDGE_SIZE_BITS):63];
					cu_id                                                      <= read_data_0_in_latched.cmd.cu_id;
					address_rd                                                 <= offset_data_0;
				end else begin
					read_data_in <= 0;
					address_rd   <= 0;
					cu_id        <= 0;
					dest_id      <= 0;
				end
			end
		end
	end


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_variable <= 0;
		end else begin
			if(enabled) begin
				if(edge_data_variable_reg.valid)begin
					edge_data_variable.valid <= edge_data_variable_reg.valid;
					edge_data_variable.cu_id <= edge_data_variable_reg.cu_id;
					edge_data_variable.id    <= edge_data_variable_reg.id;
					edge_data_variable.data  <= swap_endianness_data_read(edge_data_variable_reg.data);
				end else begin
					edge_data_variable <= 0;
				end
			end
		end
	end



////////////////////////////////////////////////////////////////////////////
//data extracton logic
////////////////////////////////////////////////////////////////////////////

	assign reg_DATA_VARIABLE_ready = reg_DATA_VARIABLE_0_ready && reg_DATA_VARIABLE_1_ready;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			reg_DATA_VARIABLE_0       <= 0;
			reg_DATA_VARIABLE_0_ready <= 0;
			reg_DATA_VARIABLE_1       <= 0;
			reg_DATA_VARIABLE_1_ready <= 0;
			edge_data_variable_reg    <= 0;
		end else begin
			if(enabled)begin
				if(read_data_0_in_latched.valid) begin
					reg_DATA_VARIABLE_0       <= read_data_0_in_latched.data;
					reg_DATA_VARIABLE_0_ready <= 1;
				end

				if(read_data_1_in_latched.valid) begin
					reg_DATA_VARIABLE_1       <= read_data_1_in_latched.data;
					reg_DATA_VARIABLE_1_ready <= 1;
				end

				if(reg_DATA_VARIABLE_ready)begin
					for (i = 0; i < CACHELINE_DATA_READ_NUM_HF; i++) begin
						if(address_rd == i)begin
							edge_data_variable_reg.data <= reg_DATA_VARIABLE_0[DATA_SIZE_READ_BITS*i +: DATA_SIZE_READ_BITS];
						end
					end

					for (i = 0; i < CACHELINE_DATA_READ_NUM_HF; i++) begin
						if(address_rd == (i+CACHELINE_DATA_READ_NUM_HF))begin
							edge_data_variable_reg.data <= reg_DATA_VARIABLE_1[DATA_SIZE_READ_BITS*i +: DATA_SIZE_READ_BITS];
						end
					end

					edge_data_variable_reg.valid <= reg_DATA_VARIABLE_ready;
					edge_data_variable_reg.cu_id <= cu_id;
					edge_data_variable_reg.id    <= dest_id;

					if(~read_data_0_in_latched.valid)
						reg_DATA_VARIABLE_0_ready <= 0;

					if(~read_data_1_in_latched.valid)
						reg_DATA_VARIABLE_1_ready <= 0;

				end else begin
					edge_data_variable_reg <= 0;
				end
			end
		end
	end

endmodule