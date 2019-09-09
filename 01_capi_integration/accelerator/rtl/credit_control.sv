import CAPI_PKG::*;
import CREDIT_PKG::*;

module credit_control (
  input logic clock,    // Clock
  input logic rstn,
  input CreditInterfaceInput credit_in,
  output CreditInterfaceOutput credit_out
);

////////////////////////////////////////////////////////////////////////////
//Credit Tracking Logic
////////////////////////////////////////////////////////////////////////////

//Any afu must track credits from psl.
//ha_croom gives initial sample of maximum credit and can be sampled during
//afu reset. Any command issued means 1 less credit. ha_rvalid normally means
//1 returned credit. Issuing a command and getting a return in the same cycle
//normally nullfies to no change in credit.

  logic [0:7] credits;
  logic init_credits;


  always_ff @ (posedge clock or negedge rstn) begin
    if (~rstn) begin
      credits <= 8'h00;
      init_credits <= 1'b0;
    end else begin
      if(~init_credits) begin
        credits <= credit_in.command_in.room;
        init_credits <= 1'b1;
      end else if (credit_in.valid_request && ~credit_in.valid_response)
      credits <= credits-8'h01;
      else if (credit_in.valid_response) begin
        if (~credit_in.valid_request ) begin
          if (credit_in.response_credits[0])
            credits <= credits-(~credit_in.response_credits[1:8]+8'h01);
          else
            credits <= credits+credit_in.response_credits[1:8];
        end
        else begin
          if (credit_in.response_credits[0])
            credits <= credits-(~credit_in.response_credits[1:8]);
          else
            credits <= credits+credit_in.response_credits[1:8]-8'h01;
        end
      end
    end
  end

  assign credit_out.credits = credits;

endmodule