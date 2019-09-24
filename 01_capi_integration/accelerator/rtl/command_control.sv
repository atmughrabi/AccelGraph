import CAPI_PKG::*;
import AFU_PKG::*;


module command_control (
  input logic clock,    // Clock
  input logic rstn,
  input logic enabled,
  input CommandBufferLine command_arbiter_in,
  input logic [3:0] ready,
  input logic [0:7] command_tag_in,
  output CommandInterfaceOutput command_out
);


  logic odd_parity;

  logic wed_request;
  logic write_request;
  logic read_request;
  logic restart_request;
  CommandInterfaceOutput command_out_latch;

  assign odd_parity                       = 1'b1; // Odd parity
  assign command_out_latch.abt            = STRICT;
  // assign command_out_latch.abt            = ABORT;
  // assign command_out_latch.abt            = PERF;
  // assign command_out_latch.abt            = PAGE;
  // assign command_out_latch.abt            = SPEC;
  assign command_out_latch.context_handle = 16'h00; // dedicated mode cch always zero

////////////////////////////////////////////////////////////////////////////
//request type
////////////////////////////////////////////////////////////////////////////

  assign wed_request     = ready[1];
  assign write_request   = ready[2];
  assign read_request    = ready[3];
  assign restart_request = ready[0];

  always_ff @(posedge clock) begin
    command_out <= command_out_latch;
  end // always_ff @(posedge clock)

////////////////////////////////////////////////////////////////////////////
//drive command
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      command_out_latch.valid   <= 1'b0;
      command_out_latch.command <= INVALID; // just zero it out
      command_out_latch.address <= 64'h0000_0000_0000_0000;
      command_out_latch.tag     <= INVALID_TAG;
      command_out_latch.size    <= 12'h000;
    end
    else begin
      command_out_latch.valid   <= command_arbiter_in.valid;
      command_out_latch.command <= command_arbiter_in.command;
      command_out_latch.address <= command_arbiter_in.address;
      command_out_latch.tag     <= command_tag_in;
      command_out_latch.size    <= command_arbiter_in.size;
    end
  end // always_ff @(posedge clock)


////////////////////////////////////////////////////////////////////////////
//partity check Logic
////////////////////////////////////////////////////////////////////////////

//Generate parity for command tag, command code, and cea. Latch parity info.
  parity #(
    .BITS(8)
  ) tag_parity_instant (
    .data(command_out_latch.tag),
    .odd(odd_parity),
    .par(command_out_latch.tag_parity)
  );

  parity #(
    .BITS(13)
  ) command_parity_instant (
    .data(command_out_latch.command),
    .odd(odd_parity),
    .par(command_out_latch.command_parity )
  );

  parity #(
    .BITS(64)
  ) address_parity_instant (
    .data(command_out_latch.address),
    .odd(odd_parity),
    .par(command_out_latch.address_parity )
  );


endmodule