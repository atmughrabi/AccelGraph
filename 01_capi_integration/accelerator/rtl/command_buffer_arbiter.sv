// -----------------------------------------------------------------------------
//
//    "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : command_buffer_arbiter.sv
// Create : 2019-09-26 15:20:46
// Revise : 2019-09-26 15:20:46
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module command_buffer_arbiter #(parameter NUM_REQUESTS = 4) (
  input  logic                                clock              , // Clock
  input  logic                                rstn               ,
  input  logic                                enabled_in         ,
  input  CommandBufferLine [NUM_REQUESTS-1:0] command_buffer_in  ,
  input  logic             [NUM_REQUESTS-1:0] requests           ,
  output CommandBufferLine                    command_arbiter_out,
  output logic             [NUM_REQUESTS-1:0] ready
);



////////////////////////////////////////////////////////////////////////////
//requests
////////////////////////////////////////////////////////////////////////////

  logic [NUM_REQUESTS-1:0] grant                    ;
  CommandBufferLine        command_arbiter_out_latch;
  logic                    enabled                  ;

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

//------------------------------------------------------------------------
// vc_FixedArb
//------------------------------------------------------------------------
// reqs[0] has the highest priority, reqs[1] has the second highest
// priority, etc.

  vc_FixedArb #(.p_num_reqs(NUM_REQUESTS)) fixed_arbiter_instance (
    .reqs  (requests),
    .grants(grant   )
  );

/////////////////////////////////////
// ready the winner if any
  integer i;
  integer j;

  always_comb begin
    command_arbiter_out_latch.valid   = 1'b0;
    command_arbiter_out_latch.cmd     = 0;
    command_arbiter_out_latch.command = INVALID; // for debugging purposes
    command_arbiter_out_latch.address = 64'h0000_0000_0000_0000;
    command_arbiter_out_latch.size    = 12'h000;
    for (i = 0; i < NUM_REQUESTS; i++) begin
      if (grant[i]) begin
        command_arbiter_out_latch.valid   = command_buffer_in[i].valid;
        command_arbiter_out_latch.cmd     = command_buffer_in[i].cmd;
        command_arbiter_out_latch.command = command_buffer_in[i].command ;
        command_arbiter_out_latch.address = command_buffer_in[i].address ;
        command_arbiter_out_latch.size    = command_buffer_in[i].size;
      end
    end
  end

  always @(posedge clock or negedge rstn) begin
    if (~rstn) begin
      command_arbiter_out.valid   <= 1'b0;
      command_arbiter_out.cmd     <= 0;
      command_arbiter_out.command <= INVALID; // for debugging purposes
      command_arbiter_out.address <= 64'h0000_0000_0000_0000;
      command_arbiter_out.size    <= 12'h000;
    end
    else begin
      if (enabled) begin
        command_arbiter_out <= command_arbiter_out_latch;
      end
      else begin
        command_arbiter_out.valid   <= 1'b0;
        command_arbiter_out.cmd     <= 0;
        command_arbiter_out.command <= INVALID; // for debugging purposes
        command_arbiter_out.address <= 64'h0000_0000_0000_0000;
        command_arbiter_out.size    <= 12'h000;
      end
    end
  end

  always_comb begin
    for (j = 0; j < NUM_REQUESTS; j++) begin
      ready[j] = grant[j] & enabled;
    end
  end

endmodule
