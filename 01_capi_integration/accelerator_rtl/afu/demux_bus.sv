// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : demux_bus.sv
// Create : 2020-02-21 19:20:47
// Revise : 2020-02-28 02:44:11
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

module demux_bus #(
	parameter DATA_WIDTH = 32               ,
	parameter BUS_WIDTH  = 8                ,
	parameter SEL_WIDTH  = $clog2(BUS_WIDTH)
) (
	input  logic                  clock                   ,
	input  logic                  rstn                    ,
	input  logic                  enabled_in              ,
	input  logic [ 0:SEL_WIDTH-1] sel_in                  ,
	input  logic [0:DATA_WIDTH-1] data_in                 ,
	output logic [0:DATA_WIDTH-1] data_out [0:BUS_WIDTH-1]
);

	logic                  enabled                           ;
	logic [ 0:SEL_WIDTH-1] sel_in_latched                    ;
	logic [ 0:SEL_WIDTH-1] sel_in_internal                   ;
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
			sel_in_internal  <= 0;
			data_in_internal <= 0;
		end else begin
			enabled          <= enabled_in;
			sel_in_internal  <= sel_in;
			data_in_internal <= data_in;
		end
	end

	always_ff @(posedge clock) begin
		data_in_latched <= data_in_internal;
	end

	always_ff @(posedge clock) begin
		if(enabled) begin
			sel_in_latched <= sel_in_internal;
		end else begin
			sel_in_latched <= 0;
		end
	end

	always_comb  begin
		data_out_latched = '{default:0};
		for (i = 0; i < BUS_WIDTH; i++) begin
			if(sel_in_latched == i)begin
				data_out_latched[i] = data_in_latched;
			end
		end
	end


	always_ff @(posedge clock) begin
		data_out_latched_S2 <= data_out_latched;
	end

	always_ff @(posedge clock) begin
		data_out <= data_out_latched_S2;
	end


endmodule
