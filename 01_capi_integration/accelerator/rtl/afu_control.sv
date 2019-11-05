// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : afu_control.sv
// Create : 2019-09-26 15:20:35
// Revise : 2019-11-05 10:27:05
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;


module afu_control #(
	parameter NUM_REQUESTS = 4,
	parameter RSP_DELAY    = 4
) (
	input  logic                         clock                   , // Clock
	input  logic                         rstn                    ,
	input  logic                         enabled_in              ,
	input  CommandBufferLine             read_command_in         ,
	input  CommandBufferLine             write_command_in        ,
	input  CommandBufferLine             wed_command_in          ,
	input  CommandInterfaceInput         command_in              ,
	input  ResponseInterface             response                ,
	input  BufferInterfaceInput          buffer_in               ,
	input  ReadWriteDataLine             write_data_0_in         ,
	input  ReadWriteDataLine             write_data_1_in         ,
	output ReadWriteDataLine             wed_data_0_out          ,
	output ReadWriteDataLine             wed_data_1_out          ,
	output ReadWriteDataLine             read_data_0_out         ,
	output ReadWriteDataLine             read_data_1_out         ,
	output ResponseBufferLine            read_response_out       ,
	output ResponseBufferLine            write_response_out      ,
	output ResponseBufferLine            wed_response_out        ,
	output logic [0:6]                   command_response_error  ,
	output logic [0:1]                   data_read_error         ,
	output logic                         data_write_error        ,
	output BufferInterfaceOutput         buffer_out              ,
	output CommandInterfaceOutput        command_out             ,
	output CommandBufferStatusInterface  command_buffer_status   ,
	output ResponseBufferStatusInterface response_buffer_status  ,
	output DataBufferStatusInterface     read_data_buffer_status ,
	output DataBufferStatusInterface     wed_data_buffer_status  ,
	output DataBufferStatusInterface     write_data_buffer_status
);



////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL
////////////////////////////////////////////////////////////////////////////

	CommandInterfaceInput command_in_latched       ;
	ResponseInterface     response_latched         ;
	ResponseInterface     response_filtered        ;
	ResponseInterface     response_filtered_restart;


	ReadDataControlInterface  read_buffer_in ;
	WriteDataControlInterface write_buffer_in;

////////////////////////////////////////////////////////////////////////////
//Command
////////////////////////////////////////////////////////////////////////////

	ReadWriteDataLine write_data_0;
	ReadWriteDataLine write_data_1;

	CommandBufferLine read_command_buffer_out   ;
	CommandBufferLine write_command_buffer_out  ;
	CommandBufferLine wed_command_buffer_out    ;
	CommandBufferLine restart_command_buffer_out;
	CommandBufferLine restart_command_in        ;

	assign restart_command_in = 0;

	ResponseControlInterfaceOut response_control_out         ;
	ResponseControlInterfaceOut response_control_out_internal;
	logic                       wed_response_buffer_pop      ;
	logic                       read_response_buffer_pop     ;
	logic                       write_response_buffer_pop    ;
	logic                       restart_response_buffer_pop  ;

	DataControlInterfaceOut read_data_control_out_0   ;
	DataControlInterfaceOut read_data_control_out_1   ;
	logic                   wed_read_data_0_buffer_pop;
	logic                   wed_read_data_1_buffer_pop;
	logic                   read_data_0_buffer_pop    ;
	logic                   read_data_1_buffer_pop    ;

	//As long as there are commands in the FIFO set it request for bus access / if there are credits

	CreditInterfaceOutput credits      ;
	CreditInterfaceOutput credits_read ;
	CreditInterfaceOutput credits_write;

	logic [0:7] write_tag  ;
	logic [0:7] command_tag;

	logic          tag_buffer_ready;
	CommandTagLine response_tag_id ;
	CommandTagLine read_tag_id     ;
	CommandTagLine command_tag_id  ;

	CommandBufferLine        command_arbiter_out                  ;
	logic [NUM_REQUESTS-1:0] requests                             ;
	logic [NUM_REQUESTS-1:0] ready                                ;
	CommandBufferLine        command_buffer_in  [0:NUM_REQUESTS-1];
	logic                    valid_request                        ;

	logic enabled;

	BufferStatus      burst_command_buffer_states_afu;
	logic             burst_command_buffer_pop       ;
	CommandBufferLine burst_command_buffer_out       ;

	logic command_write_valid;

	ResponseBufferLine restart_response_out;

	genvar i;

	CommandBufferLine command_issue_register;

	ResponseControlInterfaceOut response_control_out_latched_S[0:RSP_DELAY-1];
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
//filter responses
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			response_filtered         <= 0;
			response_filtered_restart <= 0;
		end else begin
			if(enabled && response.valid) begin
				case (response.response)
					DONE,AERROR,DERROR,NLOCK,NRES,FAILED: begin
						response_filtered         <= response;
						response_filtered_restart <= 0;
					end
					PAGED,FAULT,FLUSHED: begin
						response_filtered         <= 0;
						response_filtered_restart <= response;
					end
					default : begin
						response_filtered         <= response;
						response_filtered_restart <= 0;
					end
				endcase
			end else begin
				response_filtered         <= 0;
				response_filtered_restart <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock) begin
		command_in_latched <= command_in;
		response_latched   <= response_filtered;

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
//command request logic
////////////////////////////////////////////////////////////////////////////

	assign requests[0]   = ~command_buffer_status.restart_buffer.empty 	 && ~burst_command_buffer_states_afu.alfull;
	assign requests[1]   = ~command_buffer_status.wed_buffer.empty 		 && ~burst_command_buffer_states_afu.alfull;
	assign requests[2]   = ~command_buffer_status.write_buffer.empty  	 && ~burst_command_buffer_states_afu.alfull && (|credits_write.credits);
	assign requests[3]   = ~command_buffer_status.read_buffer.empty   	 && ~burst_command_buffer_states_afu.alfull && (|credits_read.credits);
	assign valid_request = |requests;

	assign command_buffer_in[0] = restart_command_buffer_out;
	assign command_buffer_in[1] = wed_command_buffer_out;
	assign command_buffer_in[2] = write_command_buffer_out;
	assign command_buffer_in[3] = read_command_buffer_out;


////////////////////////////////////////////////////////////////////////////
//Buffer arbitration logic
////////////////////////////////////////////////////////////////////////////

	// command_buffer_arbiter #(.NUM_REQUESTS(NUM_REQUESTS)) command_buffer_arbiter_instant (
	// 	.clock              (clock              ),
	// 	.rstn               (rstn               ),
	// 	.enabled_in         (enabled            ),
	// 	.requests           (requests           ),
	// 	.command_buffer_in  (command_buffer_in  ),
	// 	.command_arbiter_out(command_arbiter_out),
	// 	.ready              (ready              )
	// );

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_REQUESTS            ),
		.WIDTH       ($bits(CommandBufferLine))
	) round_robin_priority_arbiter_N_input_1_ouput_command_buffer_arbiter_instant (
		.clock      (clock              ),
		.rstn       (rstn               ),
		.enabled    (enabled            ),
		.buffer_in  (command_buffer_in  ),
		.requests   (requests           ),
		.arbiter_out(command_arbiter_out),
		.ready      (ready              )
	);

////////////////////////////////////////////////////////////////////////////
//command interface control logic
////////////////////////////////////////////////////////////////////////////

	command_control command_control_instant (
		.clock             (clock                 ),
		.rstn              (rstn                  ),
		.enabled_in        (enabled               ),
		.command_arbiter_in(command_issue_register),
		.command_tag_in    (command_tag           ),
		.command_out       (command_out           )
	);

////////////////////////////////////////////////////////////////////////////
//command restart control logic
////////////////////////////////////////////////////////////////////////////

	CommandBufferLine restart_command_out;
	logic             restart_pending    ;

	restart_control restart_command_control_instant (
		.clock                 (clock                    ),
		.enabled_in            (enabled                  ),
		.rstn                  (rstn                     ),
		.command_outstanding_in(command_issue_register   ),
		.command_tag_in        (command_tag              ),
		.restart_response_in   (restart_response_out     ),
		.response              (response_filtered_restart),
		.credits_in            (credits.credits          ),
		.restart_command_out   (restart_command_out      ),
		.restart_pending       (restart_pending          )
	);


////////////////////////////////////////////////////////////////////////////
//Credit Tracking Logic
////////////////////////////////////////////////////////////////////////////

	credit_control credits_total_control_instant (
		.clock     (clock                                                                                                                                    ),
		.rstn      (rstn                                                                                                                                     ),
		.enabled_in(enabled                                                                                                                                  ),
		.credit_in ({command_issue_register.valid,response_control_out.response.valid,response_control_out.response.response_credits,command_in_latched.room}),
		.credit_out(credits                                                                                                                                  )
	);

	credit_control credits_read_control_instant (
		.clock     (clock                                                                                                                         ),
		.rstn      (rstn                                                                                                                          ),
		.enabled_in(enabled                                                                                                                       ),
		.credit_in ({read_command_buffer_out.valid,response_control_out.read_response,response_control_out.response.response_credits,CREDITS_READ}),
		.credit_out(credits_read                                                                                                                  )
	);

	credit_control credits_write_control_instant (
		.clock     (clock                                                                                                                            ),
		.rstn      (rstn                                                                                                                             ),
		.enabled_in(enabled                                                                                                                          ),
		.credit_in ({write_command_buffer_out.valid,response_control_out.write_response,response_control_out.response.response_credits,CREDITS_WRITE}),
		.credit_out(credits_write                                                                                                                    )
	);

////////////////////////////////////////////////////////////////////////////
//response control
////////////////////////////////////////////////////////////////////////////


	response_control response_control_instant (
		.clock               (clock                        ),
		.rstn                (rstn                         ),
		.enabled_in          (enabled                      ),
		.response            (response_latched             ),
		.response_tag_id_in  (response_tag_id              ),
		.response_error      (command_response_error       ),
		.response_control_out(response_control_out_internal)
	);

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			response_control_out_latched_S[0] <= 0;
		end else begin
			if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
				response_control_out_latched_S[0] <= response_control_out_internal;
			end else begin
				response_control_out_latched_S[0] <= 0;
			end
		end
	end

	generate
		for ( i = 1; i < (RSP_DELAY); i++) begin : generate_response_delay
			always_ff @(posedge clock or negedge rstn) begin
				if(~rstn) begin
					response_control_out_latched_S[i] <= 0;
				end else begin
					if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
						response_control_out_latched_S[i] <= response_control_out_latched_S[i-1];
					end else begin
						response_control_out_latched_S[i] <= 0;
					end
				end
			end
		end
	endgenerate

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			response_control_out <= 0;
		end else begin
			if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
				response_control_out <= response_control_out_latched_S[RSP_DELAY-1];
			end else begin
				response_control_out <= 0;
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
		if(command_issue_register.valid)begin
			if(command_issue_register.cmd.cmd_type == CMD_WRITE)
				command_write_valid = 1;
			else
				command_write_valid = 0;
		end
	end


	write_data_control write_data_control_instant (
		.clock              (clock              ),
		.rstn               (rstn               ),
		.enabled_in         (enabled            ),
		.buffer_in          (write_buffer_in    ),
		.command_write_valid(command_write_valid),
		.command_tag_in     (command_tag        ),
		.write_data_0_in    (write_data_0       ),
		.write_data_1_in    (write_data_1       ),
		.data_write_error   (data_write_error   ),
		.buffer_out         (buffer_out         )
	);


////////////////////////////////////////////////////////////////////////////
//tag control
////////////////////////////////////////////////////////////////////////////


	assign command_tag_id = command_issue_register.cmd;

	tag_control tag_control_instant (
		.clock               (clock                       ),
		.rstn                (rstn                        ),
		.enabled_in          (enabled                     ),
		.tag_response_valid  (response_latched.valid      ),
		.response_tag        (response_latched.tag        ),
		.response_tag_id_out (response_tag_id             ),
		.data_read_tag       (write_tag                   ), // reminder PSL sees read as write and opposite
		.data_read_tag_id_out(read_tag_id                 ),
		.tag_command_valid   (command_issue_register.valid),
		.tag_command_id      (command_tag_id              ),
		.command_tag_out     (command_tag                 ),
		.tag_buffer_ready    (tag_buffer_ready            )
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
	assign burst_command_buffer_pop = ~burst_command_buffer_states_afu.empty && tag_buffer_ready && (|credits.credits);
	fifo #(
		.WIDTH   ($bits(CommandBufferLine)),
		.DEPTH   (16                      ),
		.HEADROOM(8                       )
	) burst_command_buffer_afu_fifo_instant (
		.clock   (clock                                 ),
		.rstn    (rstn                                  ),
		
		.push    (command_arbiter_out.valid             ),
		.data_in (command_arbiter_out                   ),
		.full    (burst_command_buffer_states_afu.full  ),
		.alFull  (burst_command_buffer_states_afu.alfull),
		
		.pop     (burst_command_buffer_pop              ),
		.valid   (burst_command_buffer_states_afu.valid ),
		.data_out(command_issue_register                ),
		.empty   (burst_command_buffer_states_afu.empty )
	);


	// always_ff @(posedge clock or negedge rstn) begin
	// 		if(~rstn) begin
	// 			request_pulse <= 0;
	// 		end else begin
	// 			request_pulse <= request_pulse + 1;
	// 		end
	// end

	// always_ff @(posedge clock or negedge rstn) begin
	// 	if(~rstn) begin
	// 		burst_command_buffer_touch    <= 0;
	// 		burst_command_buffer_touch_S2 <= 0;
	// 		burst_command_buffer_exec     <= 0;
	// 		burst_command_buffer_exec_S2  <= 0;
	// 		burst_command_buffer_exec_S3  <= 0;
	// 		command_issue_register        <= 0;
	// 	end else begin
	// 		if(enabled) begin
	// 			burst_command_buffer_touch              <= burst_command_buffer_out;
	// 			burst_command_buffer_touch.command      <= TOUCH_I;
	// 			burst_command_buffer_touch.size         <= 12'h080;
	// 			burst_command_buffer_touch.address      <= (burst_command_buffer_out.address & ADDRESS_EDGE_ALIGN_MASK);
	// 			burst_command_buffer_touch.cmd.cu_id    <= PREFETCH_CONTROL_ID;
	// 			burst_command_buffer_touch.cmd.cmd_type <= CMD_PREFETCH;
	// 			burst_command_buffer_touch_S2 <= burst_command_buffer_touch;

	// 			burst_command_buffer_exec    <= burst_command_buffer_out;
	// 			burst_command_buffer_exec_S2 <= burst_command_buffer_exec;
	// 			burst_command_buffer_exec_S3 <= burst_command_buffer_exec_S2;

	// 			if(burst_command_buffer_touch_S2.valid)
	// 				command_issue_register <= burst_command_buffer_touch_S2;
	// 			else if(burst_command_buffer_exec_S3.valid)
	// 				command_issue_register <= burst_command_buffer_exec_S3;
	// 			else
	// 				command_issue_register <= 0;
	// 		end
	// 	end
	// end

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
		
		.pop     (ready[3]                                ),
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
		
		.pop     (ready[2]                                 ),
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
		
		.pop     (ready[1]                               ),
		.valid   (command_buffer_status.wed_buffer.valid ),
		.data_out(wed_command_buffer_out                 ),
		.empty   (command_buffer_status.wed_buffer.empty )
	);


////////////////////////////////////////////////////////////////////////////
//Buffers Restart Commands
////////////////////////////////////////////////////////////////////////////
	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(RESTART_CMD_BUFFER_SIZE )
	) restart_command_buffer_fifo_instant (
		.clock   (clock                                      ),
		.rstn    (rstn                                       ),
		
		.push    (restart_command_in.valid                   ),
		.data_in (restart_command_in                         ),
		.full    (command_buffer_status.restart_buffer.full  ),
		.alFull  (command_buffer_status.restart_buffer.alfull),
		
		.pop     (ready[0]                                   ),
		.valid   (command_buffer_status.restart_buffer.valid ),
		.data_out(restart_command_buffer_out                 ),
		.empty   (command_buffer_status.restart_buffer.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Response Buffers
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Write Responses
////////////////////////////////////////////////////////////////////////////

	assign write_response_buffer_pop = ~response_buffer_status.write_buffer.empty;

	fifo #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(WRITE_RSP_BUFFER_SIZE    )
	) write_response_buffer_fifo_instant (
		.clock   (clock                                     ),
		.rstn    (rstn                                      ),
		
		.push    (response_control_out.write_response       ),
		.data_in (response_control_out.response             ),
		.full    (response_buffer_status.write_buffer.full  ),
		.alFull  (response_buffer_status.write_buffer.alfull),
		
		.pop     (write_response_buffer_pop                 ),
		.valid   (response_buffer_status.write_buffer.valid ),
		.data_out(write_response_out                        ),
		.empty   (response_buffer_status.write_buffer.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Buffers Read Responses
////////////////////////////////////////////////////////////////////////////

	assign read_response_buffer_pop = ~response_buffer_status.read_buffer.empty;

	fifo #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(READ_RSP_BUFFER_SIZE     )
	) read_response_buffer_fifo_instant (
		.clock   (clock                                    ),
		.rstn    (rstn                                     ),
		
		.push    (response_control_out.read_response       ),
		.data_in (response_control_out.response            ),
		.full    (response_buffer_status.read_buffer.full  ),
		.alFull  (response_buffer_status.read_buffer.alfull),
		
		.pop     (read_response_buffer_pop                 ),
		.valid   (response_buffer_status.read_buffer.valid ),
		.data_out(read_response_out                        ),
		.empty   (response_buffer_status.read_buffer.empty )
	);

////////////////////////////////////////////////////////////////////////////
//restart Read Responses
////////////////////////////////////////////////////////////////////////////

	assign restart_response_buffer_pop = ~response_buffer_status.restart_buffer.empty;

	fifo #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(RESTART_RSP_BUFFER_SIZE  )
	) restart_response_buffer_fifo_instant (
		.clock   (clock                                       ),
		.rstn    (rstn                                        ),
		
		.push    (response_control_out.restart_response       ),
		.data_in (response_control_out.response               ),
		.full    (response_buffer_status.restart_buffer.full  ),
		.alFull  (response_buffer_status.restart_buffer.alfull),
		
		.pop     (restart_response_buffer_pop                 ),
		.valid   (response_buffer_status.restart_buffer.valid ),
		.data_out(restart_response_out                        ),
		.empty   (response_buffer_status.restart_buffer.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Buffers WED Responses
////////////////////////////////////////////////////////////////////////////

	assign wed_response_buffer_pop = ~response_buffer_status.wed_buffer.empty;

	fifo #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(WED_RSP_BUFFER_SIZE      )
	) wed_response_buffer_fifo_instant (
		.clock   (clock                                   ),
		.rstn    (rstn                                    ),
		
		.push    (response_control_out.wed_response       ),
		.data_in (response_control_out.response           ),
		.full    (response_buffer_status.wed_buffer.full  ),
		.alFull  (response_buffer_status.wed_buffer.alfull),
		
		.pop     (wed_response_buffer_pop                 ),
		.valid   (response_buffer_status.wed_buffer.valid ),
		.data_out(wed_response_out                        ),
		.empty   (response_buffer_status.wed_buffer.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Buffers WED Read Data
////////////////////////////////////////////////////////////////////////////

	assign wed_read_data_0_buffer_pop = ~wed_data_buffer_status.buffer_0.empty;

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WED_DATA_BUFFER_SIZE    )
	) wed_read_data_0_buffer_fifo_instant (
		.clock   (clock                                 ),
		.rstn    (rstn                                  ),
		
		.push    (read_data_control_out_0.wed_data      ),
		.data_in (read_data_control_out_0.line          ),
		.full    (wed_data_buffer_status.buffer_0.full  ),
		.alFull  (wed_data_buffer_status.buffer_0.alfull),
		
		.pop     (wed_read_data_0_buffer_pop            ),
		.valid   (wed_data_buffer_status.buffer_0.valid ),
		.data_out(wed_data_0_out                        ),
		.empty   (wed_data_buffer_status.buffer_0.empty )
	);

	assign wed_read_data_1_buffer_pop = ~wed_data_buffer_status.buffer_1.empty;

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WED_DATA_BUFFER_SIZE    )
	) wed_read_data_1_buffer_fifo_instant (
		.clock   (clock                                 ),
		.rstn    (rstn                                  ),
		
		.push    (read_data_control_out_1.wed_data      ),
		.data_in (read_data_control_out_1.line          ),
		.full    (wed_data_buffer_status.buffer_1.full  ),
		.alFull  (wed_data_buffer_status.buffer_1.alfull),
		
		.pop     (wed_read_data_1_buffer_pop            ),
		.valid   (wed_data_buffer_status.buffer_1.valid ),
		.data_out(wed_data_1_out                        ),
		.empty   (wed_data_buffer_status.buffer_1.empty )
	);


////////////////////////////////////////////////////////////////////////////
//Buffers CU Read Data
////////////////////////////////////////////////////////////////////////////

	assign read_data_0_buffer_pop = ~read_data_buffer_status.buffer_0.empty;

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_DATA_BUFFER_SIZE   )
	) cu_read_data_0_buffer_fifo_instant (
		.clock   (clock                                  ),
		.rstn    (rstn                                   ),
		
		.push    (read_data_control_out_0.read_data      ),
		.data_in (read_data_control_out_0.line           ),
		.full    (read_data_buffer_status.buffer_0.full  ),
		.alFull  (read_data_buffer_status.buffer_0.alfull),
		
		.pop     (read_data_0_buffer_pop                 ),
		.valid   (read_data_buffer_status.buffer_0.valid ),
		.data_out(read_data_0_out                        ),
		.empty   (read_data_buffer_status.buffer_0.empty )
	);

	assign read_data_1_buffer_pop = ~read_data_buffer_status.buffer_1.empty;

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_DATA_BUFFER_SIZE   )
	) cu_read_data_1_buffer_fifo_instant (
		.clock   (clock                                  ),
		.rstn    (rstn                                   ),
		
		.push    (read_data_control_out_1.read_data      ),
		.data_in (read_data_control_out_1.line           ),
		.full    (read_data_buffer_status.buffer_1.full  ),
		.alFull  (read_data_buffer_status.buffer_1.alfull),
		
		.pop     (read_data_1_buffer_pop                 ),
		.valid   (read_data_buffer_status.buffer_1.valid ),
		.data_out(read_data_1_out                        ),
		.empty   (read_data_buffer_status.buffer_1.empty )
	);

////////////////////////////////////////////////////////////////////////////
//Buffers CU Write DATA
////////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WRITE_DATA_BUFFER_SIZE  )
	) cu_write_data_0_buffer_fifo_instant (
		.clock   (clock                                   ),
		.rstn    (rstn                                    ),
		
		.push    (write_command_in.valid                  ),
		.data_in (write_data_0_in                         ),
		.full    (write_data_buffer_status.buffer_0.full  ),
		.alFull  (write_data_buffer_status.buffer_0.alfull),
		
		.pop     (command_write_valid                     ),
		.valid   (write_data_buffer_status.buffer_0.valid ),
		.data_out(write_data_0                            ),
		.empty   (write_data_buffer_status.buffer_0.empty )
	);


	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(WRITE_DATA_BUFFER_SIZE  )
	) cu_write_data_1_buffer_fifo_instant (
		.clock   (clock                                   ),
		.rstn    (rstn                                    ),
		
		.push    (write_command_in.valid                  ),
		.data_in (write_data_1_in                         ),
		.full    (write_data_buffer_status.buffer_1.full  ),
		.alFull  (write_data_buffer_status.buffer_1.alfull),
		
		.pop     (command_write_valid                     ),
		.valid   (write_data_buffer_status.buffer_1.valid ),
		.data_out(write_data_1                            ),
		.empty   (write_data_buffer_status.buffer_1.empty )
	);

endmodule





