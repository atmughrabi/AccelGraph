// -----------------------------------------------------------------------------
//
//    "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : mmio.sv
// Create : 2019-09-26 15:21:36
// Revise : 2019-12-16 15:43:32
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import AFU_PKG::*;

module mmio (
  input  logic                      clock                 ,
  input  logic                      rstn_in               ,
  input  logic [0:63]               report_errors         ,
  input  cu_return_type             cu_return             ,
  input  logic [0:63]               cu_return_done        ,
  input  logic [0:63]               cu_status             ,
  input  logic [0:63]               afu_status            ,
  input  ResponseStatistcsInterface response_statistics   ,
  output afu_configure_type         afu_configure_out     ,
  output cu_configure_type          cu_configure_out      ,
  input  MMIOInterfaceInput         mmio_in               ,
  output MMIOInterfaceOutput        mmio_out_out          ,
  output logic [ 0:1]               mmio_errors_out       ,
  output logic                      report_errors_ack_out , // each register has an ack
  output logic                      cu_return_done_ack_out, // each register has an ack
  output logic                      reset_mmio_out
);


  logic               rstn              ;
  MMIOInterfaceOutput mmio_out          ;
  logic [0:1]         mmio_errors       ;
  logic               report_errors_ack ; // each register has an ack
  logic               cu_return_done_ack; // each register has an ack
  logic               reset_mmio        ;

  afu_configure_type afu_configure;
  cu_configure_type  cu_configure ;

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

  logic cfg_read_latched          ;
  logic cfg_read                  ;
  logic cfg_write_latched         ;
  logic cfg_write                 ;
  logic doubleword_latched        ;
  logic doubleword                ;
  logic report_errors_ack_latched ;
  logic cu_return_done_ack_latched;

  logic [0:23]       address               ;
  logic [0:23]       address_latched       ;
  logic [0:63]       data_in               ;
  logic [0:63]       data_in_latched       ;
  logic [0:63]       data_out              ;
  logic [0:63]       data_cfg              ;
  logic              data_out_parity       ;
  logic              data_in_parity_link   ;
  logic              data_in_parity        ;
  logic              address_parity_link   ;
  logic              address_parity        ;
  logic              data_ack              ;
  logic [0:63]       report_errors_latched ;
  cu_return_type     cu_return_latched     ;
  logic [0:63]       cu_return_done_latched;
  logic [0:63]       afu_status_latched    ;
  logic [0:63]       cu_status_latched     ;
  logic [0:63]       cu_return_mmio_ack    ;
  logic [0:63]       report_errors_mmio_ack;
  logic              mmio_in_latched_valid ;
  MMIOInterfaceInput mmio_in_latched       ;

  ResponseStatistcsInterface response_statistics_out_latched;
  // Set our AFU Descriptor values refer to page
  assign afu_desc.num_ints_per_process     = 16'h0000;
  assign afu_desc.num_of_processes         = 16'h0001;
  assign afu_desc.num_of_afu_crs           = 16'h0001;
  assign afu_desc.req_prog_model           = 16'h8010; // dedicated process
  assign afu_desc.reserved_1               = 0;
  assign afu_desc.reserved_2               = 8'h00;
  assign afu_desc.afu_cr_len               = 56'h0000_0000_0000_01;
  assign afu_desc.afu_cr_offset            = 64'h0000_0000_0000_0100;
  assign afu_desc.reserved_3               = 6'b00_0000;
  assign afu_desc.psa_per_process_required = 1'b0;
  assign afu_desc.psa_required             = 1'b1;
  assign afu_desc.psa_length               = 56'h0000_0000_0000_00;
  assign afu_desc.psa_offset               = 0;
  assign afu_desc.reserved_4               = 8'h00;
  assign afu_desc.afu_eb_len               = 56'h0000_0000_0000_00;
  assign afu_desc.afu_eb_offset            = 0;

  assign odd_parity    = 1'b1; // Odd parity
  assign enable_errors = 1'b1; // enable errors


  assign reset_mmio = 1;

  always_ff @(posedge clock or negedge rstn_in) begin
    if(~rstn_in) begin
      rstn <= 0;
    end else begin
      rstn <= rstn_in;
    end
  end

////////////////////////////////////////////////////////////////////////////
//latch the input/output from the PSL
////////////////////////////////////////////////////////////////////////////


  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      report_errors_latched           <= 0;
      cu_return_latched               <= 0;
      cu_return_done_latched          <= 0;
      afu_status_latched              <= 0;
      cu_status_latched               <= 0;
      response_statistics_out_latched <= 0;
    end else  begin
      report_errors_latched           <= report_errors;
      cu_return_done_latched          <= cu_return_done;
      cu_return_latched               <= cu_return;
      afu_status_latched              <= afu_status;
      cu_status_latched               <= cu_status;
      response_statistics_out_latched <= response_statistics;
    end
  end

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      afu_configure_out      <= 0;
      cu_configure_out       <= 0;
      mmio_out_out           <= 0;
      mmio_errors_out        <= 0;
      report_errors_ack_out  <= 0;
      cu_return_done_ack_out <= 0;
      reset_mmio_out         <= 1;
    end else  begin
      afu_configure_out      <= afu_configure;
      cu_configure_out       <= cu_configure;
      mmio_out_out           <= mmio_out;
      mmio_errors_out        <= mmio_errors;
      report_errors_ack_out  <= report_errors_ack;
      cu_return_done_ack_out <= cu_return_done_ack;
      reset_mmio_out         <= reset_mmio;
    end
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
      data_cfg <= 0;
    end else  begin
      if(cfg_read) begin
        data_cfg <= read_afu_descriptor(afu_desc, address[0:22]);
      end else begin
        data_cfg <= 0;
      end
    end
  end

// Data acknowledege signal
  always_ff @(posedge clock) begin
    data_ack <= cfg_read_latched || cfg_write_latched || mmio_read_latched || mmio_write_latched;
  end

  assign cu_return_done_ack_latched = (|cu_return_mmio_ack);
  assign report_errors_ack_latched  = (|report_errors_mmio_ack);

// Write DATA LOGIC
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      cu_configure           <= 0;
      afu_configure          <= 0;
      cu_return_mmio_ack     <= 0;
      report_errors_mmio_ack <= 0;
    end else begin
      if (mmio_write_latched) begin
        case (address_latched)
          CU_CONFIGURE : begin
            cu_configure.var1 <= data_in_latched;
          end
          CU_CONFIGURE_2 : begin
            cu_configure.var2 <= data_in_latched;
          end
          AFU_CONFIGURE : begin
            afu_configure.var1 <= data_in_latched;
          end
          AFU_CONFIGURE_2 : begin
            afu_configure.var2 <= data_in_latched;
          end
          CU_RETURN_DONE_ACK : begin
            cu_return_mmio_ack <= data_in_latched;
          end
          ERROR_REG_ACK : begin
            report_errors_mmio_ack <= data_in_latched;
          end
          default : begin
            cu_configure           <= 0;
            afu_configure          <= 0;
            cu_return_mmio_ack     <= 0;
            report_errors_mmio_ack <= 0;
          end
        endcase
      end else begin
        cu_configure           <= 0;
        afu_configure          <= 0;
        cu_return_mmio_ack     <= 0;
        report_errors_mmio_ack <= 0;
      end
    end
  end

  // Read DATA LOGIC
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      data_out <= 0;
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
          CU_RETURN : begin
            data_out <= cu_return_latched.var1;
          end
          CU_RETURN_2 : begin
            data_out <= cu_return_latched.var2;
          end
          CU_RETURN_DONE : begin
            data_out <= cu_return_done_latched;
          end
          ERROR_REG : begin
            data_out <= report_errors_latched;
          end
          AFU_STATUS : begin
            data_out <= afu_status_latched;
          end
          CU_STATUS : begin
            data_out <= cu_status_latched;
          end
          DONE_RESTART_COUNT_REG : begin
            data_out <= response_statistics_out_latched.DONE_RESTART_count;
          end
          DONE_COUNT_REG : begin
            data_out <= response_statistics_out_latched.DONE_count;
          end
          FLUSHED_COUNT_REG : begin
            data_out <= response_statistics_out_latched.FLUSHED_count;
          end
          PAGED_COUNT_REG : begin
            data_out <= response_statistics_out_latched.PAGED_count;
          end
          AERROR_COUNT_REG : begin
            data_out <= response_statistics_out_latched.AERROR_count;
          end
          DERROR_COUNT_REG : begin
            data_out <= response_statistics_out_latched.DERROR_count;
          end
          FAILED_COUNT_REG : begin
            data_out <= response_statistics_out_latched.FAILED_count;
          end
          FAULT_COUNT_REG : begin
            data_out <= response_statistics_out_latched.FAULT_count;
          end
          NRES_COUNT_REG : begin
            data_out <= response_statistics_out_latched.NRES_count;
          end
          NLOCK_COUNT_REG : begin
            data_out <= response_statistics_out_latched.NLOCK_count;
          end
          CYCLE_COUNT_REG : begin
            data_out <= response_statistics_out_latched.CYCLE_count;
          end
          DONE_READ_COUNT_REG : begin
            data_out <= response_statistics_out_latched.DONE_READ_count;
          end
          DONE_WRITE_COUNT_REG : begin
            data_out <= response_statistics_out_latched.DONE_WRITE_count;
          end
          DONE_PREFETCH_READ_COUNT_REG : begin
            data_out <= response_statistics_out_latched.DONE_PREFETCH_READ_count;
          end
          DONE_PREFETCH_WRITE_COUNT_REG : begin
            data_out <= response_statistics_out_latched.DONE_PREFETCH_WRITE_count;
          end
          READ_BYTE_COUNT_REG : begin
            data_out <= response_statistics_out_latched.READ_BYTE_count;
          end
          WRITE_BYTE_COUNT_REG : begin
            data_out <= response_statistics_out_latched.WRITE_BYTE_count;
          end
          PREFETCH_READ_BYTE_COUNT_REG : begin
            data_out <= response_statistics_out_latched.PREFETCH_READ_BYTE_count;
          end
          PREFETCH_WRITE_BYTE_COUNT_REG : begin
            data_out <= response_statistics_out_latched.PREFETCH_WRITE_BYTE_count;
          end
          default : begin
            data_out <= data_out;
          end
        endcase
      end else begin
        data_out <= data_out;
      end
    end
  end

  always_ff @(posedge clock) begin
    mmio_out.ack         <= data_ack;
    mmio_out.data        <= data_out;
    mmio_out.data_parity <= data_out_parity;
    report_errors_ack    <= report_errors_ack_latched;
    cu_return_done_ack   <= cu_return_done_ack_latched;
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
      data_in        <= 0;
    end else begin
      if(mmio_in_latched.valid && ~mmio_in_latched.read) begin
        data_in_parity <= mmio_in_latched.data_parity;
        data_in        <= mmio_in_latched.data;
      end else begin
        data_in_parity <= odd_parity;
        data_in        <= 0;
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
      mmio_in_latched_valid <= 0;
    end else begin
      mmio_in_latched_valid <= mmio_in_latched.valid;
    end
  end

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      mmio_data_error    <= 1'b0;
      mmio_address_error <= 1'b0;
      detected_errors    <= 2'b00;
    end else begin
      if(mmio_in_latched_valid) begin
        mmio_data_error    <= data_in_parity_link ^ data_in_parity;
        mmio_address_error <= address_parity_link ^ address_parity;
      end else begin
        mmio_data_error    <= 1'b0;
        mmio_address_error <= 1'b0;
      end
      detected_errors <= {mmio_data_error, mmio_address_error};
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
