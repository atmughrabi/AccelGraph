// -----------------------------------------------------------------------------
//
//      "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// graph-unit-bfs-kernel: cu_BFS/CSR/PULL/BottomUp cu_update_kernel_control.
//
// Oracle: independent-bfs-v1.  The expected update stream is derived from the
// hand authored source edge list in GRAPH_FIXTURE_PKG and the bottom-up BFS
// contract (a vertex adopts the first in-neighbour that is on the frontier,
// sets its frontier byte, and records that neighbour as the parent), never
// from production code.
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;
import GRAPH_FIXTURE_PKG::*;
import ALGO_CHECK_PKG::*;

module bfs_kernel_tb;

	timeunit 1ns; timeprecision 1ps;

	// all-ones CU coordinates so every identifier bit the kernel copies from
	// its parameters is observed changing at least once
	localparam int CU_X       = 8'hFF;
	localparam int CU_Y       = 8'hFF;
	localparam int BREAK_HOLD = 5;
	localparam int MAX_EXPECT = 512;
	localparam int RESP_DELAY = 3;
	localparam int BIN_COUNT  = 19;

	// Census event budget.  Every completion counter in the kernel advances by
	// one per accepted write acknowledge, so bit k of a counter first changes
	// when the count reaches 2**k.  The census therefore walks the counters
	// with an explicit event burst whose length is a crossing point, not a
	// percentage: 2**24 accepted acknowledges observe counter bits 0 to 24.
	// +CENSUS_BURST=<n> changes it for a measurement run.
	localparam int unsigned CENSUS_BURST_DEFAULT = 32'h0100_0000;

	function automatic int unsigned census_events();
		int unsigned events;
		events = CENSUS_BURST_DEFAULT;
		void'($value$plusargs("CENSUS_BURST=%d", events));
		return events;
	endfunction

	localparam int PAT_NONE  = 0;
	localparam int PAT_ALL   = 1;
	localparam int PAT_FIRST = 2;
	localparam int PAT_LAST  = 3;
	localparam int PAT_LEVEL  = 4;
	localparam int PAT_MIDDLE = 5;

	logic clock = 1'b0;
	logic rstn  = 1'b0;

	ResponseBufferLine write_response_in  ;
	BufferStatus       write_buffer_status;
	EdgeDataRead       edge_data          ;
	BufferStatus       data_buffer_status ;
	logic              write_bus_grant    ;
	logic              write_bus_request  ;
	logic              edge_data_request  ;
	EdgeDataWrite      edge_data_write_out;
	VertexInterface    vertex_job         ;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_resp;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum;
	logic                          break_S_out            ;

	int unsigned cycle_count;
	int unsigned stall_mask ;
	int unsigned vectors    ;
	int unsigned scenarios  ;

	// scoreboard
	int exp_index[0:MAX_EXPECT-1];
	int exp_data1[0:MAX_EXPECT-1];
	int exp_data2[0:MAX_EXPECT-1];
	int exp_count;
	int obs_count;
	int completions_expected;
	int obs_at_reset        ;
	int responses_sent      ;

	bit cover_bin[0:BIN_COUNT-1];
	bit masks_seen[0:MASK_COUNT-1];

	int break_count;
	bit visited[0:FX_MAX_VERTICES-1];
	int active_fixture;

	logic [0:3] resp_pipe;

	// census overrides: let the census tasks drive the buffer status, hold the
	// write bus, and inject write acknowledges directly
	bit          census_drive_status ;
	BufferStatus census_write_status ;
	bit          census_hold_grant   ;
	bit          census_drive_response;

	cu_update_kernel_control #(
		.CU_ID_X   (CU_X      ),
		.CU_ID_Y   (CU_Y      ),
		.BREAK_HOLD(BREAK_HOLD)
	) dut (
		.clock                      (clock                  ),
		.rstn_in                    (rstn                   ),
		.enabled_in                 (1'b1                   ),
		.write_response_in          (write_response_in      ),
		.write_buffer_status        (write_buffer_status    ),
		.edge_data                  (edge_data              ),
		.data_buffer_status         (data_buffer_status     ),
		.edge_data_write_bus_grant  (write_bus_grant        ),
		.edge_data_write_bus_request(write_bus_request      ),
		.edge_data_request          (edge_data_request      ),
		.edge_data_write_out        (edge_data_write_out    ),
		.vertex_job                 (vertex_job             ),
		.vertex_num_counter_resp_out(vertex_num_counter_resp),
		.edge_data_counter_accum_out(edge_data_counter_accum),
		.break_S_out                (break_S_out            )
	);

	always #1 clock = ~clock;

	always @(posedge clock)
		cycle_count <= cycle_count + 1;

////////////////////////////////////////////////////////////////////////////
// failure bundle
////////////////////////////////////////////////////////////////////////////

	task automatic bundle(input string reason);
		$display("FAILURE-BUNDLE bfs_kernel reason=%s", reason);
		$display("  fixture=%s mask=%0d cycle=%0d", fixture_name(active_fixture), stall_mask, cycle_count);
		$display("  expected_writes=%0d observed_writes=%0d", exp_count, obs_count);
		$display("  completions_expected=%0d vertex_num_counter_resp=%0d edge_data_counter_accum=%0d",
			completions_expected, vertex_num_counter_resp, edge_data_counter_accum);
		$display("  write_bus_request=%0b edge_data_request=%0b break_S_out=%0b",
			write_bus_request, edge_data_request, break_S_out);
	endtask

	task automatic fail(input string reason);
		bundle(reason);
		$error("bfs_kernel mismatch %s", reason);
		$fatal(1);
	endtask

////////////////////////////////////////////////////////////////////////////
// write bus / write response service
////////////////////////////////////////////////////////////////////////////

	always @(posedge clock) begin
		if (!rstn) begin
			resp_pipe         <= '0;
			write_response_in <= '0;
			responses_sent    <= 0;
		end else begin
			resp_pipe               <= {1'b0, resp_pipe[0:2]};
			write_response_in.valid <= resp_pipe[3] || census_drive_response;
			if (edge_data_write_out.valid) begin
				resp_pipe[0]   <= 1'b1;
				responses_sent <= responses_sent + 1;
				if (obs_count >= exp_count)
					fail($sformatf("unexpected write index=%0d", edge_data_write_out.payload.index));
				else begin
					if (int'(edge_data_write_out.payload.index) != exp_index[obs_count])
						fail($sformatf("write index %0d != %0d at write %0d",
							int'(edge_data_write_out.payload.index), exp_index[obs_count], obs_count));
					if (int'(edge_data_write_out.payload.data_1) != exp_data1[obs_count])
						fail($sformatf("write frontier %0d != %0d at write %0d",
							int'(edge_data_write_out.payload.data_1), exp_data1[obs_count], obs_count));
					if (int'(edge_data_write_out.payload.data_2) != exp_data2[obs_count])
						fail($sformatf("write parent %0d != %0d at write %0d",
							int'(edge_data_write_out.payload.data_2), exp_data2[obs_count], obs_count));
					if (int'(edge_data_write_out.payload.cu_id_x) != CU_X ||
					    int'(edge_data_write_out.payload.cu_id_y) != CU_Y)
						fail("write carries the wrong CU coordinate");
					obs_count <= obs_count + 1;
				end
			end
		end
	end

	// The write bus grant and the downstream write-buffer almost-full flag are
	// the graph.write and graph.kernel backpressure domains.
	always @(posedge clock) begin
		write_bus_grant <= !census_hold_grant &&
			!domain_stalled(stall_mask, DOMAIN_WRITE, cycle_count);
		if (census_drive_status) begin
			write_buffer_status <= census_write_status;
		end else begin
			write_buffer_status.alfull <= domain_stalled(stall_mask, DOMAIN_KERNEL, cycle_count);
			write_buffer_status.full   <= 1'b0;
			write_buffer_status.empty  <= 1'b1;
			write_buffer_status.valid  <= 1'b0;
		end
	end

	always @(posedge clock)
		if (rstn && break_S_out)
			break_count <= break_count + 1;

////////////////////////////////////////////////////////////////////////////
// stimulus helpers
////////////////////////////////////////////////////////////////////////////

	function automatic bit visited_of(input int pattern, input int fx, input int v, input int level, input int root);
		case (pattern)
			PAT_NONE  : return 1'b0;
			PAT_ALL   : return 1'b1;
			PAT_FIRST : return bit'(v == 0);
			PAT_LAST  : return bit'(v == FX_NUM_VERTICES[fx] - 1);
			PAT_LEVEL : return bit'(bfs_distance(fx, root, v) == level);
			PAT_MIDDLE: return bit'(v == 2);
			default   : return 1'b0;
		endcase
	endfunction

	task automatic apply_reset();
		rstn              = 1'b0;
		vertex_job        = '0;
		edge_data         = '0;
		data_buffer_status       = '0;
		data_buffer_status.empty = 1'b1;
		repeat (4) @(posedge clock);
		rstn = 1'b1;
		repeat (4) @(posedge clock);
		obs_at_reset = obs_count;
	endtask

	task automatic stall_gap(input int domain);
		while (domain_stalled(stall_mask, domain, cycle_count))
			@(posedge clock);
	endtask

	// Streams one vertex job and its inverse-CSR edge slice.  `trailing`
	// injects one extra in-flight edge inside the documented BREAK_HOLD window
	// after the break to prove the hold suppresses duplicate updates.
	task automatic drive_vertex(input int fx, input int v, input bit trailing);
		int deg;
		int nb ;
		int k  ;
		bit hit;
		int break_base;
		deg = inverse_degree(fx, v);
		hit = 1'b0;

		if (deg == 0)
			cover_bin[0] = 1'b1;
		else if (deg == 1)
			cover_bin[1] = 1'b1;
		else
			cover_bin[2] = 1'b1;

		// independent golden: first frontier in-neighbour wins
		for (k = 0; k < deg; k++) begin
			nb = inverse_neighbor(fx, v, k);
			if (!hit && visited[nb]) begin
				if (exp_count >= MAX_EXPECT)
					fail("expected-write storage exhausted");
				exp_index[exp_count] = v ;
				exp_data1[exp_count] = 1 ;
				exp_data2[exp_count] = nb;
				exp_count            = exp_count + 1;
				hit                  = 1'b1;
				if (k == 0)
					cover_bin[3] = 1'b1;
				else if (k == deg - 1)
					cover_bin[5] = 1'b1;
				else
					cover_bin[4] = 1'b1;
				if (nb == v)
					cover_bin[7] = 1'b1;
			end
		end
		if (!hit)
			cover_bin[6] = 1'b1;
		if (deg >= 2 && inverse_neighbor(fx, v, 0) == inverse_neighbor(fx, v, 1))
			cover_bin[8] = 1'b1;
		completions_expected = completions_expected + 1;

		break_base = break_count;
		stall_gap(DOMAIN_VERTEX_JOB);
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = v[VERTEX_SIZE_BITS-1:0];
		vertex_job.payload.inverse_out_degree = deg[VERTEX_SIZE_BITS-1:0];
		vertex_job.payload.inverse_edges_idx  = inverse_edge_index(fx, v, 0) < 0 ?
			'0 : inverse_edge_index(fx, v, 0);
		vertex_job.payload.parent             = '0;
		@(posedge clock);

		data_buffer_status.empty = (deg == 0);
		for (k = 0; k < deg; k++) begin
			if (break_count != break_base)
				break;
			nb = inverse_neighbor(fx, v, k);
			stall_gap(DOMAIN_EDGE_READ);
			edge_data.valid                = 1'b1;
			edge_data.payload.data         = visited[nb] ? 8'h01 : 8'h00;
			edge_data.payload.src          = v [EDGE_SIZE_BITS-1:0];
			edge_data.payload.dest         = nb[EDGE_SIZE_BITS-1:0];
			edge_data.payload.cu_id_x      = CU_X;
			edge_data.payload.cu_id_y      = CU_Y;
			vectors                        = vectors + 1;
			@(posedge clock);
			edge_data.valid          = 1'b0;
			data_buffer_status.empty = (k == deg - 1);
		end
		data_buffer_status.empty = 1'b1;

		if (trailing && hit) begin
			// one extra in-flight edge inside the BREAK_HOLD window
			nb                        = inverse_neighbor(fx, v, deg - 1);
			edge_data.valid           = 1'b1;
			edge_data.payload.data    = 8'h80;
			edge_data.payload.src     = v [EDGE_SIZE_BITS-1:0];
			edge_data.payload.dest    = nb[EDGE_SIZE_BITS-1:0];
			@(posedge clock);
			edge_data.valid = 1'b0;
			cover_bin[16]        = 1'b1;
		end

		// wait for the completion pulse, then release the vertex job exactly as
		// the algorithm shell does
		for (k = 0; k < 512; k++) begin
			if (break_count != break_base)
				break;
			@(posedge clock);
		end
		if (break_count == break_base)
			fail($sformatf("vertex %0d never reported break_S_out", v));
		if (break_count > break_base + 1)
			fail($sformatf("vertex %0d reported %0d completions", v, break_count - break_base));
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		// The BREAK_HOLD shift register suppresses updates while it drains and
		// blocks the next inverse-degree load, so the next vertex job may only
		// be issued after the hold window.  cu_vertex_bfs achieves the same
		// spacing by pulsing the kernel reset on break_S_out; that alternative
		// is covered by the shell-style break-reset scenario below.
		repeat (BREAK_HOLD + 2) @(posedge clock);
	endtask

	// ------------------------------------------------------------------
	// Census stimulus: walking-one and walking-zero patterns on every field
	// this testbench drives, saturation of the result buffer, and a bounded
	// counter burst.  Everything the kernel can observe is exercised so the
	// remaining zero points are only parameter constants, unused interface
	// bits, or counter bits beyond the bounded event budget.
	// ------------------------------------------------------------------
	task automatic census_status_sweep();
		census_drive_status = 1'b1;
		for (int i = 0; i < 16; i++) begin
			@(posedge clock);
			data_buffer_status.full    = i[0];
			data_buffer_status.alfull  = i[1];
			data_buffer_status.valid   = i[2];
			data_buffer_status.empty   = i[3];
			census_write_status.full   = i[0];
			census_write_status.alfull = i[1];
			census_write_status.valid  = i[2];
			census_write_status.empty  = i[3];
		end
		@(posedge clock);
		data_buffer_status       = '0;
		data_buffer_status.empty = 1'b1;
		census_write_status      = '0;
		@(posedge clock);
		census_drive_status = 1'b0;
		@(posedge clock);
	endtask

	// Drives write acknowledges directly so the completion counters walk through
	// their low order bits within a bounded cycle budget.
	task automatic census_response_burst(input int unsigned events);
		census_drive_response = 1'b1;
		// an unsigned loop: a repeat count above 2**31 is read as a negative
		// signed value and would silently skip the burst
		for (int unsigned k = 0; k < events; k++)
			@(posedge clock);
		census_drive_response = 1'b0;
		repeat (8) @(posedge clock);
	endtask

	task automatic census_cu_id_sweep();
		// walking one and walking zero on the identifiers the engine attaches
		// to every element it hands to the kernel
		for (int i = 0; i < CU_ID_RANGE; i++) begin
			@(posedge clock);
			edge_data.valid           = 1'b0;
			edge_data.payload.cu_id_x = (CU_ID_RANGE)'(1) << i;
			edge_data.payload.cu_id_y = ~((CU_ID_RANGE)'(1) << i);
			edge_data.payload.data    = (i % 2) ? '1 : '0;
			edge_data.payload.src     = (EDGE_SIZE_BITS)'(1) << (i % EDGE_SIZE_BITS);
			edge_data.payload.dest    = ~((EDGE_SIZE_BITS)'(1) << (i % EDGE_SIZE_BITS));
		end
		@(posedge clock);
		edge_data = '0;
	endtask

	// Fills the result buffer past its almost-full threshold with the write bus
	// held, then releases it, so the buffer status bits are observed in both
	// directions and no update is lost.
	task automatic census_write_buffer_saturation(input int pushes);
		int break_base;
		bit saturated;
		saturated = 1'b0;
		census_hold_grant = 1'b1;
		for (int k = 0; k < pushes; k++) begin
			// the producer must honour the kernel's own element request, which
			// deasserts once the result buffer reports almost full
			if (k > 0 && !edge_data_request) begin
				saturated = 1'b1;
				break;
			end
			break_base = break_count;
			@(posedge clock);
			vertex_job.valid                      = 1'b1;
			vertex_job.payload.id                 = (VERTEX_SIZE_BITS)'(k);
			vertex_job.payload.inverse_out_degree = 1;
			@(posedge clock);
			data_buffer_status.empty = 1'b0;
			edge_data.valid        = 1'b1;
			edge_data.payload.data = 8'hFF;
			edge_data.payload.src  = (EDGE_SIZE_BITS)'(k);
			edge_data.payload.dest = ~((EDGE_SIZE_BITS)'(k));
			if (exp_count >= MAX_EXPECT)
				fail("expected-write storage exhausted");
			exp_index[exp_count] = k;
			exp_data1[exp_count] = 1;
			exp_data2[exp_count] = int'(~((EDGE_SIZE_BITS)'(k)));
			exp_count            = exp_count + 1;
			completions_expected = completions_expected + 1;
			vectors              = vectors + 1;
			@(posedge clock);
			edge_data.valid = 1'b0;
			for (int guard = 0; guard < 64; guard++) begin
				if (break_count != break_base)
					break;
				@(posedge clock);
			end
			vertex_job.valid = 1'b0;
			@(posedge clock);
			vertex_job = '0;
			repeat (BREAK_HOLD + 2) @(posedge clock);
		end
		census_hold_grant = 1'b0;
		repeat (1024) @(posedge clock);
		if (!saturated)
			fail("the result buffer never reported almost full under a held write bus");
		cover_bin[12] = 1'b1;
	endtask

	// Bounded event burst that walks the completion counters through their low
	// order bits; the remaining high order bits are declared counter-range.
	task automatic census_counter_burst(input int events);
		int break_base;
		for (int k = 0; k < events; k++) begin
			break_base = break_count;
			@(posedge clock);
			vertex_job.valid                      = 1'b1;
			vertex_job.payload.id                 = (VERTEX_SIZE_BITS)'(k);
			vertex_job.payload.inverse_out_degree = 1;
			@(posedge clock);
			edge_data.valid        = 1'b1;
			edge_data.payload.data = 8'h00;
			edge_data.payload.src  = (EDGE_SIZE_BITS)'(k);
			edge_data.payload.dest = '0;
			vectors                = vectors + 1;
			completions_expected   = completions_expected + 1;
			@(posedge clock);
			edge_data.valid = 1'b0;
			for (int guard = 0; guard < 32; guard++) begin
				if (break_count != break_base)
					break;
				@(posedge clock);
			end
			vertex_job.valid = 1'b0;
			@(posedge clock);
			vertex_job = '0;
			repeat (BREAK_HOLD + 1) @(posedge clock);
		end
	endtask

	task automatic drain(input int cycles);
		repeat (cycles) @(posedge clock);
	endtask

	// Drives one synthetic vertex whose identifier and parent exercise the full
	// width of the vertex/edge fields so the control and payload toggles of the
	// update path are observed, not only the small tiny-graph identifiers.
	task automatic drive_pattern_vertex(
			input logic [0:(VERTEX_SIZE_BITS-1)] id  ,
			input logic [  0:(EDGE_SIZE_BITS-1)] dest,
			input logic [0:(DATA_SIZE_READ_BITS-1)] data
		);
		int break_base;
		int k;
		break_base = break_count;
		if (|data) begin
			if (exp_count >= MAX_EXPECT)
				fail("expected-write storage exhausted");
			exp_index[exp_count] = int'(id)  ;
			exp_data1[exp_count] = 1         ;
			exp_data2[exp_count] = int'(dest);
			exp_count            = exp_count + 1;
		end
		completions_expected = completions_expected + 1;

		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = id;
		// a frontier hit breaks immediately, so the inverse degree field can
		// carry the sweep pattern; the miss case keeps a degree of one so the
		// countdown still reaches zero
		vertex_job.payload.inverse_out_degree = ((|data) && (|dest)) ? dest : (VERTEX_SIZE_BITS)'(1);
		vertex_job.payload.inverse_edges_idx  = dest;
		vertex_job.payload.parent             = dest;
		@(posedge clock);
		data_buffer_status.empty  = 1'b0;
		edge_data.valid           = 1'b1;
		edge_data.payload.data    = data;
		edge_data.payload.src     = id  ;
		edge_data.payload.dest    = dest;
		edge_data.payload.cu_id_x = CU_X;
		edge_data.payload.cu_id_y = CU_Y;
		vectors                   = vectors + 1;
		@(posedge clock);
		edge_data.valid          = 1'b0;
		data_buffer_status.empty = 1'b1;
		for (k = 0; k < 512; k++) begin
			if (break_count != break_base)
				break;
			@(posedge clock);
		end
		if (break_count == break_base)
			fail("pattern vertex never reported break_S_out");
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		repeat (BREAK_HOLD + 2) @(posedge clock);
	endtask

	task automatic run_fixture(
			input int  fx     ,
			input int  pattern,
			input int  level  ,
			input int  root   ,
			input int  mask   ,
			input bit  trailing
		);
		int v;
		active_fixture = fx;
		stall_mask     = mask;
		masks_seen[mask % MASK_COUNT] = 1'b1;
		scenarios      = scenarios + 1;
		for (v = 0; v < FX_MAX_VERTICES; v++)
			visited[v] = 1'b0;
		for (v = 0; v < FX_NUM_VERTICES[fx]; v++)
			visited[v] = visited_of(pattern, fx, v, level, root);
		for (v = 0; v < FX_NUM_VERTICES[fx]; v++)
			drive_vertex(fx, v, trailing);
		drain(24);
		if (obs_count != exp_count)
			fail($sformatf("observed %0d writes, expected %0d", obs_count, exp_count));
		if (mask != 0)
			cover_bin[9 + (mask % 4)] = 1'b1;
	endtask

////////////////////////////////////////////////////////////////////////////
// scenarios
////////////////////////////////////////////////////////////////////////////

	int unsigned mask_index;
	int unsigned bins_hit  ;
	int unsigned masks_hit ;

	initial begin
		cycle_count          = 0;
		stall_mask           = 0;
		vectors              = 0;
		scenarios            = 0;
		exp_count            = 0;
		completions_expected = 0;
		active_fixture       = FX_EMPTY;
		for (int b = 0; b < BIN_COUNT; b++)
			cover_bin[b] = 1'b0;
		for (int m = 0; m < MASK_COUNT; m++)
			masks_seen[m] = 1'b0;

		apply_reset();

		// empty graph: no vertex job at all must produce no traffic
		active_fixture = FX_EMPTY;
		drain(32);
		if (obs_count != 0 || vertex_num_counter_resp != 0 || edge_data_counter_accum != 0)
			fail("empty graph produced traffic");

		// isolated vertex, unreachable frontier, and frontier hits
		run_fixture(FX_SINGLE_VERTEX, PAT_NONE , 0, 0, 0, 1'b0);
		run_fixture(FX_CHAIN        , PAT_NONE , 0, 0, 0, 1'b0);
		run_fixture(FX_CHAIN        , PAT_ALL  , 0, 0, 0, 1'b0);
		run_fixture(FX_CHAIN        , PAT_LEVEL, 0, 0, 0, 1'b0);
		run_fixture(FX_CHAIN        , PAT_LEVEL, 1, 0, 0, 1'b0);
		run_fixture(FX_CHAIN        , PAT_LEVEL, 2, 0, 0, 1'b0);
		run_fixture(FX_STAR         , PAT_FIRST, 0, 0, 0, 1'b0);
		run_fixture(FX_CYCLE        , PAT_ALL  , 0, 0, 0, 1'b0);
		run_fixture(FX_DISCONNECTED , PAT_FIRST, 0, 0, 0, 1'b0);
		run_fixture(FX_SELF_LOOP    , PAT_ALL  , 0, 0, 0, 1'b0);
		run_fixture(FX_DUPLICATE_EDGE, PAT_ALL , 0, 0, 0, 1'b0);
		run_fixture(FX_SINK         , PAT_LAST , 0, 0, 0, 1'b0);
		run_fixture(FX_K4           , PAT_LAST , 0, 0, 0, 1'b0);
		run_fixture(FX_K4           , PAT_MIDDLE, 0, 0, 0, 1'b0);

		// trailing in-flight edge inside BREAK_HOLD
		run_fixture(FX_K4, PAT_ALL, 0, 0, 0, 1'b1);

		// every local backpressure mask with bounded release
		for (mask_index = 0; mask_index < MASK_COUNT; mask_index++)
			run_fixture(FX_K4, PAT_LAST, 0, 0, mask_index, 1'b0);

		// reset in the middle of an edge stream
		active_fixture   = FX_K4;
		stall_mask       = 0;
		visited[0]       = 1'b0;
		visited[1]       = 1'b0;
		visited[2]       = 1'b0;
		visited[3]       = 1'b1;
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = 0;
		vertex_job.payload.inverse_out_degree = 3;
		@(posedge clock);
		edge_data.valid        = 1'b1;
		edge_data.payload.data = 8'h00;
		edge_data.payload.src  = 0;
		edge_data.payload.dest = 1;
		@(posedge clock);
		apply_reset();
		cover_bin[13]   = 1'b1;
		completions_expected = 0;
		drain(16);
		if (obs_count != exp_count)
			fail("reset during edge stream leaked a write");
		if (vertex_num_counter_resp != 0 || edge_data_counter_accum != 0)
			fail("reset did not clear the completion counters");

		// reset with a write pending in the buffer: hold the grant so the write
		// cannot drain, then reset
		stall_mask       = (1 << DOMAIN_WRITE);
		visited[0]       = 1'b1;
		visited[1]       = 1'b1;
		visited[2]       = 1'b1;
		visited[3]       = 1'b1;
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = 1;
		vertex_job.payload.inverse_out_degree = 3;
		@(posedge clock);
		edge_data.valid        = 1'b1;
		edge_data.payload.data = 8'h01;
		edge_data.payload.src  = 1;
		edge_data.payload.dest = 0;
		@(posedge clock);
		edge_data.valid = 1'b0;
		drain(6);
		apply_reset();
		stall_mask = 0;
		cover_bin[14]  = 1'b1;
		completions_expected = 0;
		drain(16);
		if (obs_count != exp_count)
			fail("reset leaked a buffered write");

		// repeat the whole traversal after reset
		run_fixture(FX_CHAIN, PAT_ALL, 0, 0, 0, 1'b0);
		cover_bin[15] = 1'b1;

		// wide identifier and parent sweep
		stall_mask = 0;
		for (int i = 0; i < VERTEX_SIZE_BITS; i++)
			drive_pattern_vertex(
				(VERTEX_SIZE_BITS)'(1) << i,
				~((EDGE_SIZE_BITS)'(1) << i),
				(i % 3 == 0) ? '0 : {DATA_SIZE_READ_BITS{1'b1}}
			);
		drive_pattern_vertex('1, '1, '1);
		drive_pattern_vertex('0, '0, 8'h01);
		drain(24);
		if (obs_count != exp_count)
			fail($sformatf("toggle sweep observed %0d writes, expected %0d", obs_count, exp_count));
		cover_bin[18] = 1'b1;

		// completion accounting for the final repeat round
		if (int'(vertex_num_counter_resp) != completions_expected)
			fail($sformatf("vertex completions %0d != %0d",
				int'(vertex_num_counter_resp), completions_expected));
		if (int'(edge_data_counter_accum) != (obs_count - obs_at_reset))
			fail($sformatf("write responses %0d != %0d",
				int'(edge_data_counter_accum), obs_count - obs_at_reset));

		// census stimulus
		census_status_sweep();
		census_cu_id_sweep();
		census_write_buffer_saturation(80);
		drain(256);
		if (obs_count != exp_count)
			fail($sformatf("write buffer saturation lost updates: %0d of %0d", obs_count, exp_count));
		census_response_burst(census_events());
		drain(64);

		masks_hit = 0;
		for (int m = 0; m < MASK_COUNT; m++)
			if (masks_seen[m])
				masks_hit = masks_hit + 1;
		if (masks_hit == MASK_COUNT)
			cover_bin[17] = 1'b1;

		bins_hit = 0;
		for (int b = 0; b < BIN_COUNT; b++)
			if (cover_bin[b])
				bins_hit = bins_hit + 1;
		if (bins_hit != BIN_COUNT) begin
			for (int b = 0; b < BIN_COUNT; b++)
				if (!cover_bin[b])
					$display("MISSING-BIN bfs_kernel bin=%0d", b);
			fail($sformatf("functional bins %0d/%0d", bins_hit, BIN_COUNT));
		end

		$display("PASS bfs_kernel_unit scenarios=%0d vectors=%0d writes=%0d bins=%0d masks=%0d",
			scenarios, vectors, obs_count, bins_hit, masks_hit);
		$finish;
	end

	initial begin
		// two time units per clock period, plus the fixed functional budget
		#(64'd8000000 + 4 * 64'(census_events()));
		fail("global timeout");
	end

endmodule
