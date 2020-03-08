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
// Revise : 2020-03-08 18:16:21
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

module demux_bus #(
	parameter DATA_WIDTH = 32               ,
	parameter BUS_WIDTH  = 8                ,
	parameter SEL_WIDTH  = $clog2(BUS_WIDTH)
) (
	input  logic                  clock                         ,
	input  logic                  rstn                          ,
	input  logic [ 0:SEL_WIDTH-1] sel_in                        ,
	input  logic [0:DATA_WIDTH-1] data_in                       ,
	input  logic                  data_in_valid                 ,
	output logic [0:DATA_WIDTH-1] data_out [0:BUS_WIDTH-1]      ,
	output logic                  data_out_valid [0:BUS_WIDTH-1]
);

	logic [0:SEL_WIDTH-1] sel_in_latched ;
	logic [0:SEL_WIDTH-1] sel_in_internal;

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
	//latch logic
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			data_in_valid_internal <= 0;
			data_in_valid_latched  <= 0;
			sel_in_internal        <= 0;
			sel_in_latched         <= 0;
		end else begin
			data_in_valid_internal <= data_in_valid;
			data_in_valid_latched  <= data_in_valid_internal;
			sel_in_internal        <= sel_in;
			sel_in_latched         <= sel_in_internal;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			data_in_internal <= 0;
		end else begin
			data_in_internal <= data_in;
		end
	end

	always_ff @(posedge clock) begin
		data_in_latched <= data_in_internal;
	end


	////////////////////////////////////////////////////////////////////////////
	//demux logic
	////////////////////////////////////////////////////////////////////////////

	generate
		for (i = 0; i < BUS_WIDTH; i++) begin : generate_demux
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					data_out_valid_internal[i] <= 0;
				end else begin
					if(sel_in_latched == i)begin
						data_out_valid_internal[i] <= data_in_valid_latched;
					end else begin
						data_out_valid_internal[i] <= 0;
					end
				end
			end

			always_ff @(posedge clock) begin
				data_out_internal[i] <= data_in_latched;
			end

			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					data_out[i]       <= 0;
					data_out_valid[i] <= 0;
				end else begin
					data_out[i]       <= data_out_latched[i];
					data_out_valid[i] <= data_out_valid_latched[i];
				end
			end
		end
	endgenerate

	always_ff @(posedge clock) begin
		data_out_valid_latched <= data_out_valid_internal;
		data_out_latched       <= data_out_internal;
	end


endmodule
