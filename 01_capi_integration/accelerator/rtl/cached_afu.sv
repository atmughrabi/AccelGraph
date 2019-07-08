import CAPI_PKG::*;

module cached_afu (
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

  
  // mmio mmio_instant(
  //   .clock      (clock),
  //   .mmio_in    (mmio_in_1),
  //   .mmio_out   (mmio_out_1));

  // control control_instant(
  //   .clock      (clock),
  //   .enabled    (job_out_1.running),
  //   .reset      (job_out_1.done),
  //   .wed        (job_in_1.address),
  //   .buffer_in  (buffer_in_1),
  //   .response   (response_1),
  //   .command_out(command_out_1),
  //   .buffer_out (buffer_out_1));

  job job_instant(
    .clock           (clock),
    .job_in          (job_in),
    .job_out         (job_out),
    .timebase_request(timebase_request),
    .parity_enabled  (parity_enabled));

  // shift_register jdone_shift(
  //   .clock(clock),
  //   .in(jdone),
  //   .out(job_out.done));


endmodule