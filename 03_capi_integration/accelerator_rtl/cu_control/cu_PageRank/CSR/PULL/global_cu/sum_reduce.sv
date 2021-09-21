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
// Revise : 2020-03-12 21:45:25
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
	logic                      enabled                [0:BUS_WIDTH-1];

	integer j;
	genvar  i;

	////////////////////////////////////////////////////////////////////////////
	//enable logic
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < BUS_WIDTH; i++) begin : generate_sum_in
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					enabled[i] <= 0;
				end else begin
					enabled[i] <= enabled_in;
				end
			end
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					partial_sums_in_latched[i] <= 0;
				end else begin
					if(enabled[i]) begin
						partial_sums_in_latched[i] <= partial_sums_in[i];
					end
				end
			end
		end
	endgenerate

	always_comb begin
		total_sum_out_latched = 0;
		for (j = 0; j < BUS_WIDTH; j++) begin
			total_sum_out_latched = total_sum_out_latched + partial_sums_in_latched[j];
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			total_sum_out <= 0;
		end else begin
			total_sum_out <= total_sum_out_latched;
		end
	end




endmodule
