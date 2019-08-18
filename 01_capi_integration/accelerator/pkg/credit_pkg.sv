package CREDIT_PKG;
  
import CAPI_PKG::*;

typedef struct packed{
  logic valid;
  logic wed_request;
  logic write_request;
  logic read_request;
  logic restart_request;
  logic [0:8] response_credits;  
  CommandInterfaceInput command_in;
} CreditInterfaceInput;


typedef struct packed{
  logic [0:7] credits;
} CreditInterfaceOutput;


endpackage