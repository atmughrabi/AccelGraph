// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_edge_data_control.sv
// Create : 2019-09-26 15:18:46
// Revise : 2019-10-31 15:18:41
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_data_control #(parameter CU_ID = 1) (
	input  logic              clock             , // Clock
	input  logic              rstn              ,
	input  logic              enabled_in        ,
	input  WEDInterface       wed_request_in    ,
	input  ResponseBufferLine read_response_in  ,
	input  ReadWriteDataLine  read_data_0_in    ,
	input  ReadWriteDataLine  read_data_1_in    ,
	input  BufferStatus       read_buffer_status,
	input  BufferStatus       edge_buffer_status,
	input  logic              edge_data_request ,
	input  EdgeInterface      edge_job          ,
	output logic              edge_request      ,
	output CommandBufferLine  read_command_out  ,
	output BufferStatus       data_buffer_status,
	output EdgeDataRead       edge_data
);

	
	//output latched
	EdgeInterface   edge_job_latched          ;
	EdgeInterface   edge_job_variable         ;
	EdgeDataRead    edge_data_variable        ;
	//input lateched
	ResponseBufferLine           read_response_in_latched            ;
	ReadWriteDataLine            read_data_0_in_latched              ;
	ReadWriteDataLine            read_data_1_in_latched              ;
	logic                        edge_request_latched                ;
	BufferStatus                 edge_buffer_status_internal         ;
	WEDInterface                 wed_request_in_latched              ;
	CommandBufferLine            read_command_out_latched            ;
	BufferStatus                 read_buffer_status_internal         ;
	logic                        read_command_job_edge_data_burst_pop;
	logic                        enabled                             ;
	logic                        edge_data_request_latched           ;
	logic                        edge_data_request_latched_internal  ;
	logic                        edge_variable_pop                   ;

	
// assign edge_request = edge_request_latched;

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
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_request <= 0;
		end else begin
			if(enabled) begin
				edge_request <= edge_request_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_in_latched  <= 0;
			read_data_0_in_latched    <= 0;
			read_data_1_in_latched    <= 0;
			edge_job_latched          <= 0;
			edge_data_request_latched <= 0;
			wed_request_in_latched    <= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched    <= wed_request_in;
				read_response_in_latched  <= read_response_in;
				read_data_0_in_latched    <= read_data_0_in;
				read_data_1_in_latched    <= read_data_1_in;
				edge_job_latched          <= edge_job;
				edge_data_request_latched <= (edge_data_request && ~data_buffer_status.empty);
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//data request command logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_out_latched <= 0;
		end else begin
			if(enabled) begin
				if(edge_job_variable.valid && wed_request_in_latched.valid)begin
					read_command_out_latched.valid <= 1'b1;

					if(wed_request_in_latched.wed.afu_config[31])
						read_command_out_latched.command <= READ_CL_S;
					else
						read_command_out_latched.command <= READ_CL_NA;

					read_command_out_latched.address              <= wed_request_in_latched.wed.auxiliary1 + (edge_job_variable.dest << $clog2(DATA_SIZE_READ));
					read_command_out_latched.size                 <= DATA_SIZE_READ;
					read_command_out_latched.cmd.vertex_struct    <= READ_GRAPH_DATA;
					read_command_out_latched.cmd.cacheline_offest <= (((edge_job_variable.dest<< $clog2(DATA_SIZE_READ)) & ADDRESS_DATA_READ_MOD_MASK) >> $clog2(DATA_SIZE_READ));
					read_command_out_latched.cmd.cu_id            <= CU_ID;
					read_command_out_latched.cmd.cmd_type         <= CMD_READ;
				end else begin
					read_command_out_latched <= 0;
				end
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//data request read logic
////////////////////////////////////////////////////////////////////////////

	assign edge_data_request_latched_internal = ~data_buffer_status.alfull;

	cu_edge_data_read_control #(.CU_ID(CU_ID)) cu_edge_data_read_control_instant (
		.clock            (clock                             ),
		.rstn             (rstn                              ),
		.enabled_in       (enabled                           ),
		.read_data_0_in   (read_data_0_in_latched            ),
		.read_data_1_in   (read_data_1_in_latched            ),
		.edge_data_request(edge_data_request_latched_internal),
		.edge_data        (edge_data_variable                )
	);


///////////////////////////////////////////////////////////////////////////
//Edge data buffer
///////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(EdgeDataRead)      ),
		.DEPTH(CU_VERTEX_JOB_BUFFER_SIZE)
	) edge_data_buffer_fifo_instant (
		.clock   (clock                    ),
		.rstn    (rstn                     ),
		
		.push    (edge_data_variable.valid ),
		.data_in (edge_data_variable       ),
		.full    (data_buffer_status.full  ),
		.alFull  (data_buffer_status.alfull),
		
		.pop     (edge_data_request_latched),
		.valid   (data_buffer_status.valid ),
		.data_out(edge_data                ),
		.empty   (data_buffer_status.empty )
	);

///////////////////////////////////////////////////////////////////////////
//Edge job buffer
///////////////////////////////////////////////////////////////////////////

	assign edge_request_latched = ~edge_buffer_status.empty && ~edge_buffer_status_internal.alfull; // request edges for Data job control
	assign edge_variable_pop    = ~edge_buffer_status_internal.empty && ~read_buffer_status_internal.alfull;

	fifo #(
		.WIDTH($bits(EdgeInterface)     ),
		.DEPTH(CU_VERTEX_JOB_BUFFER_SIZE)
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

	assign read_command_job_edge_data_burst_pop = ~read_buffer_status_internal.empty && ~read_buffer_status.alfull;

	fifo #(
		.WIDTH($bits(CommandBufferLine) ),
		.DEPTH(CU_VERTEX_JOB_BUFFER_SIZE)
	) read_command_edge_data_burst_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (read_command_out_latched.valid      ),
		.data_in (read_command_out_latched            ),
		.full    (read_buffer_status_internal.full    ),
		.alFull  (read_buffer_status_internal.alfull  ),
		
		.pop     (read_command_job_edge_data_burst_pop),
		.valid   (read_buffer_status_internal.valid   ),
		.data_out(read_command_out                    ),
		.empty   (read_buffer_status_internal.empty   )
	);




endmodule