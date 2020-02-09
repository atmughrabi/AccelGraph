// -----------------------------------------------------------------------------
//
//    "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : round_robin_priority_arbiter.sv
// Create : 2019-09-26 15:25:04
// Revise : 2019-12-08 14:00:34
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module round_robin_priority_arbiter_N_input_1_ouput #(
  parameter NUM_REQUESTS = 4,
  parameter WIDTH        = 8
) (
  input  logic                    clock                       , // Clock
  input  logic                    rstn                        ,
  input  logic                    enabled                     ,
  input  logic [       0:WIDTH-1] buffer_in [0:NUM_REQUESTS-1],
  input  logic [NUM_REQUESTS-1:0] submit                      ,
  input  logic [NUM_REQUESTS-1:0] requests                    ,
  output logic [       0:WIDTH-1] arbiter_out                 ,
  output logic [NUM_REQUESTS-1:0] ready
);

////////////////////////////////////////////////////////////////////////////
//requests
////////////////////////////////////////////////////////////////////////////

  logic [NUM_REQUESTS-1:0] grant;

// vc_RoundRobinArb
//------------------------------------------------------------------------
// Ensures strong fairness among the requesters. The requester which wins
// the grant will be the lowest priority requester the next cycle.


  generate if(NUM_REQUESTS > 1) begin
      vc_RoundRobinArb #(
        .p_num_reqs(NUM_REQUESTS)
      )round_robin_arbiter_instance(
        .clock (clock),
        .rstn  (rstn),
        .reqs (requests),
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

  always @(posedge clock or negedge rstn) begin
    if (~rstn) begin
      arbiter_out <= 0;
      ready       <= 0;
    end else begin
      if (enabled) begin
        for ( i = 0; i < NUM_REQUESTS; i++) begin
          if (submit[i]) begin
            arbiter_out <= buffer_in[i];
          end
          ready[i] <= grant[i];
        end
        if (~(|submit)) begin
          arbiter_out <= 0;
        end
      end
    end
  end

endmodule


module round_robin_priority_arbiter_1_input_N_ouput #(
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

// vc_RoundRobinArb
//------------------------------------------------------------------------
// Ensures strong fairness among the requesters. The requester which wins
// the grant will be the lowest priority requester the next cycle.

  generate if(NUM_REQUESTS > 1) begin
      vc_RoundRobinArb #(
        .p_num_reqs(NUM_REQUESTS)
      )round_robin_arbiter_instance(
        .clock (clock),
        .rstn  (rstn),
        .reqs (requests),
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
