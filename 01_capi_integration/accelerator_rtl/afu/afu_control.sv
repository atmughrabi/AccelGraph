// -----------------------------------------------------------------------------
//
//		"CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : afu_control.sv
// Create : 2019-09-26 15:20:35
// Revise : 2019-12-07 01:48:34
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;


module afu_control #(
	parameter NUM_REQUESTS    = 5 ,
	parameter RSP_DELAY       = 10,
	parameter CREDIT_HEADROOM = 8
) (
	input  logic                         clock                      , // Clock
	input  logic                         rstn                       ,
	input  logic                         enabled_in                 ,
	input  afu_configure_type            afu_configure              ,
	input  CommandBufferLine             prefetch_read_command_in   ,
	input  CommandBufferLine             prefetch_write_command_in  ,
	input  CommandBufferLine             read_command_in            ,
	input  CommandBufferLine             write_command_in           ,
	input  CommandBufferLine             wed_command_in             ,
	input  CommandInterfaceInput         command_in                 ,
	input  ResponseInterface             response                   ,
	input  BufferInterfaceInput          buffer_in                  ,
	input  ReadWriteDataLine             write_data_0_in            ,
	input  ReadWriteDataLine             write_data_1_in            ,
	output logic [0:63]                  afu_status                 ,
	output ReadWriteDataLine             wed_data_0_out             ,
	output ReadWriteDataLine             wed_data_1_out             ,
	output ReadWriteDataLine             read_data_0_out            ,
	output ReadWriteDataLine             read_data_1_out            ,
	output ResponseBufferLine            read_response_out          ,
	output ResponseBufferLine            prefetch_read_response_out ,
	output ResponseBufferLine            prefetch_write_response_out,
	output ResponseBufferLine            write_response_out         ,
	output ResponseBufferLine            wed_response_out           ,
	output logic [ 0:6]                  command_response_error     ,
	output logic [ 0:1]                  data_read_error            ,
	output logic                         data_write_error           ,
	output logic                         credit_overflow_error      ,
	output BufferInterfaceOutput         buffer_out                 ,
	output CommandInterfaceOutput        command_out                ,
	output CommandBufferStatusInterface  command_buffer_status      ,
	output ResponseStatistcsInterface    response_statistics        ,
	output ResponseBufferStatusInterface response_buffer_status     ,
	output DataBufferStatusInterface     read_data_buffer_status    ,
	output DataBufferStatusInterface     wed_data_buffer_status     ,
	output DataBufferStatusInterface     write_data_buffer_status
);



////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL
////////////////////////////////////////////////////////////////////////////

	CommandInterfaceInput command_in_latched;

	ResponseInterface response_tagged                  ;
	ResponseInterface response_tagged_latched          ;
	ResponseInterface response_filtered_done           ;
	ResponseInterface response_filtered_done_latched   ;
	ResponseInterface response_filtered_stats          ;
	ResponseInterface response_filtered_stats_latched  ;
	ResponseInterface response_filtered_restart        ;
	ResponseInterface response_filtered_restart_latched;


	ReadDataControlInterface  read_buffer_in ;
	WriteDataControlInterface write_buffer_in;

////////////////////////////////////////////////////////////////////////////
//Command
////////////////////////////////////////////////////////////////////////////

	ReadWriteDataLine write_data_0;
	ReadWriteDataLine write_data_1;

	ReadWriteDataLine cu_write_data_0;
	ReadWriteDataLine cu_write_data_1;


	CommandBufferLine prefetch_read_command_buffer_out ;
	CommandBufferLine prefetch_write_command_buffer_out;
	CommandBufferLine read_command_buffer_out          ;
	CommandBufferLine write_command_buffer_out         ;
	CommandBufferLine wed_command_buffer_out           ;


	ResponseControlInterfaceOut response_control_out         ;
	ResponseControlInterfaceOut response_control_out_internal;

	DataControlInterfaceOut read_data_control_out_0;
	DataControlInterfaceOut read_data_control_out_1;

	//As long as there are commands in the FIFO set it request for bus access / if there are credits

	CreditInterfaceOutput credits               ;
	CreditInterfaceOutput credits_read          ;
	CreditInterfaceOutput credits_prefetch_read ;
	CreditInterfaceOutput credits_prefetch_write;
	CreditInterfaceOutput credits_write         ;

	logic [0:7] write_tag          ;
	logic [0:7] command_tag        ;
	logic [0:7] command_tag_latched;

	logic          tag_buffer_ready;
	CommandTagLine response_tag_id ;
	CommandTagLine read_tag_id     ;
	CommandTagLine command_tag_id  ;

	logic             round_robin_priority_enabled   ;
	logic             fixed_priority_enabled         ;
	CommandBufferLine command_arbiter_out            ;
	CommandBufferLine command_arbiter_out_fixed      ;
	CommandBufferLine command_arbiter_out_round_robin;

	logic [NUM_REQUESTS-1:0] requests;
	logic [NUM_REQUESTS-1:0] submit  ;

	logic [NUM_REQUESTS-1:0] ready            ;
	logic [NUM_REQUESTS-1:0] ready_fixed      ;
	logic [NUM_REQUESTS-1:0] ready_round_robin;

	CommandBufferLine command_buffer_in[0:NUM_REQUESTS-1];

	logic enabled                      ;
	logic enabled_credit_total         ;
	logic enabled_credit_read          ;
	logic enabled_credit_write         ;
	logic enabled_credit_prefetch_read ;
	logic enabled_credit_prefetch_write;



	DataBufferStatusInterface burst_write_data_buffer_status ;
	BufferStatus              burst_command_buffer_states_afu;
	logic                     burst_command_buffer_pop       ;
	CommandBufferLine         burst_command_buffer_out       ;
	CommandBufferLine         command_buffer_out             ;
	CommandBufferLine         command_buffer_out_bypass      ;


	logic command_write_valid;

	ResponseStatistcsInterface response_statistics_out;
	ResponseBufferLine         restart_response_out   ;
	CommandBufferLine          restart_command_out    ;
	logic                      restart_pending        ;
	logic                      ready_restart_issue    ;

	CommandBufferLine command_issue_register;

	ResponseControlInterfaceOut response_control_out_latched_S[0:RSP_DELAY-1];

	logic [ 0:7] total_credits          ;
	logic [ 0:7] read_credits           ;
	logic [ 0:7] write_credits          ;
	logic [ 0:7] prefetch_read_credits  ;
	logic [ 0:7] prefetch_write_credits ;
	logic [0:63] afu_configure_latched  ;
	logic [0:63] afu_configure_2_latched;

	genvar i;

	assign afu_config_ready = (|afu_configure_latched);
////////////////////////////////////////////////////////////////////////////
//drive output response stats
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			response_statistics <= 0;
		end else begin
			response_statistics <= response_statistics_out;
		end
	end

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			afu_status              <= 0;
			afu_configure_latched   <= 0;
			afu_configure_2_latched <= 0;
		end else begin
			if(enabled) begin
				if((|afu_configure.var1)) begin
					afu_status            <= afu_configure.var1;
					afu_configure_latched <= afu_configure.var1;
				end
				if((|afu_configure.var2)) begin
					afu_configure_2_latched <= afu_configure.var2;
				end
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled <= 0;
		end else begin
			enabled <= enabled_in;
		end
	end

////////////////////////////////////////////////////////////////////////////
//filter responses
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			response_filtered_done    <= 0;
			response_filtered_restart <= 0;
			response_tagged           <= 0;
			response_filtered_stats   <= 0;
		end else begin
			if(enabled && response.valid) begin
				case (response.response)
					DONE,NLOCK,NRES,FAILED: begin
						response_filtered_done    <= response;
						response_filtered_restart <= 0;
						response_tagged           <= response;
					end
					DERROR,AERROR,PAGED,FAULT,FLUSHED: begin
						response_filtered_done    <= 0;
						response_filtered_restart <= response;
						response_tagged           <= response;
						response_tagged.valid     <= 0;
					end
					default : begin
						response_filtered_done    <= response;
						response_filtered_restart <= 0;
						response_tagged           <= response;
					end
				endcase

				response_filtered_stats <= response;

			end else begin
				response_filtered_done    <= 0;
				response_filtered_restart <= 0;
				response_tagged           <= 0;
				response_filtered_stats   <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//capture response statistics
////////////////////////////////////////////////////////////////////////////

	response_statistics_control response_statistics_control_instant (
		.clock                  (clock                          ),
		.rstn                   (rstn                           ),
		.enabled_in             (enabled                        ),
		.response               (response_filtered_stats_latched),
		.response_tag_id_in     (response_tag_id                ),
		.response_statistics_out(response_statistics_out        )
	);

////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock) begin
		command_in_latched <= command_in;

		response_filtered_stats_latched   <= response_filtered_stats;
		response_filtered_done_latched    <= response_filtered_done;
		response_filtered_restart_latched <= response_filtered_restart;
		response_tagged_latched           <= response_tagged;

		write_tag <= buffer_in.write_tag;

		read_buffer_in.write_valid      <= buffer_in.write_valid;
		read_buffer_in.write_tag        <= buffer_in.write_tag;
		read_buffer_in.write_tag_parity <= buffer_in.write_tag_parity;
		read_buffer_in.write_address    <= buffer_in.write_address;
		read_buffer_in.write_data       <= buffer_in.write_data;
		read_buffer_in.write_parity     <= buffer_in.write_parity;

		write_buffer_in.read_valid      <= buffer_in.read_valid;
		write_buffer_in.read_tag        <= buffer_in.read_tag;
		write_buffer_in.read_tag_parity <= buffer_in.read_tag_parity;
		write_buffer_in.read_address    <= buffer_in.read_address;
	end

////////////////////////////////////////////////////////////////////////////
//command request logic Priority 0->NUM_REQUESTS (high)->(low)
////////////////////////////////////////////////////////////////////////////

	assign requests[PRIORITY_WED]            = ~command_buffer_status.wed_buffer.empty 		 && ~burst_command_buffer_states_afu.alfull;
	assign requests[PRIORITY_WRITE]          = ~command_buffer_status.write_buffer.empty  	 && ~burst_command_buffer_states_afu.alfull && (|credits_write.credits);
	assign requests[PRIORITY_READ]           = ~command_buffer_status.read_buffer.empty   	 && ~burst_command_buffer_states_afu.alfull && (|credits_read.credits);
	assign requests[PRIORITY_PREFTECH_WRITE] = ~command_buffer_status.prefetch_write_buffer.empty    && ~burst_command_buffer_states_afu.alfull && (|credits_prefetch_write.credits);
	assign requests[PRIORITY_PREFETCH_READ]  = ~command_buffer_status.prefetch_read_buffer.empty     && ~burst_command_buffer_states_afu.alfull && (|credits_prefetch_read.credits);

	assign command_buffer_in[PRIORITY_WED]            = wed_command_buffer_out;
	assign command_buffer_in[PRIORITY_WRITE]          = write_command_buffer_out;
	assign command_buffer_in[PRIORITY_READ]           = read_command_buffer_out;
	assign command_buffer_in[PRIORITY_PREFTECH_WRITE] = prefetch_write_command_buffer_out;
	assign command_buffer_in[PRIORITY_PREFETCH_READ]  = prefetch_read_command_buffer_out;

	assign submit[PRIORITY_WED]            = wed_command_buffer_out.valid;
	assign submit[PRIORITY_WRITE]          = write_command_buffer_out.valid;
	assign submit[PRIORITY_READ]           = read_command_buffer_out.valid;
	assign submit[PRIORITY_PREFTECH_WRITE] = prefetch_write_command_buffer_out.valid;
	assign submit[PRIORITY_PREFETCH_READ]  = prefetch_read_command_buffer_out.valid;

////////////////////////////////////////////////////////////////////////////
//Buffer arbitration logic
////////////////////////////////////////////////////////////////////////////

	// always_comb begin
	// 	command_arbiter_out.valid    = command_arbiter_out_round_robin.valid;
	// 	ready                        = ready_round_robin;
	// 	round_robin_priority_enabled = 0;
	// 	fixed_priority_enabled       = 0;
	// 	if(enabled)begin
	// 		if(afu_configure_latched[63]) begin
	// 			command_arbiter_out.valid    = command_arbiter_out_round_robin.valid;
	// 			ready                        = ready_round_robin;
	// 			round_robin_priority_enabled = 1;
	// 			fixed_priority_enabled       = 0;
	// 		end else if(afu_configure_latched[62]) begin
	// 			command_arbiter_out.valid    = command_arbiter_out_fixed.valid;
	// 			ready                        = ready_fixed;
	// 			round_robin_priority_enabled = 0;
	// 			fixed_priority_enabled       = 1;
	// 		end
	// 	end
	// end

	// always_comb begin
	// 	command_arbiter_out.payload = command_arbiter_out_round_robin.payload ;
	// 	if(afu_configure_latched[63]) begin
	// 		command_arbiter_out.payload = command_arbiter_out_round_robin.payload ;
	// 	end else if(afu_configure_latched[62]) begin
	// 		command_arbiter_out.payload = command_arbiter_out_fixed.payload ;
	// 	end
	// end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			command_arbiter_out.valid    <= 0;
			ready                        <= 0;
			round_robin_priority_enabled <= 0;
			fixed_priority_enabled       <= 0;
		end else begin
			if(enabled)begin
				if(afu_configure_latched[63]) begin
					command_arbiter_out.valid    <= command_arbiter_out_round_robin.valid;
					ready                        <= ready_round_robin;
					round_robin_priority_enabled <= 1;
					fixed_priority_enabled       <= 0;
				end else if(afu_configure_latched[62]) begin
					command_arbiter_out.valid    <= command_arbiter_out_fixed.valid;
					ready                        <= ready_fixed;
					round_robin_priority_enabled <= 0;
					fixed_priority_enabled       <= 1;
				end else begin
					command_arbiter_out.valid    <= command_arbiter_out_round_robin.valid;
					ready                        <= ready_round_robin;
					round_robin_priority_enabled <= 1;
					fixed_priority_enabled       <= 0;
				end
			end
		end
	end

	always_ff @(posedge clock) begin
		if(afu_configure_latched[63]) begin
			command_arbiter_out.payload <= command_arbiter_out_round_robin.payload ;
		end else if(afu_configure_latched[62]) begin
			command_arbiter_out.payload <= command_arbiter_out_fixed.payload ;
		end else begin
			command_arbiter_out.payload <= command_arbiter_out_round_robin.payload ;
		end
	end

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_REQUESTS            ),
		.WIDTH       ($bits(CommandBufferLine))
	) round_robin_priority_arbiter_N_input_1_ouput_command_buffer_arbiter_instant (
		.clock      (clock                          ),
		.rstn       (rstn                           ),
		.enabled    (round_robin_priority_enabled   ),
		.buffer_in  (command_buffer_in              ),
		.submit     (submit                         ),
		.requests   (requests                       ),
		.arbiter_out(command_arbiter_out_round_robin),
		.ready      (ready_round_robin              )
	);

	fixed_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_REQUESTS            ),
		.WIDTH       ($bits(CommandBufferLine))
	) fixed_priority_arbiter_N_input_1_ouput_command_buffer_arbiter_instant (
		.clock      (clock                    ),
		.rstn       (rstn                     ),
		.enabled    (fixed_priority_enabled   ),
		.buffer_in  (command_buffer_in        ),
		.submit     (submit                   ),
		.requests   (requests                 ),
		.arbiter_out(command_arbiter_out_fixed),
		.ready      (ready_fixed              )
	);


////////////////////////////////////////////////////////////////////////////
//command interface control logic
////////////////////////////////////////////////////////////////////////////

	command_control command_control_instant (
		.clock             (clock                 ),
		.rstn              (rstn                  ),
		.enabled_in        (enabled               ),
		.command_arbiter_in(command_issue_register),
		.command_tag_in    (command_tag_latched   ),
		.command_out       (command_out           )
	);

////////////////////////////////////////////////////////////////////////////
//command restart control logic
////////////////////////////////////////////////////////////////////////////


	restart_control restart_command_control_instant (
		.clock                    (clock                            ),
		.enabled_in               (enabled                          ),
		.rstn                     (rstn                             ),
		.command_outstanding_in   (command_issue_register           ),
		.command_tag_in           (command_tag_latched              ),
		.restart_response_in      (restart_response_out             ),
		.response_in              (response_filtered_restart_latched),
		.response_tag_id_in       (response_tag_id                  ),
		.credits_in               (credits.credits                  ),
		.total_credits            (total_credits                    ),
		.ready_restart_issue      (ready_restart_issue              ),
		.restart_command_issue_out(restart_command_out              ),
		.restart_command_flushed  (restart_command_flushed          ),
		.restart_pending          (restart_pending                  )
	);


////////////////////////////////////////////////////////////////////////////
//command restart/regular switch control logic
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			command_issue_register.valid <= 0;
			command_tag_latched          <= 0;
		end else begin
			if(enabled) begin
				if(ready_restart_issue && command_buffer_out_bypass.valid) begin
					command_issue_register.valid <= command_buffer_out_bypass.valid;
					command_tag_latched          <= command_buffer_out_bypass.payload.cmd.tag;
				end else begin
					command_issue_register.valid <= command_buffer_out.valid;
					command_tag_latched          <= command_tag;
				end
			end
		end
	end

	always_ff @(posedge clock) begin
		if(ready_restart_issue && command_buffer_out_bypass.valid) begin
			command_issue_register.payload <= command_buffer_out_bypass.payload;
		end else begin
			command_issue_register.payload <= command_buffer_out.payload;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			command_buffer_out.valid        <= 0;
			command_buffer_out_bypass.valid <= 0;
		end else begin
			if(enabled) begin
				if(ready_restart_issue && (restart_command_out.valid && restart_command_flushed)) begin
					command_buffer_out_bypass.valid <= restart_command_out.valid ;
					command_buffer_out.valid        <= 0;
				end else if(ready_restart_issue && (restart_command_out.valid && ~restart_command_flushed)) begin
					command_buffer_out.valid        <= restart_command_out.valid ;
					command_buffer_out_bypass.valid <= 0;
				end else if (burst_command_buffer_out.valid) begin
					command_buffer_out.valid        <= burst_command_buffer_out.valid ;
					command_buffer_out_bypass.valid <= 0;
				end else begin
					command_buffer_out.valid        <= 0;
					command_buffer_out_bypass.valid <= 0;
				end
			end
		end
	end

	always_ff @(posedge clock) begin
		if(ready_restart_issue && (restart_command_out.valid && restart_command_flushed)) begin
			command_buffer_out_bypass.payload <= restart_command_out.payload;
		end else if(ready_restart_issue && (restart_command_out.valid && ~restart_command_flushed)) begin
			command_buffer_out.payload <= restart_command_out.payload;
		end else if (burst_command_buffer_out.valid) begin
			command_buffer_out.payload <= burst_command_buffer_out.payload;
		end
	end


////////////////////////////////////////////////////////////////////////////
//Credit Tracking Logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			total_credits          <= 0;
			read_credits           <= 0;
			write_credits          <= 0;
			prefetch_read_credits  <= 0;
			prefetch_write_credits <= 0;
			credit_overflow_error  <= 0;
		end else begin
			if(afu_config_ready) begin
				total_credits          <= (command_in_latched.room-CREDIT_HEADROOM);
				read_credits           <= (total_credits >> afu_configure_latched[0:3]);
				write_credits          <= (total_credits >> afu_configure_latched[4:7]);
				prefetch_read_credits  <= (total_credits >> afu_configure_latched[8:11]);
				prefetch_write_credits <= (total_credits >> afu_configure_latched[12:15]);
			end
			if(enabled) begin
				if((credits.credits <= 255) && (credits.credits > 64))
					credit_overflow_error <= 1;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled_credit_total          <= 0;
			enabled_credit_read           <= 0;
			enabled_credit_write          <= 0;
			enabled_credit_prefetch_read  <= 0;
			enabled_credit_prefetch_write <= 0;
		end else begin
			if(|total_credits) begin
				enabled_credit_total          <= 1;
				enabled_credit_read           <= 1;
				enabled_credit_write          <= 1;
				enabled_credit_prefetch_read  <= 1;
				enabled_credit_prefetch_write <= 1;
			end
		end
	end


	credit_control credits_total_control_instant (
		.clock     (clock                                                                                                                              ),
		.rstn      (rstn                                                                                                                               ),
		.enabled_in(enabled_credit_total                                                                                                               ),
		.credit_in ({command_buffer_out.valid,response_control_out.response.valid,response_control_out.response.payload.response_credits,total_credits}),
		.credit_out(credits                                                                                                                            )
	);

	credit_control credits_read_control_instant (
		.clock     (clock                                                                                                                                 ),
		.rstn      (rstn                                                                                                                                  ),
		.enabled_in(enabled_credit_read                                                                                                                   ),
		.credit_in ({read_command_buffer_out.valid,response_control_out.read_response,response_control_out.response.payload.response_credits,read_credits}),
		.credit_out(credits_read                                                                                                                          )
	);


	credit_control credits_write_control_instant (
		.clock     (clock                                                                                                                                    ),
		.rstn      (rstn                                                                                                                                     ),
		.enabled_in(enabled_credit_write                                                                                                                     ),
		.credit_in ({write_command_buffer_out.valid,response_control_out.write_response,response_control_out.response.payload.response_credits,write_credits}),
		.credit_out(credits_write                                                                                                                            )
	);

	credit_control credits_prefetch_read_control_instant (
		.clock     (clock                                                                                                                                                            ),
		.rstn      (rstn                                                                                                                                                             ),
		.enabled_in(enabled_credit_prefetch_read                                                                                                                                     ),
		.credit_in ({prefetch_read_command_buffer_out.valid,response_control_out.prefetch_read_response,response_control_out.response.payload.response_credits,prefetch_read_credits}),
		.credit_out(credits_prefetch_read                                                                                                                                            )
	);

	credit_control credits_prefetch_write_control_instant (
		.clock     (clock                                                                                                                                                               ),
		.rstn      (rstn                                                                                                                                                                ),
		.enabled_in(enabled_credit_prefetch_write                                                                                                                                       ),
		.credit_in ({prefetch_write_command_buffer_out.valid,response_control_out.prefetch_write_response,response_control_out.response.payload.response_credits,prefetch_write_credits}),
		.credit_out(credits_prefetch_write                                                                                                                                              )
	);


////////////////////////////////////////////////////////////////////////////
//response control
////////////////////////////////////////////////////////////////////////////


	response_control response_control_instant (
		.clock               (clock                         ),
		.rstn                (rstn                          ),
		.enabled_in          (enabled                       ),
		.response            (response_filtered_done_latched),
		.response_tag_id_in  (response_tag_id               ),
		.response_error      (command_response_error        ),
		.response_control_out(response_control_out_internal )
	);

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			response_control_out_latched_S[0].response.valid <= 0;
		end else begin
			if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
				response_control_out_latched_S[0] <= response_control_out_internal;
			end
		end
	end

	generate
		for ( i = 1; i < (RSP_DELAY); i++) begin : generate_response_delay
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					response_control_out_latched_S[i].response.valid  <= 0;
				end else begin
					if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
						response_control_out_latched_S[i] <= response_control_out_latched_S[i-1];
					end
				end
			end
		end
	endgenerate

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			response_control_out.response.valid <= 0;
		end else begin
			if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
				response_control_out <= response_control_out_latched_S[RSP_DELAY-1];
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//read data control
////////////////////////////////////////////////////////////////////////////


	read_data_control read_data_control_instant (
		.clock                  (clock                        ),
		.rstn                   (rstn                         ),
		.enabled_in             (enabled                      ),
		.buffer_in              (read_buffer_in               ),
		.data_read_tag_id_in    (read_tag_id                  ),
		.response_control_in    (response_control_out_internal),
		.data_read_error        (data_read_error              ),
		.read_data_control_out_0(read_data_control_out_0      ),
		.read_data_control_out_1(read_data_control_out_1      )
	);

////////////////////////////////////////////////////////////////////////////
//write data control
////////////////////////////////////////////////////////////////////////////

	always_comb begin
		command_write_valid = 0;
		if(command_buffer_out.valid)begin
			if(command_buffer_out.payload.cmd.cmd_type == CMD_WRITE)
				command_write_valid = 1;
			else
				command_write_valid = 0;
		end
	end


	write_data_control write_data_control_instant (
		.clock           (clock           ),
		.rstn            (rstn            ),
		.enabled_in      (enabled         ),
		.buffer_in       (write_buffer_in ),
		.command_tag_in  (command_tag     ),
		.write_data_0_in (write_data_0    ),
		.write_data_1_in (write_data_1    ),
		.data_write_error(data_write_error),
		.buffer_out      (buffer_out      )
	);


////////////////////////////////////////////////////////////////////////////
//tag control
////////////////////////////////////////////////////////////////////////////


	assign command_tag_id = command_buffer_out.payload.cmd;

	tag_control tag_control_instant (
		.clock               (clock                        ),
		.rstn                (rstn                         ),
		.enabled_in          (enabled                      ),
		.tag_response_valid  (response_tagged_latched.valid),
		.response_tag        (response_tagged_latched.tag  ),
		.response_tag_id_out (response_tag_id              ),
		.data_read_tag       (write_tag                    ), // reminder PSL sees read as write and opposite
		.data_read_tag_id_out(read_tag_id                  ),
		.tag_command_valid   (command_buffer_out.valid     ),
		.tag_command_id      (command_tag_id               ),
		.command_tag_out     (command_tag                  ),
		.tag_buffer_ready    (tag_buffer_ready             )
	);

////////////////////////////////////////////////////////////////////////////
//Burst Buffer Read Commands
////////////////////////////////////////////////////////////////////////////

	// CommandBufferLine burst_command_buffer_touch   ;
	// CommandBufferLine burst_command_buffer_touch_S2;
	// CommandBufferLine burst_command_buffer_exec    ;
	// CommandBufferLine burst_command_buffer_exec_S2 ;
	// CommandBufferLine burst_command_buffer_exec_S3 ;

	// logic request_pulse                            ;
	// assign burst_command_buffer_pop = ~burst_command_buffer_states_afu.empty && tag_buffer_ready && (|credits.credits) && ~(|request_pulse);
	assign burst_command_buffer_pop = ~burst_command_buffer_states_afu.empty && tag_buffer_ready && (credits.credits>CREDIT_HEADROOM) && ~restart_pending;
	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(BURST_CMD_BUFFER_SIZE   )
	) burst_command_buffer_afu_fifo_instant (
		.clock   (clock                                 ),
		.rstn    (rstn                                  ),
		
		.push    (command_arbiter_out.valid             ),
		.data_in (command_arbiter_out                   ),
		.full    (burst_command_buffer_states_afu.full  ),
		.alFull  (burst_command_buffer_states_afu.alfull),
		
		.pop     (burst_command_buffer_pop              ),
		.valid   (burst_command_buffer_states_afu.valid ),
		.data_out(burst_command_buffer_out              ),
		.empty   (burst_command_buffer_states_afu.empty )
	);


////////////////////////////////////////////////////////////////////////////
//Buffer Prefetch READ Commands
////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(CommandBufferLine)     ),
		.DEPTH(PREFETCH_READ_CMD_BUFFER_SIZE)
	) preftech_read_command_buffer_fifo_instant (
		.clock   (clock                                            ),
		.rstn    (rstn                                             ),
		
		.push    (prefetch_read_command_in.valid                   ),
		.data_in (prefetch_read_command_in                         ),
		.full    (command_buffer_status.prefetch_read_buffer.full  ),
		.alFull  (command_buffer_status.prefetch_read_buffer.alfull),
		
		.pop     (ready[PRIORITY_PREFETCH_READ]                    ),
		.valid   (command_buffer_status.prefetch_read_buffer.valid ),
		.data_out(prefetch_read_command_buffer_out                 ),
		.empty   (command_buffer_status.prefetch_read_buffer.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Buffer Prefetch WRITE Commands
////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(CommandBufferLine)      ),
		.DEPTH(PREFETCH_WRITE_CMD_BUFFER_SIZE)
	) preftech_write_command_buffer_fifo_instant (
		.clock   (clock                                             ),
		.rstn    (rstn                                              ),
		
		.push    (prefetch_write_command_in.valid                   ),
		.data_in (prefetch_write_command_in                         ),
		.full    (command_buffer_status.prefetch_write_buffer.full  ),
		.alFull  (command_buffer_status.prefetch_write_buffer.alfull),
		
		.pop     (ready[PRIORITY_PREFTECH_WRITE]                    ),
		.valid   (command_buffer_status.prefetch_write_buffer.valid ),
		.data_out(prefetch_write_command_buffer_out                 ),
		.empty   (command_buffer_status.prefetch_write_buffer.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Buffer Read Commands
////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_command_buffer_fifo_instant (
		.clock   (clock                                   ),
		.rstn    (rstn                                    ),
		
		.push    (read_command_in.valid                   ),
		.data_in (read_command_in                         ),
		.full    (command_buffer_status.read_buffer.full  ),
		.alFull  (command_buffer_status.read_buffer.alfull),
		
		.pop     (ready[PRIORITY_READ]                    ),
		.valid   (command_buffer_status.read_buffer.valid ),
		.data_out(read_command_buffer_out                 ),
		.empty   (command_buffer_status.read_buffer.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Buffers Write Commands
////////////////////////////////////////////////////////////////////////////
	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(WRITE_CMD_BUFFER_SIZE   )
	) write_command_buffer_fifo_instant (
		.clock   (clock                                    ),
		.rstn    (rstn                                     ),
		
		.push    (write_command_in.valid                   ),
		.data_in (write_command_in                         ),
		.full    (command_buffer_status.write_buffer.full  ),
		.alFull  (command_buffer_status.write_buffer.alfull),
		
		.pop     (ready[PRIORITY_WRITE]                    ),
		.valid   (command_buffer_status.write_buffer.valid ),
		.data_out(write_command_buffer_out                 ),
		.empty   (command_buffer_status.write_buffer.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Buffers WED Commands
////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(WED_CMD_BUFFER_SIZE     )
	) wed_command_buffer_fifo_instant (
		.clock   (clock                                  ),
		.rstn    (rstn                                   ),
		
		.push    (wed_command_in.valid                   ),
		.data_in (wed_command_in                         ),
		.full    (command_buffer_status.wed_buffer.full  ),
		.alFull  (command_buffer_status.wed_buffer.alfull),
		
		.pop     (ready[PRIORITY_WED]                    ),
		.valid   (command_buffer_status.wed_buffer.valid ),
		.data_out(wed_command_buffer_out                 ),
		.empty   (command_buffer_status.wed_buffer.empty )
	);


////////////////////////////////////////////////////////////////////////////
//Response Buffers
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Write Responses
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_response_out.valid <= 0;
		end else begin
			if(enabled) begin
				if(response_control_out.write_response)
					write_response_out.valid <= response_control_out.response.valid;
				else
					write_response_out.valid <= 0;
			end
		end
	end


	always_ff @(posedge clock) begin
		write_response_out.payload <= response_control_out.response.payload;
	end

////////////////////////////////////////////////////////////////////////////
//Buffers Read Responses
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_out.valid <= 0;
		end else begin
			if(enabled) begin
				if(response_control_out.read_response)
					read_response_out.valid <= response_control_out.response.valid;
				else
					read_response_out.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_response_out.payload <= response_control_out.response.payload;
	end


////////////////////////////////////////////////////////////////////////////
//Buffers Prefetch READ Responses
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_read_response_out.valid <= 0;
		end else begin
			if(enabled) begin
				if(response_control_out.prefetch_read_response)
					prefetch_read_response_out.valid <= response_control_out.response.valid;
				else
					prefetch_read_response_out.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		prefetch_read_response_out.payload <= response_control_out.response.payload;
	end

////////////////////////////////////////////////////////////////////////////
//Buffers Prefetch WRITE Responses
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_write_response_out.valid <= 0;
		end else begin
			if(enabled) begin
				if(response_control_out.prefetch_write_response)
					prefetch_write_response_out.valid <= response_control_out.response.valid ;
				else
					prefetch_write_response_out.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		prefetch_write_response_out.payload <= response_control_out.response.payload;
	end

////////////////////////////////////////////////////////////////////////////
//restart Read Responses
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			restart_response_out.valid <= 0;
		end else begin
			if(enabled) begin
				if(response_control_out.restart_response)
					restart_response_out.valid <= response_control_out.response.valid;
				else
					restart_response_out.valid <= 0;
			end
		end
	end


	always_ff @(posedge clock) begin
		restart_response_out.payload <= response_control_out.response.payload;
	end

////////////////////////////////////////////////////////////////////////////
//Buffers WED Responses
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_response_out.valid <= 0;
		end else begin
			if(enabled) begin
				if(response_control_out.wed_response)
					wed_response_out.valid <= response_control_out.response.valid;
				else
					wed_response_out.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		wed_response_out.payload <= response_control_out.response.payload;
	end

////////////////////////////////////////////////////////////////////////////
//Buffers WED Read Data
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_data_0_out.valid <= 0;
		end else begin
			if(enabled) begin
				if(read_data_control_out_0.wed_data)
					wed_data_0_out.valid <= read_data_control_out_0.line.valid;
				else
					wed_data_0_out.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		wed_data_0_out.payload <= read_data_control_out_0.line.payload;
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_data_1_out.valid <= 0;
		end else begin
			if(enabled) begin
				if(read_data_control_out_1.wed_data)
					wed_data_1_out.valid <= read_data_control_out_1.line.valid;
				else
					wed_data_1_out.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		wed_data_1_out.payload <= read_data_control_out_1.line.payload;
	end

////////////////////////////////////////////////////////////////////////////
//Buffers CU Read Data
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_0_out.valid <= 0;
		end else begin
			if(enabled) begin
				if(read_data_control_out_0.read_data)
					read_data_0_out.valid <= read_data_control_out_0.line.valid;
				else
					read_data_0_out.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_data_0_out.payload <= read_data_control_out_0.line.payload;
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_data_1_out.valid <= 0;
		end else begin
			if(enabled) begin
				if(read_data_control_out_1.read_data)
					read_data_1_out.valid <= read_data_control_out_1.line.valid;
				else
					read_data_1_out.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_data_1_out.payload <= read_data_control_out_1.line.payload;
	end

////////////////////////////////////////////////////////////////////////////
//Buffers CU Write DATA
////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WRITE_DATA_BUFFER_SIZE  )
	) cu_write_data_0_buffer_fifo_instant (
		.clock   (clock                                   ),
		.rstn    (rstn                                    ),
		
		.push    (write_data_0_in.valid                   ),
		.data_in (write_data_0_in                         ),
		.full    (write_data_buffer_status.buffer_0.full  ),
		.alFull  (write_data_buffer_status.buffer_0.alfull),
		
		.pop     (ready[PRIORITY_WRITE]                   ),
		.valid   (write_data_buffer_status.buffer_0.valid ),
		.data_out(cu_write_data_0                         ),
		.empty   (write_data_buffer_status.buffer_0.empty )
	);


	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WRITE_DATA_BUFFER_SIZE  )
	) cu_write_data_1_buffer_fifo_instant (
		.clock   (clock                                   ),
		.rstn    (rstn                                    ),
		
		.push    (write_data_1_in.valid                   ),
		.data_in (write_data_1_in                         ),
		.full    (write_data_buffer_status.buffer_1.full  ),
		.alFull  (write_data_buffer_status.buffer_1.alfull),
		
		.pop     (ready[PRIORITY_WRITE]                   ),
		.valid   (write_data_buffer_status.buffer_1.valid ),
		.data_out(cu_write_data_1                         ),
		.empty   (write_data_buffer_status.buffer_1.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Burst Buffers CU Write DATA
////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(BURST_CMD_BUFFER_SIZE   )
	) burst_write_data_0_buffer_fifo_instant (
		.clock   (clock                                         ),
		.rstn    (rstn                                          ),
		
		.push    (cu_write_data_0.valid                         ),
		.data_in (cu_write_data_0                               ),
		.full    (burst_write_data_buffer_status.buffer_0.full  ),
		.alFull  (burst_write_data_buffer_status.buffer_0.alfull),
		
		.pop     (command_write_valid                           ),
		.valid   (burst_write_data_buffer_status.buffer_0.valid ),
		.data_out(write_data_0                                  ),
		.empty   (burst_write_data_buffer_status.buffer_0.empty )
	);


	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(BURST_CMD_BUFFER_SIZE   )
	) burst_write_data_1_buffer_fifo_instant (
		.clock   (clock                                         ),
		.rstn    (rstn                                          ),
		
		.push    (cu_write_data_1.valid                         ),
		.data_in (cu_write_data_1                               ),
		.full    (burst_write_data_buffer_status.buffer_1.full  ),
		.alFull  (burst_write_data_buffer_status.buffer_1.alfull),
		
		.pop     (command_write_valid                           ),
		.valid   (burst_write_data_buffer_status.buffer_1.valid ),
		.data_out(write_data_1                                  ),
		.empty   (burst_write_data_buffer_status.buffer_1.empty )
	);

endmodule





