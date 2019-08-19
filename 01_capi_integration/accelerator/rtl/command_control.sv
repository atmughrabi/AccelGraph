import CAPI_PKG::*;
import CREDIT_PKG::*;
import COMMAND_PKG::*;


module command_control (
	input logic clock,    // Clock
	input logic rstn, 	
	input logic enabled,
	input CommandInterfaceInput command_in,
  input CommandBufferArbiterInterfaceOut command_arbiter_in,
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

  assign wed_request      = command_arbiter_in.wed_ready;
  assign write_request    = command_arbiter_in.write_ready;
  assign read_request     = command_arbiter_in.read_ready;
  assign restart_request  = command_arbiter_in.restart_ready;

  logic valid_request;


////////////////////////////////////////////////////////////////////////////
//drive command
////////////////////////////////////////////////////////////////////////////



  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
        command_out.valid    <= 1'b0;
        command_out.command  <= INVALID; // just zero it out
        command_out.address  <= 64'h0000_0000_0000_0000;
        command_out.tag      <= INVALID_TAG;
        command_out.size     <= 12'h000;
    end 
    else begin
        command_out.valid    <= command_arbiter_in.command_buffer_out.valid;
        command_out.command  <= command_arbiter_in.command_buffer_out.command;
        command_out.address  <= command_arbiter_in.command_buffer_out.address;
        command_out.tag      <= command_arbiter_in.command_buffer_out.tag;
        command_out.size     <= command_arbiter_in.command_buffer_out.size;
      end
  end // always_ff @(posedge clock)



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