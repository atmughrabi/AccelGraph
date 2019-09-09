import CAPI_PKG::*;

module job (
  input logic clock,    // Clock
  input logic rstn,
  input JobInterfaceInput job_in,
  input logic [0:63]  report_errors,
  output logic [0:1]  job_errors,
  output JobInterfaceOutput job_out,
  output logic timebase_request,
  output logic parity_enabled,
  output logic reset_job
);

  logic prev_rstn;
  logic next_rstn;
  logic start_job;
  logic done_job;
  logic odd_parity;

  logic command_parity_link;
  logic address_parity_link;
  logic command_parity;
  logic address_parity;
  logic [0:7]  command;
  logic [0:63] address;

  logic job_command_error;
  logic job_address_error;
  logic enable_errors;
  logic [0:1] detected_errors;
  logic [0:63]  reported_errors;

  JobInterfaceInput job_in_latched;

  assign odd_parity       = 1'b1; // Odd parity
  assign parity_enabled   = 1'b1;
  assign job_out.cack     = 1'b0; // Dedicated mode AFU, LLCMD not supported
  assign job_out.yield    = 1'b0; // Job yield not used
  assign timebase_request = 1'b0; // Timebase request not used

  assign enable_errors = 1'b1;


////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock) begin
    job_in_latched  <= job_in;
  end

////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL
////////////////////////////////////////////////////////////////////////////


  always_ff @(posedge clock) begin
    if(job_in_latched.valid) begin
      case(job_in_latched.command)
        RESET: begin
          start_job <= 1'b0;
          reset_job <= 1'b0;
          prev_rstn <= 1'b0;
          next_rstn <= 1'b0;
          done_job  <= 1'b0;
        end
        START: begin
          start_job <= 1'b1;
          reset_job <= 1'b1;
        end
        default: begin
          start_job  <= 1'b0;
          reset_job  <= 1'b1;
          prev_rstn  <= 1'b0;
          next_rstn  <= 1'b0;
        end
      endcase
    end else begin
      start_job <= 1'b0;
      reset_job <= 1'b1;
      next_rstn <= rstn;
      prev_rstn <= next_rstn;
      done_job  <= ~prev_rstn && next_rstn;
    end
  end
  // Detect when the reset signal is done so we send jdone signal
  // This is detected for one pulse when reset transition from low to high.


  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      job_out.running <= 1'b0;
    end else begin
      if(start_job || job_out.running)
        job_out.running <= 1'b1;
    end
  end

  always_ff @(posedge clock) begin
    if(done_job) begin
      job_out.done <= 1'b1;
    end else begin
      job_out.done <= 1'b0;
    end
  end

////////////////////////////////////////////////////////////////////////////
//partity check Logic
////////////////////////////////////////////////////////////////////////////
  // Parity check
  always_ff @(posedge clock) begin
    if(job_in_latched.valid) begin
      command_parity <= job_in_latched.command_parity;
      address_parity <= job_in_latched.address_parity;
      command        <= job_in_latched.command;
      address        <= job_in_latched.address;
    end else if(done_job) begin
      command_parity <= odd_parity;
      address_parity <= odd_parity;
      command        <= 8'h00;
      address        <= 64'h0000_0000_0000_0000;
    end
  end


  parity #(
    .BITS(8)
  ) job_command_parity_instant (
    .data            (command),
    .odd             (odd_parity),
    .par             (command_parity_link)
  );

  parity #(
    .BITS(64)
  ) job_address_parity_instant (
    .data            (address),
    .odd             (odd_parity),
    .par             (address_parity_link)
  );


////////////////////////////////////////////////////////////////////////////
// Error Logic
////////////////////////////////////////////////////////////////////////////
  // Error logic
  // once error flag is asserted enable errors gets disabled and last error gets latched for reporting
  // after the reset signal is finished done job is asserted with any error if exists.

  // assign error_flag = (|detected_errors) && enable_errors;

  always_ff @(posedge clock) begin
    if(job_in_latched.valid) begin
      case(job_in_latched.command)
        RESET: begin
          reported_errors <= 64'b0;
        end
        default: begin
          if(~(|reported_errors))
            reported_errors <= report_errors;
        end
      endcase
    end else begin
      if(~(|reported_errors))
        reported_errors <= report_errors;
    end
  end

  always_ff @(posedge clock) begin
    if(~rstn) begin
      job_command_error    <= 1'b0;
      job_address_error    <= 1'b0;
      detected_errors      <= 2'b00;
    end else begin
      job_command_error <= command_parity_link ^ command_parity;
      job_address_error <= address_parity_link ^ address_parity;
      detected_errors   <= {job_command_error,job_address_error};
    end
  end

  always_ff @(posedge clock) begin
    if(enable_errors) begin
      job_errors <= detected_errors;
    end else  begin
      job_errors <= 2'b00;
    end
  end

  always_ff @(posedge clock) begin
    if(done_job) begin
      job_out.error     <= reported_errors;
    end else  begin
      job_out.error     <= 64'h0000_0000_0000_0000;
    end
  end

endmodule