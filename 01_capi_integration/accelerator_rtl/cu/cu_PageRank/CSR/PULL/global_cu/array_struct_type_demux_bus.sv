// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : array_struct_type_demux_bus.sv
// Create : 2020-02-21 22:35:40
// Revise : 2020-03-02 06:28:13
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import CU_PKG::*;

module array_struct_type_demux_bus #(
	parameter DATA_WIDTH = 32,
	parameter BUS_WIDTH  = 2
) (
	input  logic                  clock                         ,
	input  logic                  rstn                          ,
	input  array_struct_type      sel_in                        ,
	input  logic [0:DATA_WIDTH-1] data_in                       ,
	input  logic                  data_in_valid                 ,
	output logic [0:DATA_WIDTH-1] data_out [0:BUS_WIDTH-1]      ,
	output logic                  data_out_valid [0:BUS_WIDTH-1]
);

	array_struct_type sel_in_latched ;
	array_struct_type sel_in_internal;

	logic [0:DATA_WIDTH-1] data_in_latched ;
	logic [0:DATA_WIDTH-1] data_in_internal;

	logic data_in_valid_latched ;
	logic data_in_valid_internal;

	logic data_out_valid_latched [0:BUS_WIDTH-1];
	logic data_out_valid_internal[0:BUS_WIDTH-1];

	logic [0:DATA_WIDTH-1] data_out_internal[0:BUS_WIDTH-1];
	logic [0:DATA_WIDTH-1] data_out_latched [0:BUS_WIDTH-1];

	genvar i;

	////////////////////////////////////////////////////////////////////////////
	//latche logic
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			data_in_valid_internal <= 0;
			data_in_valid_latched  <= 0;
			sel_in_internal        <= STRUCT_INVALID;
			sel_in_latched         <= STRUCT_INVALID;
		end else begin
			data_in_valid_internal <= data_in_valid;
			data_in_valid_latched  <= data_in_valid_internal;
			sel_in_internal        <= sel_in;
			sel_in_latched         <= sel_in_internal;
		end
	end

	always_ff @(posedge clock) begin
		data_in_internal <= data_in;
	end

	always_ff @(posedge clock) begin
		data_in_latched <= data_in_internal;
	end

	always_ff @(posedge clock) begin
		data_out       <= data_out_latched;
		data_out_valid <= data_out_valid_latched;
	end

	////////////////////////////////////////////////////////////////////////////
	//demux logic
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			data_out_valid_internal[0] <= 0;
			data_out_valid_internal[1] <= 0;
		end else begin
			case (sel_in_latched)
				INV_EDGE_ARRAY_DEST : begin
					data_out_valid_internal[0] <= data_in_valid_latched;
					data_out_valid_internal[1] <= 0;
				end
				READ_GRAPH_DATA : begin
					data_out_valid_internal[0] <= 0;
					data_out_valid_internal[1] <= data_in_valid_latched;
				end
				default : begin
					data_out_valid_internal[0] <= 0;
					data_out_valid_internal[1] <= 0;
				end
			endcase
		end
	end

	always_ff @(posedge clock) begin
		data_out_internal[0] <= data_in_latched;
		data_out_internal[1] <= data_in_latched;
	end

	always_ff @(posedge clock) begin
		data_out_valid_latched <= data_out_valid_internal;
		data_out_latched       <= data_out_internal;
	end


endmodule
