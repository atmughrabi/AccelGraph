package WED_PKG;
	
import CAPI_PKG::*;

typedef enum int unsigned {
  WED_RESET,
  WED_IDLE,
  WED_REQ,
  WED_WAITING_FOR_REQUEST,
  WED_DONE_REQ
} wed_state;

typedef struct packed{
  logic [0:63] address;
  logic [0:63] size;   // 8
  logic [0:63] stripe1;// 8
  logic [0:63] stripe2;// 8
  logic [0:63] parity; // 8 => 32 bytes command_out.address
} WED_request;

typedef struct packed{
  WED_request wed;
  logic valid;
} WEDInterfaceOutput;

endpackage