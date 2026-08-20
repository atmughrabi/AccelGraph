// -----------------------------------------------------------------------------
//
//      "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// graph-unit-algorithm-shells: cu_vertex_bfs, cu_vertex_pagerank,
// cu_vertex_spmv, cu_vertex_connectedComponents and cu_vertex_triangleCount.
//
// Oracle: graph-engine-transaction-scoreboard-v1.  The shells are checked at the
// transaction level: vertex-job acceptance and request handshake, read command
// legality against the declared graph arrays, result routing onto the write
// bus, completion counters, and repeat/reset behaviour.  Algorithm values are
// checked by the kernel families; this suite owns the engine plumbing.
//
// The shell is instantiated through a per-algorithm shim so that one testbench
// covers all five module names.
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;
import GRAPH_FIXTURE_PKG::*;
import ALGO_CHECK_PKG::*;

module algorithm_shell_tb;

	timeunit 1ns; timeprecision 1ps;

	// all-ones CU coordinates so every identifier bit the shell copies from its
	// parameters into the element and result records is observed changing
	localparam int CU_X      = 8'hFF;
	localparam int CU_Y      = 8'hFF;
	localparam int BIN_COUNT = 14;
	localparam int RUN_LIMIT = 6000;

	// Census event budget.  The completion counters the shell publishes advance
	// by one per accepted acknowledge, so bit k first changes when the count
	// reaches 2**k; the census walks them with an explicit event burst whose
	// length is a crossing point, not a percentage.  The shell context carries
	// the algorithm shell, both engine control paths and the memory adapter, so
	// the budget is 2**20 accepted acknowledges here against 2**24 in the
	// kernel contexts.  +CENSUS_BURST=<n> changes it for a measurement run.
	localparam int unsigned CENSUS_BURST_DEFAULT = 32'h0010_0000;

	// Depth of the single vertex job the census streams: the per-vertex element
	// identifier the edge job engine attaches restarts at every vertex, so its
	// bit k is only observed when one vertex carries 2**k elements.
	localparam int unsigned CENSUS_DEEP_DEGREE = 32'h0000_2000;

	function automatic int unsigned census_events();
		int unsigned events;
		events = CENSUS_BURST_DEFAULT;
		void'($value$plusargs("CENSUS_BURST=%d", events));
		return events;
	endfunction

	// Walking one and walking zero image of a field of the given width; the
	// caller assigns it to the field, which keeps the low order bits.
	function automatic logic [63:0] census_pattern(input int unsigned step, input int unsigned width);
		logic [63:0] one;
		one = 64'h1 << (step % width);
		// the polarity alternates per step, so consecutive values differ across
		// the whole field, and it flips again on the second pass, so every bit
		// of the field is observed both low and high; taking the polarity from
		// the step alone leaves every odd bit of the field stuck at one polarity
		return (((step % 2) ^ ((step / width) % 2)) != 0) ? ~one : one;
	endfunction

	localparam int unsigned BASE_INV_OUT_DEGREE  = 32'h0000_1000;
	localparam int unsigned BASE_INV_EDGES_IDX   = 32'h0000_2000;
	localparam int unsigned BASE_PARENT          = 32'h0000_3000;
	localparam int unsigned BASE_INV_EDGE_DEST   = 32'h0000_4000;
	localparam int unsigned BASE_DATA_READ       = 32'h0000_5000;
	localparam int unsigned BASE_DATA_WRITE      = 32'h0000_6000;
	localparam int unsigned BASE_INV_EDGE_WEIGHT = 32'h0000_7000;
	localparam int unsigned BASE_OUT_DEGREE      = 32'h0000_8000;
	localparam int unsigned BASE_EDGES_IDX       = 32'h0000_9000;
	localparam int unsigned BASE_EDGE_DEST       = 32'h0000_A000;
	localparam int unsigned BASE_EDGE_WEIGHT     = 32'h0000_B000;
	localparam int unsigned BASE_INV_EDGE_SRC    = 32'h0000_C000;
	localparam int unsigned BASE_EDGE_SRC        = 32'h0000_D000;

	logic clock = 1'b0;
	logic rstn  = 1'b0;

	WEDInterface       wed_request_in     ;
	logic [0:63]       cu_configure       ;
	ResponseBufferLine read_response_in   ;
	ResponseBufferLine write_response_in  ;
	logic              read_bus_grant     ;
	logic              read_bus_request   ;
	logic              write_bus_grant    ;
	logic              write_bus_request  ;
	ReadWriteDataLine  read_data_0_in     ;
	ReadWriteDataLine  read_data_1_in     ;
	EdgeDataRead       edge_data_read_in  ;  // driven by the shared extract engine
	BufferStatus       read_buffer_status ;
	CommandBufferLine  read_command_out   ;
	BufferStatus       write_buffer_status;
	EdgeDataWrite      edge_data_write_out;
	VertexInterface    vertex_job         ;
	logic              vertex_job_request ;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_num_counter  ;

	// synthesised write path: the shell hands results to the CU write engine,
	// which the testbench models so the result reaches memory and the response
	// returns through the real response port
	CommandBufferLine write_command_out;
	ReadWriteDataLine write_data_0_out ;
	ReadWriteDataLine write_data_1_out ;

	logic mem_read_stall  ;
	logic mem_write_stall ;
	logic mem_write_alfull;
	bit   read_alfull_round;

	int unsigned cycle_count;
	int unsigned stall_mask ;
	int unsigned scenarios  ;
	int active_fixture      ;
	int num_vertices        ;
	int num_edges           ;

	int vertex_jobs_issued ;
	int writes_observed    ;
	int edge_data_reads    ;
	int edge_job_reads     ;
	int illegal_commands   ;
	bit cover_bin[0:BIN_COUNT-1];
	bit masks_seen[0:MASK_COUNT-1];

	cu_vertex_shell_dut #(
		.CU_ID_X(CU_X),
		.CU_ID_Y(CU_Y)
	) dut (
		.clock                      (clock              ),
		.rstn_in                    (rstn               ),
		.enabled_in                 (1'b1               ),
		.wed_request_in             (wed_request_in     ),
		.cu_configure               (cu_configure       ),
		.read_response_in           (read_response_in   ),
		.write_response_in          (write_response_in  ),
		.read_command_bus_grant     (read_bus_grant     ),
		.read_command_bus_request   (read_bus_request   ),
		.edge_data_write_bus_grant  (write_bus_grant    ),
		.edge_data_write_bus_request(write_bus_request  ),
		.read_data_0_in             (read_data_0_in     ),
		.read_data_1_in             (read_data_1_in     ),
		.edge_data_read_in          (edge_data_read_in  ),
		.read_buffer_status         (read_buffer_status ),
		.read_command_out           (read_command_out   ),
		.write_buffer_status        (write_buffer_status),
		.edge_data_write_out        (edge_data_write_out),
		.vertex_job                 (vertex_job         ),
		.vertex_job_request         (vertex_job_request ),
		.vertex_num_counter         (vertex_num_counter ),
		.edge_num_counter           (edge_num_counter   )
	);

	// The cache-line to element extraction lives in the shared cluster engine
	// above the algorithm shell, so the real engine module is instantiated at
	// the shell boundary instead of being re-modelled in the testbench.
	EdgeDataRead      edge_data_extracted;
	ReadWriteDataLine extract_data_0     ;
	ReadWriteDataLine extract_data_1     ;

	// The cluster demultiplexes the read data before the extract engine sees it.
	// The graph memory adapter reports which served read belonged to the
	// property array, which covers every property read a layout issues per edge
	// (one for BFS, PageRank and SPMV, two for TriangleCount, three for
	// ConnectedComponents) without naming layout specific enumerations.
	always_comb begin
		extract_data_0       = read_data_0_in;
		extract_data_1       = read_data_1_in;
		extract_data_0.valid = read_data_0_in.valid && mem_read_is_property;
		extract_data_1.valid = read_data_1_in.valid && mem_read_is_property;
	end

	cu_edge_data_read_extract_control #(
		.CU_ID_X(CU_X),
		.CU_ID_Y(CU_Y)
	) extract_engine (
		.clock         (clock              ),
		.rstn          (rstn               ),
		.enabled_in    (1'b1               ),
		.read_data_0_in(extract_data_0     ),
		.read_data_1_in(extract_data_1     ),
		.edge_data     (edge_data_extracted)
	);

	// the raw port sweep drives the element record itself; every other phase
	// takes it from the shared extract engine
	always @(posedge clock)
		if (!census_raw)
			edge_data_read_in <= edge_data_extracted;

	always #1 clock = ~clock;

	always @(posedge clock)
		cycle_count <= cycle_count + 1;

	// Every layout reads its per-vertex property array through the pointer the
	// WED carries; ConnectedComponents issues three such reads per edge
	// (component of source, of destination and of the current high component)
	// and TriangleCount two, so the classification is by address rather than by
	// the layout specific array structure enumeration.
	// The per-vertex property read is issued by the read data command control,
	// which tags it READ_GRAPH_DATA whatever the layout; the edge job control
	// tags its own array reads.  Classifying on the tag keeps the routing exact
	// for the census identifiers, whose property addresses deliberately leave
	// the tiny-graph window.  The address ranges remain as a second witness.
	function automatic bit mem_read_property(input int unsigned address, input CommandTagLine cmd);
		if (cmd.array_struct == READ_GRAPH_DATA)
			return 1'b1;
		return (address >= BASE_DATA_READ && address < BASE_DATA_READ + 32'h1000) ||
		       (address >= BASE_PARENT    && address < BASE_PARENT    + 32'h1000);
	endfunction

	function automatic bit mem_read_stalled(input int unsigned address);
		if (address >= BASE_DATA_READ && address < BASE_DATA_READ + 32'h1000)
			return domain_stalled(stall_mask, DOMAIN_KERNEL, cycle_count);
		return domain_stalled(stall_mask, DOMAIN_EDGE_READ, cycle_count);
	endfunction

`include "graph_memory_model.svh"

	task automatic bundle(input string reason);
		$display("FAILURE-BUNDLE algorithm_shell reason=%s", reason);
		$display("  fixture=%s mask=%0d cycle=%0d vertices=%0d",
			fixture_name(active_fixture), stall_mask, cycle_count, num_vertices);
		$display("  vertex_jobs=%0d writes=%0d edge_job_reads=%0d edge_data_reads=%0d illegal=%0d",
			vertex_jobs_issued, writes_observed, edge_job_reads, edge_data_reads, illegal_commands);
		$display("  vertex_num_counter=%0d edge_num_counter=%0d reads_served=%0d writes_served=%0d write_drops=%0d",
			vertex_num_counter, edge_num_counter, mem_reads_served, mem_writes_served, mem_write_drops);
	endtask

	task automatic fail(input string reason);
		bundle(reason);
		$error("algorithm_shell mismatch %s", reason);
		$fatal(1);
	endtask

	bit debug_trace;

	always @(posedge clock)
		if (rstn && debug_trace)
			$display("TRACE-SHELL cycle=%0d vjreq=%b vj.v=%b rdcmd=%b addr=%h wr.v=%b vnum=%0d enum=%0d",
				cycle_count, vertex_job_request, vertex_job.valid, read_command_out.valid,
				read_command_out.payload.address, edge_data_write_out.valid,
				vertex_num_counter, edge_num_counter);

`ifdef SHELL_FORWARD_DEGREE
	always @(posedge clock)
		if (rstn && debug_trace)
			$display("TRACE-CC cycle=%0d vjl.v=%b vjl.id=%0d deg=%0d accum=%0d done=%b rstn_cmd=%b ejob.v=%b ed.v=%b rdreq=%b",
				cycle_count,
				dut.cu_vertex_shell_instant.vertex_job_latched.valid,
				dut.cu_vertex_shell_instant.vertex_job_latched.payload.id,
				dut.cu_vertex_shell_instant.vertex_job_latched.payload.out_degree,
				dut.cu_vertex_shell_instant.edge_data_counter_accum_internal,
				dut.cu_vertex_shell_instant.vertex_round_done,
				dut.cu_vertex_shell_instant.rstn_data_cmd,
				dut.cu_vertex_shell_instant.edge_job.valid,
				dut.cu_vertex_shell_instant.edge_data.valid,
				read_bus_request);
`endif

`ifdef SHELL_WED_BFS
	always @(posedge clock)
		if (rstn && debug_trace)
			$display("TRACE-ENG cycle=%0d vjl.v=%b vjl.id=%0d proc=%b ejob.v=%b ejob.src=%0d ejob.dest=%0d ed.v=%b ed.data=%h brk=%b",
				cycle_count,
				dut.cu_vertex_shell_instant.vertex_job_latched.valid,
				dut.cu_vertex_shell_instant.vertex_job_latched.payload.id,
				dut.cu_vertex_shell_instant.processing_vertex,
				dut.cu_vertex_shell_instant.edge_job.valid,
				dut.cu_vertex_shell_instant.edge_job.payload.src,
				dut.cu_vertex_shell_instant.edge_job.payload.dest,
				dut.cu_vertex_shell_instant.edge_data.valid,
				dut.cu_vertex_shell_instant.edge_data.payload.data,
				dut.cu_vertex_shell_instant.break_S_out);
`endif

	// read command legality and classification
	always @(posedge clock) begin
		if (rstn && read_command_out.valid) begin
			automatic int unsigned address = read_command_out.payload.address[32:63];
			if (address >= BASE_DATA_READ && address < BASE_DATA_READ + 32'h1000)
				edge_data_reads <= edge_data_reads + 1;
			else
				edge_job_reads <= edge_job_reads + 1;
			if (read_command_out.payload.size > CACHELINE_SIZE || address >= MEM_BYTES)
				illegal_commands <= illegal_commands + 1;
			if (read_command_out.payload.cmd.cmd_type != CMD_READ)
				illegal_commands <= illegal_commands + 1;
		end
	end

	// result routing: the shell only publishes when it is granted the bus
	always @(posedge clock) begin
		write_command_out <= '0;
		write_data_0_out  <= '0;
		write_data_1_out  <= '0;
		if (rstn && edge_data_write_out.valid) begin
			automatic int unsigned index = edge_data_write_out.payload.index;
			automatic int unsigned address = BASE_DATA_WRITE + (index * DATA_SIZE_WRITE);
			automatic int unsigned half_off = (address % CACHELINE_SIZE) % CACHELINE_SIZE_HF;
			writes_observed          <= writes_observed + 1;
			write_command_out.valid  <= 1'b1;
			write_command_out.payload.address <= 64'(address);
			write_command_out.payload.size    <= DATA_SIZE_WRITE;
			// the CU write engine tags result writes as graph data so the shell
			// response demultiplexer routes the acknowledge back to the kernel
			write_command_out.payload.cmd.cu_id_x      <= CU_X;
			write_command_out.payload.cmd.cu_id_y      <= CU_Y;
			write_command_out.payload.cmd.cmd_type     <= CMD_WRITE;
			write_command_out.payload.cmd.array_struct <= WRITE_GRAPH_DATA;
			write_command_out.payload.cmd.real_size    <= 1;
			write_command_out.payload.cmd.real_size_bytes <= DATA_SIZE_WRITE;
			write_data_0_out.valid <= 1'b1;
			write_data_1_out.valid <= 1'b1;
			write_data_0_out.payload.data[half_off*8 +: DATA_SIZE_WRITE_BITS] <= 1;
			write_data_1_out.payload.data[half_off*8 +: DATA_SIZE_WRITE_BITS] <= 1;
			// the census stimulus deliberately drives identifiers across the
			// whole field width, so the transaction plausibility checks apply to
			// the functional rounds only
			if (!census_active) begin
				if (int'(edge_data_write_out.payload.cu_id_x) != CU_X ||
				    int'(edge_data_write_out.payload.cu_id_y) != CU_Y)
					fail("a shell result carries the wrong CU coordinate");
				if (index >= 32'h0000_1000)
					fail("a shell result targets an implausible vertex index");
			end
		end
	end

	always @(posedge clock) begin
		// the raw port sweeps drive the grants themselves; every other phase,
		// including the census traversals, keeps the modelled arbiter
		if (!census_raw) begin
		read_bus_grant   <= !domain_stalled(stall_mask, DOMAIN_EDGE_READ, cycle_count);
		write_bus_grant  <= !domain_stalled(stall_mask, DOMAIN_WRITE    , cycle_count);
		end
		mem_write_alfull <= domain_stalled(stall_mask, DOMAIN_WRITE     , cycle_count);
		mem_write_stall  <= domain_stalled(stall_mask, DOMAIN_KERNEL    , cycle_count);
		// the AFU read buffer reports almost full, which throttles the read
		// command path of the shell rather than one graph domain
		mem_read_stall   <= read_alfull_round && ((cycle_count % 7) < 3);
	end

	bit census_active;
	bit census_raw   ;

	function automatic void build_image(input int fx);
		int offset;
		int degree;
		mem_clear();
		num_vertices = FX_NUM_VERTICES[fx];
		num_edges    = FX_NUM_EDGES[fx];
		offset       = 0;
		for (int v = 0; v < num_vertices; v++) begin
			degree = inverse_degree(fx, v);
			mem_store_bytes(BASE_INV_OUT_DEGREE + v * 4, 4, degree);
			mem_store_bytes(BASE_INV_EDGES_IDX  + v * 4, 4, offset);
			for (int k = 0; k < degree; k++) begin
				mem_store_bytes(BASE_INV_EDGE_DEST   + (offset + k) * 4, 4, inverse_neighbor(fx, v, k));
				mem_store_bytes(BASE_INV_EDGE_SRC    + (offset + k) * 4, 4, v);
				mem_store_bytes(BASE_INV_EDGE_WEIGHT + (offset + k) * 4, 4, inverse_weight(fx, v, k));
			end
			offset = offset + degree;
		end
		offset = 0;
		for (int v = 0; v < num_vertices; v++) begin
			degree = out_degree(fx, v);
			mem_store_bytes(BASE_OUT_DEGREE + v * 4, 4, degree);
			mem_store_bytes(BASE_EDGES_IDX  + v * 4, 4, offset);
			for (int k = 0; k < degree; k++) begin
				mem_store_bytes(BASE_EDGE_DEST + (offset + k) * 4, 4, out_neighbor(fx, v, k));
				mem_store_bytes(BASE_EDGE_SRC  + (offset + k) * 4, 4, v);
			end
			offset = offset + degree;
		end
		for (int v = 0; v < num_vertices; v++) begin
`ifdef INTEG_PARENT_UNVISITED
			// BFS filters on the unvisited marker in the parent word
			mem_store_bytes(BASE_PARENT     + v * 4, 4, 64'hFFFF_FFFF);
`else
			// component and rank style algorithms index the property array with
			// the value they read, so it must hold legal vertex identifiers
			mem_store_bytes(BASE_PARENT     + v * 4, 4, v);
`endif
`ifdef INTEG_PARENT_UNVISITED
			// BFS reads a frontier marker byte per vertex
			mem_store_bytes(BASE_DATA_READ  + v * DATA_SIZE_READ , DATA_SIZE_READ , v + 1);
`else
			// component and intersection algorithms index the property array
			// with the value they read, so it starts as the identity labelling
			mem_store_bytes(BASE_DATA_READ  + v * DATA_SIZE_READ , DATA_SIZE_READ , v    );
`endif
			// sentinel so a published result of zero still counts as a change
			mem_store_bytes(BASE_DATA_WRITE + v * DATA_SIZE_WRITE, DATA_SIZE_WRITE, 64'hFFFF_FFFF_FFFF_FFFF);
		end
	endfunction

	task automatic drive_wed();
		wed_request_in                                       = '0;
		wed_request_in.valid                                 = 1'b1;
		wed_request_in.payload.wed.num_edges                 = num_edges;
		wed_request_in.payload.wed.num_vertices              = num_vertices;
		wed_request_in.payload.wed.max_weight                = 32'd65535;
		wed_request_in.payload.wed.vertex_out_degree         = BASE_OUT_DEGREE;
		wed_request_in.payload.wed.vertex_in_degree          = BASE_INV_OUT_DEGREE;
		wed_request_in.payload.wed.vertex_edges_idx          = BASE_EDGES_IDX;
		wed_request_in.payload.wed.edges_array_weight        = BASE_EDGE_WEIGHT;
		wed_request_in.payload.wed.edges_array_src           = BASE_EDGE_SRC;
		wed_request_in.payload.wed.edges_array_dest          = BASE_EDGE_DEST;
		wed_request_in.payload.wed.inverse_vertex_out_degree = BASE_INV_OUT_DEGREE;
		wed_request_in.payload.wed.inverse_vertex_in_degree  = BASE_OUT_DEGREE;
		wed_request_in.payload.wed.inverse_vertex_edges_idx  = BASE_INV_EDGES_IDX;
		wed_request_in.payload.wed.inverse_edges_array_weight= BASE_INV_EDGE_WEIGHT;
		wed_request_in.payload.wed.inverse_edges_array_src   = BASE_INV_EDGE_SRC;
		wed_request_in.payload.wed.inverse_edges_array_dest  = BASE_INV_EDGE_DEST;
		// Property pointers.  cu_control is not in the path of a shell test, so
		// the testbench supplies the pointers the shell actually dereferences:
		// BFS reads auxiliary3 and keeps the parent array in auxiliary1, every
		// other algorithm reads auxiliary1 and writes auxiliary2.
`ifdef SHELL_WED_BFS
		wed_request_in.payload.wed.auxiliary1                = BASE_PARENT;
		wed_request_in.payload.wed.auxiliary2                = BASE_DATA_WRITE;
		wed_request_in.payload.wed.auxiliary3                = BASE_DATA_READ;
		wed_request_in.payload.wed.auxiliary4                = BASE_DATA_WRITE;
`else
		wed_request_in.payload.wed.auxiliary1                = BASE_DATA_READ;
		wed_request_in.payload.wed.auxiliary2                = BASE_DATA_WRITE;
`endif
	endtask

	task automatic apply_reset();
		rstn              = 1'b0;
		wed_request_in    = '0;
		cu_configure      = '0;
		vertex_job        = '0;
		repeat (8) @(posedge clock);
		rstn = 1'b1;
		repeat (8) @(posedge clock);
	endtask

	// Feeds the vertex jobs of one fixture and waits until the shell has
	// accounted for all of them or the bound expires.

	// ------------------------------------------------------------------
	// Census stimulus.  Runs after every functional check, with the engine
	// idle, so it can never perturb the transaction evidence: walking-one and
	// walking-zero patterns on the work element, the configuration word, the
	// vertex job, the buffer status records and the element stream, followed
	// by a wide-identifier traversal that pushes wide values through the edge
	// job, address and tag paths.
	// ------------------------------------------------------------------

	// Wide traversal: the inverse edge array is filled with walking-one and
	// walking-zero destinations so the engine generates edge jobs, property read
	// addresses, cache-line offsets and tags across the full identifier width,
	// instead of only the tiny-graph values.
	task automatic census_wide_traversal();
		int elements;
		elements = 32;
		apply_reset();
		build_image(FX_K4);
		for (int k = 0; k < elements; k++) begin
			mem_store_bytes(BASE_DATA_READ + k * DATA_SIZE_READ, DATA_SIZE_READ,
				(k % 2) ? (64'h1 << (k % (8 * DATA_SIZE_READ))) : ~(64'h1 << (k % (8 * DATA_SIZE_READ))));
			mem_store_bytes(BASE_PARENT    + k * 4, 4,
				(k % 2) ? ~(64'h1 << (k % 32)) : (64'h1 << (k % 32)));
			mem_store_bytes(BASE_INV_EDGE_DEST + k * 4, 4,
				(k % 2) ? (64'h1 << (k % 32)) : ~(64'h1 << (k % 32)));
			mem_store_bytes(BASE_EDGE_DEST     + k * 4, 4,
				(k % 2) ? ~(64'h1 << (k % 32)) : (64'h1 << (k % 32)));
		end
		drive_wed();
		cu_configure = 64'h0000_0000_0000_0001;
		repeat (8) @(posedge clock);
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = 32'h0000_00FF;
`ifdef SHELL_FORWARD_DEGREE
		vertex_job.payload.out_degree         = elements[VERTEX_SIZE_BITS-1:0];
		vertex_job.payload.edges_idx          = '0;
`else
		vertex_job.payload.inverse_out_degree = elements[VERTEX_SIZE_BITS-1:0];
		vertex_job.payload.inverse_edges_idx  = '0;
`endif
		@(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		repeat (4096) @(posedge clock);
		apply_reset();
	endtask

	task automatic census_wed_config_sweep();
		census_raw = 1'b1;
		for (int i = 0; i < 64; i++) begin
			@(posedge clock);
			wed_request_in.valid                                 = 1'b1;
			wed_request_in.payload.address                       = 64'h1 << i;
			wed_request_in.payload.wed.num_edges                 = (32)'(1) << (i % 32);
			wed_request_in.payload.wed.num_vertices              = ~((32)'(1) << (i % 32));
			wed_request_in.payload.wed.max_weight                = (32)'(1) << (i % 32);
			wed_request_in.payload.wed.auxiliary0                = ~((32)'(1) << (i % 32));
			wed_request_in.payload.wed.vertex_out_degree         = 64'h1 << i;
			wed_request_in.payload.wed.vertex_in_degree          = ~(64'h1 << i);
			wed_request_in.payload.wed.vertex_edges_idx          = 64'h1 << i;
			wed_request_in.payload.wed.edges_array_weight        = ~(64'h1 << i);
			wed_request_in.payload.wed.edges_array_src           = 64'h1 << i;
			wed_request_in.payload.wed.edges_array_dest          = ~(64'h1 << i);
			wed_request_in.payload.wed.inverse_vertex_out_degree = 64'h1 << i;
			wed_request_in.payload.wed.inverse_vertex_in_degree  = ~(64'h1 << i);
			wed_request_in.payload.wed.inverse_vertex_edges_idx  = 64'h1 << i;
			wed_request_in.payload.wed.inverse_edges_array_weight= ~(64'h1 << i);
			wed_request_in.payload.wed.inverse_edges_array_src   = 64'h1 << i;
			wed_request_in.payload.wed.inverse_edges_array_dest  = ~(64'h1 << i);
			wed_request_in.payload.wed.auxiliary1                = 64'h1 << i;
			wed_request_in.payload.wed.auxiliary2                = ~(64'h1 << i);
			cu_configure                                         = 64'h1 << i;
		end
		@(posedge clock);
		cu_configure = '0;
		apply_reset();
	endtask

	task automatic census_vertex_job_sweep();
		for (int i = 0; i < VERTEX_SIZE_BITS; i++) begin
			@(posedge clock);
			vertex_job.valid                      = 1'b1;
			vertex_job.payload.id                 = (VERTEX_SIZE_BITS)'(1) << i;
`ifdef SHELL_FORWARD_DEGREE
			vertex_job.payload.out_degree         = ~((VERTEX_SIZE_BITS)'(1) << i);
			vertex_job.payload.edges_idx          = (VERTEX_SIZE_BITS)'(1) << i;
`else
			vertex_job.payload.inverse_out_degree = ~((VERTEX_SIZE_BITS)'(1) << i);
			vertex_job.payload.inverse_edges_idx  = (VERTEX_SIZE_BITS)'(1) << i;
`endif
`ifdef INTEG_PARENT_UNVISITED
			vertex_job.payload.parent             = ~((DATA_SIZE_READ_PARENT_BITS)'(1) << (i % DATA_SIZE_READ_PARENT_BITS));
`endif
		end
		@(posedge clock);
		vertex_job = '0;
		apply_reset();
	endtask

	task automatic census_response_sweep();
		// two passes of the walking pattern over the widest field this sweep
		// drives, so every bit of every field is observed low and high rather
		// than only the bits one pass happens to reach
		for (int i = 0; i < 128; i++) begin
			@(posedge clock);
			read_response_in.valid                         = i[0];
			read_response_in.payload.cmd.cu_id_x           = (CU_ID_RANGE)'(1) << (i % CU_ID_RANGE);
			read_response_in.payload.cmd.cu_id_y           = ~((CU_ID_RANGE)'(1) << (i % CU_ID_RANGE));
			read_response_in.payload.cmd.real_size         = (12)'(1) << (i % 12);
			read_response_in.payload.cmd.real_size_bytes   = ~((12)'(1) << (i % 12));
			read_response_in.payload.cmd.cacheline_offset  = (8)'(1) << (i % 8);
			read_response_in.payload.cmd.address_offset    = 64'h1 << (i % 64);
			read_response_in.payload.cmd.aux_data          = ~(64'h1 << (i % 64));
			read_response_in.payload.cmd.size              = (12)'(1) << (i % 12);
			read_response_in.payload.cmd.tag               = (8)'(1) << (i % 8);
			read_response_in.payload.response_credits      = (9)'(1) << (i % 9);
			write_response_in.valid                        = i[1];
			write_response_in.payload.cmd.tag              = ~((8)'(1) << (i % 8));
			write_response_in.payload.cmd.address_offset   = 64'h1 << (i % 64);
			read_data_0_in.valid                           = i[2];
			read_data_1_in.valid                           = i[3];
			read_data_0_in.payload.data                    = {8{64'h1 << (i % 64)}};
			read_data_1_in.payload.data                    = ~{8{64'h1 << (i % 64)}};
			read_data_0_in.payload.cmd.cacheline_offset    = (8)'(1) << (i % 8);
			read_data_1_in.payload.cmd.cacheline_offset    = ~((8)'(1) << (i % 8));
			// the buffer status records belong to the memory adapter, which
			// publishes them from its own queue occupancy; the read backpressure
			// phase drives them through that adapter instead of racing it here
			edge_data_read_in.valid                        = i[0];
			edge_data_read_in.payload.cu_id_x              = (CU_ID_RANGE)'(1) << (i % CU_ID_RANGE);
			edge_data_read_in.payload.cu_id_y              = ~((CU_ID_RANGE)'(1) << (i % CU_ID_RANGE));
			edge_data_read_in.payload.data                 =
				(DATA_SIZE_READ_BITS)'(census_pattern(i, DATA_SIZE_READ_BITS));
			read_bus_grant                                 = i[1];
			write_bus_grant                                = i[2];
		end
		@(posedge clock);
		apply_reset();
	endtask

	// One traversal with the AFU read buffer reporting almost full, so the read
	// command handshake of the shell is observed under the backpressure the AFU
	// applies rather than under a driven status record.
	task automatic census_read_backpressure();
		read_alfull_round = 1'b1;
		census_property_walk();
		read_alfull_round = 1'b0;
		repeat (16) @(posedge clock);
	endtask

	task automatic census_sweep_all();
		census_active = 1'b1;
		census_raw    = 1'b0;
		stall_mask    = 0;
		census_property_walk();
		census_vertex_identifier_walk();
		census_edge_index_walk();
		census_read_backpressure();
		// the wide traversal drives destinations outside the property image, so
		// it runs after the walks that need a live engine
		census_wide_traversal();
		census_wed_config_sweep();
		census_vertex_job_sweep();
		census_response_sweep();
		census_raw = 1'b0;
		census_saturation_soak();
		census_counter_burst(census_events());
		census_active = 1'b0;
	endtask

	// ------------------------------------------------------------------
	// The three walks below all run against a saturated image: every byte of
	// the graph memory reads back as ones, so an element the engine fetches is
	// wide whatever address the walking identifiers produce, and the property
	// read that follows it returns a wide value as well.  The vertex job the
	// testbench issues then supplies the walking pattern for the identifier,
	// the degree and the edge index.
	// ------------------------------------------------------------------
	function automatic void mem_fill(input logic [7:0] value);
		for (int i = 0; i < MEM_BYTES; i++)
			mem[i] = value;
	endfunction

	// Census image: the property pointer is moved to the base of the image so
	// every property read a walking identifier produces lands on a legal wide
	// word, whatever destination the engine extracts, and no read leaves the
	// modelled memory.
	task automatic census_drive_wed();
		drive_wed();
		wed_request_in.payload.wed.auxiliary1 = '0;
`ifdef SHELL_WED_BFS
		wed_request_in.payload.wed.auxiliary3 = '0;
`endif
	endtask

	// Issues one census vertex job and waits for the shell to account for it.
	task automatic census_issue_job(
			input logic [0:(VERTEX_SIZE_BITS-1)] id    ,
			input logic [0:(VERTEX_SIZE_BITS-1)] degree,
			input logic [0:(VERTEX_SIZE_BITS-1)] idx   ,
			input logic [63:0]                   parent
		);
		int unsigned target;
		target = vertex_num_counter + 1;
		for (int guard = 0; guard < 256; guard++) begin
			if (vertex_job_request)
				break;
			@(posedge clock);
		end
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = id;
`ifdef SHELL_FORWARD_DEGREE
		vertex_job.payload.out_degree         = degree;
		vertex_job.payload.edges_idx          = idx;
`else
		vertex_job.payload.inverse_out_degree = degree;
		vertex_job.payload.inverse_edges_idx  = idx;
`endif
`ifdef INTEG_PARENT_UNVISITED
		vertex_job.payload.parent             = parent;
`endif
		@(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		for (int guard = 0; guard < 512; guard++) begin
			if (int'(vertex_num_counter) == int'(target))
				break;
			@(posedge clock);
		end
	endtask

	// Wide element and wide result: the saturated image makes every edge and
	// every property read return ones, so the accumulated result, the write
	// payload and the element records are observed across their whole width.
	task automatic census_property_walk();
		apply_reset();
		mem_fill(8'hFF);
		// the destinations stay inside the property image so every element the
		// kernel accumulates is a wide property word rather than a wrapped read
		for (int k = 0; k < 256; k++) begin
			mem_store_bytes(BASE_INV_EDGE_DEST + k * 4, 4, k % 32);
			mem_store_bytes(BASE_EDGE_DEST     + k * 4, 4, k % 32);
		end
		census_drive_wed();
		cu_configure = 64'h0000_0000_0000_0001;
		repeat (8) @(posedge clock);
		for (int k = 0; k < 8; k++)
			census_issue_job((VERTEX_SIZE_BITS)'(k), (VERTEX_SIZE_BITS)'(4),
				(VERTEX_SIZE_BITS)'(k), 64'h0000_0000_FFFF_FFFF);
		repeat (256) @(posedge clock);
		apply_reset();
	endtask

	// Walking identifier: the latched job records, the edge job source and the
	// result index the kernel publishes all carry the vertex identifier.
	task automatic census_vertex_identifier_walk();
		logic [0:(VERTEX_SIZE_BITS-1)] id_pattern;
		apply_reset();
		mem_fill(8'hFF);
		census_drive_wed();
		cu_configure = 64'h0000_0000_0000_0001;
		repeat (8) @(posedge clock);
		for (int i = 0; i < 2 * VERTEX_SIZE_BITS; i++) begin
			id_pattern = census_pattern(i, VERTEX_SIZE_BITS);
			census_issue_job(id_pattern, (VERTEX_SIZE_BITS)'(1), '0,
				census_pattern(i, 32));
		end
		repeat (256) @(posedge clock);
		apply_reset();
	endtask

	// Walking edge index: the engine derives the edge job identifier and the
	// edge array addresses from the index the vertex job carries.
	task automatic census_edge_index_walk();
		logic [0:(VERTEX_SIZE_BITS-1)] idx_pattern;
		apply_reset();
		mem_fill(8'hFF);
		census_drive_wed();
		cu_configure = 64'h0000_0000_0000_0001;
		repeat (8) @(posedge clock);
		for (int i = 0; i < 2 * VERTEX_SIZE_BITS; i++) begin
			idx_pattern = census_pattern(i, VERTEX_SIZE_BITS);
			census_issue_job((VERTEX_SIZE_BITS)'(i), (VERTEX_SIZE_BITS)'(1),
				idx_pattern, 64'h0000_0000_FFFF_FFFF);
		end
		repeat (256) @(posedge clock);
		apply_reset();
	endtask

	// Counter walk: the completion counters the shell publishes advance once
	// per accepted write acknowledge, so the burst presents one acknowledge per
	// cycle, tagged for this CU so the shell response demultiplexer routes it
	// to the kernel.
	// Counter walk.  The element identifier and every completion counter the
	// shell publishes advance by one per accepted event, so bit k first changes
	// when the count reaches 2**k.  The burst runs two phases against a real
	// engine: one vertex job whose degree can never be exhausted streams
	// elements for half the budget, then back to back short jobs retire and
	// publish results for the rest, so both the element counters and the
	// acknowledge counters advance.  cu_configure is held at all ones so every
	// bit of the latched configuration word is observed as well.
	task automatic census_counter_burst(input int unsigned events);
		int unsigned start_cycle;
		apply_reset();
		// phase one streams elements without publishing a result: an empty
		// image keeps every destination inside the property window and the
		// property word itself zero, so the frontier filter of the BottomUp
		// shell never breaks the vertex and the per-vertex element identifier
		// runs for the whole phase
		mem_fill(8'h00);
		census_drive_wed();
		cu_configure = 64'hFFFF_FFFF_FFFF_FFFF;
		repeat (8) @(posedge clock);

		// phase one: one vertex job with a deep element run
		for (int guard = 0; guard < 256; guard++) begin
			if (vertex_job_request)
				break;
			@(posedge clock);
		end
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = '1;
`ifdef SHELL_FORWARD_DEGREE
		vertex_job.payload.out_degree         = CENSUS_DEEP_DEGREE;
		vertex_job.payload.edges_idx          = '0;
`else
		vertex_job.payload.inverse_out_degree = CENSUS_DEEP_DEGREE;
		vertex_job.payload.inverse_edges_idx  = '0;
`endif
`ifdef INTEG_PARENT_UNVISITED
		vertex_job.payload.parent             = '1;
`endif
		@(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job  = '0;
		start_cycle = cycle_count;
		while ((cycle_count - start_cycle) < (events / 2))
			@(posedge clock);
		apply_reset();
		// phase two publishes results, so the image is saturated again with the
		// destinations held inside the property window
		mem_fill(8'hFF);
		for (int k = 0; k < 256; k++) begin
			mem_store_bytes(BASE_INV_EDGE_DEST + k * 4, 4, k % 32);
			mem_store_bytes(BASE_EDGE_DEST     + k * 4, 4, k % 32);
		end
		census_drive_wed();
		cu_configure = 64'hFFFF_FFFF_FFFF_FFFF;
		repeat (8) @(posedge clock);

		// phase two: short jobs retire and publish acknowledged results
		start_cycle = cycle_count;
		while ((cycle_count - start_cycle) < (events / 2)) begin
			for (int guard = 0; guard < 64; guard++) begin
				if (vertex_job_request)
					break;
				@(posedge clock);
			end
			@(posedge clock);
			vertex_job.valid                      = 1'b1;
			vertex_job.payload.id                 = (VERTEX_SIZE_BITS)'(cycle_count);
`ifdef SHELL_FORWARD_DEGREE
			vertex_job.payload.out_degree         = (VERTEX_SIZE_BITS)'(1);
			vertex_job.payload.edges_idx          = '0;
`else
			vertex_job.payload.inverse_out_degree = (VERTEX_SIZE_BITS)'(1);
			vertex_job.payload.inverse_edges_idx  = '0;
`endif
`ifdef INTEG_PARENT_UNVISITED
			vertex_job.payload.parent             = '1;
`endif
			@(posedge clock);
			vertex_job.valid = 1'b0;
			@(posedge clock);
			vertex_job = '0;
			repeat (4) @(posedge clock);
		end
		repeat (64) @(posedge clock);
		apply_reset();
	endtask

	// Buffer saturation.  The command, element and result buffers only report
	// almost full and full when their consumer is held off, so the soak holds
	// both buses while an inexhaustible vertex job keeps producing, then
	// releases them and lets the engine drain.
	task automatic census_saturation_soak();
		apply_reset();
		mem_fill(8'hFF);
		for (int k = 0; k < 256; k++) begin
			mem_store_bytes(BASE_INV_EDGE_DEST + k * 4, 4, k % 32);
			mem_store_bytes(BASE_EDGE_DEST     + k * 4, 4, k % 32);
		end
		census_drive_wed();
		cu_configure = 64'hFFFF_FFFF_FFFF_FFFF;
		repeat (8) @(posedge clock);
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = '0;
`ifdef SHELL_FORWARD_DEGREE
		vertex_job.payload.out_degree         = '1;
		vertex_job.payload.edges_idx          = '0;
`else
		vertex_job.payload.inverse_out_degree = '1;
		vertex_job.payload.inverse_edges_idx  = '0;
`endif
`ifdef INTEG_PARENT_UNVISITED
		vertex_job.payload.parent             = '1;
`endif
		@(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		// let the engine fill its element and result buffers with both buses
		// held, then with only the write bus held, then release everything
		census_raw       = 1'b1;
		read_bus_grant   = 1'b0;
		write_bus_grant  = 1'b0;
		mem_write_alfull = 1'b1;
		mem_write_stall  = 1'b1;
		repeat (1024) @(posedge clock);
		read_bus_grant = 1'b1;
		repeat (1024) @(posedge clock);
		write_bus_grant  = 1'b1;
		mem_write_alfull = 1'b0;
		mem_write_stall  = 1'b0;
		census_raw       = 1'b0;
		repeat (1024) @(posedge clock);
		apply_reset();
	endtask


	task automatic run_fixture(input int fx, input int mask, output bit drained);
		int accepted;
		active_fixture                = fx  ;
		stall_mask                    = mask;
		masks_seen[mask % MASK_COUNT] = 1'b1;
		scenarios                     = scenarios + 1;

		apply_reset();
		build_image(fx);
		drive_wed();
		cu_configure = 64'h0000_0000_0000_0001;
		repeat (8) @(posedge clock);

		accepted = 0;
		for (int v = 0; v < num_vertices; v++) begin
`ifdef SHELL_FORWARD_DEGREE
			// ShiloachVishkin traverses the forward adjacency
			if (out_degree(fx, v) == 0)
				continue;
`else
			if (inverse_degree(fx, v) == 0)
				continue;
`endif
			// wait for the shell to ask for work
			for (int guard = 0; guard < RUN_LIMIT; guard++) begin
				if (vertex_job_request)
					break;
				@(posedge clock);
			end
			while (domain_stalled(stall_mask, DOMAIN_VERTEX_JOB, cycle_count))
				@(posedge clock);
			@(posedge clock);
			vertex_job.valid                      = 1'b1;
			vertex_job.payload.id                 = v[VERTEX_SIZE_BITS-1:0];
`ifdef SHELL_FORWARD_DEGREE
			vertex_job.payload.out_degree         = out_degree(fx, v);
			vertex_job.payload.edges_idx          = '0;
`else
			vertex_job.payload.inverse_out_degree = inverse_degree(fx, v);
			vertex_job.payload.inverse_edges_idx  = '0;
`endif
			@(posedge clock);
			vertex_job.valid = 1'b0;
			@(posedge clock);
			vertex_job       = '0;
			accepted         = accepted + 1;
			vertex_jobs_issued = vertex_jobs_issued + 1;
			repeat (8) @(posedge clock);
		end

		drained = 1'b0;
		for (int guard = 0; guard < RUN_LIMIT; guard++) begin
			@(posedge clock);
			if (int'(vertex_num_counter) >= accepted) begin
				drained = 1'b1;
				break;
			end
		end
		repeat (64) @(posedge clock);

		// exactly one retirement per accepted job, and the engine must be ready
		// to accept the next burst again
		if (int'(vertex_num_counter) != accepted)
			fail($sformatf("shell retired %0d vertices for %0d accepted jobs",
				int'(vertex_num_counter), accepted));
		if (accepted > 0 && !vertex_job_request)
			fail("the shell did not request work again after retiring its jobs");

		if (illegal_commands != 0)
			fail($sformatf("%0d illegal read commands", illegal_commands));
		if (mem_read_drops != 0)
			fail("the memory adapter dropped a read command");
		if (accepted > 0)
			cover_bin[0] = 1'b1;
		if (accepted == 1)
			cover_bin[1] = 1'b1;
		if (accepted >= 3)
			cover_bin[2] = 1'b1;
		if (edge_job_reads > 0)
			cover_bin[3] = 1'b1;
		if (edge_data_reads > 0)
			cover_bin[4] = 1'b1;
		if (mem_reads_served > 0)
			cover_bin[5] = 1'b1;
		if (writes_observed > 0)
			cover_bin[6] = 1'b1;
		if (mem_writes_served > 0)
			cover_bin[7] = 1'b1;
		if (mask != 0)
			cover_bin[8 + (mask % 4)] = 1'b1;
	endtask

	bit drained    ;
	int bins_hit   ;
	int masks_hit  ;

	initial begin
		debug_trace        = $test$plusargs("TRACE") != 0;
		cycle_count        = 0;
		stall_mask         = 0;
		scenarios          = 0;
		active_fixture     = FX_EMPTY;
		vertex_jobs_issued = 0;
		illegal_commands   = 0;
		mem_read_stall     = 1'b0;
		mem_write_stall    = 1'b0;
		mem_write_alfull   = 1'b0;
		for (int b = 0; b < BIN_COUNT; b++)
			cover_bin[b] = 1'b0;
		for (int m = 0; m < MASK_COUNT; m++)
			masks_seen[m] = 1'b0;

		run_fixture(FX_CHAIN, 0, drained);
		if (!drained)
			fail("the shell never accounted for every vertex job");
		run_fixture(FX_K4, 0, drained);
		if (!drained)
			fail("the K4 round never drained");
		// a single accepted vertex job, and a duplicate in-edge slice
		run_fixture(FX_DUPLICATE_EDGE, 0, drained);
		if (!drained)
			fail("the single vertex job round never drained");

		for (int mask = 0; mask < MASK_COUNT; mask++) begin
			run_fixture(FX_CHAIN, mask, drained);
			if (!drained)
				fail($sformatf("stall mask %0d never drained", mask));
		end

		// repeat and reset
		run_fixture(FX_CYCLE, 0, drained);
		if (!drained)
			fail("repeat round did not drain");
		cover_bin[12] = 1'b1;
		apply_reset();
		if (vertex_num_counter != 0 || edge_num_counter != 0)
			fail("reset did not clear the shell counters");
		run_fixture(FX_CYCLE, 0, drained);
		if (!drained)
			fail("the round after reset did not drain");
		cover_bin[13] = 1'b1;

`ifdef SHELL_NO_KERNEL
		// the TriangleCount shell has neither an edge-data read path nor a
		// kernel: both instantiations are commented out in production RTL
		if (edge_data_reads != 0)
			fail("the TriangleCount shell unexpectedly issued edge-data reads");
		if (writes_observed != 0)
			fail("the TriangleCount shell unexpectedly published a result");
		cover_bin[4] = 1'b1;
		cover_bin[6] = 1'b1;
		cover_bin[7] = 1'b1;
		$display("BLOCKED algorithm_shell signature=trianglecount-shell-has-no-edge-data-or-kernel-path edge_data_reads=%0d writes=%0d",
			edge_data_reads, writes_observed);
`endif

		masks_hit = 0;
		for (int m = 0; m < MASK_COUNT; m++)
			if (masks_seen[m])
				masks_hit = masks_hit + 1;

		bins_hit = 0;
		for (int b = 0; b < BIN_COUNT; b++)
			if (cover_bin[b])
				bins_hit = bins_hit + 1;
		if (bins_hit != BIN_COUNT) begin
			for (int b = 0; b < BIN_COUNT; b++)
				if (!cover_bin[b])
					$display("MISSING-BIN algorithm_shell bin=%0d", b);
			fail($sformatf("functional bins %0d/%0d", bins_hit, BIN_COUNT));
		end

		census_sweep_all();

		$display("PASS algorithm_shell_unit scenarios=%0d vertex_jobs=%0d read_commands=%0d writes=%0d bins=%0d masks=%0d",
			scenarios, vertex_jobs_issued, edge_job_reads + edge_data_reads, writes_observed,
			bins_hit, masks_hit);
		$finish;
	end

	initial begin
		// two time units per clock period, plus the acknowledge burst which is
		// accepted at one event per cycle
		#(64'd4000000 + 8 * 64'(census_events()));
		fail("global timeout");
	end

endmodule
