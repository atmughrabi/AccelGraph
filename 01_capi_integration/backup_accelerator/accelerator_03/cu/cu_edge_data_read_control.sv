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
// Revise : 2019-10-31 15:15:46
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_data_read_control  #(parameter CU_ID = 1)(
	input  logic             clock             , // Clock
	input  logic             rstn              ,
	input  logic             enabled_in        ,
	input  ReadWriteDataLine read_data_0_in    ,
	input  ReadWriteDataLine read_data_1_in    ,
	input  logic             edge_data_request ,
	output EdgeDataRead      edge_data
);

	localparam WORDS                          = 1                                                                                                              ;
	localparam CACHELINE_DATA_READ_ADDR_BITS  = $clog2((DATA_SIZE_READ_BITS < CACHELINE_SIZE_BITS) ? (WORDS * CACHELINE_SIZE_BITS)/DATA_SIZE_READ_BITS : WORDS);
	localparam CACHELINE_DATA_WRITE_ADDR_BITS = $clog2((DATA_SIZE_READ_BITS < CACHELINE_SIZE_BITS) ? WORDS : (WORDS * DATA_SIZE_READ_BITS)/CACHELINE_SIZE_BITS);


	//output latched
	EdgeDataRead    edge_data_variable        ;
	EdgeDataRead    edge_data_variable_latched;
	BufferStatus       data_buffer_status;
	//input lateched
	ResponseBufferLine           read_response_in_latched            ;
	ReadWriteDataLine            read_data_0_in_latched              ;
	ReadWriteDataLine            read_data_0_in_latched_S2           ;
	ReadWriteDataLine            read_data_1_in_latched              ;
	logic [                 0:7] offset_data_0                       ;
	logic [                 0:7] offset_data_1                       ;
	logic                        enabled                             ;
	logic                        edge_data_request_latched           ;

	logic [             0:CACHELINE_SIZE_BITS-1] read_data_in      ;
	logic [0:(CACHELINE_DATA_WRITE_ADDR_BITS-1)] address_wr        ;
	logic [ 0:(CACHELINE_DATA_READ_ADDR_BITS-1)] address_rd        ;
	logic [ 0:(CACHELINE_DATA_READ_ADDR_BITS-1)] address_rd_latched;
	logic                                        we                ;
	logic                                        we_latched        ;

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
			edge_data_request_latched <= 0;
		end else begin
			if(enabled) begin
				read_data_0_in_latched_S2 <= read_data_0_in;
				read_data_0_in_latched    <= read_data_0_in_latched_S2;
				read_data_1_in_latched    <= read_data_1_in;
				edge_data_request_latched <= (edge_data_request && ~data_buffer_status.empty);
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//data request read logic
////////////////////////////////////////////////////////////////////////////

	assign offset_data_0 = read_data_0_in_latched.cmd.cacheline_offest;
	assign offset_data_1 = (((CACHELINE_SIZE >> ($clog2(DATA_SIZE_READ)+1))-1) & read_data_1_in_latched.cmd.cacheline_offest);

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			we           <= 0;
			read_data_in <= 0;
			address_wr   <= 0;
			address_rd   <= 0;
		end else begin
			if(enabled) begin
				if(read_data_0_in_latched.valid && read_data_1_in_latched.valid)begin
					we                                                         <= 1;
					read_data_in[0:CACHELINE_SIZE_BITS_HF-1]                   <= read_data_0_in_latched.data;
					read_data_in[CACHELINE_SIZE_BITS_HF:CACHELINE_SIZE_BITS-1] <= read_data_1_in_latched.data;
					address_wr                                                 <= 0;
					address_rd                                                 <= offset_data_0;
				end else begin
					we           <= 0;
					read_data_in <= 0;
					address_wr   <= 0;
					address_rd   <= 0;
				end
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			address_rd_latched <= 0;
			we_latched         <= 0;
		end else begin
			address_rd_latched               <= address_rd;
			we_latched                       <= we;
			edge_data_variable_latched.valid <= we_latched;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_variable <= 0;
		end else begin
			if(enabled) begin
				if(edge_data_variable_latched.valid)begin
					edge_data_variable.valid <= edge_data_variable_latched.valid;
					edge_data_variable.cu_id <= CU_ID;
					edge_data_variable.data  <= swap_endianness_data_read(edge_data_variable_latched.data);
				end else begin
					edge_data_variable <= 0;
				end
			end
		end
	end

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

////////////////////////////////////////////////////////////////////////////
//cacheline_instant
////////////////////////////////////////////////////////////////////////////

	mixed_width_ram #(
		.WORDS(WORDS              ),
		.WW   (CACHELINE_SIZE_BITS),
		.RW   (DATA_SIZE_READ_BITS)
	) cacheline_instant (
		.clock   (clock                          ),
		.we      (we                             ),
		.wr_addr (address_wr                     ),
		.data_in (read_data_in                   ),
		
		.rd_addr (address_rd_latched             ),
		.data_out(edge_data_variable_latched.data)
	);



endmodule