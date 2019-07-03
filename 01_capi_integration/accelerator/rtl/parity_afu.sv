import CAPI_PKG::*;

module parity_afu (
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
  output MMIOInterfaceOutput mmio_out);

  // logic jdone;

  // logic clock_1;
  logic timebase_request_1;
  logic parity_enabled_1;

   JobInterfaceInput job_in_1;
   CommandInterfaceInput command_in_1;
   BufferInterfaceInput buffer_in_1;
   ResponseInterface response_1;
   MMIOInterfaceInput mmio_in_1;
  
   JobInterfaceOutput job_out_1;
   CommandInterfaceOutput command_out_1;
   BufferInterfaceOutput buffer_out_1;
   MMIOInterfaceOutput mmio_out_1;

  always_ff @ (posedge clock) begin

    //
  // clock_1           <= clock;
  timebase_request  <= timebase_request_1;
  parity_enabled    <= parity_enabled_1;

    // input
  job_in_1      <= job_in;
  command_in_1  <= command_in;
  buffer_in_1   <= buffer_in;
  response_1    <= response;
  mmio_in_1     <= mmio_in;

    //output
  job_out <= job_out_1;
  command_out <= command_out_1;
  buffer_out <= buffer_out_1;
  mmio_out <= mmio_out_1;

    
  end


  mmio mmio_instant(
    .clock      (clock),
    .mmio_in    (mmio_in_1),
    .mmio_out   (mmio_out_1));

  control control_instant(
    .clock      (clock),
    .enabled    (job_out_1.running),
    .reset      (job_out_1.done),
    .wed        (job_in_1.address),
    .buffer_in  (buffer_in_1),
    .response   (response_1),
    .command_out(command_out_1),
    .buffer_out (buffer_out_1));

  job job_instant(
    .clock           (clock),
    .job_in          (job_in_1),
    .job_out         (job_out_1),
    .timebase_request(timebase_request_1),
    .parity_enabled  (parity_enabled_1));

  // shift_register jdone_shift(
  //   .clock(clock),
  //   .in(jdone),
  //   .out(job_out.done));


endmodule