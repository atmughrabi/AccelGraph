package COMMAND_PKG;
  
import CAPI_PKG::*;

////////////////////////////////////////////////////////////////////////////
//Command Buffer fifo line
////////////////////////////////////////////////////////////////////////////

typedef struct packed {
	logic valid;
    logic [0:7] tag;            // ah_ctag,        // Command tag
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
} CommandBufferStatusInterfaceOut;


////////////////////////////////////////////////////////////////////////////
//Command Response Buffer line
////////////////////////////////////////////////////////////////////////////

typedef struct packed {
    logic valid;              // ha_rvalid,     // Response valid
    logic [0:7] tag;          // ha_rtag,       // Response tag
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
} ResponseBufferStatusInterfaceOut;

// Deal with not "done" responses. Not ever expecting most response codes,
  // so afu should signal error if these occur. Never asked for reservation or
  // lock, so nres/nlock shouldn't happen. Failed is normally response to bad
  // parity or unsupported command type. Most others mean something went wrong
  // during address translation.

 function logic [0:5] cmd_response_error_type(psl_response_t reponse_code);

 	logic [0:5] cmd_response_error;

    case(reponse_code)
      AERROR: begin //Offset 0x00
        cmd_response_error = 6'b000001;
      end
      DERROR: begin //Offset 0x20
        cmd_response_error = 6'b000010;
      end
      FAILED: begin //Offset 0x28
        cmd_response_error = 6'b000100;
      end
      FAULT: begin //Offset 0x30
      	cmd_response_error = 6'b001000;
      end
      default: begin
       	cmd_response_error = 6'b000000;
      end
    endcase

    return cmd_response_error;

  endfunction : cmd_response_error_type

endpackage