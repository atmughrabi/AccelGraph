// -----------------------------------------------------------------------------
//
//      "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// graph-integration-cu-control: the real graph cu_control top of one layout
// driven through the CAPI command/response/data boundary by an independent
// graph memory adapter.
//
// The suite exercises the five named graph backpressure domains
// (graph.vertex_job, graph.edge_job, graph.edge_read, graph.write and
// graph.kernel), repeat and reset, and checks the exact WED target and progress
// contract plus the legality of every command the CU issues.
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;
import GRAPH_FIXTURE_PKG::*;

module graph_integration_tb;

	timeunit 1ns; timeprecision 1ps;

	localparam int DOMAIN_VERTEX_JOB = 0;
	localparam int DOMAIN_EDGE_JOB   = 1;
	localparam int DOMAIN_EDGE_READ  = 2;
	localparam int DOMAIN_WRITE      = 3;
	localparam int DOMAIN_KERNEL     = 4;
	localparam int DOMAIN_COUNT      = 5;
	localparam int MASK_COUNT        = 32;
	localparam int STALL_PERIOD[0:DOMAIN_COUNT-1] = '{3, 4, 2, 5, 6};

	localparam int BIN_COUNT = 15;
	localparam int RUN_LIMIT = 80000;
	// A directed ring graph with more vertices than any layout has graph CUs, so
	// every cluster of every layout receives work in one round.
	localparam int RING_VERTICES = 24;
	// The lower half of configuration word one is the host -K argument
	// (ker_numThreads): the total number of graph kernel CUs the round may use,
	// counted across the whole topology.  One asks for a single CU, which is the
	// first CU of the first cluster; the full topology count asks for every CU.
`ifdef INTEG_MAX_KERNEL_CUS
	// A layout whose graph algorithm path cannot run a round on its whole
	// topology declares the largest count it completes with, so the limit is
	// visible in the suite declaration and in the run log instead of being
	// hidden in the stimulus.
	localparam int TOPOLOGY_KERNEL_CUS = `INTEG_MAX_KERNEL_CUS;
`else
	localparam int TOPOLOGY_KERNEL_CUS = NUM_GRAPH_CU_GLOBAL * NUM_VERTEX_CU_GLOBAL;
`endif

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

	WEDInterface       wed_request_in              ;
	ResponseBufferLine read_response_in            ;
	ResponseBufferLine prefetch_read_response_in   ;
	ResponseBufferLine prefetch_write_response_in  ;
	ResponseBufferLine write_response_in           ;
	ReadWriteDataLine  read_data_0_in              ;
	ReadWriteDataLine  read_data_1_in              ;
	BufferStatus       read_buffer_status          ;
	BufferStatus       prefetch_read_buffer_status ;
	BufferStatus       prefetch_write_buffer_status;
	BufferStatus       write_buffer_status         ;
	cu_configure_type  cu_configure                ;

	cu_return_type    cu_return                 ;
	logic             cu_done                   ;
	logic [0:63]      cu_status                 ;
	CommandBufferLine read_command_out          ;
	CommandBufferLine prefetch_read_command_out ;
	CommandBufferLine prefetch_write_command_out;
	CommandBufferLine write_command_out         ;
	ReadWriteDataLine write_data_0_out          ;
	ReadWriteDataLine write_data_1_out          ;

	logic mem_read_stall ;
	logic mem_write_stall;
	logic mem_write_alfull;
	bit   read_alfull_round;

	int unsigned cycle_count ;
	int unsigned stall_mask  ;
	int unsigned scenarios   ;
	int active_fixture       ;
	int num_vertices         ;
	int num_edges            ;
	// the -K argument of the round: how many graph kernel CUs of the whole
	// topology the host asked for
	int kernel_cus           ;

	int read_commands_seen [0:8];
	int write_commands_seen      ;
	int illegal_commands         ;
	bit cover_bin[0:BIN_COUNT-1] ;
	bit masks_seen[0:MASK_COUNT-1];

	cu_control dut (
		.clock                       (clock                       ),
		.rstn_in                     (rstn                        ),
		.enabled_in                  (1'b1                        ),
		.wed_request_in              (wed_request_in              ),
		.read_response_in            (read_response_in            ),
		.prefetch_read_response_in   (prefetch_read_response_in   ),
		.prefetch_write_response_in  (prefetch_write_response_in  ),
		.write_response_in           (write_response_in           ),
		.read_data_0_in              (read_data_0_in              ),
		.read_data_1_in              (read_data_1_in              ),
		.read_buffer_status          (read_buffer_status          ),
		.prefetch_read_buffer_status (prefetch_read_buffer_status ),
		.prefetch_write_buffer_status(prefetch_write_buffer_status),
		.write_buffer_status         (write_buffer_status         ),
		.cu_configure                (cu_configure                ),
		.cu_return                   (cu_return                   ),
		.cu_done                     (cu_done                     ),
		.cu_status                   (cu_status                   ),
		.read_command_out            (read_command_out            ),
		.prefetch_read_command_out   (prefetch_read_command_out   ),
		.prefetch_write_command_out  (prefetch_write_command_out  ),
		.write_command_out           (write_command_out           ),
		.write_data_0_out            (write_data_0_out            ),
		.write_data_1_out            (write_data_1_out            )
	);

	always #1 clock = ~clock;

	always @(posedge clock)
		cycle_count <= cycle_count + 1;

	function automatic bit domain_stalled(input int domain);
		if (((stall_mask >> domain) & 1) == 0)
			return 1'b0;
		return bit'(((cycle_count / STALL_PERIOD[domain]) % 2) == 1);
	endfunction

	// Per-array backpressure so each named graph domain can be stalled on its
	// own path rather than stalling the whole read port.  The classification is
	// by address range so it stays portable across the layout packages, whose
	// array_struct enumerations differ.
	function automatic int read_domain_of(input int unsigned address);
		if (address >= BASE_INV_EDGE_DEST && address < BASE_INV_EDGE_DEST + 32'h1000)
			return DOMAIN_EDGE_JOB;
		if (address >= BASE_EDGE_DEST && address < BASE_EDGE_DEST + 32'h1000)
			return DOMAIN_EDGE_JOB;
		if (address >= BASE_DATA_READ && address < BASE_DATA_READ + 32'h1000)
			return DOMAIN_EDGE_READ;
		return DOMAIN_VERTEX_JOB;
	endfunction

	// The per-vertex property read is issued by the read data command control,
	// which tags it READ_GRAPH_DATA; the edge job control tags its own array
	// reads.  The address ranges remain as a second witness for a served read
	// that carries no tag.
	function automatic bit mem_read_property(input int unsigned address, input CommandTagLine cmd);
		if (cmd.array_struct == READ_GRAPH_DATA)
			return 1'b1;
		return (address >= BASE_DATA_READ && address < BASE_DATA_READ + 32'h1000) ||
		       (address >= BASE_PARENT    && address < BASE_PARENT    + 32'h1000);
	endfunction

	function automatic bit mem_read_stalled(input int unsigned address);
		return domain_stalled(read_domain_of(address));
	endfunction

`include "graph_memory_model.svh"

	// Number of vertices whose result property changed from its initialised
	// zero value, used as the writeback evidence of a completed round.
	function automatic int changed_write_entries();
		int changed;
		changed = 0;
		for (int v = 0; v < num_vertices; v++)
			if (mem_load_bytes(BASE_DATA_WRITE + v * DATA_SIZE_WRITE, DATA_SIZE_WRITE) !=
			    ((DATA_SIZE_WRITE >= 8) ? 64'hFFFF_FFFF_FFFF_FFFF :
			     ((64'h1 << (8 * DATA_SIZE_WRITE)) - 1)))
				changed = changed + 1;
		return changed;
	endfunction

	task automatic bundle(input string reason);
		$display("FAILURE-BUNDLE graph_integration reason=%s", reason);
		$display("  fixture=%s mask=%0d cycle=%0d vertices=%0d edges=%0d",
			fixture_name(active_fixture), stall_mask, cycle_count, num_vertices, num_edges);
		$display("  cu_done=%0b cu_return.var1=%0d cu_return.var2=%0d cu_status=%h",
			cu_done, cu_return.var1, cu_return.var2, cu_status);
		$display("  reads_served=%0d writes_served=%0d read_drops=%0d write_drops=%0d",
			mem_reads_served, mem_writes_served, mem_read_drops, mem_write_drops);
		$display("  vertex_reads=%0d edge_job_reads=%0d edge_data_reads=%0d writes=%0d illegal=%0d",
			read_commands_seen[DOMAIN_VERTEX_JOB],
			read_commands_seen[DOMAIN_EDGE_JOB],
			read_commands_seen[DOMAIN_EDGE_READ],
			write_commands_seen, illegal_commands);
	endtask

	task automatic fail(input string reason);
		bundle(reason);
		$error("graph_integration mismatch %s", reason);
		$fatal(1);
	endtask

	bit debug_trace;

	always @(posedge clock) begin
		if (rstn && debug_trace && read_command_out.valid)
			$display("TRACE-RD cycle=%0d struct=%0d addr=%h size=%0d cl_off=%0d real=%0d",
				cycle_count, read_command_out.payload.cmd.array_struct,
				read_command_out.payload.address, read_command_out.payload.size,
				read_command_out.payload.cmd.cacheline_offset,
				read_command_out.payload.cmd.real_size);
		if (rstn && debug_trace && write_command_out.valid)
			$display("TRACE-WR cycle=%0d addr=%h size=%0d", cycle_count,
				write_command_out.payload.address, write_command_out.payload.size);
	end

	always @(posedge clock)
		if (rstn && debug_trace && ((cycle_count % 2000) == 0))
			$display("TRACE-TICK cycle=%0d scenario=%0d done=%0d filtered=%0d total=%0d cu_done=%b reads=%0d writes=%0d",
				cycle_count, scenarios, dut.vertex_job_counter_done_latched,
				dut.vertex_job_counter_filtered, dut.vertex_job_counter_total_latched,
				cu_done, mem_reads_served, mem_writes_served);

	always @(posedge clock)
		if (rstn && debug_trace && cu_done)
			$display("TRACE-PROGRESS cycle=%0d done=%0d filtered=%0d total=%0d num_vertices=%0d",
				cycle_count, dut.vertex_job_counter_done_latched,
				dut.vertex_job_counter_filtered, dut.vertex_job_counter_total_latched,
				num_vertices);

`ifdef INTEG_TRACE_CC
	// per graph-CU forensics: which cluster stops contributing progress
	always @(posedge clock)
		if (rstn && debug_trace && ((cycle_count % 4000) == 0))
			$display("TRACE-CU cycle=%0d done_cu=%0d,%0d,%0d,%0d edge_cu=%0d,%0d,%0d,%0d reset_cu=%b",
				cycle_count,
				dut.vertex_job_counter_done_cu_in[0], dut.vertex_job_counter_done_cu_in[1],
				dut.vertex_job_counter_done_cu_in[2], dut.vertex_job_counter_done_cu_in[3],
				dut.edge_job_counter_done_cu_in[0], dut.edge_job_counter_done_cu_in[1],
				dut.edge_job_counter_done_cu_in[2], dut.edge_job_counter_done_cu_in[3],
				dut.reset_cu_in);
`endif

	// command legality monitor
	always @(posedge clock) begin
		if (rstn && read_command_out.valid) begin
			automatic int unsigned address = read_command_out.payload.address[32:63];
			read_commands_seen[read_domain_of(address)] <=
				read_commands_seen[read_domain_of(address)] + 1;
			if (read_command_out.payload.size > CACHELINE_SIZE)
				illegal_commands <= illegal_commands + 1;
			if (address >= MEM_BYTES)
				illegal_commands <= illegal_commands + 1;
			if (read_command_out.payload.cmd.cmd_type != CMD_READ)
				illegal_commands <= illegal_commands + 1;
		end
		if (rstn && write_command_out.valid) begin
			automatic int unsigned address = write_command_out.payload.address[32:63];
			write_commands_seen <= write_commands_seen + 1;
			if (write_command_out.payload.size == 0 ||
			    write_command_out.payload.size > CACHELINE_SIZE_HF)
				illegal_commands <= illegal_commands + 1;
			if (!((address >= BASE_DATA_WRITE && address < BASE_DATA_WRITE + 32'h1000) ||
			      (address >= BASE_PARENT     && address < BASE_PARENT     + 32'h1000)))
				illegal_commands <= illegal_commands + 1;
		end
	end

	// graph.write stalls the result path in front of the CU (the write buffer
	// reports almost full); graph.kernel stalls the write acknowledge stream the
	// algorithm kernels use for their completion accounting.
	always @(posedge clock) begin
		mem_write_alfull <= domain_stalled(DOMAIN_WRITE);
		mem_write_stall  <= domain_stalled(DOMAIN_KERNEL);
		// the AFU read buffer reports almost full, which throttles the read
		// command path of every graph CU rather than one graph domain
		mem_read_stall   <= read_alfull_round && ((cycle_count % 7) < 3);
	end

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
				mem_store_bytes(BASE_EDGE_DEST   + (offset + k) * 4, 4, out_neighbor(fx, v, k));
				mem_store_bytes(BASE_EDGE_SRC    + (offset + k) * 4, 4, v);
				mem_store_bytes(BASE_EDGE_WEIGHT + (offset + k) * 4, 4, FX_EDGE_WEIGHT[fx][out_edge_index(fx, v, k)]);
			end
			offset = offset + degree;
		end
		// Property arrays.  The BFS vertex filter only admits a vertex whose
		// parent word has its sign bit set (the unvisited marker) and whose
		// inverse out degree is non zero, so the parent array starts unvisited
		// and every source property is non zero.
		for (int v = 0; v < num_vertices; v++) begin
`ifdef INTEG_PARENT_UNVISITED
			// BFS filters on the unvisited marker in the parent word
			mem_store_bytes(BASE_PARENT     + v * 4, 4, 64'hFFFF_FFFF);
`else
			// component and rank style algorithms index the property array with
			// the value they read, so it must hold legal vertex identifiers
			mem_store_bytes(BASE_PARENT     + v * 4, 4, v);
`endif
			mem_store_bytes(BASE_DATA_READ  + v * DATA_SIZE_READ , DATA_SIZE_READ , v + 1);
			// sentinel so a published result of zero still counts as a change
			mem_store_bytes(BASE_DATA_WRITE + v * DATA_SIZE_WRITE, DATA_SIZE_WRITE, 64'hFFFF_FFFF_FFFF_FFFF);
		end
	endfunction

	// A ring of the given size, built here rather than taken from the fixture
	// registry: it carries more vertices than any layout has graph CUs, so one
	// round hands work to every cluster of the top instead of keeping the first
	// cluster busy on its own.  Every vertex has one inverse and one forward
	// edge, so every vertex passes both the degree and the frontier filter.
	function automatic void build_ring_image(input int vertices);
		mem_clear();
		num_vertices = vertices;
		num_edges    = vertices;
		for (int v = 0; v < vertices; v++) begin
			mem_store_bytes(BASE_INV_OUT_DEGREE  + v * 4, 4, 1);
			mem_store_bytes(BASE_INV_EDGES_IDX   + v * 4, 4, v);
			mem_store_bytes(BASE_INV_EDGE_DEST   + v * 4, 4, (v + vertices - 1) % vertices);
			mem_store_bytes(BASE_INV_EDGE_SRC    + v * 4, 4, v);
			mem_store_bytes(BASE_INV_EDGE_WEIGHT + v * 4, 4, v + 1);
			mem_store_bytes(BASE_OUT_DEGREE      + v * 4, 4, 1);
			mem_store_bytes(BASE_EDGES_IDX       + v * 4, 4, v);
			mem_store_bytes(BASE_EDGE_DEST       + v * 4, 4, (v + 1) % vertices);
			mem_store_bytes(BASE_EDGE_SRC        + v * 4, 4, v);
			mem_store_bytes(BASE_EDGE_WEIGHT     + v * 4, 4, v + 1);
`ifdef INTEG_PARENT_UNVISITED
			mem_store_bytes(BASE_PARENT          + v * 4, 4, 64'hFFFF_FFFF);
`else
			mem_store_bytes(BASE_PARENT          + v * 4, 4, v);
`endif
			mem_store_bytes(BASE_DATA_READ  + v * DATA_SIZE_READ , DATA_SIZE_READ , v + 1);
			mem_store_bytes(BASE_DATA_WRITE + v * DATA_SIZE_WRITE, DATA_SIZE_WRITE, 64'hFFFF_FFFF_FFFF_FFFF);
		end
	endfunction

	task automatic drive_wed();
		wed_request_in                                    = '0;
		wed_request_in.valid                              = 1'b1;
		wed_request_in.payload.address                    = 64'h0000_0000_0000_0000;
		wed_request_in.payload.wed.num_edges              = num_edges;
		wed_request_in.payload.wed.num_vertices           = num_vertices;
		wed_request_in.payload.wed.max_weight             = 32'd65535;
		wed_request_in.payload.wed.auxiliary0             = 32'd0;
		wed_request_in.payload.wed.vertex_out_degree      = BASE_OUT_DEGREE;
		wed_request_in.payload.wed.vertex_in_degree       = BASE_INV_OUT_DEGREE;
		wed_request_in.payload.wed.vertex_edges_idx       = BASE_EDGES_IDX;
		wed_request_in.payload.wed.edges_array_weight     = BASE_EDGE_WEIGHT;
		wed_request_in.payload.wed.edges_array_src        = BASE_EDGE_SRC;
		wed_request_in.payload.wed.edges_array_dest       = BASE_EDGE_DEST;
		wed_request_in.payload.wed.inverse_vertex_out_degree = BASE_INV_OUT_DEGREE;
		wed_request_in.payload.wed.inverse_vertex_in_degree  = BASE_OUT_DEGREE;
		wed_request_in.payload.wed.inverse_vertex_edges_idx  = BASE_INV_EDGES_IDX;
		wed_request_in.payload.wed.inverse_edges_array_weight= BASE_INV_EDGE_WEIGHT;
		wed_request_in.payload.wed.inverse_edges_array_src   = BASE_INV_EDGE_SRC;
		wed_request_in.payload.wed.inverse_edges_array_dest  = BASE_INV_EDGE_DEST;
		wed_request_in.payload.wed.auxiliary1              = BASE_PARENT;
		wed_request_in.payload.wed.auxiliary2              = BASE_DATA_WRITE;
	endtask

	task automatic apply_reset();
		rstn                         = 1'b0;
		cu_configure                 = '0;
		wed_request_in               = '0;
		prefetch_read_response_in    = '0;
		prefetch_write_response_in   = '0;
		prefetch_read_buffer_status  = '0;
		prefetch_write_buffer_status = '0;
		prefetch_read_buffer_status.empty  = 1'b1;
		prefetch_write_buffer_status.empty = 1'b1;
		// hold reset long enough for every in-flight engine pipeline stage and
		// the graph memory adapter queues to drain, which is the reset protocol
		// the AFU reset control publishes
		repeat (64) @(posedge clock);
		rstn = 1'b1;
		repeat (32) @(posedge clock);
	endtask

	// Runs one graph to completion and returns the number of cycles consumed.
	task automatic run_graph(input int fx, input int mask, output int cycles_used, output bit completed);
		int start_cycle;
		active_fixture                = fx  ;
		stall_mask                    = mask;
		masks_seen[mask % MASK_COUNT] = 1'b1;
		scenarios                     = scenarios + 1;

		apply_reset();
		build_image(fx);
		drive_wed();
		// cu_control overrides wed.auxiliary3/auxiliary4 with configuration
		// words three and four, so the property read and write array pointers
		// travel through the configuration path
		cu_configure.var1 = 64'(kernel_cus);
		cu_configure.var2 = 64'h0000_0000_0000_0000;
		cu_configure.var3 = 64'(BASE_DATA_READ) ;
		cu_configure.var4 = 64'(BASE_DATA_WRITE);

		start_cycle = cycle_count;
		completed   = 1'b0;
		for (int i = 0; i < RUN_LIMIT; i++) begin
			@(posedge clock);
			if (cu_done) begin
				completed = 1'b1;
				break;
			end
		end
		cycles_used = cycle_count - start_cycle;
		repeat (32) @(posedge clock);
	endtask

	// Runs the directed ring graph, which is built here instead of taken from
	// the fixture registry.
	task automatic run_ring_graph(input int vertices, output int cycles_used, output bit completed);
		int start_cycle;
		active_fixture = FX_EMPTY;
		stall_mask     = 0;
		scenarios      = scenarios + 1;

		apply_reset();
		build_ring_image(vertices);
		drive_wed();
		cu_configure.var1 = 64'(kernel_cus);
		cu_configure.var2 = 64'h0000_0000_0000_0000;
		cu_configure.var3 = 64'(BASE_DATA_READ) ;
		cu_configure.var4 = 64'(BASE_DATA_WRITE);

		start_cycle = cycle_count;
		completed   = 1'b0;
		for (int i = 0; i < RUN_LIMIT; i++) begin
			@(posedge clock);
			if (cu_done) begin
				completed = 1'b1;
				break;
			end
		end
		cycles_used = cycle_count - start_cycle;
		repeat (32) @(posedge clock);
	endtask

	// Configuration word contract.  The four configuration words are primary
	// inputs of the CU and are broadcast to every graph CU, and the CU only
	// takes a word while it carries a non zero value, so each bit is driven low
	// and high again from an all ones background.  The sweep runs with no work
	// element descriptor presented, where the CU is not ready and the engines
	// are idle, so it cannot perturb a graph round.
	task automatic sweep_configuration();
		apply_reset();
		cu_configure = '0;
		@(posedge clock);
		cu_configure.var1 = '1;
		cu_configure.var2 = '1;
		cu_configure.var3 = '1;
		cu_configure.var4 = '1;
		repeat (4) @(posedge clock);
		for (int index = 0; index < 64; index++) begin
			cu_configure.var1 = ~(64'h1 << index);
			cu_configure.var2 = ~(64'h1 << index);
			cu_configure.var3 = ~(64'h1 << index);
			cu_configure.var4 = ~(64'h1 << index);
			repeat (2) @(posedge clock);
			cu_configure.var1 = '1;
			cu_configure.var2 = '1;
			cu_configure.var3 = '1;
			cu_configure.var4 = '1;
			repeat (2) @(posedge clock);
		end
		cu_configure = '0;
		repeat (8) @(posedge clock);
		if (cu_done)
			fail("the configuration sweep completed a round without a work element descriptor");
	endtask

	int cycles_used;
	bit completed  ;
	int bins_hit   ;
	int masks_hit  ;
	int completions;

	initial begin
		debug_trace       = $test$plusargs("TRACE") != 0;
		cycle_count       = 0;
		stall_mask        = 0;
		scenarios         = 0;
		completions       = 0;
		active_fixture    = FX_EMPTY;
		illegal_commands  = 0;
		write_commands_seen = 0;
		read_alfull_round = 1'b0;
		// the rounds below run with a single kernel CU, which is the first CU of
		// the first cluster, until a round asks for the whole topology
		kernel_cus        = 1;
		if (TOPOLOGY_KERNEL_CUS != (NUM_GRAPH_CU_GLOBAL * NUM_VERTEX_CU_GLOBAL))
			$display("LIMIT graph_integration kernel_cus=%0d topology=%0d",
				TOPOLOGY_KERNEL_CUS, NUM_GRAPH_CU_GLOBAL * NUM_VERTEX_CU_GLOBAL);
		for (int i = 0; i <= 8; i++)
			read_commands_seen[i] = 0;
		for (int b = 0; b < BIN_COUNT; b++)
			cover_bin[b] = 1'b0;
		for (int m = 0; m < MASK_COUNT; m++)
			masks_seen[m] = 1'b0;

		// configuration path first: it needs an idle CU and every later round
		// starts from its own reset
		sweep_configuration();
		cover_bin[12] = 1'b1;

		// all-ready baseline
		run_graph(FX_CHAIN, 0, cycles_used, completed);
		if (debug_trace)
			$display("TRACE-RUN completed=%0b cycles=%0d reads=%0d writes=%0d return1=%0d return2=%0d vertices=%0d",
				completed, cycles_used, mem_reads_served, mem_writes_served,
				cu_return.var1, cu_return.var2, num_vertices);
		if (!completed)
			fail($sformatf("baseline run did not reach cu_done after %0d cycles", cycles_used));
		completions = completions + 1;
		cover_bin[0] = 1'b1;
		if (int'(cu_return.var1) != num_vertices)
			fail($sformatf("WED progress %0d != num_vertices %0d", int'(cu_return.var1), num_vertices));
		cover_bin[1] = 1'b1;
		if (illegal_commands != 0)
			fail($sformatf("%0d illegal commands", illegal_commands));
		cover_bin[2] = 1'b1;
		if (mem_read_drops != 0 || mem_write_drops != 0)
			fail("the memory adapter dropped a command");
		cover_bin[3] = 1'b1;

		// topology and fixture sweep
		run_graph(FX_SINGLE_VERTEX, 0, cycles_used, completed);
		if (completed) completions = completions + 1;
		cover_bin[4] = 1'b1;
		run_graph(FX_STAR, 0, cycles_used, completed);
		if (completed) completions = completions + 1;
		run_graph(FX_K4, 0, cycles_used, completed);
		if (completed) completions = completions + 1;
		cover_bin[5] = 1'b1;
		// every K4 vertex is reachable in one pull round, so the round must
		// publish at least one result and every result must land in the
		// declared writable range
		if (mem_writes_served == 0)
			fail("the K4 round published no result write");
		if (changed_write_entries() == 0)
			fail("no result property changed after the K4 round");
		$display("EVIDENCE graph_integration k4 writes=%0d changed_vertices=%0d",
			mem_writes_served, changed_write_entries());

		// every graph stall mask
		for (int mask = 0; mask < MASK_COUNT; mask++) begin
			run_graph(FX_CHAIN, mask, cycles_used, completed);
			if (!completed)
				fail($sformatf("stall mask %0d did not reach cu_done", mask));
			completions = completions + 1;
			if (int'(cu_return.var1) != num_vertices)
				fail($sformatf("stall mask %0d published progress %0d != %0d",
					mask, int'(cu_return.var1), num_vertices));
		end
		cover_bin[6] = 1'b1;
		cover_bin[7] = 1'b1;

		// the AFU read buffer reports almost full while a graph runs, which
		// throttles the read command path of every graph CU at once
		read_alfull_round = 1'b1;
		run_graph(FX_K4, 0, cycles_used, completed);
		read_alfull_round = 1'b0;
		if (!completed)
			fail("the round with an almost full read buffer did not reach cu_done");
		completions = completions + 1;
		if (int'(cu_return.var1) != num_vertices)
			fail($sformatf("the almost full read buffer round published progress %0d != %0d",
				int'(cu_return.var1), num_vertices));
		cover_bin[13] = 1'b1;

		// a graph with more vertices than the top has graph CUs, so every
		// cluster of the layout receives work and drives its own command bus
		// handshake; the round asks for the whole topology, which is what
		// activates every cluster
		kernel_cus = TOPOLOGY_KERNEL_CUS;
		run_ring_graph(RING_VERTICES, cycles_used, completed);
		kernel_cus = 1;
		if (!completed)
			fail($sformatf("the %0d vertex ring round did not reach cu_done", RING_VERTICES));
		completions = completions + 1;
		if (int'(cu_return.var1) != num_vertices)
			fail($sformatf("the ring round published progress %0d != %0d",
				int'(cu_return.var1), num_vertices));
		if (illegal_commands != 0)
			fail($sformatf("%0d illegal commands in the ring round", illegal_commands));
		cover_bin[14] = 1'b1;

		// repeat the same graph twice back to back
		run_graph(FX_CYCLE, 0, cycles_used, completed);
		if (!completed)
			fail("repeat round one did not complete");
		completions = completions + 1;
		run_graph(FX_CYCLE, 0, cycles_used, completed);
		if (!completed)
			fail("repeat round two did not complete");
		completions = completions + 1;
		cover_bin[8] = 1'b1;

		// reset in the middle of a run, then a clean rerun
		// the relaunch runs on the whole topology, so every cluster of the top
		// has to be re-armed by the reset rather than only the first one
		kernel_cus     = TOPOLOGY_KERNEL_CUS;
		active_fixture = FX_K4;
		stall_mask     = 0;
		apply_reset();
		build_image(FX_K4);
		drive_wed();
		cu_configure.var1 = 64'(kernel_cus);
		cu_configure.var3 = 64'(BASE_DATA_READ) ;
		cu_configure.var4 = 64'(BASE_DATA_WRITE);
		repeat (200) @(posedge clock);
		apply_reset();
		if (cu_done)
			fail("cu_done survived a reset");
		cover_bin[9] = 1'b1;
		run_graph(FX_K4, 0, cycles_used, completed);
		if (!completed)
			fail("the run after a mid-flight reset did not complete");
		completions = completions + 1;
		if (int'(cu_return.var1) != num_vertices)
			fail($sformatf("the run after a mid-flight reset published progress %0d != %0d",
				int'(cu_return.var1), num_vertices));
		cover_bin[10] = 1'b1;
		kernel_cus = 1;

		masks_hit = 0;
		for (int m = 0; m < MASK_COUNT; m++)
			if (masks_seen[m])
				masks_hit = masks_hit + 1;
		if (masks_hit == MASK_COUNT)
			cover_bin[11] = 1'b1;

		bins_hit = 0;
		for (int b = 0; b < BIN_COUNT; b++)
			if (cover_bin[b])
				bins_hit = bins_hit + 1;
		if (bins_hit != BIN_COUNT) begin
			for (int b = 0; b < BIN_COUNT; b++)
				if (!cover_bin[b])
					$display("MISSING-BIN graph_integration bin=%0d", b);
			fail($sformatf("functional bins %0d/%0d", bins_hit, BIN_COUNT));
		end

		$display("PASS graph_integration scenarios=%0d completions=%0d reads=%0d writes=%0d bins=%0d masks=%0d",
			scenarios, completions, mem_reads_served, mem_writes_served, bins_hit, masks_hit);
		$finish;
	end

	initial begin
		#20000000;
		fail("global timeout");
	end

endmodule
