package COMMAND_PKG;
  
import CAPI_PKG::*;

typedef struct packed {
	logic valid;
    request_tag tag;            // ah_ctag,        // Command tag
    afu_command_t command;      // ah_com,         // Command code
    logic [0:63] address;       // ah_cea,         // Command address
    logic [0:11] size;          // ah_csize,       // Command size
  } CommandBufferLine;

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



endpackage