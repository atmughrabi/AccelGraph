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
// Revise : 2019-11-08 07:28:25
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

package GLOBALS_CU_PKG;

	import GLOBALS_AFU_PKG::*;

////////////////////////////////////////////////////////////////////////////
// CU-Control (Buffer sizes)
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
// CU-Control CU Globals
////////////////////////////////////////////////////////////////////////////

// How many compute unites you want : each 1 graph_cu contains N vertex_cu's MIN (2 X 2) MAX (N X M)
// TOTAL CUS = NUM_GRAPH_CU_GLOBAL X NUM_VERTEX_CU_GLOBAL
////////////////////////////////////////////////////////////////////////////

	parameter NUM_GRAPH_CU_GLOBAL  = 6;
	parameter NUM_VERTEX_CU_GLOBAL = 4;

	parameter CU_VERTEX_JOB_BUFFER_SIZE = 64;
	parameter CU_EDGE_JOB_BUFFER_SIZE   = 64;


////////////////////////////////////////////////////////////////////////////
// CU-Control CU Globals
////////////////////////////////////////////////////////////////////////////

// ACCEL-GRAPH Sturctue sizes
////////////////////////////////////////////////////////////////////////////

	parameter VERTEX_SIZE             = 4                                           ; // vertex size is n bytes
	parameter VERTEX_SIZE_BITS        = VERTEX_SIZE * 8                             ; // vertex size is n*8 Bits
	parameter CACHELINE_VERTEX_NUM    = (CACHELINE_SIZE >> $clog2(VERTEX_SIZE))     ;
	parameter CACHELINE_VERTEX_NUM_HF = (CACHELINE_SIZE >> $clog2(VERTEX_SIZE)) >> 1; // number of vertices in one cacheline
	parameter VERTEX_NULL_BITS        = {VERTEX_SIZE_BITS{1'b0}}                    ;

	parameter EDGE_SIZE             = 4                                         ; // edge size is n bytes
	parameter EDGE_SIZE_BITS        = EDGE_SIZE * 8                             ; // edge size is n*8 Bits
	parameter CACHELINE_EDGE_NUM    = (CACHELINE_SIZE >> $clog2(EDGE_SIZE))     ;
	parameter CACHELINE_EDGE_NUM_HF = (CACHELINE_SIZE >> $clog2(EDGE_SIZE)) >> 1; // number of edges in one cacheline
	parameter EDGE_NULL_BITS        = {EDGE_SIZE_BITS{1'b0}}                    ;

	parameter DATA_SIZE_READ               = 4                                              ; // edge data size is n bytes Auxiliary1
	parameter DATA_SIZE_READ_BITS          = DATA_SIZE_READ * 8                             ; // edge data size is n*8 Bits
	parameter CACHELINE_DATA_READ_NUM      = (CACHELINE_SIZE >> $clog2(DATA_SIZE_READ))     ;
	parameter CACHELINE_DATA_READ_NUM_HF   = (CACHELINE_SIZE >> $clog2(DATA_SIZE_READ)) >> 1;
	parameter CACHELINE_DATA_READ_NUM_BITS = $clog2(CACHELINE_DATA_READ_NUM)                ; // number of edges in one cacheline

	parameter DATA_SIZE_WRITE             = 4                                               ; // edge data size is n bytes Auxiliary2
	parameter DATA_SIZE_WRITE_BITS        = DATA_SIZE_WRITE * 8                             ; // edge data size is n*8 Bits
	parameter CACHELINE_DATA_WRITE_NUM    = (CACHELINE_SIZE >> $clog2(DATA_SIZE_WRITE))     ;
	parameter CACHELINE_DATA_WRITE_NUM_HF = (CACHELINE_SIZE >> $clog2(DATA_SIZE_WRITE)) >> 1; // number of edges in one cacheline

	// aligenment to cacheline 128-BYTES
	parameter [0:63] ADDRESS_ARRAY_ALIGN_MASK = {{57{1'b1}},{7{1'b0}}};
	parameter [0:63] ADDRESS_ARRAY_MOD_MASK   = {{57{1'b0}},{7{1'b1}}};

	parameter [0:63] ADDRESS_DATA_READ_ALIGN_MASK = {{57{1'b1}},{7{1'b0}}};
	parameter [0:63] ADDRESS_DATA_READ_MOD_MASK   = {{57{1'b0}},{7{1'b1}}};

	parameter [0:63] ADDRESS_DATA_WRITE_ALIGN_MASK = {{57{1'b1}},{7{1'b0}}};
	parameter [0:63] ADDRESS_DATA_WRITE_MOD_MASK   = {{57{1'b0}},{7{1'b1}}};

	parameter [0:63] ADDRESS_EDGE_ALIGN_MASK = {{57{1'b1}},{7{1'b0}}};
	parameter [0:63] ADDRESS_EDGE_MOD_MASK   = {{57{1'b0}},{7{1'b1}}};

	parameter CACHELINE_INT_COUNTER_BITS = $clog2((VERTEX_SIZE_BITS < CACHELINE_SIZE_BITS_HF) ? (2 * CACHELINE_SIZE_BITS_HF)/VERTEX_SIZE_BITS : 2);

////////////////////////////////////////////////////////////////////////////
//  AFU/CU-Control CU IDs any compute unit that generate command must have an ID
////////////////////////////////////////////////////////////////////////////

	parameter VERTEX_CONTROL_ID          = (RESTART_ID - 1)                ;
	parameter EDGE_DATA_READ_CONTROL_ID  = (VERTEX_CONTROL_ID - 1)         ;
	parameter EDGE_DATA_WRITE_CONTROL_ID = (EDGE_DATA_READ_CONTROL_ID - 1) ;
	parameter PREFETCH_CONTROL_ID        = (EDGE_DATA_WRITE_CONTROL_ID - 1);

endpackage