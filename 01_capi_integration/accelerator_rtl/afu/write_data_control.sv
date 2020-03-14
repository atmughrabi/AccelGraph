// -----------------------------------------------------------------------------
//
//    "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : write_data_control.sv
// Create : 2019-09-26 15:25:21
// Revise : 2019-09-26 15:25:21
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import AFU_PKG::*;

module write_data_control (
  input  logic                     clock           , // Clock
  input  logic                     rstn_in         ,
  input  logic                     enabled_in      ,
  input  WriteDataControlInterface buffer_in       ,
  input  logic [0:7]               command_tag_in  ,
  input  ReadWriteDataLine         write_data_0_in ,
  input  ReadWriteDataLine         write_data_1_in ,
  output logic                     data_write_error,
  output BufferInterfaceOutput     buffer_out
);

  logic odd_parity     ;
  logic tag_parity     ;
  logic tag_parity_link;

  logic             enable_errors           ;
  logic             detected_errors         ;
  logic             tag_parity_error        ;
  logic [0:3]       read_latency            ;
  ReadWriteDataLine write_data_0_in_latched ;
  ReadWriteDataLine write_data_1_in_latched ;
  logic [0:7]       command_tag_0_in_latched;
  logic [0:7]       command_tag_1_in_latched;

  logic [0:7] buffer_out_read_parity;

  ReadWriteDataLine                    write_data_0_out;
  ReadWriteDataLine                    write_data_1_out;
  logic                                enabled         ;
  logic [0:(CACHELINE_SIZE_BITS_HF-1)] write_data      ;

  logic       read_valid_data ; // ha_brvalid,     // Buffer Read valid
  logic       read_valid_error; // ha_brvalid,     // Buffer Read valid
  logic [0:7] read_tag        ; // ha_brtag,       // Buffer Read tag
  logic [0:5] read_address    ; // ha_brad,        // Buffer Read address
  logic       rstn            ;

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

  assign odd_parity    = 1'b1; // Odd parity
  assign enable_errors = 1'b1; // enable errors

  
  always_ff @(posedge clock or negedge rstn_in) begin
    if(~rstn_in) begin
      rstn <= 0;
    end else begin
      rstn <= rstn_in;
    end
  end

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      write_data_0_in_latched.valid <= 0;
      write_data_1_in_latched.valid <= 0;
      command_tag_0_in_latched      <= 0;
      command_tag_1_in_latched      <= 0;
    end else begin
      if(enabled) begin
        write_data_0_in_latched.valid <= write_data_0_in.valid;
        write_data_1_in_latched.valid <= write_data_1_in.valid;
        command_tag_0_in_latched      <= command_tag_in;
        command_tag_1_in_latched      <= command_tag_in;
      end
    end
  end

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      write_data_0_in_latched.payload <= ~0;
      write_data_1_in_latched.payload <= ~0;
    end else begin
      write_data_0_in_latched.payload <= write_data_0_in.payload;
      write_data_1_in_latched.payload <= write_data_1_in.payload;
    end
  end

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
//Read Buffer data tag requests
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      read_valid_data  <= 0;
      read_valid_error <= 0;
      read_tag         <= 0;
      read_address     <= 0;
    end else begin
      if(enabled) begin
        read_valid_data  <= buffer_in.read_valid;
        read_valid_error <= buffer_in.read_valid;
        read_tag         <= buffer_in.read_tag;
        read_address     <= buffer_in.read_address;
      end
    end
  end

////////////////////////////////////////////////////////////////////////////
//Read Buffer out data parity check
////////////////////////////////////////////////////////////////////////////

  // dw_parity #(.DOUBLE_WORDS(8)) write_data_parity_instant (
  //   .data(buffer_out.read_data  ),
  //   .odd (odd_parity            ),
  //   .par (buffer_out.read_parity)
  // );

  dw_parity #(.DOUBLE_WORDS(8)) write_data_parity_instant (
    .data(write_data            ),
    .odd (odd_parity            ),
    .par (buffer_out_read_parity)
  );

////////////////////////////////////////////////////////////////////////////
//partity check Logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity <= odd_parity;
    end else begin
      if(enabled) begin
        tag_parity <= buffer_in.read_tag_parity;
      end
    end
  end

  parity #(.BITS(8)) write_tag_parity_instant (
    .data(read_tag       ),
    .odd (odd_parity     ),
    .par (tag_parity_link)
  );

////////////////////////////////////////////////////////////////////////////
//Ram Data each hold half cache line
////////////////////////////////////////////////////////////////////////////
// latency 4 cycles
  assign read_latency = 4'h3;

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn)
      write_data <= ~0;
    else begin
      if(read_valid_data) begin
        case (read_address)
          6'h00 : begin
            write_data <= write_data_0_out.payload.data;
          end
          6'h01 : begin
            write_data <= write_data_1_out.payload.data;
          end
        endcase
      end
    end
  end

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      buffer_out.read_latency <= read_latency;
      buffer_out.read_parity  <= odd_parity;
      buffer_out.read_data    <= ~0;
    end else begin
      buffer_out.read_latency <= read_latency;
      buffer_out.read_parity  <= buffer_out_read_parity;
      buffer_out.read_data    <= write_data;
    end
  end

  ram #(
    .WIDTH($bits(ReadWriteDataLine)),
    .DEPTH(256                     )
  ) write_data_0_ram_instant (
    .clock   (clock                        ),
    .we      (write_data_0_in_latched.valid),
    .wr_addr (command_tag_0_in_latched     ),
    .data_in (write_data_0_in_latched      ),
    
    .rd_addr (buffer_in.read_tag           ),
    .data_out(write_data_0_out             )
  );


  ram #(
    .WIDTH($bits(ReadWriteDataLine)),
    .DEPTH(256                     )
  ) write_data_1_ram_instant (
    .clock   (clock                        ),
    .we      (write_data_1_in_latched.valid),
    .wr_addr (command_tag_1_in_latched     ),
    .data_in (write_data_1_in_latched      ),
    
    .rd_addr (buffer_in.read_tag           ),
    .data_out(write_data_1_out             )
  );

////////////////////////////////////////////////////////////////////////////
// Error Logic
////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity_error <= 1'b0;
      detected_errors  <= 1'b0;
    end else begin

      if(read_valid_error)
        tag_parity_error <= tag_parity_link ^ tag_parity;
      else
        tag_parity_error <= 1'b0;

      detected_errors <= {tag_parity_error};
    end
  end

  always_ff @(posedge clock) begin
    if(enable_errors) begin
      data_write_error <= detected_errors;
    end else  begin
      data_write_error <= 1'b0;
    end
  end


endmodule