import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module round_robin_priority_arbiter #(
  parameter NUM_REQUESTS = 4,
  parameter WIDTH = 8
) (
  input logic clock,    // Clock
  input logic rstn,
  input logic enabled,
  input logic [0:WIDTH-1] buffer_in [0:NUM_REQUESTS-1],
  input  logic [NUM_REQUESTS-1:0] requests,
  output logic [0:WIDTH-1] arbiter_out,
  output logic [NUM_REQUESTS-1:0] ready
);



////////////////////////////////////////////////////////////////////////////
//requests
////////////////////////////////////////////////////////////////////////////

  logic [NUM_REQUESTS-1:0] grant;
  logic [0:WIDTH-1] arbiter_out_latch;


// vc_RoundRobinArb
//------------------------------------------------------------------------
// Ensures strong fairness among the requesters. The requester which wins
// the grant will be the lowest priority requester the next cycle.

  vc_RoundRobinArb #(
    .p_num_reqs(NUM_REQUESTS)
  )round_robin_arbiter_instance(
    .clock (clock),
    .rstn  (rstn),
    .reqs (requests),
    .grants(grant)
  );

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
