package CU_PKG;
	
import CAPI_PKG::*;

typedef enum {
  AFU_IDLE,
  WED_REQ,
  WAITING_FOR_REQUEST,
  REQUEST_STRIPES1,
  REQUEST_STRIPES2,
  WAITING_FOR_STRIPES,
  WRITE_REQ,
  WRITE_DATA,
  DONE_REQ,
  FINAL,
  XX
} state;

typedef struct {
  logic [0:63] size;
  logic [0:63] stripe1;
  logic [0:63] stripe2;
  logic [0:63] parity;
} parity_request;

typedef enum logic [0:7] {
  WED_TAG,
  STRIPE1_READ,
  STRIPE2_READ,
  PARITY_WRITE,
  DONE_WRITE
} request_tag;


endpackage