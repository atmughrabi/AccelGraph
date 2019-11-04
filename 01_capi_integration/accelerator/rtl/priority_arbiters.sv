// -----------------------------------------------------------------------------
//
//    "ECE 5745 Tutorial 4: Verilog Hardware Description Language"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : School of Electrical and Computer Engineering Cornell University
// File   : priority_arbiters.sv
// Create : 2019-09-26 15:21:54
// Revise : 2019-09-26 15:21:54
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

//========================================================================
// Verilog Components: Arbiters
//========================================================================
// There are three basic arbiter components which are provided in this
// file: vc_FixedArbChain, vc_VariableArbChain, vc_RoundRobinArbChain.
// These basic components can be combined in various ways to create the
// desired arbiter.


//------------------------------------------------------------------------
// vc_FixedArbChain
//------------------------------------------------------------------------
// reqs[0] has the highest priority, reqs[1] has the second
// highest priority, etc.

module vc_FixedArbChain #(parameter p_num_reqs = 2) (
  input  logic                  kin   , // kill in
  input  logic [p_num_reqs-1:0] reqs  , // 1 = making a req, 0 = no req
  output logic [p_num_reqs-1:0] grants, // (one-hot) 1 indicates req won grant
  output logic                  kout    // kill out
);

  // The internal kills signals essentially form a kill chain from the
  // highest priority to the lowest priority requester. The highest
  // priority requster (say requester i) which is actually making a
  // request sets the kill signal for the next requester to one (ie
  // kills[i+1]) and then this kill signal is propagated to all lower
  // priority requesters.

  logic [p_num_reqs:0] kills;
  assign kills[0] = 1'b0;

  // The per requester logic first computes the grant signal and then
  // computes the kill signal for the next requester.

  logic [p_num_reqs-1:0] grants_int;

  genvar i;
  generate
    for ( i = 0; i < p_num_reqs; i = i + 1 )
      begin : per_req_logic

        // Grant is true if this requester is not killed and it is actually
        // making a req.

        assign grants_int[i] = !kills[i] && reqs[i];

        // Kill is true if this requester was either killed or it received
        // the grant.

        assign kills[i+1] = kills[i] || grants_int[i];

      end
  endgenerate

  // We AND kin into the grant and kout signals afterwards so that we can
  // begin doing the arbitration before we know kin. This also allows us
  // to build hybrid tree-ripple arbiters out of vc_FixedArbChain
  // components.

  assign grants = grants_int & {p_num_reqs{~kin}};
  assign kout   = kills[p_num_reqs] || kin;

endmodule

//------------------------------------------------------------------------
// vc_FixedArb
//------------------------------------------------------------------------
// reqs[0] has the highest priority, reqs[1] has the second highest
// priority, etc.

module vc_FixedArb #(parameter p_num_reqs = 2) (
  input  logic [p_num_reqs-1:0] reqs  , // 1 = making a req, 0 = no req
  output logic [p_num_reqs-1:0] grants  // (one-hot) 1 = which req won grant
);

  logic dummy_kout;

  vc_FixedArbChain #(p_num_reqs) fixed_arb_chain (
    .kin   (1'b0      ),
    .reqs  (reqs      ),
    .grants(grants    ),
    .kout  (dummy_kout)
  );

endmodule
//------------------------------------------------------------------------
// vc_VariableArbChain
//------------------------------------------------------------------------
// The input priority signal is a one-hot signal where the one indicates
// which request should be given highest priority.

module vc_VariableArbChain #(parameter p_num_reqs = 2) (
  input  logic                  kin      , // kill in
  input  logic [p_num_reqs-1:0] priority_, // (one-hot) 1 is req w/ highest pri
  input  logic [p_num_reqs-1:0] reqs     , // 1 = making a req, 0 = no req
  output logic [p_num_reqs-1:0] grants   , // (one-hot) 1 is req won grant
  output logic                  kout       // kill out
);

  // The internal kills signals essentially form a kill chain from the
  // highest priority to the lowest priority requester. Unliked the fixed
  // arb, the priority input is used to determine which request has the
  // highest priority. We could use a circular kill chain, but static
  // timing analyzers would probably consider it a combinational loop
  // (which it is) and choke. Instead we replicate the kill chain. See
  // Principles and Practices of Interconnection Networks, Dally +
  // Towles, p354 for more info.

  logic [2*p_num_reqs:0] kills;
  assign kills[0] = 1'b1;

  logic [2*p_num_reqs-1:0] priority_int;
  assign priority_int = { {p_num_reqs{1'b0}}, priority_ };

  logic [2*p_num_reqs-1:0] reqs_int;
  assign reqs_int = { reqs, reqs };

  logic [2*p_num_reqs-1:0] grants_int;

  // The per requester logic first computes the grant signal and then
  // computes the kill signal for the next requester.

  localparam p_num_reqs_x2 = (p_num_reqs << 1);
  genvar i;
  generate
    for ( i = 0; i < 2*p_num_reqs; i = i + 1 )
      begin : per_req_logic

        // If this is the highest priority requester, then we ignore the
        // input kill signal, otherwise grant is true if this requester is
        // not killed and it is actually making a req.

        assign grants_int[i]
          = priority_int[i] ? reqs_int[i] : (!kills[i] && reqs_int[i]);

        // If this is the highest priority requester, then we ignore the
        // input kill signal, otherwise kill is true if this requester was
        // either killed or it received the grant.

        assign kills[i+1]
          = priority_int[i] ? grants_int[i] : (kills[i] || grants_int[i]);

      end
  endgenerate

  // To calculate final grants we OR the two grants from the replicated
  // kill chain. We also AND in the global kin signal.

  assign grants
    = (grants_int[p_num_reqs-1:0] | grants_int[2*p_num_reqs-1:p_num_reqs])
      & {p_num_reqs{~kin}};

  assign kout = kills[2*p_num_reqs] || kin;

endmodule

//------------------------------------------------------------------------
// vc_VariableArb
//------------------------------------------------------------------------
// The input priority signal is a one-hot signal where the one indicates
// which request should be given highest priority.

module vc_VariableArb #(parameter p_num_reqs = 2) (
  input  logic [p_num_reqs-1:0] priority_, // (one-hot) 1 is req w/ highest pri
  input  logic [p_num_reqs-1:0] reqs     , // 1 = making a req, 0 = no req
  output logic [p_num_reqs-1:0] grants     // (one-hot) 1 is req won grant
);

  logic dummy_kout;

  vc_VariableArbChain #(p_num_reqs) variable_arb_chain (
    .kin      (1'b0      ),
    .priority_(priority_ ),
    .reqs     (reqs      ),
    .grants   (grants    ),
    .kout     (dummy_kout)
  );

endmodule

//------------------------------------------------------------------------
// vc_RoundRobinArbChain
//------------------------------------------------------------------------
// Ensures strong fairness among the requesters. The requester which wins
// the grant will be the lowest priority requester the next cycle.

module vc_RoundRobinArbChain #(
  parameter p_num_reqs            = 2,
  parameter p_priority_rstn_value = 1  // (one-hot) 1 = high priority req
) (
  input  logic                  clock ,
  input  logic                  rstn  ,
  input  logic                  kin   , // kill in
  input  logic [p_num_reqs-1:0] reqs  , // 1 = making a req, 0 = no req
  output logic [p_num_reqs-1:0] grants, // (one-hot) 1 is req won grant
  output logic                  kout    // kill out
);

  // We only update the priority if a requester actually received a grant

  logic priority_en;
  assign priority_en = |grants;

  // Next priority is just the one-hot grant vector left rotated by one

  logic [p_num_reqs-1:0] priority_next;
  assign priority_next = { grants[p_num_reqs-2:0], grants[p_num_reqs-1] };

  // State for the one-hot priority vector

  logic [p_num_reqs-1:0] priority_;

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      priority_ <= p_priority_rstn_value;
    end else begin
      if(priority_en)
        priority_ <= priority_next;
    end
  end

  // always @( posedge clock )
  //   if ( rstn || priority_en )
  //     priority_ <= rstn ? p_priority_rstn_value : priority_next;

  // Variable arbiter chain

  vc_VariableArbChain #(p_num_reqs) variable_arb_chain (
    .kin      (kin      ),
    .priority_(priority_),
    .reqs     (reqs     ),
    .grants   (grants   ),
    .kout     (kout     )
  );

endmodule

//------------------------------------------------------------------------
// vc_RoundRobinArb
//------------------------------------------------------------------------
// Ensures strong fairness among the requesters. The requester which wins
// the grant will be the lowest priority requester the next cycle.
//
//  NOTE : Ideally we would just instantiate the vc_RoundRobinArbChain
//         and wire up kin to zero, but VCS seems to have trouble with
//         correctly elaborating the parameteres in that situation. So
//         for now we just duplicate the code from vc_RoundRobinArbChain
//

// module vc_RoundRobinArb #(parameter p_num_reqs = 2) (
//   input  logic                clock,
//   input  logic                rstn,
//   input  logic [p_num_reqs-1:0] reqs,    // 1 = making a req, 0 = no req
//   output logic [p_num_reqs-1:0] grants   // (one-hot) 1 is req won grant
// );

//   // We only update the priority if a requester actually received a grant

//   logic priority_en;
//   assign priority_en = |grants;

//   // Next priority is just the one-hot grant vector left rotated by one

//   logic [p_num_reqs-1:0] priority_next;
//   assign priority_next = { grants[p_num_reqs-2:0], grants[p_num_reqs-1] };

//   // State for the one-hot priority vector

//   logic [p_num_reqs-1:0] priority_;

//   // always @( posedge clock )
//   //   if ( rstn || priority_en )
//   //     priority_ <= rstn ? 1 : priority_next;

//   always_ff @(posedge clock or negedge rstn) begin
//     if(~rstn) begin
//       priority_ <= 1;
//     end else begin
//       if(priority_en)
//         priority_ <= priority_next;
//     end
//   end

//   // Variable arbiter chain

//   logic dummy_kout;

//   vc_VariableArbChain#(p_num_reqs) variable_arb_chain
//     (
//       .kin       (1'b0),
//       .priority_ (priority_),
//       .reqs      (reqs),
//       .grants    (grants),
//       .kout      (dummy_kout)
//     );

// endmodule


//Using Two Simple Priority Arbiters with a Mask - scalable
//author: dongjun_luo@hotmail.com
module vc_RoundRobinArb #(parameter p_num_reqs = 2) (
  input  logic                  clock ,
  input  logic                  rstn  ,
  input  logic [p_num_reqs-1:0] reqs  , // 1 = making a req, 0 = no req
  output logic [p_num_reqs-1:0] grants  // (one-hot) 1 is req won grant
);


  logic [p_num_reqs-1:0] rotate_ptr  ;
  logic [p_num_reqs-1:0] mask_req    ;
  logic [p_num_reqs-1:0] mask_grant  ;
  logic [p_num_reqs-1:0] grant_comb  ;
  logic                  no_mask_req ;
  logic [p_num_reqs-1:0] nomask_grant;
  logic                  update_ptr  ;

  genvar i;

// rotate pointer update logic
  assign update_ptr = |grants[p_num_reqs-1:0];
  always @ (posedge clock or negedge rstn) begin
    if (~rstn) begin
      rotate_ptr[0] <= 1;
      rotate_ptr[1] <= 1;
    end
    else if (update_ptr)
      begin
        // note: p_num_reqs must be at least 2
        rotate_ptr[0] <= grants[p_num_reqs-1];
        rotate_ptr[1] <= grants[p_num_reqs-1] | grants[0];
      end
  end

  generate
    for (i=2;i<p_num_reqs;i=i+1) begin : generate_rotate_ptr
      always @ (posedge clock or negedge rstn) begin
        if (~rstn)
          rotate_ptr[i] <= 1'b1;
        else if (update_ptr)
          rotate_ptr[i] <= grants[p_num_reqs-1] | (|grants[i-1:0]);
      end
    end
  endgenerate

// mask grants generation logic
  assign mask_req[p_num_reqs-1:0] = reqs[p_num_reqs-1:0] & rotate_ptr[p_num_reqs-1:0];

  assign mask_grant[0] = mask_req[0];
  generate
    for (i=1;i<p_num_reqs;i=i+1)  begin : generate_mask_grant
      assign mask_grant[i] = (~|mask_req[i-1:0]) & mask_req[i];
    end
  endgenerate

// non-mask grants generation logic
  assign nomask_grant[0] = reqs[0];
  generate
    for (i=1;i<p_num_reqs;i=i+1)  begin : generate_nomask_grant
      assign nomask_grant[i] = (~|reqs[i-1:0]) & reqs[i];
    end
  endgenerate

// grants generation logic
  assign no_mask_req                = ~|mask_req[p_num_reqs-1:0];
  assign grant_comb[p_num_reqs-1:0] = mask_grant[p_num_reqs-1:0] | (nomask_grant[p_num_reqs-1:0] & {p_num_reqs{no_mask_req}});

  always @ (posedge clock or negedge rstn) begin
    if (~rstn)  grants[p_num_reqs-1:0] <= {p_num_reqs{1'b0}};
    else    grants[p_num_reqs-1:0] <= grant_comb[p_num_reqs-1:0] & ~grants[p_num_reqs-1:0];
  end
endmodule