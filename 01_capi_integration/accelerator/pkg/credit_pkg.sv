package CREDIT_PKG;

	import GLOBALS_PKG::*;
	import CAPI_PKG::*;


	typedef struct packed{
		logic valid_request;
		logic valid_response;
		logic [0:8] response_credits;
		CommandInterfaceInput command_in;
	} CreditInterfaceInput;


	typedef struct packed{
		logic [0:7] credits;
	} CreditInterfaceOutput;


endpackage