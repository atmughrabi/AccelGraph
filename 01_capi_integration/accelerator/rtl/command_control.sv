import CAPI_PKG::*;
import AFU_PKG::*;


module command_control (
  input logic clock,    // Clock
  input logic rstn,
  input logic enabled,
  input CommandBufferArbiterInterfaceOut command_arbiter_in,
  input logic [0:7] command_tag_in,
  output CommandInterfaceOutput command_out
);


  logic odd_parity;

  logic wed_request;
  logic write_request;
  logic read_request;
  logic restart_request;

  assign odd_parity                 = 1'b1; // Odd parity
  assign command_out.abt            = STRICT;
  assign command_out.context_handle = 16'h00; // dedicated mode cch always zero

////////////////////////////////////////////////////////////////////////////
//request type
////////////////////////////////////////////////////////////////////////////

  assign wed_request     = command_arbiter_in.wed_ready;
  assign write_request   = command_arbiter_in.write_ready;
  assign read_request    = command_arbiter_in.read_ready;
  assign restart_request = command_arbiter_in.restart_ready;

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
      command_out.tag      <= command_tag_in;
      command_out.size     <= command_arbiter_in.command_buffer_out.size;
    end
  end // always_ff @(posedge clock)


////////////////////////////////////////////////////////////////////////////
//partity check Logic
////////////////////////////////////////////////////////////////////////////

//Generate parity for command tag, command code, and cea. Latch parity info.
  parity #(
    .BITS(8)
  ) tag_parity_instant (
    .data(command_out.tag),
    .odd(odd_parity),
    .par(command_out.tag_parity)
  );

  parity #(
    .BITS(13)
  ) command_parity_instant (
    .data(command_out.command),
    .odd(odd_parity),
    .par(command_out.command_parity )
  );

  parity #(
    .BITS(64)
  ) address_parity_instant (
    .data(command_out.address),
    .odd(odd_parity),
    .par(command_out.address_parity )
  );


endmodule