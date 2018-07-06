

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
  longint unsigned size;
  pointer_t stripe1;
  pointer_t stripe2;
  pointer_t parity;
} parity_request;

typedef enum logic [0:7] {
  WED_TAG,
  STRIPE1_READ,
  STRIPE2_READ,
  PARITY_WRITE,
  DONE_WRITE
} request_tag;


endpackage