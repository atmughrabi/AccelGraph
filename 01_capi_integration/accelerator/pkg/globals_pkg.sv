package GLOBALS_PKG;

////////////////////////////////////////////////////////////////////////////
// CU-Control CU Globals
////////////////////////////////////////////////////////////////////////////

// How many compute unites you want : each graph_cu contains N vertex_cu's 
////////////////////////////////////////////////////////////////////////////

	parameter NUM_GRAPH_CU_GLOBAL        = 1;
	parameter NUM_VERTEX_CU_GLOBAL       = 32;

////////////////////////////////////////////////////////////////////////////
//  AFU-Control CAPI Globals
////////////////////////////////////////////////////////////////////////////

	parameter CACHELINE_SIZE         = 128; // cacheline is 128bytes
	parameter CACHELINE_SIZE_BITS    = (CACHELINE_SIZE * 8); // cacheline is 128bytes
	parameter CACHELINE_SIZE_HF      = (CACHELINE_SIZE >> 1); // cacheline is 128bytes
	parameter CACHELINE_SIZE_BITS_HF = (CACHELINE_SIZE_HF * 8); // cacheline is 128bytes

////////////////////////////////////////////////////////////////////////////
// AFU-Control Command Tags generation (Buffer size)
////////////////////////////////////////////////////////////////////////////
	
	parameter TAG_COUNT               = 32;
	parameter INVALID_TAG             = 8'h00;

	parameter READ_CMD_BUFFER_SIZE    = 256;
	parameter WRITE_CMD_BUFFER_SIZE   = 256;
	parameter RESTART_CMD_BUFFER_SIZE = 2;
	parameter WED_CMD_BUFFER_SIZE     = 2;

	parameter READ_RSP_BUFFER_SIZE    = 256;
	parameter WRITE_RSP_BUFFER_SIZE   = 256;
	parameter RESTART_RSP_BUFFER_SIZE = 2;
	parameter WED_RSP_BUFFER_SIZE     = 2;

	parameter READ_DATA_BUFFER_SIZE    = 256;
	parameter WRITE_DATA_BUFFER_SIZE   = 256;
	parameter RESTART_DATA_BUFFER_SIZE = 2;
	parameter WED_DATA_BUFFER_SIZE     = 2;
	
////////////////////////////////////////////////////////////////////////////
// AFU-Control MMIO Registers Mapping on AFU and HOSt
////////////////////////////////////////////////////////////////////////////
	
	parameter ALGO_STATUS  = 26'h 3FFFFF8 >> 2; // algorithm status DONE/RUNNING HOST reads this address
	parameter ALGO_REQUEST = 26'h 3FFFFF0 >> 2; // algorithm status START/STOP/RESET AFU reads this address
	parameter ERROR_REG    = 26'h 3FFFFE8 >> 2; // AFU error reporting HOST reads this address

////////////////////////////////////////////////////////////////////////////
// CU-Control CU Globals
////////////////////////////////////////////////////////////////////////////

// ACCEL-GRAPH Sturctue sizes
////////////////////////////////////////////////////////////////////////////

	parameter VERTEX_SIZE                = 4; // vertex size is 4 bytes
	parameter VERTEX_SIZE_BITS           = VERTEX_SIZE * 8; // vertex size is 4 bytes
	parameter EDGE_SIZE                  = 4; // vertex size is 4 bytes
	parameter EDGE_SIZE_BITS             = EDGE_SIZE * 8; // vertex size is 4 bytes
	parameter [0:63] ADDRESS_ALIGN_MASK  = {{57{1'b1}},{7{1'b0}}}; // cacheline is 128bytes
	parameter [0:63] ADDRESS_MOD_MASK    = {{57{1'b0}},{7{1'b1}}};  // cacheline is 128bytes
	
	parameter CACHELINE_VERTEX_NUM       = (CACHELINE_SIZE >> $clog2(VERTEX_SIZE)); // number of vertices in one cacheline
	parameter CACHELINE_EDGE_NUM         = (CACHELINE_SIZE >> $clog2(EDGE_SIZE)); // number of edges in one cacheline
	parameter CACHELINE_INT_COUNTER_BITS = $clog2((VERTEX_SIZE_BITS < CACHELINE_SIZE_BITS_HF) ? (2 * CACHELINE_SIZE_BITS_HF)/VERTEX_SIZE_BITS : 2);

////////////////////////////////////////////////////////////////////////////
//  AFU/CU-Control CU IDs any compute unite that generate command must have an ID
////////////////////////////////////////////////////////////////////////////
	
	parameter  CU_ID_RANGE      = 8;
	
	parameter INVALID_ID        = {CU_ID_RANGE{1'b0}};
	parameter WED_ID            = {CU_ID_RANGE{1'b1}};
	parameter VERTEX_CONTROL_ID = (WED_ID - 1);         // This is the CU that requests and schedules graph vertices to other CUs
	
	typedef logic [0:(CU_ID_RANGE-1)] cu_id_t;
endpackage