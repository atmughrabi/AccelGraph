package AFU_PKG;

  import CAPI_PKG::*;
  import CU_PKG::*;

  typedef enum logic [0:2]{
    CMD_INVALID,
    CMD_READ,
    CMD_WRITE,
    CMD_PREFETCH,
    CMD_WED,
    CMD_RESTART
  } command_type;

  typedef logic [0:8] cu_id_t;

////////////////////////////////////////////////////////////////////////////
// Tag Buffer data
////////////////////////////////////////////////////////////////////////////

  typedef struct packed {
    cu_id_t cu_id;      // Compute unit id generating the command for now we support four
    vertex_struct vertex_struct;
    command_type cmd_type;    // The compute unit from the AFU SIDE will send the command type Rd/Wr/Prefetch
  } CommandTagLine;

////////////////////////////////////////////////////////////////////////////
//Command Buffer fifo line
////////////////////////////////////////////////////////////////////////////

  typedef struct packed {
    logic valid;
    CommandTagLine cmd;
    afu_command_t command;      // ah_com,         // Command code
    logic [0:63] address;       // ah_cea,         // Command address
    logic [0:11] size;          // ah_csize,       // Command size
  } CommandBufferLine;


  typedef struct packed {
    logic full;
    logic alfull;
    logic valid;
    logic empty;
  } BufferStatus;

////////////////////////////////////////////////////////////////////////////
//Command Arbiter
////////////////////////////////////////////////////////////////////////////

  typedef struct packed {
    logic wed_request;
    logic write_request;
    logic read_request;
    logic restart_request;
  } CommandBufferArbiterInterfaceIn;

  typedef struct packed {
    logic valid;
    logic wed_ready;
    logic write_ready;
    logic read_ready;
    logic restart_ready;
    CommandBufferLine command_buffer_out;
  } CommandBufferArbiterInterfaceOut;

  typedef struct packed {
    BufferStatus wed_buffer;
    BufferStatus write_buffer;
    BufferStatus read_buffer;
    BufferStatus restart_buffer;
  } CommandBufferStatusInterface;


////////////////////////////////////////////////////////////////////////////
//Response Control
////////////////////////////////////////////////////////////////////////////

  typedef struct packed {
    logic valid;              // ha_rvalid,     // Response valid
    CommandTagLine cmd;
    psl_response_t response;  // ha_response,   // Response
  } ResponseBufferLine;

  typedef struct packed {
    logic read_response;
    logic write_response;
    logic wed_response;
    logic restart_response;
    ResponseBufferLine response;
  } ResponseControlInterfaceOut;

  typedef struct packed {
    BufferStatus wed_buffer;
    BufferStatus write_buffer;
    BufferStatus read_buffer;
    BufferStatus restart_buffer;
  } ResponseBufferStatusInterface;

////////////////////////////////////////////////////////////////////////////
//Data Control
////////////////////////////////////////////////////////////////////////////
  typedef struct packed { // one cacheline is 128bytes each sent on separate 64bytes chunks
    CommandTagLine cmd;
    logic [0:511] data;
  } ReadWriteDataLine;

  typedef struct packed {
    logic read_data;
    logic wed_data;
    ReadWriteDataLine line;
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
      AERROR: begin
        cmd_response_error = 6'b000001;
      end
      DERROR: begin
        cmd_response_error = 6'b000010;
      end
      FAILED: begin
        cmd_response_error = 6'b000100;
      end
      FAULT: begin
        cmd_response_error = 6'b001000;
      end
      default: begin
        cmd_response_error = 6'b000000;
      end
    endcase

    return cmd_response_error;

  endfunction : cmd_response_error_type

endpackage