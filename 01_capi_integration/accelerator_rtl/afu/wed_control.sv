// -----------------------------------------------------------------------------
//
//    "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : wed_control.sv
// Create : 2019-09-26 15:25:16
// Revise : 2019-09-26 15:25:16
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module wed_control (
  input  logic              clock                ,
  input  logic              enabled_in           ,
  input  logic              rstn_in              ,
  input  logic [0:63]       wed_address          ,
  input  ReadWriteDataLine  wed_data_0_in        ,
  input  ReadWriteDataLine  wed_data_1_in        ,
  input  ResponseBufferLine wed_response_in      ,
  input  BufferStatus       command_buffer_status,
  output CommandBufferLine  command_out          ,
  output WEDInterface       wed_request_out
);

  wed_state                         current_state, next_state;
  logic [0:(CACHELINE_SIZE_BITS-1)] wed_cacheline128;
  logic                             enabled         ;
  logic                             rstn            ;
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
//latch the inputs from the PSL
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn)
      current_state <= WED_RESET;
    else
      current_state <= next_state;
  end // always_ff @(posedge clock)

  always_comb begin
    next_state = current_state;
    case (current_state)
      WED_RESET : begin
        next_state = WED_IDLE;
      end // WED_RESET
      WED_IDLE : begin
        if(enabled && ~wed_request_out.valid && ~command_buffer_status.alfull)
          next_state = WED_REQ;
        else
          next_state = WED_IDLE;
      end // WED_IDLE
      WED_REQ : begin
        next_state = WED_WAITING_FOR_REQUEST;
      end // WED_REQ
      WED_WAITING_FOR_REQUEST : begin
        if (wed_response_in.valid && wed_response_in.payload.cmd.cu_id_x == WED_ID && wed_response_in.payload.response == DONE) begin
          next_state = WED_DONE_REQ;
        end
        else
          next_state = WED_WAITING_FOR_REQUEST;
      end
      WED_DONE_REQ : begin
        // if (command_out.tag != DONE_WRITE) begin
        next_state = WED_IDLE;
        // end
      end // WED_DONE_REQ
    endcase
  end // always_comb

  always_ff @(posedge clock) begin
    case (current_state)
      WED_RESET : begin
        command_out.valid     <= 0;
        wed_cacheline128      <= 0;
        wed_request_out.valid <= 0;
      end // WED_RESET:
      WED_IDLE : begin
        command_out.valid <= 1'b0;
      end // WED_IDLE:
      WED_REQ : begin
        command_out.valid           <= 1'b1;
        command_out.payload.size    <= 12'h080;
        command_out.payload.command <= READ_CL_NA;
        command_out.payload.address <= wed_address;

        command_out.payload.cmd.cu_id_x          <= WED_ID;
        command_out.payload.cmd.cu_id_y          <= WED_ID;
        command_out.payload.cmd.cmd_type         <= CMD_WED;
        command_out.payload.cmd.array_struct     <= STRUCT_INVALID;
        command_out.payload.cmd.real_size        <= 32;
        command_out.payload.cmd.real_size_bytes  <= 128;
        command_out.payload.cmd.cacheline_offest <= 0;
        command_out.payload.cmd.address_offest   <= 0;
        command_out.payload.cmd.tag              <= 0;
        command_out.payload.cmd.abt              <= STRICT;

        wed_request_out.payload.address <= wed_address;
      end // WED_REQ
      WED_WAITING_FOR_REQUEST : begin
        command_out.valid <= 0;
        if (wed_data_0_in.payload.cmd.cu_id_x == WED_ID) begin
          wed_cacheline128[0:CACHELINE_SIZE_BITS_HF-1] <= wed_data_0_in.payload.data;
        end
        if (wed_data_1_in.payload.cmd.cu_id_x == WED_ID) begin
          wed_cacheline128[CACHELINE_SIZE_BITS_HF:CACHELINE_SIZE_BITS-1] <= wed_data_1_in.payload.data;
        end
      end // WED_WAITING_FOR_REQUEST
      WED_DONE_REQ : begin
        wed_request_out.valid       <= 1'b1;
        wed_request_out.payload.wed <= map_DataArrays_to_WED(wed_cacheline128);
      end // WED_WAITING_FOR_REQUEST
    endcase // next_state
  end // always_ff @(posedge clock)

endmodule