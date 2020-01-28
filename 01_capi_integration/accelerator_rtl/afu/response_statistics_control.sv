// -----------------------------------------------------------------------------
//
//    "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : response_statistics_control.sv
// Create : 2019-11-29 06:19:32
// Revise : 2019-11-29 06:19:32
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import CAPI_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module response_statistics_control (
  input  logic                      clock                  , // Clock
  input  logic                      rstn                   ,
  input  logic                      enabled_in             ,
  input  ResponseInterface          response               ,
  input  CommandTagLine             response_tag_id_in     ,
  output ResponseStatistcsInterface response_statistics_out
);


  ResponseInterface          response_latched               ;
  CommandTagLine             response_tag_id_latched        ;
  ResponseStatistcsInterface response_statistics_out_latched;


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
      response_latched <= 0;
    end else begin
      if(enabled && response.valid) begin
        response_latched <= response;
      end else begin
        response_latched <= 0;
      end
    end
  end


////////////////////////////////////////////////////////////////////////////
//output latching Logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      response_statistics_out <= 0;
    end else begin
      if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
        response_statistics_out <= response_statistics_out_latched;
      end else begin
        response_statistics_out <= 0;
      end
    end
  end

////////////////////////////////////////////////////////////////////////////
//Response stats switch Logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      response_statistics_out_latched <= 0;
    end else begin
      if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
        if(response_latched.valid) begin
          case(response_latched.response)
            DONE : begin

              if(response_tag_id_in.cmd_type == CMD_RESTART)
                response_statistics_out_latched.DONE_RESTART_count <= response_statistics_out_latched.DONE_RESTART_count + 1;
              else if (response_tag_id_in.cmd_type == CMD_PREFETCH_READ)
                response_statistics_out_latched.DONE_PREFETCH_READ_count <= response_statistics_out_latched.DONE_PREFETCH_READ_count + 1;
              else if (response_tag_id_in.cmd_type == CMD_PREFETCH_WRITE)
                response_statistics_out_latched.DONE_PREFETCH_WRITE_count <= response_statistics_out_latched.DONE_PREFETCH_WRITE_count + 1;
              else if (response_tag_id_in.cmd_type == CMD_READ)
                response_statistics_out_latched.DONE_READ_count <= response_statistics_out_latched.DONE_READ_count + 1;
              else if (response_tag_id_in.cmd_type == CMD_WRITE)
                response_statistics_out_latched.DONE_WRITE_count <= response_statistics_out_latched.DONE_WRITE_count + 1;

              response_statistics_out_latched.DONE_count <= response_statistics_out_latched.DONE_count + 1;

            end
            FLUSHED : begin
              response_statistics_out_latched.FLUSHED_count <= response_statistics_out_latched.FLUSHED_count + 1;
            end
            PAGED : begin
              response_statistics_out_latched.PAGED_count <= response_statistics_out_latched.PAGED_count + 1;
            end
            AERROR : begin
              response_statistics_out_latched.AERROR_count <= response_statistics_out_latched.AERROR_count + 1;
            end
            DERROR : begin
              response_statistics_out_latched.DERROR_count <= response_statistics_out_latched.DERROR_count + 1;
            end
            FAILED : begin
              response_statistics_out_latched.FAILED_count <= response_statistics_out_latched.FAILED_count + 1;
            end
            FAULT : begin
              response_statistics_out_latched.FAULT_count <= response_statistics_out_latched.FAULT_count + 1;
            end
            NRES : begin
              response_statistics_out_latched.NRES_count <= response_statistics_out_latched.NRES_count + 1;
            end
            NLOCK : begin
              response_statistics_out_latched.NLOCK_count <= response_statistics_out_latched.NLOCK_count + 1;
            end
            default : begin
              response_statistics_out_latched <= response_statistics_out_latched;
            end
          endcase
        end

        response_statistics_out_latched.CYCLE_count <= response_statistics_out_latched.CYCLE_count + 1;
      end
    end
  end

endmodule