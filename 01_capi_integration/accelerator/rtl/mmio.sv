// -----------------------------------------------------------------------------
//
//    "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : mmio.sv
// Create : 2019-09-26 15:21:36
// Revise : 2019-09-26 15:21:36
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import GLOBALS_PKG::*;
import CAPI_PKG::*;

module mmio (
  input  logic               clock                      ,
  input  logic               rstn                       ,
  input  logic [0:63]        report_errors              ,
  input  logic [0:63]        algorithm_status           ,
  output logic [0:63]        algorithm_requests         ,
  input  MMIOInterfaceInput  mmio_in                    ,
  output MMIOInterfaceOutput mmio_out                   ,
  output logic [ 0:1]        mmio_errors                ,
  output logic               report_errors_ack          , // each register has an ack
  output logic               report_algorithm_status_ack, // each register has an ack
  output logic               reset_mmio
);

  AFUDescriptor afu_desc  ;
  logic         odd_parity;

  logic       enable_errors     ;
  logic [0:1] detected_errors   ;
  logic       mmio_data_error   ;
  logic       mmio_address_error;



  logic mmio_read_latched ;
  logic mmio_read         ;
  logic mmio_write_latched;
  logic mmio_write        ;

  logic cfg_read_latched                   ;
  logic cfg_read                           ;
  logic cfg_write_latched                  ;
  logic cfg_write                          ;
  logic doubleword_latched                 ;
  logic doubleword                         ;
  logic report_errors_ack_latched          ;
  logic report_algorithm_status_ack_latched;

  logic [0:23] address                 ;
  logic [0:23] address_latched         ;
  logic [0:63] data_in                 ;
  logic [0:63] data_in_latched         ;
  logic [0:63] data_out                ;
  logic [0:63] data_cfg                ;
  logic        data_out_parity         ;
  logic        data_in_parity_link     ;
  logic        data_in_parity          ;
  logic        address_parity_link     ;
  logic        address_parity          ;
  logic        data_ack                ;
  logic [0:63] report_errors_latched   ;
  logic [0:63] algorithm_status_latched;

  MMIOInterfaceInput mmio_in_latched;

  // Set our AFU Descriptor values refer to page
  assign afu_desc.num_ints_per_process     = 16'h0000;
  assign afu_desc.num_of_processes         = 16'h0001;
  assign afu_desc.num_of_afu_crs           = 16'h0001;
  assign afu_desc.req_prog_model           = 16'h8010; // dedicated process
  assign afu_desc.reserved_1               = 64'h0000_0000_0000_0000;
  assign afu_desc.reserved_2               = 8'h00;
  assign afu_desc.afu_cr_len               = 56'h0000_0000_0000_01;
  assign afu_desc.afu_cr_offset            = 64'h0000_0000_0000_0100;
  assign afu_desc.reserved_3               = 6'b00_0000;
  assign afu_desc.psa_per_process_required = 1'b0;
  assign afu_desc.psa_required             = 1'b1;
  assign afu_desc.psa_length               = 56'h0000_0000_0000_00;
  assign afu_desc.psa_offset               = 64'h0000_0000_0000_0000;
  assign afu_desc.reserved_4               = 8'h00;
  assign afu_desc.afu_eb_len               = 56'h0000_0000_0000_00;
  assign afu_desc.afu_eb_offset            = 64'h0000_0000_0000_0000;

  assign odd_parity    = 1'b1; // Odd parity
  assign enable_errors = 1'b1; // enable errors


  assign reset_mmio = 1;

////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL
////////////////////////////////////////////////////////////////////////////


  always_ff @(posedge clock) begin
    report_errors_latched    <= report_errors;
    algorithm_status_latched <= algorithm_status;
  end


  always_ff @(posedge clock) begin
    mmio_in_latched <= mmio_in;
  end

// MMIO Config Logic
  always_ff @(posedge clock) begin
    cfg_read  <= mmio_in_latched.valid && mmio_in_latched.cfg && mmio_in_latched.read;
    cfg_write <= mmio_in_latched.valid && mmio_in_latched.cfg && ~mmio_in_latched.read;
  end

  always_ff @(posedge clock) begin
    cfg_read_latched  <= cfg_read;
    cfg_write_latched <= cfg_write;
  end

// MMIO READ/WRITE Logic
  always_ff @(posedge clock) begin
    mmio_read  <= mmio_in_latched.valid && ~mmio_in_latched.cfg && mmio_in_latched.read;
    mmio_write <= mmio_in_latched.valid && ~mmio_in_latched.cfg && ~mmio_in_latched.read;
  end

  always_ff @(posedge clock) begin
    mmio_read_latched  <= mmio_read;
    mmio_write_latched <= mmio_write;
  end

// MMIO READ/WRITE double or single word
  always_ff @(posedge clock) begin
    if(mmio_in_latched.valid)
      doubleword <= mmio_in_latched.doubleword;
  end

  always_ff @(posedge clock) begin
    doubleword_latched <= doubleword;
  end

// data out to host logic
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      data_cfg <= 64'h0000_0000_0000_0000;
    end else  begin
      if(cfg_read) begin
        data_cfg <= read_afu_descriptor(afu_desc, address[0:22]);
      end else begin
        data_cfg <= 64'h0000_0000_0000_0000;
      end
    end
  end

// Data acknowledege signal
  always_ff @(posedge clock) begin
    data_ack <= cfg_read_latched || cfg_write_latched || mmio_read_latched || mmio_write_latched;
  end

// Write DATA LOGIC
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      algorithm_requests <= 64'h0000_0000_0000_0000;
    end else begin
      if (mmio_write_latched) begin
        case (address_latched)
          ALGO_REQUEST : begin
            algorithm_requests <= data_in_latched;
          end
          default : begin
            algorithm_requests <= 64'h0000_0000_0000_0000;
          end
        endcase
      end else begin
        algorithm_requests <= 64'h0000_0000_0000_0000;
      end
    end
  end

  // Read DATA LOGIC
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      data_out                            <= 64'h0000_0000_0000_0000;
      report_errors_ack_latched           <= 1'b0;
      report_algorithm_status_ack_latched <= 1'b0;
    end else begin
      if(cfg_read_latched) begin
        if(doubleword_latched) begin
          data_out <= data_cfg;
        end else if (address_latched[23]) begin
          data_out <= {data_cfg[32:63], data_cfg[32:63]};
        end else begin
          data_out <= {data_cfg[0:31], data_cfg[0:31]};
        end
      end else if (mmio_read_latched) begin
        case (address_latched)
          ALGO_STATUS : begin
            data_out                            <= algorithm_status_latched;
            report_algorithm_status_ack_latched <= (|algorithm_status_latched);
          end
          ERROR_REG : begin
            data_out                  <= report_errors_latched;
            report_errors_ack_latched <= (|report_errors_latched);
          end
          default : begin
            data_out                            <= data_out;
            report_errors_ack_latched           <= 1'b0;
            report_algorithm_status_ack_latched <= 1'b0;
          end
        endcase
      end else begin
        data_out                            <= data_out;
        report_errors_ack_latched           <= 1'b0;
        report_algorithm_status_ack_latched <= 1'b0;
      end
    end
  end

  always_ff @(posedge clock) begin
    mmio_out.ack                <= data_ack;
    mmio_out.data               <= data_out;
    mmio_out.data_parity        <= data_out_parity;
    report_errors_ack           <= report_errors_ack_latched;
    report_algorithm_status_ack <= report_algorithm_status_ack_latched;
  end

  parity #(.BITS(64)) mmio_data_out_parity_instant (
    .data(data_out       ),
    .odd (odd_parity     ),
    .par (data_out_parity)
  );

////////////////////////////////////////////////////////////////////////////
//partity check Logic
////////////////////////////////////////////////////////////////////////////
  // Parity check
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      address_parity <= odd_parity;
      address        <= 24'h00_0000;
    end else begin
      if(mmio_in_latched.valid) begin
        address_parity <= mmio_in_latched.address_parity;
        address        <= mmio_in_latched.address;
      end else begin
        address_parity <= odd_parity;
        address        <= 24'h00_0000;
      end
    end
  end

  always_ff @(posedge clock) begin
    address_latched <= address;
  end

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      data_in_parity <= odd_parity;
      data_in        <= 64'h0000_0000_0000_0000;
    end else begin
      if(mmio_in_latched.valid && ~mmio_in_latched.read) begin
        data_in_parity <= mmio_in_latched.data_parity;
        data_in        <= mmio_in_latched.data;
      end else begin
        data_in_parity <= odd_parity;
        data_in        <= 64'h0000_0000_0000_0000;
      end
    end
  end

  always_ff @(posedge clock) begin
    data_in_latched <= data_in;
  end

  parity #(.BITS(64)) mmio_data_in_parity_instant (
    .data(data_in            ),
    .odd (odd_parity         ),
    .par (data_in_parity_link)
  );

  parity #(.BITS(24)) mmio_address_parity_instant (
    .data(address            ),
    .odd (odd_parity         ),
    .par (address_parity_link)
  );

////////////////////////////////////////////////////////////////////////////
// Error Logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      mmio_data_error    <= 1'b0;
      mmio_address_error <= 1'b0;
      detected_errors    <= 2'b00;
    end else begin
      mmio_data_error    <= data_in_parity_link ^ data_in_parity;
      mmio_address_error <= address_parity_link ^ address_parity;
      detected_errors    <= {mmio_data_error, mmio_address_error};
    end
  end

  always_ff @(posedge clock) begin
    if(enable_errors) begin
      mmio_errors <= detected_errors;
    end else  begin
      mmio_errors <= 2'b00;
    end
  end


endmodule
