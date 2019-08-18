import CAPI_PKG::*;
import CREDIT_PKG::*;
import COMMAND_PKG::*;


module command_control (
	input logic clock,    // Clock
	input logic rstn, 	
	input logic enabled,
	input CommandInterfaceInput command_in,
  input CommandBufferLine command_buffer_in,
  input ResponseInterface response,
  output CommandInterfaceOutput command_out
);

  assign command_out.command_parity  = ~^command_out.command;
  assign command_out.address_parity  = ~^command_out.address;
  assign command_out.tag_parity      = ~^command_out.tag;
  assign command_out.abt             = STRICT;
  assign command_out.context_handle  = 16'h00;

////////////////////////////////////////////////////////////////////////////
//request type
////////////////////////////////////////////////////////////////////////////

  logic wed_request;
  logic write_request;
  logic read_request;
  logic restart_request;

  assign wed_request = 0;
  assign write_request = 0;
  assign read_request = 0;
  assign restart_request = 0;

  logic valid_request;


////////////////////////////////////////////////////////////////////////////
//Credit Tracking Logic
////////////////////////////////////////////////////////////////////////////

 CreditInterfaceOutput credits;

 credit_control credit_control_instant(
      .clock         (clock),
      .rstn          (rstn),
      .credit_in     ({response.valid,wed_request,write_request,read_request,restart_request,response.credits,command_in}),
      .credit_out    (credits));

endmodule