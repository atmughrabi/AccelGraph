// -----------------------------------------------------------------------------
//
//    "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : afu_pkg.sv
// Create : 2019-09-26 15:19:52
// Revise : 2019-09-26 15:19:52
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

package AFU_PKG;

  import GLOBALS_PKG::*;
  import CAPI_PKG::*;
  import CU_PKG::*;

  typedef enum int unsigned {
    CMD_INVALID,
    CMD_READ,
    CMD_WRITE,
    CMD_PREFETCH,
    CMD_WED,
    CMD_RESTART
  } command_type;


////////////////////////////////////////////////////////////////////////////
// ERROR Control
////////////////////////////////////////////////////////////////////////////

  typedef enum int unsigned {
    ERROR_RESET,
    ERROR_IDLE,
    ERROR_MMIO_REQ,
    ERROR_WAIT_MMIO_REQ,
    ERROR_RESET_REQ,
    ERROR_RESET_PENDING
  } error_state;

  typedef enum int unsigned {
    DONE_RESET,
    DONE_IDLE,
    DONE_MMIO_REQ,
    DONE_WAIT_MMIO_REQ,
    DONE_RESET_REQ,
    DONE_RESET_PENDING
  } done_state;

////////////////////////////////////////////////////////////////////////////
// Restart Command Issue
////////////////////////////////////////////////////////////////////////////

typedef enum int unsigned {
    RESTART_RESET,
    RESTART_IDLE,
    RESTART_INIT,
    RESTART_SEND_CMD,
    RESTART_RESP_WAIT,
    RESTART_SEND_CMD_FLUSHED,
    RESTART_DONE
  } restart_state;

////////////////////////////////////////////////////////////////////////////
// Tag Buffer data
////////////////////////////////////////////////////////////////////////////

  typedef enum int unsigned {
    TAG_BUFFER_RESET,
    TAG_BUFFER_INIT,
    TAG_BUFFER_POP,
    TAG_BUFFER_READY
  } tag_buffer_state;

  typedef struct packed {
    cu_id_t                              cu_id           ; // Compute unit id generating the command for now we support four
    vertex_struct_type                   vertex_struct   ;
    command_type                         cmd_type        ; // The compute unit from the AFU SIDE will send the command type Rd/Wr/Prefetch
    logic [0:CACHELINE_INT_COUNTER_BITS] real_size       ;
    logic [0:CACHELINE_INT_COUNTER_BITS] cacheline_offest;
    logic [                         0:7] tag             ;
  } CommandTagLine;

////////////////////////////////////////////////////////////////////////////
//Command Buffer fifo line
////////////////////////////////////////////////////////////////////////////

  typedef struct packed {
    logic                  valid  ;
    CommandTagLine         cmd    ;
    afu_command_t          command; // ah_com,         // Command code
    logic [0:63]           address; // ah_cea,         // Command address
    logic [0:11]           size   ; // ah_csize,       // Command size
    trans_order_behavior_t abt    ; // ah_cabt,        // Command ABT
  } CommandBufferLine;


  typedef struct packed {
    logic full  ;
    logic alfull;
    logic valid ;
    logic empty ;
  } BufferStatus;

////////////////////////////////////////////////////////////////////////////
//Command Arbiter
////////////////////////////////////////////////////////////////////////////

  typedef struct packed {
    logic wed_request    ;
    logic write_request  ;
    logic read_request   ;
    logic restart_request;
  } CommandBufferArbiterInterfaceIn;

  typedef struct packed {
    BufferStatus wed_buffer    ;
    BufferStatus write_buffer  ;
    BufferStatus read_buffer   ;
    BufferStatus restart_buffer;
  } CommandBufferStatusInterface;


////////////////////////////////////////////////////////////////////////////
//Response Control
////////////////////////////////////////////////////////////////////////////

  typedef struct packed {
    logic          valid           ; // ha_rvalid,     // Response valid
    CommandTagLine cmd             ;
    logic [0:8]    response_credits;
    psl_response_t response        ; // ha_response,   // Response
  } ResponseBufferLine;

  typedef struct packed {
    logic              read_response   ;
    logic              write_response  ;
    logic              wed_response    ;
    logic              restart_response;
    ResponseBufferLine response        ;
  } ResponseControlInterfaceOut;

  typedef struct packed {
    BufferStatus wed_buffer    ;
    BufferStatus write_buffer  ;
    BufferStatus read_buffer   ;
    BufferStatus restart_buffer;
  } ResponseBufferStatusInterface;

////////////////////////////////////////////////////////////////////////////
//Data Control
////////////////////////////////////////////////////////////////////////////
  typedef struct packed { // one cacheline is 128bytes each sent on separate 64bytes chunks
    logic                                write_valid     ; // ha_bwvalid,     // Buffer Write valid
    logic [                         0:7] write_tag       ; // ha_bwtag,       // Buffer Write tag
    logic                                write_tag_parity; // ha_bwtagpar,    // Buffer Write tag parity
    logic [                         0:5] write_address   ; // ha_bwad,        // Buffer Write address
    logic [0:(CACHELINE_SIZE_BITS_HF-1)] write_data      ; // ha_bwdata,      // Buffer Write data
    logic [                         0:7] write_parity    ; // ha_bwpar,       // Buffer Write parity
  } ReadDataControlInterface;

  typedef struct packed { // one cacheline is 128bytes each sent on separate 64bytes chunks
    logic       read_valid     ; // ha_brvalid,     // Buffer Read valid
    logic [0:7] read_tag       ; // ha_brtag,       // Buffer Read tag
    logic       read_tag_parity; // ha_brtagpar,    // Buffer Read tag parity
    logic [0:5] read_address   ; // ha_brad,        // Buffer Read address
  } WriteDataControlInterface;

  typedef struct packed { // one cacheline is 128bytes each sent on separate 64bytes chunks
    logic                                valid;
    CommandTagLine                       cmd  ;
    logic [0:(CACHELINE_SIZE_BITS_HF-1)] data ;
  } ReadWriteDataLine;

  typedef struct packed {
    logic             read_data;
    logic             wed_data ;
    ReadWriteDataLine line     ;
  } DataControlInterfaceOut;

  typedef struct packed {
    BufferStatus buffer_0;
    BufferStatus buffer_1;
  } DataBufferStatusInterface;

// Deal with not "done" responses. Not ever expecting most response codes,
  // so afu should signal error if these occur. Never asked for reservation or
  // lock, so nres/nlock shouldn't happen. Failed is normally response to bad
  // parity or unsupported command type. Most others mean something went wrong
  // during address translation.

  function logic [0:5] cmd_response_error_type(psl_response_t reponse_code);

    logic [0:5] cmd_response_error;

    case(reponse_code)
      AERROR : begin
        cmd_response_error = 6'b000001;
      end
      DERROR : begin
        cmd_response_error = 6'b000010;
      end
      FAILED : begin
        cmd_response_error = 6'b000100;
      end
      FAULT : begin
        cmd_response_error = 6'b001000;
      end
      PAGED : begin
        cmd_response_error = 6'b010000;
      end
      FLUSHED : begin
        cmd_response_error = 6'b100000;
      end
      default : begin
        cmd_response_error = 6'b000000;
      end
    endcase

    return cmd_response_error;

  endfunction : cmd_response_error_type

endpackage