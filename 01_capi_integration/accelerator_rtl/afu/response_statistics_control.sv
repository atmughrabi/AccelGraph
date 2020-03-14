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
  input  logic                      rstn_in                ,
  input  logic                      enabled_in             ,
  input  ResponseInterface          response               ,
  input  CommandTagLine             response_tag_id_in     ,
  output ResponseStatistcsInterface response_statistics_out
);


  ResponseInterface          response_latched               ;
  ResponseInterface          response_latched_S2            ;
  ResponseInterface          response_latched_S3            ;
  CommandTagLine             response_tag_id_latched        ;
  CommandTagLine             response_tag_id_latched_S2     ;
  ResponseStatistcsInterface response_statistics_out_latched;


  logic enabled;
  logic rstn   ;

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn_in) begin
    if(~rstn_in) begin
      rstn <= 0;
    end else begin
      rstn <= rstn_in;
    end
  end

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
      response_latched.valid <= 0;
    end else begin
      if(enabled) begin
        response_latched.valid <= response.valid;
      end
    end
  end

  always_ff @(posedge clock) begin
    response_latched.tag         <= response.tag;
    response_latched.tag_parity  <= response.tag_parity;
    response_latched.response    <= response.response;
    response_latched.credits     <= response.credits;
    response_latched.cache_state <= response.cache_state;
    response_latched.cache_pos   <= response.cache_pos;
  end

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      response_latched_S2.valid <= 0;
    end else begin
      if(enabled) begin
        response_latched_S2.valid <= response_latched.valid;
      end
    end
  end

  always_ff @(posedge clock) begin
    response_latched_S2.tag         <= response_latched.tag;
    response_latched_S2.tag_parity  <= response_latched.tag_parity;
    response_latched_S2.response    <= response_latched.response;
    response_latched_S2.credits     <= response_latched.credits;
    response_latched_S2.cache_state <= response_latched.cache_state;
    response_latched_S2.cache_pos   <= response_latched.cache_pos;
    response_tag_id_latched         <= response_tag_id_in;
  end

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      response_latched_S3.valid <= 0;
    end else begin
      if(enabled) begin
        response_latched_S3.valid <= response_latched_S2.valid ;
      end
    end
  end

  always_ff @(posedge clock) begin
    response_latched_S3.tag         <= response_latched_S2.tag;
    response_latched_S3.tag_parity  <= response_latched_S2.tag_parity;
    response_latched_S3.response    <= response_latched_S2.response;
    response_latched_S3.credits     <= response_latched_S2.credits;
    response_latched_S3.cache_state <= response_latched_S2.cache_state;
    response_latched_S3.cache_pos   <= response_latched_S2.cache_pos;
    response_tag_id_latched_S2      <= response_tag_id_latched;
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
        if(response_latched_S2.valid) begin
          case(response_latched_S2.response)
            DONE : begin
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

      if(response_latched_S3.valid) begin
        case(response_latched_S3.response)
          DONE : begin
            case(response_tag_id_latched_S2.cmd_type)
              CMD_RESTART : begin
                response_statistics_out_latched.DONE_RESTART_count <= response_statistics_out_latched.DONE_RESTART_count + 1;
              end
              CMD_PREFETCH_READ : begin
                response_statistics_out_latched.DONE_PREFETCH_READ_count <= response_statistics_out_latched.DONE_PREFETCH_READ_count + 1;
                response_statistics_out_latched.PREFETCH_READ_BYTE_count <= response_statistics_out_latched.PREFETCH_READ_BYTE_count + response_tag_id_latched_S2.real_size_bytes;
              end
              CMD_PREFETCH_WRITE : begin
                response_statistics_out_latched.DONE_PREFETCH_WRITE_count <= response_statistics_out_latched.DONE_PREFETCH_WRITE_count + 1;
                response_statistics_out_latched.PREFETCH_WRITE_BYTE_count <= response_statistics_out_latched.PREFETCH_WRITE_BYTE_count + response_tag_id_latched_S2.real_size_bytes;
              end
              CMD_READ : begin
                response_statistics_out_latched.DONE_READ_count <= response_statistics_out_latched.DONE_READ_count + 1;
                response_statistics_out_latched.READ_BYTE_count <= response_statistics_out_latched.READ_BYTE_count + response_tag_id_latched_S2.real_size_bytes;
              end
              CMD_WRITE : begin
                response_statistics_out_latched.DONE_WRITE_count <= response_statistics_out_latched.DONE_WRITE_count + 1;
                response_statistics_out_latched.WRITE_BYTE_count <= response_statistics_out_latched.WRITE_BYTE_count + response_tag_id_latched_S2.real_size_bytes;
              end

            endcase
          end
        endcase
      end

    end
  end
endmodule