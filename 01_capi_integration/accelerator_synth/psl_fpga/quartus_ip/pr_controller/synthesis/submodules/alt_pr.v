// (C) 2001-2013 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


////////////////////////////////////////////////////////////////////
//
//  ALT_PR
//
//  Copyright (C) 1991-2013 Altera Corporation
//  Your use of Altera Corporation's design tools, logic functions 
//  and other software and tools, and its AMPP partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Altera Program License 
//  Subscription Agreement, Altera MegaCore Function License 
//  Agreement, or other applicable license agreement, including, 
//  without limitation, that your use is for the sole purpose of 
//  programming logic devices manufactured by Altera and sold by 
//  Altera or its authorized distributors.  Please refer to the 
//  applicable agreement for further details.
//
////////////////////////////////////////////////////////////////////

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pr(
	clk,
	nreset,
	pr_start,
	double_pr,
	freeze,
	status,
	data,
	data_valid,
	data_read,
	pr_ready_pin,
	pr_done_pin,
	pr_error_pin,
	pr_request_pin,
	pr_clk_pin,
	pr_data_pin,
	crc_error_pin
);
	parameter PR_INTERNAL_HOST = 1; // '1' means Internal Host, '0' means External Host
	parameter CDRATIO = 1; // valid: 1, 2, 4
	parameter DATA_WIDTH_INDEX = 16; // valid: 1, 2, 4, 8, 16, 32
	parameter CB_DATA_WIDTH = 16;
	parameter ENABLE_JTAG = 1;	// '1' means Enable JTAG debug mode, '0' means Disable
	parameter EDCRC_OSC_DIVIDER = 1; // valid: 1, 2, 4, 8, 16, 32, 64, 128, 256
	parameter DEVICE_FAMILY	= "Stratix V";
	parameter UNIQUE_IDENTIFIER = 2013;
	parameter ENABLE_BITSTREAM_COMPATIBILITY_CHECK = 0;
	
	input clk;
	input nreset;
	input pr_start;
	input double_pr;
	input data_valid;
	input [DATA_WIDTH_INDEX-1:0] data;
	input pr_ready_pin;
	input pr_done_pin;
	input pr_error_pin;
	input crc_error_pin;
	
	output freeze;
	output data_read;
	output [1:0] status;
	output pr_request_pin;
	output pr_clk_pin;
	output [CB_DATA_WIDTH-1:0] pr_data_pin;

	reg [1:0] status_reg;
	reg lock_error_reg;
	
	wire clk_w;
	wire pr_start_w;
	wire freeze_w;
	wire double_pr_w;
	wire crc_error_w;
	wire pr_error_w;
	wire pr_ready_w;
	wire pr_done_w;
	wire pr_clk_w;
	wire [CB_DATA_WIDTH-1:0] pr_data_w;
	wire [CB_DATA_WIDTH-1:0] data_w;
	wire data_valid_w;
	wire data_read_w;
	wire jtag_control_w;
	wire jtag_start_w;
	wire jtag_tck_w;
	wire jtag_double_pr_w;
	wire [CB_DATA_WIDTH-1:0] jtag_data_w;
	wire jtag_data_valid_w;
	wire jtag_data_read_w;
	wire [CB_DATA_WIDTH-1:0] stardard_data_w;
	wire stardard_data_valid_w;
	wire stardard_data_read_w;
	wire bitstream_incompatible_w;
	
	assign freeze = freeze_w;
	assign status = status_reg;
	assign pr_start_w = jtag_control_w ? jtag_start_w : pr_start;
	assign clk_w = jtag_control_w ? jtag_tck_w : clk;
	assign double_pr_w = jtag_control_w ? jtag_double_pr_w : double_pr;
	
	always @(negedge nreset or posedge clk_w)
	begin
		if (~nreset) begin
			status_reg <= 0;
			lock_error_reg <= 0;
		end
		else if (crc_error_w && ~lock_error_reg) begin
			status_reg <= 2'b10;
			lock_error_reg <= 1;
		end
		else if (freeze_w) begin
			if (bitstream_incompatible_w && ~lock_error_reg) begin
				status_reg <= 2'b11;
				lock_error_reg <= 1;
			end
			else if (pr_error_w && ~lock_error_reg) begin
				status_reg <= 2'b01;
				lock_error_reg <= 1;
			end
		end
		else if (pr_start_w) begin
			status_reg <= 0;
			lock_error_reg <= 0;
		end
	end
	
	alt_pr_cb_controller alt_pr_cb_controller(
		.clk(clk_w),
		.nreset(nreset),
		.pr_start(pr_start_w),
		.double_pr(double_pr_w),
		.o_freeze(freeze_w),
		.o_crc_error(crc_error_w),
		.o_pr_error(pr_error_w),
		.o_pr_ready(pr_ready_w),
		.o_pr_done(pr_done_w),
		.pr_clk(pr_clk_w),
		.pr_ready_pin(pr_ready_pin),
		.pr_done_pin(pr_done_pin),
		.pr_error_pin(pr_error_pin),
		.o_pr_request_pin(pr_request_pin),
		.o_pr_clk_pin(pr_clk_pin),
		.o_pr_data_pin(pr_data_pin),
		.crc_error_pin(crc_error_pin),
		.pr_data(pr_data_w)
	);
	defparam alt_pr_cb_controller.CDRATIO = CDRATIO; 
	defparam alt_pr_cb_controller.CB_DATA_WIDTH = CB_DATA_WIDTH;
	defparam alt_pr_cb_controller.EDCRC_OSC_DIVIDER = EDCRC_OSC_DIVIDER;
    defparam alt_pr_cb_controller.PR_INTERNAL_HOST = PR_INTERNAL_HOST;
	defparam alt_pr_cb_controller.DEVICE_FAMILY = DEVICE_FAMILY;
	defparam alt_pr_cb_controller.UNIQUE_IDENTIFIER = UNIQUE_IDENTIFIER;
	
	alt_pr_bitstream_host alt_pr_bitstream_host(
		.clk(clk_w),
		.nreset(nreset),
		.pr_start(pr_start_w),
		.double_pr(double_pr_w),
		.freeze(freeze_w),
		.crc_error(crc_error_w),
		.pr_error(pr_error_w),
		.pr_ready(pr_ready_w),
		.pr_done(pr_done_w),
		.data(data_w),
		.data_valid(data_valid_w),
		.o_data_read(data_read_w),
		.o_pr_clk(pr_clk_w),
		.o_pr_data(pr_data_w),
		.o_bitstream_incompatible(bitstream_incompatible_w)
	);
	defparam alt_pr_bitstream_host.PR_INTERNAL_HOST = PR_INTERNAL_HOST; 
	defparam alt_pr_bitstream_host.CDRATIO = CDRATIO; 
	defparam alt_pr_bitstream_host.DONE_TO_END = ((CDRATIO==1) ? 7 : ((CDRATIO==2) ? 3 : 1 ));
	defparam alt_pr_bitstream_host.CB_DATA_WIDTH = CB_DATA_WIDTH; 
	defparam alt_pr_bitstream_host.UNIQUE_IDENTIFIER = UNIQUE_IDENTIFIER;
	defparam alt_pr_bitstream_host.ENABLE_BITSTREAM_COMPATIBILITY_CHECK = ENABLE_BITSTREAM_COMPATIBILITY_CHECK; 
	
	alt_pr_data_source_controller alt_pr_data_source_controller(
		.clk(clk_w),
		.nreset(nreset),
		.jtag_control(jtag_control_w),
		.jtag_data(jtag_data_w),
		.jtag_data_valid(jtag_data_valid_w),
		.o_jtag_data_read(jtag_data_read_w),
		.standard_data(stardard_data_w),
		.standard_data_valid(stardard_data_valid_w),
		.o_standard_data_read(stardard_data_read_w),
		.data_read(data_read_w),
		.o_data(data_w),
		.o_data_valid(data_valid_w)
	);
	defparam alt_pr_data_source_controller.CB_DATA_WIDTH = CB_DATA_WIDTH; 
	
	alt_pr_standard_data_interface alt_pr_standard_data_interface(
		.clk(clk_w),
		.nreset(nreset),
		.freeze(freeze_w),
		.o_stardard_data(stardard_data_w),
		.o_stardard_data_valid(stardard_data_valid_w),
		.stardard_data_read(stardard_data_read_w),
		.data(data),
		.data_valid(data_valid),
		.o_data_read(data_read)
	);
	defparam alt_pr_standard_data_interface.CB_DATA_WIDTH = CB_DATA_WIDTH; 
	defparam alt_pr_standard_data_interface.DATA_WIDTH_INDEX = DATA_WIDTH_INDEX; 

	generate
		if (ENABLE_JTAG == 1) begin
			alt_pr_jtag_interface alt_pr_jtag_interface(
				.nreset(nreset),
				.freeze(freeze_w),
				.pr_ready(pr_ready_w),
				.pr_done(pr_done_w),
				.pr_error(pr_error_w),
				.crc_error(crc_error_w),
				.o_tck(jtag_tck_w),
				.o_double_pr(jtag_double_pr_w),
				.o_jtag_control(jtag_control_w),
				.o_jtag_start(jtag_start_w),
				.o_jtag_data(jtag_data_w),
				.o_jtag_data_valid(jtag_data_valid_w),
				.jtag_data_read(jtag_data_read_w),
				.bitstream_incompatible(bitstream_incompatible_w)
			);
			defparam alt_pr_jtag_interface.PR_INTERNAL_HOST = PR_INTERNAL_HOST;
			defparam alt_pr_jtag_interface.CB_DATA_WIDTH = CB_DATA_WIDTH;
		end
		else begin
			assign jtag_tck_w = 1'b0;
			assign jtag_double_pr_w = 1'b0;
			assign jtag_control_w = 1'b0;
			assign jtag_start_w = 1'b0;
			assign jtag_data_w = 1'b0;
			assign jtag_data_valid_w = 1'b0;
		end
	endgenerate 
	
endmodule

