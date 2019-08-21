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

always @ (posedge clock or negedge rstn) begin
    if (~rstn)
      credit_out.credits <= credit_in.command_in.room;
    else if (credit_in.valid_request && ~credit_in.valid_response)
      credit_out.credits <= credit_out.credits-8'h01;
    else if (credit_in.valid_response) begin
      if (~credit_in.valid_request )
        begin
        if (credit_in.response_credits[0])
          credit_out.credits <= credit_out.credits-(~credit_in.response_credits[1:8]+8'h01);
        else
          credit_out.credits <= credit_out.credits+credit_in.response_credits[1:8];
      end
      else begin
        if (credit_in.response_credits[0])
          credit_out.credits <= credit_out.credits-(~credit_in.response_credits[1:8]);
        else
          credit_out.credits <= credit_out.credits+credit_in.response_credits[1:8]-8'h01;
      end
    end
  end

endmodule