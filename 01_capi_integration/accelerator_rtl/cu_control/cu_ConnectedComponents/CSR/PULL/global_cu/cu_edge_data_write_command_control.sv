// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_edge_data_write_command_control.sv
// Create : 2019-10-31 14:36:36
// Revise : 2019-11-08 10:49:02
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_data_write_command_control #(
	parameter CU_ID_X = 1,
	parameter CU_ID_Y = 1
) (
	input  logic             clock            , // Clock
	input  logic             rstn             ,
	input  logic             enabled_in       ,
	input  logic [0:63]      cu_configure     ,
	input  WEDInterface      wed_request_in   ,
	input  EdgeDataWrite     edge_data_write  ,
	output ReadWriteDataLine write_data_0_out ,
	output ReadWriteDataLine write_data_1_out ,
	output CommandBufferLine write_command_out
);
	CommandTagLine    cmd                      ;
	logic             enabled                  ;
	ReadWriteDataLine write_data_0_out_latched ;
	ReadWriteDataLine write_data_1_out_latched ;
	CommandBufferLine write_command_out_latched;
	WEDInterface      wed_request_in_latched   ;
	logic [ 0:7]      offset_data              ;
	logic [0:63]      cu_configure_latched     ;
	EdgeDataWrite     edge_data_write_latched  ;


////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_data_0_out.valid  <= 0;
			write_data_1_out.valid  <= 0;
			write_command_out.valid <= 0;
		end else begin
			if(enabled) begin
				write_data_0_out.valid  <= write_data_0_out_latched.valid;
				write_data_1_out.valid  <= write_data_1_out_latched.valid;
				write_command_out.valid <= write_command_out_latched.valid;
			end
		end
	end

	always_ff @(posedge clock) begin
		write_data_0_out.payload  <= write_data_0_out_latched.payload;
		write_data_1_out.payload  <= write_data_1_out_latched.payload;
		write_command_out.payload <= write_command_out_latched.payload;
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched.valid  <= 0;
			cu_configure_latched          <= 0;
			edge_data_write_latched.valid <= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched.valid <= wed_request_in.valid;
				if((|cu_configure))
					cu_configure_latched <= cu_configure;
				edge_data_write_latched.valid <= edge_data_write.valid ;
			end
		end
	end

	always_ff @(posedge clock) begin
		wed_request_in_latched.payload  <= wed_request_in.payload;
		edge_data_write_latched.payload <= edge_data_write.payload ;
	end

////////////////////////////////////////////////////////////////////////////
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
//edge_data_accumulate
////////////////////////////////////////////////////////////////////////////

	always_comb begin
		cmd                  = 0;
		offset_data          = (((CACHELINE_SIZE >> ($clog2(DATA_SIZE_WRITE)+1))-1) & edge_data_write_latched.payload.index);
		cmd.array_struct     = WRITE_GRAPH_DATA;
		cmd.real_size        = 1;
		cmd.real_size_bytes  = DATA_SIZE_WRITE;
		cmd.cacheline_offset = (((edge_data_write_latched.payload.index << $clog2(DATA_SIZE_WRITE)) & ADDRESS_DATA_WRITE_MOD_MASK) >> $clog2(DATA_SIZE_WRITE));
		cmd.cu_id_x          = edge_data_write_latched.payload.cu_id_x;
		cmd.cu_id_y          = edge_data_write_latched.payload.cu_id_y;
		cmd.cmd_type         = CMD_WRITE;
		cmd.abt              = STRICT;
		cmd.address_offset   = edge_data_write_latched.payload.index;
		cmd.aux_data         = edge_data_write_latched.payload.data;
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out_latched.valid <= 0;
			write_data_0_out_latched.valid  <= 0;
			write_data_1_out_latched.valid  <= 0;
		end else begin
			if (edge_data_write_latched.valid) begin
				write_command_out_latched.valid <= edge_data_write_latched.valid;
				write_data_0_out_latched.valid  <= edge_data_write_latched.valid;
				write_data_1_out_latched.valid  <= edge_data_write_latched.valid;
			end else begin
				write_command_out_latched.valid <= 0;
				write_data_0_out_latched.valid  <= 0;
				write_data_1_out_latched.valid  <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		if (edge_data_write_latched.valid) begin
			write_command_out_latched.payload.address <= wed_request_in_latched.payload.wed.auxiliary2 + (edge_data_write_latched.payload.index << $clog2(DATA_SIZE_WRITE));
			write_command_out_latched.payload.size    <= DATA_SIZE_WRITE;
			write_command_out_latched.payload.cmd     <= cmd;

			write_data_0_out_latched.payload.cmd                                                          <= cmd;
			write_data_0_out_latched.payload.data[offset_data*DATA_SIZE_WRITE_BITS+:DATA_SIZE_WRITE_BITS] <= swap_endianness_data_write(edge_data_write_latched.payload.data) ;

			write_data_1_out_latched.payload.cmd                                                          <= cmd;
			write_data_1_out_latched.payload.data[offset_data*DATA_SIZE_WRITE_BITS+:DATA_SIZE_WRITE_BITS] <= swap_endianness_data_write(edge_data_write_latched.payload.data) ;

			write_data_1_out_latched.payload.cmd.abt  <= map_CABT(cu_configure_latched[15:17]);
			write_data_0_out_latched.payload.cmd.abt  <= map_CABT(cu_configure_latched[15:17]);
			write_command_out_latched.payload.cmd.abt <= map_CABT(cu_configure_latched[15:17]);
			write_command_out_latched.payload.abt     <= map_CABT(cu_configure_latched[15:17]);

			if (cu_configure_latched[19]) begin
				write_command_out_latched.payload.command <= WRITE_MS;
			end else begin
				write_command_out_latched.payload.command <= WRITE_NA;
			end
		end else begin
			write_data_0_out_latched.payload <= 0;
			write_data_1_out_latched.payload <= 0;
		end
	end




endmodule