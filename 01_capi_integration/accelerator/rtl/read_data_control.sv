// -----------------------------------------------------------------------------
//
//    "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : read_data_control.sv
// Create : 2019-09-30 02:22:24
// Revise : 2019-09-30 02:22:24
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;
import AFU_PKG::*;

module read_data_control (
  input  logic                       clock                  , // Clock
  input  logic                       rstn                   ,
  input  logic                       enabled_in             ,
  input  ReadDataControlInterface    buffer_in              ,
  input  CommandTagLine              data_read_tag_id_in    ,
  input  ResponseControlInterfaceOut response_control_in    ,
  output logic [0:1]                 data_read_error        ,
  output DataControlInterfaceOut     read_data_control_out_0,
  output DataControlInterfaceOut     read_data_control_out_1
);

  logic                       odd_parity               ;
  logic                       tag_parity               ;
  logic                       tag_parity_link          ;
  logic [0:7]                 data_write_parity_latched;
  logic                       write_valid_latched      ;
  logic [0:7]                 data_write_parity_link   ;
  ReadDataControlInterface    buffer_in_latched        ;
  ResponseControlInterfaceOut response_latched         ;

  logic       enable_errors    ;
  logic [0:1] detected_errors  ;
  logic       data_parity_error;
  logic       tag_parity_error ;

  logic                   read_data_0_we;
  logic [0:7]             wr_addr_0     ;
  logic [0:7]             rd_addr_0     ;
  DataControlInterfaceOut data_out_0    ;

  logic                   read_data_1_we;
  logic [0:7]             wr_addr_1     ;
  logic [0:7]             rd_addr_1     ;
  DataControlInterfaceOut data_out_1    ;


  DataControlInterfaceOut read_data_control_out_0_latched   ;
  DataControlInterfaceOut read_data_control_out_1_latched   ;
  DataControlInterfaceOut read_data_control_out_1_latched_S2;



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
      buffer_in_latched         <= 0;
      data_write_parity_latched <= 0;
      write_valid_latched       <= 0;
      response_latched          <= 0;
    end else begin
      if(enabled) begin
        buffer_in_latched         <= buffer_in;
        data_write_parity_latched <= buffer_in.write_parity;
        write_valid_latched       <= buffer_in.write_valid;
        response_latched          <= response_control_in;
      end else begin
        buffer_in_latched         <= 0;
        data_write_parity_latched <= 0;
        write_valid_latched       <= 0;
        response_latched          <= 0;
      end
    end
  end


////////////////////////////////////////////////////////////////////////////
//Read Data Buffer switch Logic LSB
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      read_data_control_out_0_latched <= 0;
    end else begin
      if(enabled && buffer_in_latched.write_valid && ~(|buffer_in_latched.write_address)) begin

        case (data_read_tag_id_in.cmd_type)
          CMD_READ : begin
            read_data_control_out_0_latched.read_data <= 1'b1;
            read_data_control_out_0_latched.wed_data  <= 1'b0;
          end
          CMD_WED : begin
            read_data_control_out_0_latched.read_data <= 1'b0;
            read_data_control_out_0_latched.wed_data  <= 1'b1;
          end
          default : begin
            read_data_control_out_0_latched.read_data <= 1'b0;
            read_data_control_out_0_latched.wed_data  <= 1'b0;
          end
        endcase

        read_data_control_out_0_latched.line.valid   <= buffer_in_latched.write_valid;
        read_data_control_out_0_latched.line.cmd     <= data_read_tag_id_in;
        read_data_control_out_0_latched.line.cmd.tag <= buffer_in_latched.write_tag;
        read_data_control_out_0_latched.line.data    <= buffer_in_latched.write_data;
        wr_addr_0                                    <= buffer_in_latched.write_tag;

      end else begin
        read_data_control_out_0_latched <= 0;
      end
    end
  end


////////////////////////////////////////////////////////////////////////////
//Read Data Buffer switch Logic MSB
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      read_data_control_out_1_latched <= 0;
    end else begin
      if(enabled && buffer_in_latched.write_valid && (|buffer_in_latched.write_address)) begin

        case (data_read_tag_id_in.cmd_type)
          CMD_READ : begin
            read_data_control_out_1_latched.read_data <= 1'b1;
            read_data_control_out_1_latched.wed_data  <= 1'b0;
          end
          CMD_WED : begin
            read_data_control_out_1_latched.read_data <= 1'b0;
            read_data_control_out_1_latched.wed_data  <= 1'b1;
          end
          default : begin
            read_data_control_out_1_latched.read_data <= 1'b0;
            read_data_control_out_1_latched.wed_data  <= 1'b0;
          end
        endcase

        read_data_control_out_1_latched.line.valid   <= buffer_in_latched.write_valid;
        read_data_control_out_1_latched.line.cmd     <= data_read_tag_id_in;
        read_data_control_out_1_latched.line.cmd.tag <= buffer_in_latched.write_tag;
        read_data_control_out_1_latched.line.data    <= buffer_in_latched.write_data;
        wr_addr_1                                    <= buffer_in_latched.write_tag;

      end else begin
        read_data_control_out_1_latched <= 0;
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
      if(enabled && buffer_in.write_valid) begin
        tag_parity <= buffer_in.write_tag_parity;
      end else begin
        tag_parity <= odd_parity;
      end
    end
  end

  parity #(.BITS(8)) write_tag_parity_instant (
    .data(buffer_in_latched.write_tag),
    .odd (odd_parity                 ),
    .par (tag_parity_link            )
  );


  dw_parity #(.DOUBLE_WORDS(8)) read_data_parity_instant (
    .data(buffer_in_latched.write_data),
    .odd (odd_parity                  ),
    .par (data_write_parity_link      )
  );


////////////////////////////////////////////////////////////////////////////
// Error Logic
////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity_error  <= 1'b0;
      data_parity_error <= 1'b0;
      detected_errors   <= 2'b00;
    end else begin
      tag_parity_error <= tag_parity_link ^ tag_parity;

      if(write_valid_latched)
        data_parity_error <= |(data_write_parity_link ^ buffer_in.write_parity);
      else
        data_parity_error <= 1'b0;

      detected_errors <= {tag_parity_error, data_parity_error};
    end
  end

  always_ff @(posedge clock) begin
    if(enable_errors) begin
      data_read_error <= detected_errors;
    end else  begin
      data_read_error <= 2'b00;
    end
  end


////////////////////////////////////////////////////////////////////////////
// Data Aggregation Logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      read_data_control_out_0            <= 0;
      read_data_control_out_1_latched_S2 <= 0;
    end else begin
      if(response_latched.response.valid && (response_latched.read_response || response_latched.wed_response ) && enabled) begin
        read_data_control_out_0            <= data_out_0;
        read_data_control_out_1_latched_S2 <= data_out_1;
      end else begin
        read_data_control_out_0            <= 0;
        read_data_control_out_1_latched_S2 <= 0;
      end
    end
  end


  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      read_data_control_out_1 <= 0;
    end else begin
      if(enabled) begin
        read_data_control_out_1 <= read_data_control_out_1_latched_S2;
      end else begin
        read_data_control_out_1 <= 0;
      end
    end
  end

////////////////////////////////////////////////////////////////////////////
// Store each cacheline half in RAM and read when response is recieved
////////////////////////////////////////////////////////////////////////////

  assign read_data_0_we = read_data_control_out_0_latched.read_data || read_data_control_out_0_latched.wed_data;
  assign read_data_1_we = read_data_control_out_1_latched.read_data || read_data_control_out_1_latched.wed_data;
  assign rd_addr_0      = response_control_in.response.cmd.tag;
  assign rd_addr_1      = response_control_in.response.cmd.tag;


  ram #(
    .WIDTH($bits(DataControlInterfaceOut)),
    .DEPTH(TAG_COUNT                     )
  ) read_data_0_instant (
    .clock   (clock                          ),
    .we      (read_data_0_we                 ),
    .wr_addr (wr_addr_0                      ),
    .data_in (read_data_control_out_0_latched),
    
    .rd_addr (rd_addr_0                      ),
    .data_out(data_out_0                     )
  );

  ram #(
    .WIDTH($bits(DataControlInterfaceOut)),
    .DEPTH(TAG_COUNT                     )
  ) read_data_1_instant (
    .clock   (clock                          ),
    .we      (read_data_1_we                 ),
    .wr_addr (wr_addr_1                      ),
    .data_in (read_data_control_out_1_latched),
    
    .rd_addr (rd_addr_1                      ),
    .data_out(data_out_1                     )
  );


endmodule