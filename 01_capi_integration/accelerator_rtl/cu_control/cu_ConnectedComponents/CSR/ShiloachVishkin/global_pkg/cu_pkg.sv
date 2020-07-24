// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_pkg.sv
// Create : 2019-09-26 15:20:09
// Revise : 2019-11-01 04:09:54
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

package CU_PKG;

// Relating to Vertex int types and sizes
	import GLOBALS_AFU_PKG::*;
	import GLOBALS_CU_PKG::*;

	typedef enum int unsigned{
		STRUCT_INVALID,
		INV_OUT_DEGREE,
		INV_EDGES_IDX,
		INV_EDGE_ARRAY_DEST,
		READ_GRAPH_DATA,
		READ_GRAPH_DATA_SRC,
		READ_GRAPH_DATA_DEST,
		READ_GRAPH_DATA_HIGH,
		WRITE_GRAPH_DATA
	} array_struct_type;

	typedef enum int unsigned {
		SEND_VERTEX_RESET,
		SEND_VERTEX_INIT,
		SEND_VERTEX_IDLE,
		START_VERTEX_REQ,
		CALC_VERTEX_REQ_SIZE,
		SEND_VERTEX_START,
		SEND_VERTEX_INV_OUT_DEGREE,
		SEND_VERTEX_INV_EDGES_IDX,
		WAIT_VERTEX_DATA,
		SHIFT_VERTEX_DATA_START,
		SHIFT_VERTEX_DATA_0,
		SHIFT_VERTEX_DATA_DONE_0,
		SHIFT_VERTEX_DATA_1,
		SHIFT_VERTEX_DATA_DONE_1
	} vertex_struct_state;

	typedef enum int unsigned {
		SEND_EDGE_RESET,
		SEND_EDGE_INIT,
		SEND_EDGE_IDLE,
		START_EDGE_REQ,
		CALC_EDGE_REQ_SIZE,
		SEND_EDGE_START,
		SEND_EDGE_INV_EDGE_ARRAY_DEST,
		WAIT_EDGE_DATA,
		SHIFT_EDGE_DATA_START,
		SHIFT_EDGE_DATA_0,
		SHIFT_EDGE_DATA_DONE_0,
		SHIFT_EDGE_DATA_1,
		SHIFT_EDGE_DATA_DONE_1
	} edge_struct_state;

	// typedef enum int unsigned {
	// 	SEND_EDGE_RESET,
	// 	SEND_EDGE_INIT,
	// 	SEND_EDGE_IDLE,
	// 	SEND_EDGE_WAIT,
	// 	START_EDGE_REQ,
	// 	CALC_EDGE_REQ_SIZE,
	// 	SEND_EDGE_SRC,
	// 	SEND_EDGE_DEST,
	// 	SEND_EDGE_WEIGHT,
	// 	SEND_EDGE_INV_SRC,
	// 	SEND_EDGE_INV_DEST,
	// 	SEND_EDGE_INV_WEIGHT
	// } edge_struct_state;

// Vertex data to travers neighbors
	typedef struct packed {
		logic [0:(VERTEX_SIZE_BITS-1)] id                ;
		logic [0:(VERTEX_SIZE_BITS-1)] inverse_out_degree;
		logic [0:(VERTEX_SIZE_BITS-1)] inverse_edges_idx ;
	} VertexInterfacePayload;

	typedef struct packed {
		logic                  valid  ;
		VertexInterfacePayload payload;
	} VertexInterface;

	typedef struct packed {
		logic [0:(EDGE_SIZE_BITS-1)] id  ;
		logic [0:(EDGE_SIZE_BITS-1)] src ;
		logic [0:(EDGE_SIZE_BITS-1)] dest;
	} EdgeInterfacePayload;

	typedef struct packed {
		logic                valid  ;
		EdgeInterfacePayload payload;
	} EdgeInterface;

	typedef struct packed {
		cu_id_t                           cu_id_x;
		cu_id_t                           cu_id_y;
		logic [0:(DATA_SIZE_READ_BITS-1)] data   ;
	} EdgeDataReadPayload;

	typedef struct packed {
		logic               valid  ;
		EdgeDataReadPayload payload;
	} EdgeDataRead;

	typedef struct packed {
		cu_id_t                            cu_id_x;
		cu_id_t                            cu_id_y;
		logic [      0:(EDGE_SIZE_BITS-1)] index  ;
		logic [0:(DATA_SIZE_WRITE_BITS-1)] data   ;
	} EdgeDataWritePayload;

	typedef struct packed {
		logic                valid  ;
		EdgeDataWritePayload payload;
	} EdgeDataWrite;




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


	function logic [0:VERTEX_SIZE_BITS-1] swap_endianness_vertex_read(logic [0:VERTEX_SIZE_BITS-1] in);

		logic [0:VERTEX_SIZE_BITS-1] out;

		integer i;
		for ( i = 0; i < VERTEX_SIZE; i++) begin
			out[i*8 +: 8] = in[((VERTEX_SIZE_BITS-1)-(i*8)) -:8];
		end

		return out;
	endfunction : swap_endianness_vertex_read


	function logic [0:EDGE_SIZE_BITS-1] swap_endianness_edge_read(logic [0:EDGE_SIZE_BITS-1] in);

		logic [0:EDGE_SIZE_BITS-1] out;

		integer i;
		for ( i = 0; i < EDGE_SIZE; i++) begin
			out[i*8 +: 8] = in[((EDGE_SIZE_BITS-1)-(i*8)) -:8];
		end

		return out;
	endfunction : swap_endianness_edge_read


// Read/write commands require the size to be a power of 2 (1, 2, 4, 8, 16, 32,64, 128).
	function logic [0:11] cmd_size_calculate(logic [0:(VERTEX_SIZE_BITS-1)]  vertex_num_counter);

		logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_size;
		logic [0:11] request_size;

		vertex_num_size = (vertex_num_counter << $clog2(VERTEX_SIZE));

		if (vertex_num_size > 64)
			request_size = 128;
		else if (vertex_num_size > 32)
			request_size = 64;
		else if (vertex_num_size > 16)
			request_size = 32;
		else if (vertex_num_size > 8)
			request_size = 16;
		else if (vertex_num_size > 4)
			request_size = 8;
		else if (vertex_num_size > 2)
			request_size = 4;
		else if (vertex_num_size > 1)
			request_size = 2;
		else if (vertex_num_size > 0)
			request_size = 1;
		else
			request_size = 0;

		return request_size;

	endfunction : cmd_size_calculate


endpackage