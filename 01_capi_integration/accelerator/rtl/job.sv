import CAPI_PKG::*;

module job  #(
  parameter NUM_EXTERNAL_RESETS = 1
  )(
  input logic clock,    // Clock
  input logic rstn,
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

  always_ff @(posedge clock) begin
      if(job_in.valid) begin
        case(job_in.command)
          RESET: begin
            start_job <= 1'b0;
            reset_job <= 1'b0;
            prev_rstn <= 1'b0;
            next_rstn <= 1'b0;
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
      end
  end


  // Detect when the reset signal is done so we send jdone signal
  // This is detected for one pulse when reset transition from low to high.
  always_ff @(posedge clock) begin
    next_rstn <= rstn;
    prev_rstn <= next_rstn;
    done_job  <= ~prev_rstn && next_rstn;
  end


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

endmodule