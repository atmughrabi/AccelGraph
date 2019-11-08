// -----------------------------------------------------------------------------
//
//    "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : response_control.sv
// Create : 2019-09-30 02:22:05
// Revise : 2019-09-30 02:22:05
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------


import CAPI_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module response_control (
  input  logic                       clock               , // Clock
  input  logic                       rstn                ,
  input  logic                       enabled_in          ,
  input  ResponseInterface           response            ,
  input  CommandTagLine              response_tag_id_in  ,
  output logic [0:6]                 response_error      ,
  output ResponseControlInterfaceOut response_control_out
);


  logic                       odd_parity                  ;
  logic                       tag_parity                  ;
  logic                       tag_parity_link             ;
  ResponseInterface           response_in                 ;
  ResponseControlInterfaceOut response_control_out_latched;

  logic       enable_errors     ;
  logic [0:6] detected_errors   ;
  logic [0:5] cmd_response_error;
  logic       tag_parity_error  ;

  assign odd_parity    = 1'b1; // Odd parity
  assign enable_errors = 1'b1; // enable errors
  logic enabled;

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
//input latching Logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      response_in <= 0;
    end else begin
      if(enabled && response.valid) begin
        response_in <= response;
      end else begin
        response_in <= 0;
      end
    end
  end


////////////////////////////////////////////////////////////////////////////
//output latching Logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      response_control_out <= 0;
    end else begin
      if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
        response_control_out <= response_control_out_latched;
      end else begin
        response_control_out <= 0;
      end
    end
  end

////////////////////////////////////////////////////////////////////////////
//Response Buffer switch Logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      response_control_out_latched <= 0;
    end else begin
      if(enabled && response_in.valid) begin
        case (response_tag_id_in.cmd_type)
          CMD_READ : begin
            response_control_out_latched.read_response    <= 1'b1;
            response_control_out_latched.write_response   <= 1'b0;
            response_control_out_latched.wed_response     <= 1'b0;
            response_control_out_latched.restart_response <= 1'b0;
          end
          CMD_WRITE : begin
            response_control_out_latched.read_response    <= 1'b0;
            response_control_out_latched.write_response   <= 1'b1;
            response_control_out_latched.wed_response     <= 1'b0;
            response_control_out_latched.restart_response <= 1'b0;
          end
          CMD_WED : begin
            response_control_out_latched.read_response    <= 1'b0;
            response_control_out_latched.write_response   <= 1'b0;
            response_control_out_latched.wed_response     <= 1'b1;
            response_control_out_latched.restart_response <= 1'b0;
          end
          CMD_RESTART : begin
            response_control_out_latched.read_response    <= 1'b0;
            response_control_out_latched.write_response   <= 1'b0;
            response_control_out_latched.wed_response     <= 1'b0;
            response_control_out_latched.restart_response <= 1'b1;
          end
          default : begin
            response_control_out_latched.read_response    <= 1'b0;
            response_control_out_latched.write_response   <= 1'b0;
            response_control_out_latched.wed_response     <= 1'b0;
            response_control_out_latched.restart_response <= 1'b0;
          end
        endcase
        response_control_out_latched.response.valid            <= response_in.valid;
        response_control_out_latched.response.cmd              <= response_tag_id_in;
        response_control_out_latched.response.cmd.tag          <= response_in.tag;
        response_control_out_latched.response.response         <= response_in.response;
        response_control_out_latched.response.response_credits <= response_in.credits;

      end else begin
        response_control_out_latched <= 0;
      end
    end
  end

////////////////////////////////////////////////////////////////////////////
//partity check Logic
////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity <= odd_parity;
    end else begin
      if(enabled && response.valid) begin
        tag_parity <= response.tag_parity;
      end else begin
        tag_parity <= odd_parity;
      end
    end
  end

  parity #(.BITS(8)) response_tag_parity_instant (
    .data(response_in.tag),
    .odd (odd_parity     ),
    .par (tag_parity_link)
  );

////////////////////////////////////////////////////////////////////////////
// Error Logic
////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity_error   <= 1'b0;
      cmd_response_error <= 6'h00;
      detected_errors    <= 7'h00;
    end else begin

      if(response_in.valid) begin
        tag_parity_error   <= tag_parity_link ^ tag_parity;
        cmd_response_error <= cmd_response_error_type(response_in.response);
      end else begin
        tag_parity_error   <= 1'b0;
        cmd_response_error <= 6'h00;
      end

      detected_errors <= {tag_parity_error, cmd_response_error};
    end
  end

  always_ff @(posedge clock) begin
    if(enable_errors) begin
      response_error <= detected_errors;
    end else  begin
      response_error <= 7'h00;
    end
  end



endmodule