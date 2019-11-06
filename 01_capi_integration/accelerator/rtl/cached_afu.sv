// -----------------------------------------------------------------------------
//
//    "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cached_afu.sv
// Create : 2019-09-26 15:20:40
// Revise : 2019-09-26 15:20:40
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;

module cached_afu #(parameter NUM_EXTERNAL_RESETS = 3) (
  input  logic                  clock           ,
  output logic                  timebase_request,
  output logic                  parity_enabled  ,
  input  JobInterfaceInput      job_in          ,
  output JobInterfaceOutput     job_out         ,
  input  CommandInterfaceInput  command_in      ,
  output CommandInterfaceOutput command_out     ,
  input  BufferInterfaceInput   buffer_in       ,
  output BufferInterfaceOutput  buffer_out      ,
  input  ResponseInterface      response        ,
  input  MMIOInterfaceInput     mmio_in         ,
  output MMIOInterfaceOutput    mmio_out
);

  // logic jdone;

  logic [0:NUM_EXTERNAL_RESETS-1] external_rstn          ;
  logic [                    0:1] job_errors             ;
  logic [                    0:1] mmio_errors            ;
  logic [                    0:1] data_read_error        ;
  logic                           data_write_error       ;
  logic [                    0:6] command_response_error ;
  logic [                   0:63] external_errors        ;
  logic [                   0:63] report_errors          ;
  logic [                   0:63] algorithm_status       ;
  logic [                   0:63] report_algorithm_status;
  logic [                   0:63] algorithm_requests     ;
  logic                           report_errors_ack      ;
  logic                           reset_afu              ;
  logic                           reset_afu_soft         ;

  logic combined_reset_afu         ;
  logic reset_done                 ;
  logic report_algorithm_status_ack;

  CommandBufferLine read_command_out ;
  CommandBufferLine write_command_out;

  ReadWriteDataLine wed_data_0_out  ;
  ReadWriteDataLine wed_data_1_out  ;
  ReadWriteDataLine read_data_0_out ;
  ReadWriteDataLine read_data_1_out ;
  ReadWriteDataLine write_data_0_out;
  ReadWriteDataLine write_data_1_out;

  CommandBufferStatusInterface  command_buffer_status   ;
  ResponseBufferStatusInterface response_buffer_status  ;
  DataBufferStatusInterface     read_data_buffer_status ;
  DataBufferStatusInterface     wed_data_buffer_status  ;
  DataBufferStatusInterface     write_data_buffer_status;

  ResponseBufferLine read_response_out ;
  ResponseBufferLine write_response_out;
  ResponseBufferLine wed_response_out  ;


  WEDInterface      wed             ; // work element descriptor -> addresses and other into
  CommandBufferLine wed_command_out ; // command for populatin WED
  logic             enabled         ;
  ResponseInterface response_latched;


  always_ff @(posedge clock) begin
    combined_reset_afu <= reset_afu & reset_afu_soft;
  end

  logic [0:7]                    restart_counter;

  always_ff @(posedge clock or negedge combined_reset_afu) begin
    if(~combined_reset_afu) begin
      restart_counter  <= 0;
    end else begin
      restart_counter  <= restart_counter + 1;
    end
  end

////////////////////////////////////////////////////////////////////////////
//enabled logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock) begin
    enabled          <= job_out.running;
    response_latched <= response;

    if(restart_counter > 235 && response.response != PAGED )
      response_latched.response <= FLUSHED;

    if(restart_counter > 190 && restart_counter < 200 && response.response != PAGED )
      response_latched.response <= FAULT;

    if(restart_counter > 100 && restart_counter < 120 && response.response != PAGED )
      response_latched.response <= AERROR;

    if(restart_counter > 30 && restart_counter < 45 && response.response != PAGED )
      response_latched.response <= DERROR;

  end

////////////////////////////////////////////////////////////////////////////
//DONE
////////////////////////////////////////////////////////////////////////////

  done_control done_control_instant (
    .clock                      (clock                      ),
    .rstn                       (reset_afu                  ),
    .soft_rstn                  (reset_afu_soft             ),
    .enabled_in                 (enabled                    ),
    .algorithm_status           (algorithm_status           ),
    .report_algorithm_status_ack(report_algorithm_status_ack),
    .reset_done                 (reset_done                 ),
    .report_algorithm_status    (report_algorithm_status    )
  );

////////////////////////////////////////////////////////////////////////////
//ERROR
////////////////////////////////////////////////////////////////////////////

  assign external_errors = {50'b0, job_errors, mmio_errors, data_write_error ,data_read_error, command_response_error};

  error_control error_control_instant (
    .clock            (clock            ),
    .rstn             (reset_afu        ),
    .enabled_in       (enabled          ),
    .external_errors  (external_errors  ),
    .report_errors_ack(report_errors_ack),
    .reset_error      (external_rstn[2] ),
    .report_errors    (report_errors    )
  );

////////////////////////////////////////////////////////////////////////////
//WED
////////////////////////////////////////////////////////////////////////////

  wed_control wed_control_instant (
    .clock                (clock                           ),
    .enabled_in           (enabled                         ),
    .rstn                 (reset_afu                       ),
    .wed_address          (job_in.address                  ),
    .wed_data_0_in        (wed_data_0_out                  ),
    .wed_data_1_in        (wed_data_1_out                  ),
    .wed_response_in      (wed_response_out                ),
    .command_buffer_status(command_buffer_status.wed_buffer),
    .command_out          (wed_command_out                 ),
    .wed_request_out      (wed                             )
  );

////////////////////////////////////////////////////////////////////////////
//Command
////////////////////////////////////////////////////////////////////////////


  afu_control afu_control_instant (
    .clock                   (clock                   ),
    .rstn                    (combined_reset_afu      ),
    .enabled_in              (enabled                 ),
    .read_command_in         (read_command_out        ),
    .write_command_in        (write_command_out       ),
    .wed_command_in          (wed_command_out         ),
    .command_in              (command_in              ),
    .response                (response_latched        ),
    .buffer_in               (buffer_in               ),
    .write_data_0_in         (write_data_0_out        ),
    .write_data_1_in         (write_data_1_out        ),
    .wed_data_0_out          (wed_data_0_out          ),
    .wed_data_1_out          (wed_data_1_out          ),
    .read_data_0_out         (read_data_0_out         ),
    .read_data_1_out         (read_data_1_out         ),
    .read_response_out       (read_response_out       ),
    .write_response_out      (write_response_out      ),
    .wed_response_out        (wed_response_out        ),
    .command_response_error  (command_response_error  ),
    .data_read_error         (data_read_error         ),
    .data_write_error        (data_write_error        ),
    .buffer_out              (buffer_out              ),
    .command_out             (command_out             ),
    .command_buffer_status   (command_buffer_status   ),
    .response_buffer_status  (response_buffer_status  ),
    .read_data_buffer_status (read_data_buffer_status ),
    .wed_data_buffer_status  (wed_data_buffer_status  ),
    .write_data_buffer_status(write_data_buffer_status)
  );

////////////////////////////////////////////////////////////////////////////
//Compute Unit
////////////////////////////////////////////////////////////////////////////


  cu_control cu_control_instant (
    .clock              (clock                             ),
    .rstn               (combined_reset_afu                ),
    .enabled_in         (enabled                           ),
    .wed_request_in     (wed                               ),
    .read_response_in   (read_response_out                 ),
    .write_response_in  (write_response_out                ),
    .read_data_0_in     (read_data_0_out                   ),
    .read_data_1_in     (read_data_1_out                   ),
    .read_buffer_status (command_buffer_status.read_buffer ),
    .algorithm_status   (algorithm_status                  ),
    .algorithm_requests (algorithm_requests                ),
    .read_command_out   (read_command_out                  ),
    .write_buffer_status(command_buffer_status.write_buffer),
    .write_command_out  (write_command_out                 ),
    .write_data_0_out   (write_data_0_out                  ),
    .write_data_1_out   (write_data_1_out                  )
  );



////////////////////////////////////////////////////////////////////////////
//MMIO
////////////////////////////////////////////////////////////////////////////

  mmio mmio_instant (
    .clock                      (clock                      ),
    .rstn                       (reset_afu                  ),
    .report_errors              (report_errors              ),
    .algorithm_status           (report_algorithm_status    ),
    .algorithm_requests         (algorithm_requests         ),
    .mmio_in                    (mmio_in                    ),
    .mmio_out                   (mmio_out                   ),
    .mmio_errors                (mmio_errors                ),
    .report_errors_ack          (report_errors_ack          ),
    .report_algorithm_status_ack(report_algorithm_status_ack),
    .reset_mmio                 (external_rstn[1]           )
  );

////////////////////////////////////////////////////////////////////////////
//JOB
////////////////////////////////////////////////////////////////////////////

  job job_instant (
    .clock           (clock           ),
    .rstn            (reset_afu       ),
    .job_in          (job_in          ),
    .report_errors   (report_errors   ),
    .job_errors      (job_errors      ),
    .job_out         (job_out         ),
    .timebase_request(timebase_request),
    .parity_enabled  (parity_enabled  ),
    .reset_job       (external_rstn[0])
  );

////////////////////////////////////////////////////////////////////////////
//RESET hard
////////////////////////////////////////////////////////////////////////////

  reset_control #(.NUM_EXTERNAL_RESETS(NUM_EXTERNAL_RESETS)) reset_instant_hard (
    .clock        (clock        ),
    .external_rstn(external_rstn),
    .rstn         (reset_afu    )
  );


////////////////////////////////////////////////////////////////////////////
//RESET soft
////////////////////////////////////////////////////////////////////////////

  reset_control #(.NUM_EXTERNAL_RESETS(1)) reset_instant_soft (
    .clock        (clock         ),
    .external_rstn(reset_done    ),
    .rstn         (reset_afu_soft)
  );

endmodule