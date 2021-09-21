// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_edge_data_read_command_control.sv
// Create : 2019-09-26 15:18:46
// Revise : 2019-11-08 10:49:54
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_data_read_command_control #(
	parameter CU_ID_X = 1,
	parameter CU_ID_Y = 1
) (
	input  logic              clock                   , // Clock
	input  logic              rstn_in                    ,
	input  logic              enabled_in              ,
	input  logic [0:63]       cu_configure            ,
	input  WEDInterface       wed_request_in          ,
	input  ResponseBufferLine read_response_in        ,
	input  EdgeDataRead       edge_data_read_in       ,
	input  BufferStatus       read_buffer_status      ,
	input  logic              edge_data_request       ,
	input  EdgeInterface      edge_job                ,
	output logic              edge_request            ,
	input  logic              read_command_bus_grant  ,
	output logic              read_command_bus_request,
	output CommandBufferLine  read_command_out        ,
	output BufferStatus       data_buffer_status      ,
	output EdgeDataRead       edge_data
);

	logic rstn                              ;
	//output latched
	EdgeInterface edge_job_latched          ;
	EdgeInterface edge_job_variable         ;
	EdgeDataRead  edge_data_latched         ;
	BufferStatus  data_buffer_status_latch  ;
	BufferStatus  read_buffer_status_latched;

	logic read_command_bus_grant_latched  ;
	logic read_command_bus_request_latched;
	//input lateched
	ResponseBufferLine read_response_in_latched                ;
	logic              edge_request_latched                    ;
	BufferStatus       edge_buffer_status_internal             ;
	WEDInterface       wed_request_in_latched                  ;
	CommandBufferLine  read_command_out_latched                ;
	BufferStatus       read_buffer_status_internal             ;
	logic              enabled                                 ;
	logic              enabled_cmd                             ;
	logic              edge_data_request_latched               ;
	logic              edge_variable_pop                       ;
	EdgeDataRead       edge_data_variable                      ;
	logic [0:63]       cu_configure_latched                    ;
	CommandBufferLine  read_command_edge_data_burst_out_latched;
	logic [0:63]       cu_configure_internal                   ;
	logic              read_command_bus_request_pop            ;


////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////
	
	always_ff @(posedge clock or negedge rstn_in) begin
		if(~rstn_in) begin
			rstn <= 0;
		end else begin
			rstn <= rstn_in;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled               <= 0;
			enabled_cmd           <= 0;
			cu_configure_internal <= 0;
		end else begin
			enabled               <= enabled_in;
			enabled_cmd           <= enabled && (|cu_configure_latched);
			cu_configure_internal <= cu_configure;
		end
	end


////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_request             <= 0;
			edge_data.valid          <= 0;
			read_command_out.valid   <= 0;
			data_buffer_status       <= 0;
			data_buffer_status.empty <= 1;
		end else begin
			if(enabled) begin
				edge_request           <= edge_request_latched;
				edge_data.valid        <= edge_data_latched.valid;
				read_command_out.valid <= read_command_edge_data_burst_out_latched.valid;
				data_buffer_status     <= data_buffer_status_latch;
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_data.payload        <= edge_data_latched.payload ;
		read_command_out.payload <= read_command_edge_data_burst_out_latched.payload ;
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_in_latched.valid   <= 0;
			edge_job_latched.valid           <= 0;
			edge_data_request_latched        <= 0;
			wed_request_in_latched.valid     <= 0;
			edge_data_variable.valid         <= 0;
			cu_configure_latched             <= 0;
			read_buffer_status_latched       <= 0;
			read_buffer_status_latched.empty <= 1;
		end else begin
			if(enabled) begin
				read_buffer_status_latched     <= read_buffer_status;
				wed_request_in_latched.valid   <= wed_request_in.valid;
				read_response_in_latched.valid <= read_response_in.valid;
				edge_job_latched.valid         <= edge_job.valid;
				edge_data_variable.valid       <= edge_data_read_in.valid;
				edge_data_request_latched      <= edge_data_request;
				if((|cu_configure_internal))
					cu_configure_latched <= cu_configure_internal;
			end
		end
	end


	always_ff @(posedge clock) begin
		wed_request_in_latched.payload   <= wed_request_in.payload;
		read_response_in_latched.payload <= read_response_in.payload;
		edge_job_latched.payload         <= edge_job.payload;
		edge_data_variable.payload       <= edge_data_read_in.payload;
	end

////////////////////////////////////////////////////////////////////////////
//data request command logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_out_latched.valid <= 0;
		end else begin
			if(enabled_cmd) begin
				if(edge_job_variable.valid && wed_request_in_latched.valid)begin
					read_command_out_latched.valid <= 1;
				end else begin
					read_command_out_latched.valid <= 0;
				end
			end
		end
	end

	always_ff @(posedge clock) begin
		read_command_out_latched.payload.address              <= wed_request_in_latched.payload.wed.auxiliary3 + ((edge_job_variable.payload.dest<< $clog2(DATA_SIZE_READ)) & ADDRESS_DATA_READ_ALIGN_MASK);
		read_command_out_latched.payload.size                 <= 12'h080;
		read_command_out_latched.payload.cmd.real_size        <= 1'b1;
		read_command_out_latched.payload.cmd.real_size_bytes  <= DATA_SIZE_READ;
		read_command_out_latched.payload.cmd.array_struct     <= READ_GRAPH_DATA;
		read_command_out_latched.payload.cmd.cacheline_offset <= (((edge_job_variable.payload.dest << $clog2(DATA_SIZE_READ)) & ADDRESS_DATA_READ_MOD_MASK) >> $clog2(DATA_SIZE_READ));
		read_command_out_latched.payload.cmd.address_offset   <= edge_job_variable.payload.dest;
		read_command_out_latched.payload.cmd.aux_data         <= edge_job_variable.payload.src;
		read_command_out_latched.payload.cmd.cu_id_x          <= CU_ID_X;
		read_command_out_latched.payload.cmd.cu_id_y          <= CU_ID_Y;
		read_command_out_latched.payload.cmd.cmd_type         <= CMD_READ;

		read_command_out_latched.payload.cmd.abt <= map_CABT(cu_configure_latched[10:12]);
		read_command_out_latched.payload.abt     <= map_CABT(cu_configure_latched[10:12]);

		if (cu_configure_latched[13]) begin
			read_command_out_latched.payload.command <= READ_CL_S;
		end else begin
			read_command_out_latched.payload.command <= READ_CL_NA;
		end
	end

///////////////////////////////////////////////////////////////////////////
//Edge data buffer
///////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(EdgeDataRead)    ),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE)
	) edge_data_buffer_fifo_instant (
		.clock   (clock                          ),
		.rstn    (rstn                           ),
		
		.push    (edge_data_variable.valid       ),
		.data_in (edge_data_variable             ),
		.full    (data_buffer_status_latch.full  ),
		.alFull  (data_buffer_status_latch.alfull),
		
		.pop     (edge_data_request_latched      ),
		.valid   (data_buffer_status_latch.valid ),
		.data_out(edge_data_latched              ),
		.empty   (data_buffer_status_latch.empty )
	);

///////////////////////////////////////////////////////////////////////////
//Edge job buffer
///////////////////////////////////////////////////////////////////////////

	assign edge_request_latched = ~edge_buffer_status_internal.alfull; // request edges for Data job control
	assign edge_variable_pop    = ~edge_buffer_status_internal.empty && ~read_buffer_status_internal.alfull;

	fifo #(
		.WIDTH($bits(EdgeInterface)   ),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE)
	) edge_job_buffer_fifo_instant (
		.clock   (clock                             ),
		.rstn    (rstn                              ),
		
		.push    (edge_job_latched.valid            ),
		.data_in (edge_job_latched                  ),
		.full    (edge_buffer_status_internal.full  ),
		.alFull  (edge_buffer_status_internal.alfull),
		
		.pop     (edge_variable_pop                 ),
		.valid   (edge_buffer_status_internal.valid ),
		.data_out(edge_job_variable                 ),
		.empty   (edge_buffer_status_internal.empty )
	);

///////////////////////////////////////////////////////////////////////////
//Read Command Edge double buffer
///////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_bus_grant_latched <= 0;
			read_command_bus_request       <= 0;
		end else begin
			if(enabled_cmd) begin
				read_command_bus_grant_latched <= read_command_bus_grant;
				read_command_bus_request       <= read_command_bus_request_latched;
			end
		end
	end

	assign read_command_bus_request_latched = ~read_buffer_status_latched.alfull && ~read_buffer_status_internal.empty;
	assign read_command_bus_request_pop     = ~read_buffer_status_latched.alfull && read_command_bus_grant_latched;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE )
	) read_command_edge_data_burst_fifo_instant (
		.clock   (clock                                   ),
		.rstn    (rstn                                    ),
		
		.push    (read_command_out_latched.valid          ),
		.data_in (read_command_out_latched                ),
		.full    (read_buffer_status_internal.full        ),
		.alFull  (read_buffer_status_internal.alfull      ),
		
		.pop     (read_command_bus_request_pop            ),
		.valid   (read_buffer_status_internal.valid       ),
		.data_out(read_command_edge_data_burst_out_latched),
		.empty   (read_buffer_status_internal.empty       )
	);




endmodule