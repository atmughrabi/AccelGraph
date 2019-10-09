// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : credit_pkg.sv
// Create : 2019-09-26 15:20:03
// Revise : 2019-09-26 15:20:04
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

package CREDIT_PKG;

	import GLOBALS_PKG::*;
	import CAPI_PKG::*;


	typedef struct packed{
		logic                 valid_request   ;
		logic                 valid_response  ;
		logic [0:8]           response_credits;
		CommandInterfaceInput command_in      ;
	} CreditInterfaceInput;


	typedef struct packed{
		logic [0:7] credits;
	} CreditInterfaceOutput;


endpackage