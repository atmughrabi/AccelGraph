// -----------------------------------------------------------------------------
//
//		"CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : globals_pkg.sv
// Create : 2019-09-26 15:20:15
// Revise : 2019-12-07 03:18:15
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

package GLOBALS_AFU_PKG;

	parameter CREDITS_READ  = 32                          ;
	parameter CREDITS_WRITE = 32                          ;
	parameter CREDITS_TOTAL = CREDITS_READ + CREDITS_WRITE; // MUST be 64 credits max

////////////////////////////////////////////////////////////////////////////
//  AFU-Control CAPI Globals
////////////////////////////////////////////////////////////////////////////
	parameter PAGE_SIZE              = 65536                  ; // Pagesize default  is 64KB
	parameter PAGE_SIZE_BITS         = (PAGE_SIZE * 8)        ;
	parameter CACHELINE_SIZE         = 128                    ; // cacheline is 128bytes
	parameter CACHELINE_SIZE_BITS    = (CACHELINE_SIZE * 8)   ;
	parameter CACHELINE_SIZE_HF      = (CACHELINE_SIZE >> 1)  ; // cacheline is 64bytes
	parameter CACHELINE_SIZE_BITS_HF = (CACHELINE_SIZE_HF * 8);

	parameter WORD             = 4              ;
	parameter WORD_BITS        = WORD * 8       ;
	parameter WORD_DOUBLE      = WORD * 2       ;
	parameter WORD_DOUBLE_BITS = WORD_DOUBLE * 8;

////////////////////////////////////////////////////////////////////////////
// AFU-Control (Buffer sizes)
////////////////////////////////////////////////////////////////////////////

	parameter TAG_COUNT   = 256  ;
	parameter INVALID_TAG = 8'h00;

	parameter BURST_CMD_BUFFER_SIZE = 64; // size of command burst for PSL leave as is

	parameter READ_CMD_BUFFER_SIZE           = 64;
	parameter WRITE_CMD_BUFFER_SIZE          = 64;
	parameter PREFETCH_READ_CMD_BUFFER_SIZE  = 64;
	parameter PREFETCH_WRITE_CMD_BUFFER_SIZE = 64;
	parameter WED_CMD_BUFFER_SIZE            = 4 ;

	parameter READ_DATA_BUFFER_SIZE  = 64; // not needed since data read in a non blocking manner
	parameter WRITE_DATA_BUFFER_SIZE = 64;
	parameter WED_DATA_BUFFER_SIZE   = 4 ;

////////////////////////////////////////////////////////////////////////////
// AFU-Control (Buffer Priorities) for Arbitration
////////////////////////////////////////////////////////////////////////////

	parameter PRIORITY_WED = 0;

	parameter PRIORITY_PREFTECH_WRITE = 1;
	parameter PRIORITY_WRITE          = 2;

	parameter PRIORITY_PREFETCH_READ = 3;
	parameter PRIORITY_READ          = 4;

////////////////////////////////////////////////////////////////////////////
// CU-Control  (Buffer size)
////////////////////////////////////////////////////////////////////////////

	parameter WRITE_ENGINE_BUFFER_HEADROOM = READ_CMD_BUFFER_SIZE + BURST_CMD_BUFFER_SIZE + CREDITS_READ;
	parameter WRITE_ENGINE_BUFFER_SIZE     = 2 ** ($clog2(WRITE_ENGINE_BUFFER_HEADROOM) + 1)            ;

////////////////////////////////////////////////////////////////////////////
// AFU-Control MMIO Registers Mapping on AFU and HOSt
////////////////////////////////////////////////////////////////////////////

	//AFU-Control Configurations
	parameter AFU_CONFIGURE   = 26'h 3FFFFF8 >> 2;
	parameter AFU_CONFIGURE_2 = 26'h 3FFFF30 >> 2;
	parameter AFU_STATUS      = 26'h 3FFFFF0 >> 2; // AFU status job running

	//CU-Control Configurations
	parameter CU_CONFIGURE   = 26'h 3FFFFE8 >> 2;
	parameter CU_CONFIGURE_2 = 26'h 3FFFF28 >> 2;
	parameter CU_STATUS      = 26'h 3FFFFE0 >> 2;

	parameter CU_RETURN     = 26'h 3FFFFD8 >> 2; // algorithm status DONE/RUNNING HOST reads this address
	parameter CU_RETURN_2   = 26'h 3FFFF10 >> 2;
	parameter CU_RETURN_ACK = 26'h 3FFFFD0 >> 2;

	parameter CU_RETURN_DONE     = 26'h 3FFFFC8 >> 2;
	parameter CU_RETURN_DONE_ACK = 26'h 3FFFFC0 >> 2;

	parameter ERROR_REG     = 26'h 3FFFFB8 >> 2; // AFU error reporting HOST reads this address
	parameter ERROR_REG_ACK = 26'h 3FFFFB0 >> 2;

	// MMIO Response Statistics
	parameter DONE_COUNT_REG                = 26'h 3FFFFA8 >> 2;
	parameter DONE_RESTART_COUNT_REG        = 26'h 3FFFFA0 >> 2;
	parameter DONE_READ_COUNT_REG           = 26'h 3FFFF98 >> 2;
	parameter DONE_WRITE_COUNT_REG          = 26'h 3FFFF90 >> 2;
	parameter DONE_PREFETCH_READ_COUNT_REG  = 26'h 3FFFF88 >> 2;
	parameter DONE_PREFETCH_WRITE_COUNT_REG = 26'h 3FFFF80 >> 2;

	parameter PAGED_COUNT_REG   = 26'h 3FFFF78 >> 2;
	parameter FLUSHED_COUNT_REG = 26'h 3FFFF70 >> 2;
	parameter AERROR_COUNT_REG  = 26'h 3FFFF68 >> 2;
	parameter DERROR_COUNT_REG  = 26'h 3FFFF60 >> 2;
	parameter FAILED_COUNT_REG  = 26'h 3FFFF58 >> 2;
	parameter FAULT_COUNT_REG   = 26'h 3FFFF50 >> 2;
	parameter NRES_COUNT_REG    = 26'h 3FFFF48 >> 2;
	parameter NLOCK_COUNT_REG   = 26'h 3FFFF40 >> 2;
	parameter CYCLE_COUNT_REG   = 26'h 3FFFF38 >> 2;

	parameter PREFETCH_READ_BYTE_COUNT_REG  = 26'h 3FFFF30 >> 2;
	parameter PREFETCH_WRITE_BYTE_COUNT_REG = 26'h 3FFFF28 >> 2;
	parameter READ_BYTE_COUNT_REG           = 26'h 3FFFF20 >> 2;
	parameter WRITE_BYTE_COUNT_REG          = 26'h 3FFFF18 >> 2;


////////////////////////////////////////////////////////////////////////////
// CU-Control CU Globals
////////////////////////////////////////////////////////////////////////////

// alignment to page 64K-BYTES
	parameter [0:63] ADDRESS_PAGE_MOD_MASK   = {{48{1'b0}},{16{1'b1}}};
	parameter [0:63] ADDRESS_PAGE_ALIGN_MASK = {{48{1'b1}},{16{1'b0}}};

	parameter TLB_SIZE            = 2048 * 2                                        ;
	parameter TLB_PAGE_BYTE_SIZE  = TLB_SIZE * PAGE_SIZE                            ;
	parameter MAX_TLB_CL_REQUESTS = TLB_SIZE * (PAGE_SIZE >> $clog2(CACHELINE_SIZE));
////////////////////////////////////////////////////////////////////////////
//  AFU-Control CU IDs any compute unite that generate command must have an ID
////////////////////////////////////////////////////////////////////////////

	parameter CU_ID_RANGE = 8;

	parameter INVALID_ID = {CU_ID_RANGE{1'b0}};
	parameter WED_ID     = {CU_ID_RANGE{1'b1}};
	parameter RESTART_ID = (WED_ID - 1)       ;

////////////////////////////////////////////////////////////////////////////
//  CU-Control CU IDs any compute unite that generate command must have an ID
////////////////////////////////////////////////////////////////////////////

	typedef logic [0:(CU_ID_RANGE-1)] cu_id_t;

endpackage