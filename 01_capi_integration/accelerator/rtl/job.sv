import CAPI_PKG::*;

module job (
  input logic clock,    // Clock
  input logic rstn,
  input logic [0:12] external_errors,
  input  JobInterfaceInput job_in,
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
logic error_flag;
logic enable_errors;
logic [0:63] detected_errors;

assign odd_parity       = 1'b1; // Odd parity
assign parity_enabled   = 1'b1;
assign job_out.cack     = 1'b0; // Dedicated mode AFU, LLCMD not supported
assign job_out.yield    = 1'b0; // Job yield not used
assign timebase_request = 1'b0; // Timebase request not used

  always_ff @(posedge clock) begin
      if(job_in.valid) begin
        case(job_in.command)
          RESET: begin
            start_job <= 1'b0;
            reset_job <= 1'b0;
            prev_rstn <= 1'b0;
            next_rstn <= 1'b0;
            enable_errors <= 1'b1;
            done_job  <= 1'b0;
          end
          START: begin
            start_job <= 1'b1;
            reset_job <= 1'b1;
            enable_errors <= 1'b1; 
          end
          default: begin
            start_job  <= 1'b0;
            reset_job  <= 1'b1;  
            prev_rstn  <= 1'b0;
            next_rstn  <= 1'b0;
            enable_errors <= 1'b1;
          end
        endcase
      end else if (error_flag) begin
        start_job <= 1'b0;
        reset_job <= 1'b0;
        prev_rstn <= 1'b0;
        next_rstn <= 1'b0;
        done_job  <= 1'b0;
        enable_errors <= 1'b0;
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
    end else if(start_job || job_out.running) begin
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

  // Parity check
  always_ff @(posedge clock) begin
      if(job_in.valid) begin
        command_parity <= job_in.command_parity;
        address_parity <= job_in.address_parity;
        command        <= job_in.command;
        address        <= job_in.address;
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
    .clock           (clock),
    .data            (command),
    .odd             (odd_parity),
    .par             (command_parity_link)
  );

  parity #(
    .BITS(64)
  ) job_address_parity_instant (
    .clock           (clock),
    .data            (address),
    .odd             (odd_parity),
    .par             (address_parity_link)
  );

  
  // Error logic
  // once error flag is asserted enable errors gets disabled and last error gets latched for reporting
  // after the reset signal is finished done job is asserted with any error if exists.
  always_ff @(posedge clock) begin
    if(enable_errors) begin
      job_command_error <= command_parity_link ^ command_parity;
      job_address_error <= address_parity_link ^ address_parity;
      detected_errors   <= {48'h0000_0000_0000,job_command_error,job_address_error, external_errors};
      error_flag        <= |detected_errors;
    end else if(done_job) begin
      detected_errors   <= 64'h0000_0000_0000_0000;
      job_command_error <= 1'b0;
      job_address_error <= 1'b0;
      error_flag        <= 1'b0;
    end else begin
      error_flag        <= 1'b0;
    end
  end

  always_ff @(posedge clock) begin
    if(done_job) begin
      job_out.error     <= detected_errors;
    end else  begin
      job_out.error     <= 64'h0000_0000_0000_0000;
    end
  end

endmodule