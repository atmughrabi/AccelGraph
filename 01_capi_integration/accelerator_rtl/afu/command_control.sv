// -----------------------------------------------------------------------------
//
//    "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : command_control.sv
// Create : 2019-09-26 15:20:51
// Revise : 2019-09-26 15:20:51
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import AFU_PKG::*;


module command_control (
  input  logic                  clock             , // Clock
  input  logic                  rstn              ,
  input  logic                  enabled_in        ,
  input  CommandBufferLine      command_arbiter_in,
  input  logic [0:7]            command_tag_in    ,
  output CommandInterfaceOutput command_out
);


  logic                  odd_parity       ;
  logic                  enabled          ;
  CommandInterfaceOutput command_out_latch;

  assign odd_parity = 1'b1; // Odd parity
  // command_out_latch.abt                  = STRICT;
  // assign command_out_latch.abt            = ABORT;
  // assign command_out_latch.abt            = PREF;
  // assign command_out_latch.abt            = PAGE;
  // assign command_out_latch.abt            = SPEC;
  assign command_out_latch.context_handle = 16'h00; // dedicated mode cch always zero

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      enabled <= 0;
    end else begin
      enabled <= enabled_in;
    end
  end

////////////////////////////////////////////////////////////////////////////
//request type
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock) begin
    command_out <= command_out_latch;
  end // always_ff @(posedge clock)

////////////////////////////////////////////////////////////////////////////
//drive command
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      command_out_latch.valid <= 1'b0;
    end
    else begin
      if(enabled) begin
        command_out_latch.valid <= command_arbiter_in.valid;
      end
    end
  end // always_ff @(posedge clock)

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      command_out_latch.command <= TOUCH_I;
      command_out_latch.address <= 0;
      command_out_latch.tag     <= 0;
      command_out_latch.size    <= 0;
      command_out_latch.abt     <= STRICT;
    end else begin
      command_out_latch.command <= command_arbiter_in.payload.command;
      command_out_latch.address <= command_arbiter_in.payload.address;
      command_out_latch.tag     <= command_tag_in;
      command_out_latch.size    <= command_arbiter_in.payload.size;
      command_out_latch.abt     <= command_arbiter_in.payload.abt;
    end
  end // always_ff @(posedge clock)


////////////////////////////////////////////////////////////////////////////
//partity check Logic
////////////////////////////////////////////////////////////////////////////

//Generate parity for command tag, command code, and cea. Latch parity info.
  parity #(.BITS(8)) tag_parity_instant (
    .data(command_out_latch.tag       ),
    .odd (odd_parity                  ),
    .par (command_out_latch.tag_parity)
  );

  parity #(.BITS(13)) command_parity_instant (
    .data(command_out_latch.command       ),
    .odd (odd_parity                      ),
    .par (command_out_latch.command_parity)
  );

  parity #(.BITS(64)) address_parity_instant (
    .data(command_out_latch.address       ),
    .odd (odd_parity                      ),
    .par (command_out_latch.address_parity)
  );


endmodule