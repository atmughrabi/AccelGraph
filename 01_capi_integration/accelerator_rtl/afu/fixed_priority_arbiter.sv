// -----------------------------------------------------------------------------
//
//    "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : fixed_priority_arbiter.sv
// Create : 2019-09-26 15:21:13
// Revise : 2019-12-08 14:01:13
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module fixed_priority_arbiter_N_input_1_ouput #(
  parameter NUM_REQUESTS = 4,
  parameter WIDTH        = 8
) (
  input  logic                    clock                       , // Clock
  input  logic                    rstn                        ,
  input  logic                    enabled                     ,
  input  logic [       0:WIDTH-1] buffer_in [0:NUM_REQUESTS-1],
  input  logic [NUM_REQUESTS-1:0] requests                    ,
  output logic [       0:WIDTH-1] arbiter_out                 ,
  output logic [NUM_REQUESTS-1:0] ready
);



////////////////////////////////////////////////////////////////////////////
//requests
////////////////////////////////////////////////////////////////////////////

  logic [NUM_REQUESTS-1:0] grant            ;
  logic [       0:WIDTH-1] arbiter_out_latch;


//------------------------------------------------------------------------
// vc_FixedArb
//------------------------------------------------------------------------
// reqs[0] has the highest priority, reqs[1] has the second highest
// priority, etc.


  generate if(NUM_REQUESTS > 1) begin
      vc_FixedArb #(
        .p_num_reqs(NUM_REQUESTS)
      )fixed_arbiter_instance(
        .reqs(requests),
        .grants(grant)
      );
    end else begin
      always_ff @(posedge clock or negedge rstn) begin : proc_grant
        if(~rstn) begin
          grant <= 0;
        end else begin
          grant <= requests;
        end
      end
    end
  endgenerate

/////////////////////////////////////
// ready the winner if any
  integer i;
  integer j;

  always_comb begin
    arbiter_out_latch = 0;
    for (i = 0; i < NUM_REQUESTS; i++) begin
      if (grant[i]) begin
        arbiter_out_latch = buffer_in[i];
      end
    end
  end

  always @(posedge clock or negedge rstn) begin
    if (~rstn) begin
      arbiter_out <= 0;
    end else begin
      if (enabled) begin
        arbiter_out <= arbiter_out_latch;
      end
      else begin
        arbiter_out <= 0;
      end
    end
  end

  always_comb begin
    for (j = 0; j < NUM_REQUESTS; j++) begin
      ready[j] = grant[j] & enabled;
    end
  end

endmodule


module fixed_priority_arbiter_1_input_N_ouput #(
  parameter NUM_REQUESTS = 4,
  parameter WIDTH        = 8
) (
  input  logic                    clock                         , // Clock
  input  logic                    rstn                          ,
  input  logic                    enabled                       ,
  input  logic [       0:WIDTH-1] buffer_in                     ,
  input  logic [NUM_REQUESTS-1:0] requests                      ,
  output logic [       0:WIDTH-1] arbiter_out [0:NUM_REQUESTS-1],
  output logic [NUM_REQUESTS-1:0] ready
);



////////////////////////////////////////////////////////////////////////////
//requests
////////////////////////////////////////////////////////////////////////////

  logic [NUM_REQUESTS-1:0] grant                              ;
  logic [NUM_REQUESTS-1:0] grant_latched                      ;
  logic [       0:WIDTH-1] arbiter_out_latch[0:NUM_REQUESTS-1];

//------------------------------------------------------------------------
// vc_FixedArb
//------------------------------------------------------------------------
// reqs[0] has the highest priority, reqs[1] has the second highest
// priority, etc.

  generate if(NUM_REQUESTS > 1) begin
      vc_FixedArb #(
        .p_num_reqs(NUM_REQUESTS)
      )fixed_arbiter_instance(
        .reqs(requests),
        .grants(grant)
      );
    end else begin
      always_ff @(posedge clock or negedge rstn) begin : proc_grant
        if(~rstn) begin
          grant <= 0;
        end else begin
          grant <= requests;
        end
      end
    end
  endgenerate

/////////////////////////////////////
// ready the winner if any
  integer i;
  integer j;

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      grant_latched <= 0;
    end else begin
      if(enabled)begin
        grant_latched <= grant;
      end
    end
  end

  always_comb begin
    for (i = 0; i < NUM_REQUESTS; i++) begin
      arbiter_out_latch[i] = 0;
      if (grant_latched[i]) begin
        arbiter_out_latch[i] = buffer_in;
      end
    end
  end

  always @(posedge clock ) begin
    arbiter_out <= arbiter_out_latch;
  end

  always_comb begin
    for (j = 0; j < NUM_REQUESTS; j++) begin
      ready[j] = grant_latched[j] & enabled;
    end
  end

endmodule
