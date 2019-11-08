// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_edge_data_write_control.sv
// Create : 2019-10-31 14:36:36
// Revise : 2019-11-08 10:49:02
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_data_write_control #(parameter CU_ID = 1) (
	input  logic             clock            , // Clock
	input  logic             rstn             ,
	input  logic             enabled_in       ,
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
	logic [0:7]       offset_data              ;


////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_data_0_out  <= 0;
			write_data_1_out  <= 0;
			write_command_out <= 0;
		end else begin
			if(enabled) begin
				write_data_0_out  <= write_data_0_out_latched;
				write_data_1_out  <= write_data_1_out_latched;
				write_command_out <= write_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched <= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched <= wed_request_in;
			end
		end
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
		offset_data          = (((CACHELINE_SIZE >> ($clog2(DATA_SIZE_WRITE)+1))-1) & edge_data_write.index);
		cmd.vertex_struct    = WRITE_GRAPH_DATA;
		cmd.cacheline_offest = (((edge_data_write.index << $clog2(DATA_SIZE_WRITE)) & ADDRESS_DATA_WRITE_MOD_MASK) >> $clog2(DATA_SIZE_WRITE));
		cmd.cu_id            = edge_data_write.cu_id;
		cmd.cmd_type         = CMD_WRITE;
		cmd.abt              = STRICT;
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out_latched <= 0;
			write_data_0_out_latched  <= 0;
			write_data_1_out_latched  <= 0;
		end else begin
			if (edge_data_write.valid && enabled) begin
				write_command_out_latched.valid <= edge_data_write.valid;

				if(wed_request_in_latched.wed.afu_config[30])
					write_command_out_latched.command <= WRITE_MS;
				else
					write_command_out_latched.command <= WRITE_NA;

				write_command_out_latched.address <= wed_request_in_latched.wed.auxiliary2 + (edge_data_write.index << $clog2(DATA_SIZE_WRITE));
				write_command_out_latched.size    <= DATA_SIZE_WRITE;
				write_command_out_latched.cmd     <= cmd;


				write_data_0_out_latched.valid                                                        <= edge_data_write.valid;
				write_data_0_out_latched.cmd                                                          <= cmd;
				write_data_0_out_latched.data[offset_data*DATA_SIZE_WRITE_BITS+:DATA_SIZE_WRITE_BITS] <= swap_endianness_data_write(edge_data_write.data) ;

				write_data_1_out_latched.valid                                                        <= edge_data_write.valid;
				write_data_1_out_latched.cmd                                                          <= cmd;
				write_data_1_out_latched.data[offset_data*DATA_SIZE_WRITE_BITS+:DATA_SIZE_WRITE_BITS] <= swap_endianness_data_write(edge_data_write.data) ;

				write_data_1_out_latched.cmd.abt  <= map_CABT(wed_request_in_latched.wed.afu_config[15:17]);
				write_data_0_out_latched.cmd.abt  <= map_CABT(wed_request_in_latched.wed.afu_config[15:17]);
				write_command_out_latched.cmd.abt <= map_CABT(wed_request_in_latched.wed.afu_config[15:17]);
				write_command_out_latched.abt     <= map_CABT(wed_request_in_latched.wed.afu_config[15:17]);

				if (wed_request_in_latched.wed.afu_config[19]) begin
					write_command_out_latched.command 			  <= WRITE_MS; 
				end else begin
					write_command_out_latched.command 			  <= WRITE_NA; 
				end



			end else begin
				write_command_out_latched <= 0;
				write_data_0_out_latched  <= 0;
				write_data_1_out_latched  <= 0;
			end
		end
	end



endmodule