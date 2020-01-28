// -----------------------------------------------------------------------------
//
//		"CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_pkg.sv
// Create : 2019-09-26 15:20:09
// Revise : 2019-12-06 22:28:51
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

package CU_PKG;

// Relating to array int types and sizes
	import GLOBALS_AFU_PKG::*;

	typedef enum int unsigned {
		READ_STREAM_RESET,
		READ_STREAM_IDLE,
		READ_STREAM_SET,
		PREFETCH_READ_STREAM_START,
		PREFETCH_READ_STREAM_REQ,
		READ_STREAM_START,
		READ_STREAM_REQ,
		READ_STREAM_PENDING,
		READ_STREAM_DONE,
		READ_STREAM_FINAL
	} read_state;

	typedef enum int unsigned {
		WRITE_STREAM_RESET,
		WRITE_STREAM_IDLE,
		WRITE_STREAM_SET,
		PREFETCH_WRITE_STREAM_START,
		PREFETCH_WRITE_STREAM_REQ,
		WRITE_STREAM_START,
		WRITE_STREAM_REQ,
		WRITE_STREAM_PENDING,
		WRITE_STREAM_DONE,
		WRITE_STREAM_FINAL
	} write_state;

	typedef enum int unsigned{
		STRUCT_INVALID,
		READ_DATA,
		WRITE_DATA,
		PREFETCH_DATA
	} array_struct_type;

	typedef struct packed {
		logic                             valid;

		cu_id_t                           cu_id;
		logic [0:(DATA_SIZE_READ_BITS-1)] data ;
	} DataRead;

	typedef struct packed {
		logic                              valid;
		cu_id_t                            cu_id;
		logic [     0:(ARRAY_SIZE_BITS-1)] index;
		logic [0:(DATA_SIZE_WRITE_BITS-1)] data ;
	} DataWrite;


	function logic [0:DATA_SIZE_WRITE_BITS-1] swap_endianness_data_write(logic [0:DATA_SIZE_WRITE_BITS-1] in);

		logic [0:DATA_SIZE_WRITE_BITS-1] out;

		integer i;
		for ( i = 0; i < DATA_SIZE_WRITE; i++) begin
			out[i*8 +: 8] = in[((DATA_SIZE_WRITE_BITS-1)-(i*8)) -:8];
		end

		return out;
	endfunction : swap_endianness_data_write

	function logic [0:DATA_SIZE_READ_BITS-1] swap_endianness_data_read(logic [0:DATA_SIZE_READ_BITS-1] in);

		logic [0:DATA_SIZE_READ_BITS-1] out;

		integer i;
		for ( i = 0; i < DATA_SIZE_READ; i++) begin
			out[i*8 +: 8] = in[((DATA_SIZE_READ_BITS-1)-(i*8)) -:8];
		end

		return out;
	endfunction : swap_endianness_data_read


	function logic [0:ARRAY_SIZE_BITS-1] swap_endianness_array_read(logic [0:ARRAY_SIZE_BITS-1] in);

		logic [0:ARRAY_SIZE_BITS-1] out;

		integer i;
		for ( i = 0; i < ARRAY_SIZE; i++) begin
			out[i*8 +: 8] = in[((ARRAY_SIZE_BITS-1)-(i*8)) -:8];
		end

		return out;
	endfunction : swap_endianness_array_read


// Read/write commands require the size to be a power of 2 (1, 2, 4, 8, 16, 32,64, 128).
	function logic [0:11] cmd_size_calculate(logic [0:(ARRAY_SIZE_BITS-1)]  num_counter);

		logic [0:(ARRAY_SIZE_BITS-1)] num_size;
		logic [0:11] request_size;

		num_size = (num_counter << $clog2(ARRAY_SIZE));

		if (num_size > 64)
			request_size = 128;
		else if (num_size > 32)
			request_size = 64;
		else if (num_size > 16)
			request_size = 32;
		else if (num_size > 8)
			request_size = 16;
		else if (num_size > 4)
			request_size = 8;
		else if (num_size > 2)
			request_size = 4;
		else if (num_size > 1)
			request_size = 2;
		else if (num_size > 0)
			request_size = 1;
		else
			request_size = 0;

		return request_size;

	endfunction : cmd_size_calculate

endpackage