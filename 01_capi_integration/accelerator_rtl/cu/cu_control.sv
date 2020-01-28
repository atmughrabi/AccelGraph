// -----------------------------------------------------------------------------
//
//    "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_control.sv
// Create : 2019-12-08 01:39:09
// Revise : 2019-12-18 20:42:50
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;


module cu_control #(parameter NUM_REQUESTS = 2) (
	input  logic              clock                       , // Clock
	input  logic              rstn                        ,
	input  logic              enabled_in                  ,
	input  WEDInterface       wed_request_in              ,
	input  ResponseBufferLine read_response_in            ,
	input  ResponseBufferLine prefetch_read_response_in   ,
	input  ResponseBufferLine prefetch_write_response_in  ,
	input  ResponseBufferLine write_response_in           ,
	input  ReadWriteDataLine  read_data_0_in              ,
	input  ReadWriteDataLine  read_data_1_in              ,
	input  BufferStatus       read_buffer_status          ,
	input  BufferStatus       prefetch_read_buffer_status ,
	input  BufferStatus       prefetch_write_buffer_status,
	input  BufferStatus       write_buffer_status         ,
	input  logic [0:63]       cu_configure                ,
	input  logic [0:63]       cu_configure_2              ,
	output logic [0:63]       cu_return                   ,
	output logic              cu_done                     ,
	output logic [0:63]       cu_status                   ,
	output CommandBufferLine  read_command_out            ,
	output CommandBufferLine  prefetch_read_command_out   ,
	output CommandBufferLine  prefetch_write_command_out  ,
	output CommandBufferLine  write_command_out           ,
	output ReadWriteDataLine  write_data_0_out            ,
	output ReadWriteDataLine  write_data_1_out
);

	// vertex control variables

	//output latched
	CommandBufferLine write_command_out_latched;
	ReadWriteDataLine write_data_0_out_latched ;
	ReadWriteDataLine write_data_1_out_latched ;
	CommandBufferLine read_command_out_latched ;

	//input lateched
	WEDInterface       wed_request_in_latched  ;
	ResponseBufferLine read_response_in_latched;

	ResponseBufferLine write_response_in_latched  ;
	ReadWriteDataLine  read_data_0_in_latched     ;
	ReadWriteDataLine  read_data_1_in_latched     ;
	ReadWriteDataLine  read_data_0_out            ;
	ReadWriteDataLine  read_data_1_out            ;
	ReadWriteDataLine  write_data_0_in            ;
	ReadWriteDataLine  write_data_1_in            ;
	BufferStatus       write_data_in_buffer_status;

	logic [                 0:63] cu_return_latched     ;
	logic [                 0:63] cu_configure_latched  ;
	logic [                 0:63] cu_configure_2_latched;
	logic                         done_algorithm        ;
	logic [0:(ARRAY_SIZE_BITS-1)] write_job_counter_done;
	logic [0:(ARRAY_SIZE_BITS-1)] read_job_counter_done ;

	logic enabled               ;
	logic enabled_instants_read ;
	logic enabled_instants_write;
	logic enabled_prefetch_read ;
	logic enabled_prefetch_write;
	logic cu_ready              ;

	ResponseBufferLine prefetch_read_response_in_latched;
	CommandBufferLine  prefetch_read_command_out_latched;

	ResponseBufferLine prefetch_write_response_in_latched;
	CommandBufferLine  prefetch_write_command_out_latched;

	logic [0:63] tlb_size           ;
	logic [0:63] max_tlb_cl_requests;

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
			enabled_instants_read  <= 0;
			enabled_instants_write <= 0;
			enabled_prefetch_read  <= 0;
			enabled_prefetch_write <= 0;
		end else begin
			if(enabled) begin
				enabled_instants_read  <= cu_ready && cu_configure_latched[23]; // activate read mode
				enabled_instants_write <= cu_ready && (cu_configure_latched[22] | cu_configure_latched[21]); // activate write mode cu_configure_latched[21]; // activate independent write mode
				enabled_prefetch_read  <= cu_ready && cu_configure_latched[30];
				enabled_prefetch_write <= cu_ready && cu_configure_latched[31];
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Done signal
////////////////////////////////////////////////////////////////////////////a
	assign cu_ready = (|cu_configure_latched) && wed_request_in_latched.valid;

	always_comb begin
		cu_return_latched = 0;
		done_algorithm    = 0;
		if(wed_request_in_latched.valid)begin
			if((cu_configure_latched[21] || cu_configure_latched[22]) && cu_configure_latched[23]) begin
				done_algorithm    = ((wed_request_in_latched.wed.size_recive == write_job_counter_done) && (wed_request_in_latched.wed.size_send == read_job_counter_done));
				cu_return_latched = {write_job_counter_done};
			end else if(cu_configure_latched[21] || cu_configure_latched[22]) begin
				done_algorithm    = ((wed_request_in_latched.wed.size_recive == write_job_counter_done));
				cu_return_latched = {write_job_counter_done};
			end else if(cu_configure_latched[23]) begin
				done_algorithm    = (wed_request_in_latched.wed.size_send == read_job_counter_done);
				cu_return_latched = {read_job_counter_done};
			end else begin
				done_algorithm    = ((wed_request_in_latched.wed.size_recive == write_job_counter_done) && (wed_request_in_latched.wed.size_send == read_job_counter_done));
				cu_return_latched = {write_job_counter_done};
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive output
////////////////////////////////////////////////////////////////////////////

	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			cu_return <= 0;
			cu_status <= 0;
			cu_done   <= 0;
		end else begin
			if(enabled)begin
				cu_return <= cu_return_latched;
				cu_done   <= done_algorithm;
				cu_status <= cu_configure_latched;
			end
		end
	end


	// drive outputs
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			write_command_out <= 0;
			write_data_0_out  <= 0;
			write_data_1_out  <= 0;
			read_command_out  <= 0;
		end else begin
			if(enabled)begin
				write_command_out <= write_command_out_latched;
				write_data_0_out  <= write_data_0_out_latched;
				write_data_1_out  <= write_data_1_out_latched;
				read_command_out  <= read_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched    <= 0;
			read_response_in_latched  <= 0;
			write_response_in_latched <= 0;
			read_data_0_in_latched    <= 0;
			read_data_1_in_latched    <= 0;
			cu_configure_latched      <= 0;
			cu_configure_2_latched    <= 0;
		end else begin
			if(enabled)begin
				wed_request_in_latched    <= wed_request_in;
				read_response_in_latched  <= read_response_in;
				write_response_in_latched <= write_response_in;
				read_data_0_in_latched    <= read_data_0_in;
				read_data_1_in_latched    <= read_data_1_in;

				if((|cu_configure))
					cu_configure_latched <= cu_configure;

				if((|cu_configure_2))
					cu_configure_2_latched <= cu_configure_2;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Independent write Engine
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//READ Engine
////////////////////////////////////////////////////////////////////////////

	cu_data_read_engine_control cu_data_read_engine_control_instant (
		.clock                         (clock                            ),
		.rstn                          (rstn                             ),
		.read_enabled_in               (enabled_instants_read            ),
		.prefetch_enabled_in           (enabled_prefetch_read            ),
		.wed_request_in                (wed_request_in_latched           ),
		.cu_configure                  (cu_configure_latched             ),
		.read_response_in              (read_response_in_latched         ),
		.read_data_0_in                (read_data_0_in_latched           ),
		.read_data_1_in                (read_data_1_in_latched           ),
		.read_command_buffer_status    (read_buffer_status               ),
		.read_data_out_buffer_status   (write_data_in_buffer_status      ),
		.prefetch_response_in          (prefetch_read_response_in_latched),
		.prefetch_command_buffer_status(prefetch_read_buffer_status      ),
		.prefetch_command_out          (prefetch_read_command_out_latched),
		.tlb_size                      (tlb_size                         ),
		.max_tlb_cl_requests           (max_tlb_cl_requests              ),
		.read_command_out              (read_command_out_latched         ),
		.read_data_0_out               (read_data_0_out                  ),
		.read_data_1_out               (read_data_1_out                  ),
		.read_job_counter_done         (read_job_counter_done            )
	);

////////////////////////////////////////////////////////////////////////////
//WRITE Engine
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock) begin
		write_data_0_in <= read_data_0_out;
	end

	assign write_data_1_in = read_data_1_out;

	cu_data_write_engine_control cu_data_write_engine_control_instant (
		.clock                         (clock                             ),
		.rstn                          (rstn                              ),
		.write_enabled_in              (enabled_instants_write            ),
		.prefetch_enabled_in           (enabled_prefetch_write            ),
		.wed_request_in                (wed_request_in_latched            ),
		.cu_configure                  (cu_configure_latched              ),
		.write_response_in             (write_response_in_latched         ),
		.write_data_0_in               (write_data_0_in                   ),
		.write_data_1_in               (write_data_1_in                   ),
		.write_command_buffer_status   (write_buffer_status               ),
		.prefetch_response_in          (prefetch_write_response_in_latched),
		.prefetch_command_buffer_status(prefetch_write_buffer_status      ),
		.tlb_size                      (tlb_size                          ),
		.max_tlb_cl_requests           (max_tlb_cl_requests               ),
		.prefetch_command_out          (prefetch_write_command_out_latched),
		.write_data_in_buffer_status   (write_data_in_buffer_status       ),
		.write_command_out             (write_command_out_latched         ),
		.write_data_0_out              (write_data_0_out_latched          ),
		.write_data_1_out              (write_data_1_out_latched          ),
		.write_job_counter_done        (write_job_counter_done            )
	);



////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_read_response_in_latched <= 0;
		end else begin
			if(enabled_prefetch_read)begin
				prefetch_read_response_in_latched <= prefetch_read_response_in;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive output
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_read_command_out <= 0;
		end else begin
			if(enabled_prefetch_read)begin
				prefetch_read_command_out <= prefetch_read_command_out_latched;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//Prefetch Stream WRITE Engine
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_write_response_in_latched <= 0;
		end else begin
			if(enabled_prefetch_write)begin
				prefetch_write_response_in_latched <= prefetch_write_response_in;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive output write prefetch
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			prefetch_write_command_out <= 0;
		end else begin
			if(enabled_prefetch_write)begin
				prefetch_write_command_out <= prefetch_write_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive TLB SIZE 
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			tlb_size            <= 0;
			max_tlb_cl_requests <= 0;
		end else begin
			if((|cu_configure_latched)) begin
				if(cu_configure_latched[39])begin
					tlb_size            <= (TLB_SIZE >> cu_configure_latched[32:35]) - 1;
					max_tlb_cl_requests <= (MAX_TLB_CL_REQUESTS >> (cu_configure_latched[32:35])) - 1;
				end else begin
					tlb_size            <= (TLB_SIZE << cu_configure_latched[32:35]) - 1;
					max_tlb_cl_requests <= (MAX_TLB_CL_REQUESTS << (cu_configure_latched[32:35])) - 1;
				end
			end
		end
	end

endmodule