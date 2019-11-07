// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : globals_pkg.sv
// Create : 2019-09-26 15:20:15
// Revise : 2019-11-07 16:06:25
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

package GLOBALS_PKG;

////////////////////////////////////////////////////////////////////////////
// CU-Control CU Globals
////////////////////////////////////////////////////////////////////////////

// How many compute unites you want : each 1 graph_cu contains N vertex_cu's
// TOTAL CUS = NUM_GRAPH_CU_GLOBAL X NUM_VERTEX_CU_GLOBAL
////////////////////////////////////////////////////////////////////////////

	parameter NUM_GRAPH_CU_GLOBAL  = 1;
	parameter NUM_VERTEX_CU_GLOBAL = 8;

	parameter CU_VERTEX_JOB_BUFFER_SIZE = 256;
	parameter CU_EDGE_JOB_BUFFER_SIZE   = 256;

////////////////////////////////////////////////////////////////////////////
//   CU-Control/AFU-Control CAPI Globals
////////////////////////////////////////////////////////////////////////////

	parameter CACHELINE_SIZE         = 128                    ; // cacheline is 128bytes
	parameter CACHELINE_SIZE_BITS    = (CACHELINE_SIZE * 8)   ; // cacheline is 128bytes
	parameter CACHELINE_SIZE_HF      = (CACHELINE_SIZE >> 1)  ; // cacheline is 128bytes
	parameter CACHELINE_SIZE_BITS_HF = (CACHELINE_SIZE_HF * 8); // cacheline is 128bytes

	parameter WORD             = 4              ;
	parameter WORD_BITS        = WORD * 8       ;
	parameter WORD_DOUBLE      = WORD * 2       ;
	parameter WORD_DOUBLE_BITS = WORD_DOUBLE * 8;

////////////////////////////////////////////////////////////////////////////
// AFU-Control Command Tags generation (Buffer size)
////////////////////////////////////////////////////////////////////////////

	parameter TAG_COUNT   = 256  ;
	parameter INVALID_TAG = 8'h00;

	parameter READ_CMD_BUFFER_SIZE    = 256;
	parameter WRITE_CMD_BUFFER_SIZE   = 256;
	parameter RESTART_CMD_BUFFER_SIZE = 4  ;
	parameter WED_CMD_BUFFER_SIZE     = 4  ;

	parameter READ_RSP_BUFFER_SIZE    = 256;
	parameter WRITE_RSP_BUFFER_SIZE   = 256;
	parameter RESTART_RSP_BUFFER_SIZE = 4  ;
	parameter WED_RSP_BUFFER_SIZE     = 4  ;

	parameter READ_DATA_BUFFER_SIZE    = 256;
	parameter WRITE_DATA_BUFFER_SIZE   = 256;
	parameter RESTART_DATA_BUFFER_SIZE = 4  ;
	parameter WED_DATA_BUFFER_SIZE     = 4  ;

////////////////////////////////////////////////////////////////////////////
// AFU-Control MMIO Registers Mapping on AFU and HOSt
////////////////////////////////////////////////////////////////////////////

	parameter ALGO_STATUS  = 26'h 3FFFFF8 >> 2; // algorithm status DONE/RUNNING HOST reads this address
	parameter ALGO_REQUEST = 26'h 3FFFFF0 >> 2; // algorithm status START/STOP/RESET AFU reads this address
	parameter ERROR_REG    = 26'h 3FFFFE8 >> 2; // AFU error reporting HOST reads this address
	parameter AFU_STATUS   = 26'h 3FFFFE0 >> 2; // AFU status job running
	parameter ALGO_RUNNING = 26'h 3FFFFD8 >> 2; // KERNEL RETURN

////////////////////////////////////////////////////////////////////////////
// CU-Control CU Globals
////////////////////////////////////////////////////////////////////////////

// ACCEL-GRAPH Sturctue sizes
////////////////////////////////////////////////////////////////////////////

	parameter VERTEX_SIZE          = 4                  ; // vertex size is n bytes
	parameter VERTEX_SIZE_BITS     = VERTEX_SIZE * 8    ; // vertex size is n*8 Bits
	parameter EDGE_SIZE            = 4                  ; // edge size is n bytes
	parameter EDGE_SIZE_BITS       = EDGE_SIZE * 8      ; // edge size is n*8 Bits
	parameter DATA_SIZE_READ       = 8                  ; // edge data size is n bytes
	parameter DATA_SIZE_READ_BITS  = DATA_SIZE_READ * 8 ; // edge data size is n*8 Bits
	parameter DATA_SIZE_WRITE      = 8                  ; // edge data size is n bytes
	parameter DATA_SIZE_WRITE_BITS = DATA_SIZE_WRITE * 8; // edge data size is n*8 Bits

	parameter [0:63] ADDRESS_EDGE_ALIGN_MASK = {{57{1'b1}},{7{1'b0}}};
	parameter [0:63] ADDRESS_EDGE_MOD_MASK   = {{57{1'b0}},{7{1'b1}}};

	parameter [0:63] ADDRESS_DATA_READ_ALIGN_MASK = {{57{1'b1}},{7{1'b0}}};
	parameter [0:63] ADDRESS_DATA_READ_MOD_MASK   = {{57{1'b0}},{7{1'b1}}};

	parameter [0:63] ADDRESS_DATA_WRITE_ALIGN_MASK = {{57{1'b1}},{7{1'b0}}};
	parameter [0:63] ADDRESS_DATA_WRITE_MOD_MASK   = {{57{1'b0}},{7{1'b1}}};

	parameter CACHELINE_VERTEX_NUM       = (CACHELINE_SIZE >> $clog2(VERTEX_SIZE))                                                                ; // number of vertices in one cacheline
	parameter CACHELINE_EDGE_NUM         = (CACHELINE_SIZE >> $clog2(EDGE_SIZE))                                                                  ; // number of edges in one cacheline
	parameter CACHELINE_INT_COUNTER_BITS = $clog2((VERTEX_SIZE_BITS < CACHELINE_SIZE_BITS_HF) ? (2 * CACHELINE_SIZE_BITS_HF)/VERTEX_SIZE_BITS : 2);

////////////////////////////////////////////////////////////////////////////
//  AFU/CU-Control CU IDs any compute unite that generate command must have an ID
////////////////////////////////////////////////////////////////////////////

	parameter CU_ID_RANGE = 8;

	parameter INVALID_ID                 = {CU_ID_RANGE{1'b0}}             ;
	parameter WED_ID                     = {CU_ID_RANGE{1'b1}}             ;
	parameter RESTART_ID                 = (WED_ID - 1)                    ;
	parameter VERTEX_CONTROL_ID          = (RESTART_ID - 1)                ;
	parameter EDGE_DATA_READ_CONTROL_ID  = (VERTEX_CONTROL_ID - 1)         ;
	parameter EDGE_DATA_WRITE_CONTROL_ID = (EDGE_DATA_READ_CONTROL_ID - 1) ;
	parameter PREFETCH_CONTROL_ID        = (EDGE_DATA_WRITE_CONTROL_ID - 1);

	typedef logic [0:(CU_ID_RANGE-1)] cu_id_t;
endpackage