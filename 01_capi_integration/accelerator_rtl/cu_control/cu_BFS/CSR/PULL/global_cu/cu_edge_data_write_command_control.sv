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
	input  logic             clock                         , // Clock
	input  logic             rstn                          ,
	input  logic             enabled_in                    ,
	output logic             edge_data_write_bus_grant_out ,
	input  logic             edge_data_write_bus_request_in,
	output logic             write_command_bus_request_out ,
	input  logic             write_command_bus_grant_in    ,
	input  logic [0:63]      cu_configure                  ,
	input  WEDInterface      wed_request_in                ,
	input  EdgeDataWrite     edge_data_write               ,
	output ReadWriteDataLine write_data_0_out              ,
	output ReadWriteDataLine write_data_1_out              ,
	output CommandBufferLine write_command_out
);
	CommandTagLine    cmd                      ;
	logic             enabled                  ;
	ReadWriteDataLine write_data_0_out_latched ;
	ReadWriteDataLine write_data_1_out_latched ;
	CommandBufferLine write_command_out_latched;

	ReadWriteDataLine write_data_0_internal ;
	ReadWriteDataLine write_data_1_internal ;
	CommandBufferLine write_command_internal;

	WEDInterface  wed_request_in_latched    ;
	logic [ 0:7]  offset_data               ;
	logic [0:63]  cu_configure_latched      ;
	EdgeDataWrite edge_data_write_in_latched;
	EdgeDataWrite edge_data_write_latched   ;
	EdgeDataWrite edge_data_write_latched_S2;

	BufferStatus edge_data_write_buffer_status     ;
	BufferStatus write_command_buffer_status       ;
	BufferStatus write_command_data_0_buffer_status;
	BufferStatus write_command_data_1_buffer_status;

	logic edge_data_write_buffer_pop;
	logic write_command_buffer_pop  ;

	logic edge_data_write_bus_grant_out_latched ;
	logic edge_data_write_bus_request_in_latched;
	logic write_command_bus_request_out_latched ;
	logic write_command_bus_grant_in_latched    ;

	logic data_mode;


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
			wed_request_in_latched.valid     <= 0;
			cu_configure_latched             <= 0;
			edge_data_write_in_latched.valid <= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched.valid <= wed_request_in.valid;

				if((|cu_configure))
					cu_configure_latched <= cu_configure;

				edge_data_write_in_latched.valid <= edge_data_write.valid ;
			end
		end
	end

	always_ff @(posedge clock) begin
		wed_request_in_latched.payload     <= wed_request_in.payload;
		edge_data_write_in_latched.payload <= edge_data_write.payload ;
	end

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled   <= 0;
			data_mode <= 0;
		end else begin
			enabled   <= enabled_in;
			data_mode <= ~data_mode;
		end
	end

////////////////////////////////////////////////////////////////////////////
//edge_data_accumulate
////////////////////////////////////////////////////////////////////////////

	always_comb begin
		if(edge_data_write_latched.valid) begin
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
			cmd.aux_data         = edge_data_write_latched.payload.data_1;
		end else begin
			offset_data          = (((CACHELINE_SIZE >> ($clog2(DATA_SIZE_WRITE_PARENT)+1))-1) & edge_data_write_latched_S2.payload.index);
			cmd.array_struct     = WRITE_GRAPH_DATA_PARENT;
			cmd.real_size        = 1;
			cmd.real_size_bytes  = DATA_SIZE_WRITE_PARENT;
			cmd.cacheline_offset = (((edge_data_write_latched_S2.payload.index << $clog2(DATA_SIZE_WRITE_PARENT)) & ADDRESS_DATA_WRITE_MOD_MASK) >> $clog2(DATA_SIZE_WRITE_PARENT));
			cmd.cu_id_x          = edge_data_write_latched_S2.payload.cu_id_x;
			cmd.cu_id_y          = edge_data_write_latched_S2.payload.cu_id_y;
			cmd.cmd_type         = CMD_WRITE;
			cmd.abt              = STRICT;
			cmd.address_offset   = edge_data_write_latched_S2.payload.index;
			cmd.aux_data         = edge_data_write_latched_S2.payload.data_2;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_internal.valid     <= 0;
			write_data_0_internal.valid      <= 0;
			write_data_1_internal.valid      <= 0;
			edge_data_write_latched_S2.valid <= 0;
		end else begin
			if (edge_data_write_latched.valid) begin
				write_command_internal.valid     <= edge_data_write_latched.valid;
				write_data_0_internal.valid      <= edge_data_write_latched.valid;
				write_data_1_internal.valid      <= edge_data_write_latched.valid;
				edge_data_write_latched_S2.valid <= edge_data_write_latched.valid;
			end else if (edge_data_write_latched_S2.valid) begin
				edge_data_write_latched_S2.valid <= 0;
				write_command_internal.valid     <= edge_data_write_latched_S2.valid;
				write_data_0_internal.valid      <= edge_data_write_latched_S2.valid;
				write_data_1_internal.valid      <= edge_data_write_latched_S2.valid;
			end else begin
				edge_data_write_latched_S2.valid <= 0;
				write_command_internal.valid     <= 0;
				write_data_0_internal.valid      <= 0;
				write_data_1_internal.valid      <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_data_write_latched_S2.payload <= edge_data_write_latched.payload;
	end

	always_ff @(posedge clock) begin
		if (edge_data_write_latched.valid) begin

			write_command_internal.payload.address <= wed_request_in_latched.payload.wed.auxiliary4 + (edge_data_write_latched.payload.index << $clog2(DATA_SIZE_WRITE));
			write_command_internal.payload.size    <= DATA_SIZE_WRITE;
			write_command_internal.payload.cmd     <= cmd;

			write_data_0_internal.payload.cmd                                                          <= cmd;
			write_data_0_internal.payload.data[offset_data*DATA_SIZE_WRITE_BITS+:DATA_SIZE_WRITE_BITS] <= swap_endianness_data_write(edge_data_write_latched.payload.data_1) ;

			write_data_1_internal.payload.cmd                                                          <= cmd;
			write_data_1_internal.payload.data[offset_data*DATA_SIZE_WRITE_BITS+:DATA_SIZE_WRITE_BITS] <= swap_endianness_data_write(edge_data_write_latched.payload.data_1) ;

			write_data_1_internal.payload.cmd.abt  <= map_CABT(cu_configure_latched[15:17]);
			write_data_0_internal.payload.cmd.abt  <= map_CABT(cu_configure_latched[15:17]);
			write_command_internal.payload.cmd.abt <= map_CABT(cu_configure_latched[15:17]);
			write_command_internal.payload.abt     <= map_CABT(cu_configure_latched[15:17]);

			if (cu_configure_latched[19]) begin
				write_command_internal.payload.command <= WRITE_MS;
			end else begin
				write_command_internal.payload.command <= WRITE_NA;
			end
		end else if (edge_data_write_latched_S2.valid) begin

			write_command_internal.payload.address <= wed_request_in_latched.payload.wed.auxiliary1 + (edge_data_write_latched_S2.payload.index << $clog2(DATA_SIZE_WRITE_PARENT));
			write_command_internal.payload.size    <= DATA_SIZE_WRITE_PARENT;
			write_command_internal.payload.cmd     <= cmd;

			write_data_0_internal.payload.cmd                                                                        <= cmd;
			write_data_0_internal.payload.data[offset_data*DATA_SIZE_WRITE_PARENT_BITS+:DATA_SIZE_WRITE_PARENT_BITS] <= swap_endianness_parent_data_write(edge_data_write_latched_S2.payload.data_2) ;

			write_data_1_internal.payload.cmd                                                                        <= cmd;
			write_data_1_internal.payload.data[offset_data*DATA_SIZE_WRITE_PARENT_BITS+:DATA_SIZE_WRITE_PARENT_BITS] <= swap_endianness_parent_data_write(edge_data_write_latched_S2.payload.data_2) ;

			write_data_1_internal.payload.cmd.abt  <= map_CABT(cu_configure_latched[15:17]);
			write_data_0_internal.payload.cmd.abt  <= map_CABT(cu_configure_latched[15:17]);
			write_command_internal.payload.cmd.abt <= map_CABT(cu_configure_latched[15:17]);
			write_command_internal.payload.abt     <= map_CABT(cu_configure_latched[15:17]);

			if (cu_configure_latched[19]) begin
				write_command_internal.payload.command <= WRITE_MS;
			end else begin
				write_command_internal.payload.command <= WRITE_NA;
			end

		end else begin
			write_data_0_internal.payload <= 0;
			write_data_1_internal.payload <= 0;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_write_bus_grant_out          <= 0;
			edge_data_write_bus_request_in_latched <= 0;
		end else begin
			if(enabled) begin
				edge_data_write_bus_grant_out          <= edge_data_write_bus_grant_out_latched;
				edge_data_write_bus_request_in_latched <= edge_data_write_bus_request_in;
			end
		end
	end

	assign edge_data_write_bus_grant_out_latched = ~write_command_buffer_status.alfull && ~edge_data_write_buffer_status.alfull && edge_data_write_bus_request_in_latched;
	assign edge_data_write_buffer_pop            = ~write_command_buffer_status.alfull && ~edge_data_write_buffer_status.empty && data_mode;


	fifo #(
		.WIDTH($bits(EdgeDataWrite) ),
		.DEPTH(WRITE_CMD_BUFFER_SIZE)
	) input_edge_data_write_buffer_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (edge_data_write_in_latched.valid    ),
		.data_in (edge_data_write_in_latched          ),
		.full    (edge_data_write_buffer_status.full  ),
		.alFull  (edge_data_write_buffer_status.alfull),
		
		.pop     (edge_data_write_buffer_pop          ),
		.valid   (edge_data_write_buffer_status.valid ),
		.data_out(edge_data_write_latched             ),
		.empty   (edge_data_write_buffer_status.empty )
	);

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_bus_grant_in_latched <= 0;
			write_command_bus_request_out      <= 0;
		end else begin
			if(enabled) begin
				write_command_bus_grant_in_latched <= write_command_bus_grant_in;
				write_command_bus_request_out      <= write_command_bus_request_out_latched;
			end
		end
	end

	assign write_command_bus_request_out_latched = ~write_command_buffer_status.empty;
	assign write_command_buffer_pop              = ~write_command_buffer_status.empty && write_command_bus_grant_in_latched;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(WRITE_CMD_BUFFER_SIZE   )
	) command_edge_data_write_buffer_fifo_instant (
		.clock   (clock                             ),
		.rstn    (rstn                              ),
		
		.push    (write_command_internal.valid      ),
		.data_in (write_command_internal            ),
		.full    (write_command_buffer_status.full  ),
		.alFull  (write_command_buffer_status.alfull),
		
		.pop     (write_command_buffer_pop          ),
		.valid   (write_command_buffer_status.valid ),
		.data_out(write_command_out_latched         ),
		.empty   (write_command_buffer_status.empty )
	);

	///////////////////////////////////////////////////////////////////////////
	//Burst Buffers CU Write DATA
	////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WRITE_CMD_BUFFER_SIZE   )
	) edge_data_write_data_0_buffer_fifo_instant (
		.clock   (clock                                    ),
		.rstn    (rstn                                     ),
		
		.push    (write_data_0_internal.valid              ),
		.data_in (write_data_0_internal                    ),
		.full    (write_command_data_0_buffer_status.full  ),
		.alFull  (write_command_data_0_buffer_status.alfull),
		
		.pop     (write_command_buffer_pop                 ),
		.valid   (write_command_data_0_buffer_status.valid ),
		.data_out(write_data_0_out_latched                 ),
		.empty   (write_command_data_0_buffer_status.empty )
	);


	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WRITE_CMD_BUFFER_SIZE   )
	) edge_data_write_data_1_buffer_fifo_instant (
		.clock   (clock                                    ),
		.rstn    (rstn                                     ),
		
		.push    (write_data_1_internal.valid              ),
		.data_in (write_data_1_internal                    ),
		.full    (write_command_data_1_buffer_status.full  ),
		.alFull  (write_command_data_1_buffer_status.alfull),
		
		.pop     (write_command_buffer_pop                 ),
		.valid   (write_command_data_1_buffer_status.valid ),
		.data_out(write_data_1_out_latched                 ),
		.empty   (write_command_data_1_buffer_status.empty )
	);


endmodule