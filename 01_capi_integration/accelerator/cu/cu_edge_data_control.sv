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
// Revise : 2019-10-03 23:03:26
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
	input  VertexInterface    vertex_job        ,
	input  logic              edge_data_request ,
	input  EdgeInterface      edge_job          ,
	output logic              edge_request      ,
	output CommandBufferLine  read_command_out  ,
	output BufferStatus       data_buffer_status,
	output EdgeData           edge_data
);

	//output latched
	EdgeInterface   edge_job_latched          ;
	EdgeInterface   edge_job_variable         ;
	EdgeData        edge_data_variable        ;
	EdgeData        edge_data_variable_latched;
	VertexInterface vertex_job_latched        ;
	logic [0:7]     response_counter          ;
	//input lateched
	ResponseBufferLine read_response_in_latched            ;
	ReadWriteDataLine  read_data_0_in_latched              ;
	ReadWriteDataLine  read_data_1_in_latched              ;
	logic              edge_request_latched                ;
	BufferStatus       edge_buffer_status_internal         ;
	WEDInterface       wed_request_in_latched              ;
	CommandBufferLine  read_command_out_latched            ;
	BufferStatus       read_buffer_status_internal         ;
	logic              read_command_job_edge_data_burst_pop;

	logic enabled                  ;
	logic edge_data_request_latched;
	logic push_edge_job            ;
	logic edge_variable_pop        ;


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
			vertex_job_latched        <= 0;
			edge_data_request_latched <= 0;
			wed_request_in_latched    <= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched    <= wed_request_in;
				read_response_in_latched  <= read_response_in;
				read_data_0_in_latched    <= read_data_0_in;
				read_data_1_in_latched    <= read_data_1_in;
				edge_job_latched          <= edge_job;
				vertex_job_latched        <= vertex_job;
				edge_data_request_latched <= edge_data_request;
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
					read_command_out_latched.valid                <= 1'b1;
					read_command_out_latched.command              <= READ_CL_NA;
					// read_command_out_latched.command              <= READ_CL_S; // just zero it out
					read_command_out_latched.address              <= wed_request_in_latched.wed.auxiliary1 + (edge_job_variable.dest << $clog2(DATA_SIZE));
					read_command_out_latched.size                 <= DATA_SIZE;
					read_command_out_latched.cmd.vertex_struct    <= READ_GRAPH_DATA;
					read_command_out_latched.cmd.cacheline_offest <= (((edge_job_variable.dest<< $clog2(DATA_SIZE)) & ADDRESS_MOD_MASK) >> $clog2(DATA_SIZE));
					read_command_out_latched.cmd.cu_id            <= CU_ID;
					read_command_out_latched.cmd.cmd_type         <= CMD_READ;
				end else begin
					read_command_out_latched <= 0;
				end
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//response tracking logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			response_counter <= 0;
		else begin
			if ( read_command_out_latched.valid) begin
				response_counter <= response_counter + 1;
			end else if (read_response_in_latched.valid) begin
				response_counter <= response_counter - 1;
			end else begin
				response_counter <= response_counter;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//data request read logic
////////////////////////////////////////////////////////////////////////////

	always_comb begin
		edge_data_variable_latched = 0;
		if(read_data_0_in_latched.valid && read_data_0_in_latched.cmd.cacheline_offest < (CACHELINE_SIZE >> ($clog2(DATA_SIZE)+1)))begin
			edge_data_variable_latched.valid = 1;
			edge_data_variable_latched.data  = data_extract_cacheline_hf(read_data_0_in_latched.cmd.cacheline_offest,read_data_0_in_latched.data);
		end
		if(read_data_1_in_latched.valid && read_data_1_in_latched.cmd.cacheline_offest >= (CACHELINE_SIZE >> ($clog2(DATA_SIZE)+1)))begin
			edge_data_variable_latched.valid = 1;
			edge_data_variable_latched.data  = data_extract_cacheline_hf((((CACHELINE_SIZE >> $clog2(DATA_SIZE))-1) & read_data_1_in_latched.cmd.cacheline_offest), read_data_1_in_latched.data);
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_variable <= 0;
		end else begin
			if(enabled) begin
				if(edge_data_variable_latched.valid)begin
					edge_data_variable.valid <= edge_data_variable_latched.valid;
					edge_data_variable.data  <= swap_endianness_word(edge_data_variable_latched.data);
				end else begin
					edge_data_variable <= 0;
				end
			end
		end
	end

///////////////////////////////////////////////////////////////////////////
//Edge data buffer
////////////////////////////////////////////////////////////////////////////
	assign push_edge_data = (edge_data_variable.valid);

	fifo #(
		.WIDTH($bits(EdgeData)        ),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE)
	) edge_data_buffer_fifo_instant (
		.clock   (clock                    ),
		.rstn    (rstn                     ),
		
		.push    (push_edge_data           ),
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
////////////////////////////////////////////////////////////////////////////
	assign edge_request_latched = ~edge_buffer_status.empty && ~edge_buffer_status_internal.alfull; // request edges for Data job control
	assign push_edge_job        = (edge_job_latched.valid);
	assign edge_variable_pop    = ~edge_buffer_status_internal.empty && ~read_buffer_status_internal.alfull;

	fifo #(
		.WIDTH($bits(EdgeInterface)   ),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE)
	) edge_job_buffer_fifo_instant (
		.clock   (clock                             ),
		.rstn    (rstn                              ),
		
		.push    (push_edge_job                     ),
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
////////////////////////////////////////////////////////////////////////////

	assign read_command_job_edge_data_burst_pop = ~read_buffer_status.alfull;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE )
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