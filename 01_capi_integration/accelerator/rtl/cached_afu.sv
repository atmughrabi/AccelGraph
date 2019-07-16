import CAPI_PKG::*;

module cached_afu  #(
  parameter NUM_EXTERNAL_RESETS = 1,
  parameter NUM_DOMAINS = 1,
  parameter SEQUENTIAL_RELEASE = 1'b0
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
  logic reset_afu;

  
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
    .parity_enabled  (parity_enabled),
    .reset_job   (external_rstn[0])
    );

  reset_control #(
    .NUM_EXTERNAL_RESETS(NUM_EXTERNAL_RESETS),
    .NUM_DOMAINS(NUM_DOMAINS),
    .SEQUENTIAL_RELEASE(SEQUENTIAL_RELEASE)
    )reset_instant(
      .clk(clock),
      .external_rstn(external_rstn),
      .rstn(reset_afu)
  );

endmodule