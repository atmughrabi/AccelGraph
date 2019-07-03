import CAPI_PKG::*;

module job (

	input clock,    // Clock
	input JobInterfaceInput job_in,
    output JobInterfaceOutput job_out,
    output timebase_request,
    output parity_enabled
	
);

assign   job_out.cack = 0,
         job_out.error = 0,
         job_out.yield = 0,
         timebase_request = 0,
         parity_enabled = 0;

  always_ff @(posedge clock) begin
    if(job_in.valid) begin
      case(job_in.command)
        RESET: begin
          job_out.done <= 1;
          job_out.running <= 0;
        end
        START: begin
          job_out.done <= 0;
          job_out.running <= 1;
        end
      endcase
    end else begin
      job_out.done <= 0;
    end
  end

endmodule