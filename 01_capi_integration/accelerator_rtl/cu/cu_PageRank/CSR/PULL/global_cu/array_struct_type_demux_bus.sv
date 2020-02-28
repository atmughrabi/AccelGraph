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
// Revise : 2020-02-28 02:44:06
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import CU_PKG::*;

module array_struct_type_demux_bus #(
	parameter DATA_WIDTH = 32,
	parameter BUS_WIDTH  = 2
) (
	input  logic                  clock                   ,
	input  logic                  rstn                    ,
	input  logic                  enabled_in              ,
	input  array_struct_type      sel_in                  ,
	input  logic [0:DATA_WIDTH-1] data_in                 ,
	output logic [0:DATA_WIDTH-1] data_out [0:BUS_WIDTH-1]
);

	logic                  enabled                           ;
	array_struct_type      sel_in_latched                    ;
	array_struct_type      sel_in_internal                   ;
	logic [0:DATA_WIDTH-1] data_in_latched                   ;
	logic [0:DATA_WIDTH-1] data_in_internal                  ;
	logic [0:DATA_WIDTH-1] data_out_latched   [0:BUS_WIDTH-1];
	logic [0:DATA_WIDTH-1] data_out_latched_S2[0:BUS_WIDTH-1];

	integer i;

	////////////////////////////////////////////////////////////////////////////
	//enable logic
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled          <= 0;
			sel_in_internal  <= STRUCT_INVALID;
			data_in_internal <= 0;
		end else begin
			enabled          <= enabled_in;
			sel_in_internal  <= sel_in;
			data_in_internal <= data_in;
		end
	end

	always_ff @(posedge clock ) begin
		data_in_latched <= data_in_internal;
	end

	always_ff @(posedge clock) begin
		if(enabled) begin
			sel_in_latched <= sel_in_internal;
		end else begin
			sel_in_latched <= STRUCT_INVALID;
		end
	end

	always_comb  begin
		data_out_latched = '{default:0};
		case (sel_in_latched)
			INV_EDGE_ARRAY_DEST : begin
				data_out_latched[0] = data_in_latched;
			end
			READ_GRAPH_DATA : begin
				data_out_latched[1] = data_in_latched;
			end
			default : begin
				data_out_latched = '{default:0};
			end
		endcase
	end

	always_ff @(posedge clock) begin
		data_out_latched_S2 <= data_out_latched;
	end

	always_ff @(posedge clock) begin
		data_out <= data_out_latched_S2;
	end


endmodule
