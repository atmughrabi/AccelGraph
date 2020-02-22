// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : sum_reduce.sv
// Create : 2020-02-21 21:32:40
// Revise : 2020-02-21 22:00:13
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


module sum_reduce #(
	parameter DATA_WIDTH_IN  = 32,
	parameter DATA_WIDTH_OUT = 32,
	parameter BUS_WIDTH      = 8
) (
	input  logic                      clock                            ,
	input  logic                      rstn                             ,
	input  logic                      enabled_in                       ,
	input  logic [ 0:DATA_WIDTH_IN-1] partial_sums_in   [0:BUS_WIDTH-1],
	output logic [0:DATA_WIDTH_OUT-1] total_sum_out
);

	logic [ 0:DATA_WIDTH_IN-1] partial_sums_in_latched[0:BUS_WIDTH-1];
	logic [0:DATA_WIDTH_OUT-1] total_sum_out_latched                 ;
	logic                      enabled                               ;
	integer                    i                                     ;

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

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			partial_sums_in_latched <= '{default:0};
		end else begin
			if(enabled) begin
				partial_sums_in_latched <= partial_sums_in;
			end
		end
	end

	always_comb begin
		total_sum_out_latched = '{default:0};
		for (i = 0; i < BUS_WIDTH; i++) begin
			total_sum_out_latched = total_sum_out_latched + partial_sums_in_latched[i];
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			total_sum_out <= 0;
		end else begin
			if(enabled)begin
				total_sum_out <= total_sum_out_latched;
			end
		end
	end



endmodule
