import CAPI_PKG::*;
import WED_PKG::*;
import COMMAND_PKG::*;

module cached_afu  #(
  parameter NUM_EXTERNAL_RESETS = 2
  )(
  input  logic clock,
  output logic timebase_request,
  output logic parity_enabled,
  input JobInterfaceInput job_in,
  output JobInterfaceOutput job_out,
  input CommandInterfaceInput command_in,
  output CommandInterfaceOutput command_out,
  input BufferInterfaceInput buffer_in,
  output BufferInterfaceOutput buffer_out,
  input ResponseInterface response,
  input MMIOInterfaceInput mmio_in,
  output MMIOInterfaceOutput mmio_out
  );

  // logic jdone;

  logic [0:NUM_EXTERNAL_RESETS-1] external_rstn;
  logic [0:12]    external_errors;
  logic [0:1]     mmio_errors;
  logic [0:3]     dma_parity_err;
  logic [0:6]     dma_resp_err;

  logic reset_afu;
  
  
 

  CommandBufferLine read_command_in;
  CommandBufferLine write_command_in;
  CommandBufferLine restart_command_in;
  CommandBufferStatusInterfaceOut command_buffer_status;

  WEDInterface wed; // work element descriptor -> addresses and other into
  CommandBufferLine wed_command_out; // command for populatin WED

  assign buffer_out.read_latency    = 4'h1;

  assign dma_parity_err   = 0;
  assign dma_resp_err     = 0;
  assign external_errors  = {mmio_errors, dma_parity_err, dma_resp_err};

////////////////////////////////////////////////////////////////////////////
//WED 
////////////////////////////////////////////////////////////////////////////

 

  wed_control wed_control_instant(
    .clock      (clock),
    .enabled    (job_out.running),
    .rstn       (reset_afu),
    .wed_address(job_in.address),
    .buffer_in  (buffer_in),
    .response   (response),
    .wed_buffer (command_buffer_status.wed_buffer),
    .command_out(wed_command_out),
    .wed_request_out(wed));

////////////////////////////////////////////////////////////////////////////
//Command 
////////////////////////////////////////////////////////////////////////////
 

  assign read_command_in = 0;
  assign write_command_in = 0;
  assign restart_command_in = 0;

 command command_instant(
    .clock        (clock),
    .rstn         (reset_afu),
    .enabled      (job_out.running),
    .read_command_in    (read_command_in),
    .write_command_in   (write_command_in),
    .wed_command_in     (wed_command_out),
    .restart_command_in (restart_command_in),
    .command_in   (command_in),
    .response     (response),
    .command_out  (command_out),
    .command_buffer_status (command_buffer_status)
    );

////////////////////////////////////////////////////////////////////////////
//MMIO 
////////////////////////////////////////////////////////////////////////////


  mmio mmio_instant(
      .clock       (clock),
      .rstn        (reset_afu),
      .mmio_in     (mmio_in),
      .mmio_out    (mmio_out),
      .mmio_errors (mmio_errors),
      .reset_mmio  (external_rstn[1]));

////////////////////////////////////////////////////////////////////////////
//JOB 
////////////////////////////////////////////////////////////////////////////

  job job_instant(
      .clock           (clock),
      .rstn            (reset_afu),
      .external_errors (external_errors),
      .job_in          (job_in),
      .job_out         (job_out),
      .timebase_request(timebase_request),
      .parity_enabled  (parity_enabled),
      .reset_job       (external_rstn[0])
    );

  reset_control #(
    .NUM_EXTERNAL_RESETS(NUM_EXTERNAL_RESETS)
    )reset_instant(
      .clock(clock),
      .external_rstn(external_rstn),
      .rstn(reset_afu)
  );

endmodule