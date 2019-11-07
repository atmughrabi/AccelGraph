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

	import GLOBALS_PKG::*;

	typedef enum int unsigned{
		STRUCT_INVALID,
		IN_DEGREE,
		OUT_DEGREE,
		EDGES_IDX,
		INV_IN_DEGREE,
		INV_OUT_DEGREE,
		INV_EDGES_IDX,
		EDGE_ARRAY_SRC,
		EDGE_ARRAY_DEST,
		EDGE_ARRAY_WEIGHT,
		INV_EDGE_ARRAY_SRC,
		INV_EDGE_ARRAY_DEST,
		INV_EDGE_ARRAY_WEIGHT,
		READ_GRAPH_DATA,
		WRITE_GRAPH_DATA
	} vertex_struct_type;

	typedef enum int unsigned {
		SEND_VERTEX_RESET,
		SEND_VERTEX_INIT,
		SEND_VERTEX_IDLE,
		SEND_VERTEX_WAIT,
		CALC_VERTEX_REQ_SIZE,
		SEND_VERTEX_IN_DEGREE,
		SEND_VERTEX_OUT_DEGREE,
		SEND_VERTEX_EDGES_IDX,
		SEND_VERTEX_INV_IN_DEGREE,
		SEND_VERTEX_INV_OUT_DEGREE,
		SEND_VERTEX_INV_EDGES_IDX
	} vertex_struct_state;

	typedef enum int unsigned {
		SEND_EDGE_RESET,
		SEND_EDGE_INIT,
		SEND_EDGE_IDLE,
		SEND_EDGE_WAIT,
		CALC_EDGE_REQ_SIZE,
		SEND_EDGE_SRC,
		SEND_EDGE_DEST,
		SEND_EDGE_WEIGHT,
		SEND_EDGE_INV_SRC,
		SEND_EDGE_INV_DEST,
		SEND_EDGE_INV_WEIGHT
	} edge_struct_state;

	typedef enum int unsigned {
		SEND_DATA_RESET,
		SEND_DATA_INIT,
		SEND_DATA_IDLE,
		SEND_DATA_WAIT,
		CALC_DATA_REQ_SIZE,
		SEND_DATA_DEST
	} dara_struct_state;

// Vertex data to travers neighbors
	typedef struct packed {
		logic                          valid             ;
		logic [0:(VERTEX_SIZE_BITS-1)] id                ;
		logic [0:(VERTEX_SIZE_BITS-1)] in_degree         ;
		logic [0:(VERTEX_SIZE_BITS-1)] out_degree        ;
		logic [0:(VERTEX_SIZE_BITS-1)] edges_idx         ;
		logic [0:(VERTEX_SIZE_BITS-1)] inverse_in_degree ;
		logic [0:(VERTEX_SIZE_BITS-1)] inverse_out_degree;
		logic [0:(VERTEX_SIZE_BITS-1)] inverse_edges_idx ;
	} VertexInterface;

	typedef struct packed {
		logic                        valid ;
		logic [0:(EDGE_SIZE_BITS-1)] id    ;
		logic [0:(EDGE_SIZE_BITS-1)] src   ;
		logic [0:(EDGE_SIZE_BITS-1)] dest  ;
		logic [0:(EDGE_SIZE_BITS-1)] weight;
	} EdgeInterface;

	typedef struct packed {
		logic                             valid;
		cu_id_t                           cu_id;
		logic [0:(DATA_SIZE_READ_BITS-1)] data ;
	} EdgeDataRead;

	typedef struct packed {
		logic                              valid;
		cu_id_t                            cu_id;
		logic [0:(EDGE_SIZE_BITS-1)]       index;
		logic [0:(DATA_SIZE_WRITE_BITS-1)] data ;
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

	function logic [0:(CACHELINE_SIZE_BITS-1)] seek_cacheline(logic [0:7]  shift_seek, logic [0:(CACHELINE_SIZE_BITS-1)] cacheline_in);

		logic [0:(CACHELINE_SIZE_BITS-1)] cacheline_out;

		cacheline_out = cacheline_in;


		if(0 == shift_seek) begin
			cacheline_out = {{(0*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(0*VERTEX_SIZE_BITS))]};
		end else if(1 == shift_seek) begin
			cacheline_out = {{(1*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(1*VERTEX_SIZE_BITS))]};
		end else if(2 == shift_seek) begin
			cacheline_out = {{(2*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(2*VERTEX_SIZE_BITS))]};
		end else if(3 == shift_seek) begin
			cacheline_out = {{(3*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(3*VERTEX_SIZE_BITS))]};
		end else if(4 == shift_seek) begin
			cacheline_out = {{(4*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(4*VERTEX_SIZE_BITS))]};
		end else if(5 == shift_seek) begin
			cacheline_out = {{(5*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(5*VERTEX_SIZE_BITS))]};
		end else if(6 == shift_seek) begin
			cacheline_out = {{(6*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(6*VERTEX_SIZE_BITS))]};
		end else if(7 == shift_seek) begin
			cacheline_out = {{(7*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(7*VERTEX_SIZE_BITS))]};
		end else if(8 == shift_seek) begin
			cacheline_out = {{(8*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(8*VERTEX_SIZE_BITS))]};
		end else if(9 == shift_seek) begin
			cacheline_out = {{(9*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(9*VERTEX_SIZE_BITS))]};
		end else if(10 == shift_seek) begin
			cacheline_out = {{(10*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(10*VERTEX_SIZE_BITS))]};
		end else if(11 == shift_seek) begin
			cacheline_out = {{(11*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(11*VERTEX_SIZE_BITS))]};
		end else if(12 == shift_seek) begin
			cacheline_out = {{(12*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(12*VERTEX_SIZE_BITS))]};
		end else if(13 == shift_seek) begin
			cacheline_out = {{(13*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(13*VERTEX_SIZE_BITS))]};
		end else if(14 == shift_seek) begin
			cacheline_out = {{(14*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(14*VERTEX_SIZE_BITS))]};
		end else if(15 == shift_seek) begin
			cacheline_out = {{(15*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(15*VERTEX_SIZE_BITS))]};
		end else if(16 == shift_seek) begin
			cacheline_out = {{(16*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(16*VERTEX_SIZE_BITS))]};
		end else if(17 == shift_seek) begin
			cacheline_out = {{(17*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(17*VERTEX_SIZE_BITS))]};
		end else if(18 == shift_seek) begin
			cacheline_out = {{(18*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(18*VERTEX_SIZE_BITS))]};
		end else if(19 == shift_seek) begin
			cacheline_out = {{(19*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(19*VERTEX_SIZE_BITS))]};
		end else if(20 == shift_seek) begin
			cacheline_out = {{(20*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(20*VERTEX_SIZE_BITS))]};
		end else if(21 == shift_seek) begin
			cacheline_out = {{(21*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(21*VERTEX_SIZE_BITS))]};
		end else if(22 == shift_seek) begin
			cacheline_out = {{(22*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(22*VERTEX_SIZE_BITS))]};
		end else if(23 == shift_seek) begin
			cacheline_out = {{(23*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(23*VERTEX_SIZE_BITS))]};
		end else if(24 == shift_seek) begin
			cacheline_out = {{(24*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(24*VERTEX_SIZE_BITS))]};
		end else if(25 == shift_seek) begin
			cacheline_out = {{(25*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(25*VERTEX_SIZE_BITS))]};
		end else if(26 == shift_seek) begin
			cacheline_out = {{(26*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(26*VERTEX_SIZE_BITS))]};
		end else if(27 == shift_seek) begin
			cacheline_out = {{(27*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(27*VERTEX_SIZE_BITS))]};
		end else if(28 == shift_seek) begin
			cacheline_out = {{(28*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(28*VERTEX_SIZE_BITS))]};
		end else if(29 == shift_seek) begin
			cacheline_out = {{(29*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(29*VERTEX_SIZE_BITS))]};
		end else if(30 == shift_seek) begin
			cacheline_out = {{(30*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(30*VERTEX_SIZE_BITS))]};
		end else if(31 == shift_seek) begin
			cacheline_out = {{(31*VERTEX_SIZE_BITS){1'b0}},cacheline_in[0:(CACHELINE_SIZE_BITS-1-(31*VERTEX_SIZE_BITS))]};
		end

		return cacheline_out;

	endfunction : seek_cacheline


endpackage