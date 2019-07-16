import CAPI_PKG::*;

module job (
  input clock,    // Clock
  input  JobInterfaceInput job_in,
  output JobInterfaceOutput job_out,
  output logic timebase_request,
  output logic parity_enabled,
  output logic reset_job
);


  JobInterfaceOutput job_out_reg;
  logic timebase_request_reg;
  logic parity_enabled_reg;
  logic reset_job_reg;
         
  always_comb begin

    job_out_reg.running = 0;
    job_out_reg.cack = 0;
    job_out_reg.error = 0;
    job_out_reg.yield = 0;
    job_out_reg.done = 0;
    timebase_request_reg = 0;
    parity_enabled_reg = 0;
    reset_job_reg = 1;


    if(job_in.valid) begin
      case(job_in.command)
        RESET: begin
          job_out_reg.done = 1;
          reset_job_reg = 0;
          job_out_reg.running = 0;
        end
        START: begin
          job_out_reg.done = 0;
          job_out_reg.running  = 1;
        end
        default : begin
          job_out_reg.done = 1;
          job_out_reg.running  = 0;
        end
      endcase
    end 
    
  end


  always_ff @(posedge clock) begin
          job_out           <= job_out_reg;
          timebase_request  <= timebase_request_reg;
          parity_enabled    <= parity_enabled_reg;
          reset_job         <= reset_job_reg;
  end

endmodule