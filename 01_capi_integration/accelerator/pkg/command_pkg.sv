package COMMAND_PKG;
  
import CAPI_PKG::*;

////////////////////////////////////////////////////////////////////////////
//Command Buffer fifo line
////////////////////////////////////////////////////////////////////////////

typedef struct packed {
	logic valid;
    request_tag tag;            // ah_ctag,        // Command tag
    afu_command_t command;      // ah_com,         // Command code
    logic [0:63] address;       // ah_cea,         // Command address
    logic [0:11] size;          // ah_csize,       // Command size
  } CommandBufferLine;

typedef struct packed {
    logic full;
    logic alfull;
    logic valid;
    logic empty;
} CommandBufferStatus;

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
    CommandBufferStatus wed_buffer;
    CommandBufferStatus write_buffer;
    CommandBufferStatus read_buffer;
    CommandBufferStatus restart_buffer;
} CommandBufferStatusInterfaceOut;


////////////////////////////////////////////////////////////////////////////
//Command Response Buffer line
////////////////////////////////////////////////////////////////////////////

endpackage