package CU_PKG;

	// parameter INVALID_ID      	= 8'h00; 		defined at capi_pkg
	// parameter WED_ID 			= 8'h01; 		defined at wed_pkg

// Relating to Vertex int types and sizes

	parameter VERTEX_SIZE 				= 4; // vertex size is 4 bytes
	parameter VERTEX_SIZE_BITS 			= VERTEX_SIZE * 8; // vertex size is 4 bytes
	parameter EDGE_SIZE 				= 4; // vertex size is 4 bytes
	parameter CACHELINE_SIZE 	   		= 128; // cacheline is 128bytes
	parameter CACHELINE_SIZE_BITS 	   	= CACHELINE_SIZE * 8; // cacheline is 128bytes
	parameter CACHELINE_VERTEX_NUM 		= (128 >> $clog2(VERTEX_SIZE)); // number of vertices in one cacheline
	parameter CACHELINE_EDGE_NUM   		= (128 >> $clog2(EDGE_SIZE)); // number of edges in one cacheline
// Relating to CU IDs
	parameter VERTEX_CONTROL_ID 		= 8'h02;			// This is the CU that requests and schedules graph vertices to other CUs

	typedef enum logic [0:2]{
		STRUCT_INVALID,
		IN_DEGREE,
		OUT_DEGREE,
		EDGES_IDX,
		INV_IN_DEGREE,
		INV_OUT_DEGREE,
		INV_EDGES_IDX
	} vertex_struct_type;

	typedef enum int unsigned {
		SEND_VERTEX_RESET,
		SEND_VERTEX_INIT,
		SEND_VERTEX_IDLE,
		CALC_VERTEX_REQ_SIZE,
		SEND_VERTEX_IN_DEGREE,
		SEND_VERTEX_OUT_DEGREE,
		SEND_VERTEX_EDGES_IDX,
		SEND_VERTEX_INV_IN_DEGREE,
		SEND_VERTEX_INV_OUT_DEGREE,
		SEND_VERTEX_INV_EDGES_IDX
	} vertex_struct_state;

// Vertex data to travers neighbors
	typedef struct packed {
		logic valid;
		logic [0:32] id;
		logic [0:32] in_degree;
		logic [0:32] out_degree;
		logic [0:32] edges_idx;
		logic [0:32] inverse_in_degree;
		logic [0:32] inverse_out_degree;
		logic [0:32] inverse_edges_idx;
	} VertexInterface;

// Read/write commands require the size to be a power of 2 (1, 2, 4, 8, 16, 32,64, 128).
	function logic [0:11] cmd_size_calculate(logic [0:31]  vertex_num_counter);

		logic [0:31] vertex_num_size;
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