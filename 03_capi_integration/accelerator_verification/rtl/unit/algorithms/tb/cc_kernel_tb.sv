// -----------------------------------------------------------------------------
//
//      "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// graph-unit-connected-components-kernel:
// cu_ConnectedComponents/CSR/ShiloachVishkin cu_update_kernel_control.
//
// Oracle: independent-component-partition-v1.
//
// The testbench owns an independent Shiloach-Vishkin label array.  For every
// forward edge it derives comp_high / comp_low / comp_comp_high itself, expects
// a hook update exactly when comp_comp_high equals comp_high, applies the same
// update to its own label array, and finally canonicalises the labels into
// partitions and compares them with the fixture package's independent
// component labelling.  Raw representative identifiers are never compared.
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;
import GRAPH_FIXTURE_PKG::*;
import ALGO_CHECK_PKG::*;

module cc_kernel_tb;

	timeunit 1ns; timeprecision 1ps;

	// all-ones CU coordinates so every identifier bit the kernel copies from
	// its parameters is observed changing at least once
	localparam int CU_X       = 8'hFF;
	localparam int CU_Y       = 8'hFF;
	localparam int MAX_EXPECT = 512;
	localparam int BIN_COUNT  = 19;
	localparam int EDGE_GAP   = 3 ;

	// Census event budget.  Every counter in this kernel advances by one per
	// accepted event, so bit k first changes when the count reaches 2**k.  The
	// census walks them with an explicit event burst whose length is a crossing
	// point, not a percentage; +CENSUS_BURST=<n> changes it for a measurement
	// run.
	localparam int unsigned CENSUS_BURST_DEFAULT = 32'h0100_0000;

	function automatic int unsigned census_events();
		int unsigned events;
		events = CENSUS_BURST_DEFAULT;
		void'($value$plusargs("CENSUS_BURST=%d", events));
		return events;
	endfunction

	logic clock = 1'b0;
	logic rstn  = 1'b0;

	ResponseBufferLine  write_response_in  ;
	BufferStatus        write_buffer_status;
	EdgeComponentUpdate edge_data          ;
	BufferStatus        data_buffer_status ;
	logic               write_bus_grant    ;
	logic               write_bus_request  ;
	logic               edge_data_request  ;
	EdgeDataWrite       edge_data_write_out;
	VertexInterface     vertex_job         ;

	logic [0:(EDGE_SIZE_BITS-1)]   continue_accum         ;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_resp;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_internal;

	int unsigned cycle_count;
	int unsigned stall_mask ;
	int unsigned vectors    ;
	int unsigned scenarios  ;
	int unsigned rounds     ;

	int exp_index[0:MAX_EXPECT-1];
	int exp_data [0:MAX_EXPECT-1];
	int exp_count;
	int obs_count;
	int obs_at_reset;
	int lost_updates    ;
	int lost_first_mask ;
	int lost_first_index;
	int lost_first_label;
	int lost_first_phase;
	int writes_seen     ;
	int writes_at_reset ;
	int resync_request  ;
	bit resync_pending  ;

	bit cover_bin[0:BIN_COUNT-1];
	bit masks_seen[0:MASK_COUNT-1];

	int label[0:FX_MAX_VERTICES-1];
	int active_fixture;
	int scan_phase   ;
	bit defect_mode  ;
	int defect_writes;

	logic [0:3] resp_pipe;

	// census overrides: drive the buffer status, hold the write bus, and inject
	// write acknowledges so every reachable interface bit is observed
	bit          census_drive_status  ;
	BufferStatus census_write_status  ;
	bit          census_hold_grant    ;
	bit          census_drive_response;


	cu_update_kernel_control #(
		.CU_ID_X(CU_X),
		.CU_ID_Y(CU_Y)
	) dut (
		.clock                               (clock                    ),
		.rstn_in                             (rstn                     ),
		.enabled_in                          (1'b1                     ),
		.write_response_in                   (write_response_in        ),
		.write_buffer_status                 (write_buffer_status      ),
		.edge_data                           (edge_data                ),
		.data_buffer_status                  (data_buffer_status       ),
		.edge_data_write_bus_grant           (write_bus_grant          ),
		.edge_data_write_bus_request         (write_bus_request        ),
		.edge_data_request                   (edge_data_request        ),
		.edge_data_write_out                 (edge_data_write_out      ),
		.vertex_job                          (vertex_job               ),
		.edge_data_counter_continue_accum    (continue_accum           ),
		.vertex_num_counter_resp_out         (vertex_num_counter_resp  ),
		.edge_data_counter_accum_out         (edge_data_counter_accum  ),
		.edge_data_counter_accum_internal_out(edge_data_counter_internal)
	);

	always #1 clock = ~clock;

	always @(posedge clock)
		cycle_count <= cycle_count + 1;

	task automatic bundle(input string reason);
		$display("FAILURE-BUNDLE cc_kernel reason=%s", reason);
		$display("  fixture=%s mask=%0d cycle=%0d round=%0d",
			fixture_name(active_fixture), stall_mask, cycle_count, rounds);
		$display("  expected_writes=%0d observed_writes=%0d", exp_count, obs_count);
		$display("  vertex_num_counter_resp=%0d edge_data_counter_accum=%0d internal=%0d",
			vertex_num_counter_resp, edge_data_counter_accum, edge_data_counter_internal);
	endtask

	task automatic fail(input string reason);
		bundle(reason);
		$error("cc_kernel mismatch %s", reason);
		$fatal(1);
	endtask

	always @(posedge clock) begin
		if (!rstn) begin
			resp_pipe         <= '0;
			write_response_in <= '0;
		end else begin
			resp_pipe               <= {1'b0, resp_pipe[0:2]};
			write_response_in.valid <= resp_pipe[3] || census_drive_response;
			if (resync_pending)
				obs_count <= resync_request;
			if (edge_data_write_out.valid && defect_mode) begin
				resp_pipe[0]  <= 1'b1;
				defect_writes <= defect_writes + 1;
			end else if (edge_data_write_out.valid) begin
				resp_pipe[0] <= 1'b1;
				writes_seen  <= writes_seen + 1;
				if (obs_count >= exp_count)
					fail($sformatf("unexpected write index=%0d", edge_data_write_out.payload.index));
				else begin
					int slot;
					slot = resync_slot(
						int'(edge_data_write_out.payload.index),
						int'(edge_data_write_out.payload.data)
					);
					if (slot < 0)
						fail($sformatf("write index=%0d label=%0d does not match expectation %0d (index=%0d label=%0d)",
							int'(edge_data_write_out.payload.index), int'(edge_data_write_out.payload.data),
							obs_count, exp_index[obs_count], exp_data[obs_count]));
					if (int'(edge_data_write_out.payload.cu_id_x) != CU_X ||
					    int'(edge_data_write_out.payload.cu_id_y) != CU_Y)
						fail("write carries the wrong CU coordinate");
					if (slot != obs_count)
						fail($sformatf("component update index=%0d label=%0d was skipped (observed index=%0d)",
							exp_index[obs_count], exp_data[obs_count],
							int'(edge_data_write_out.payload.index)));
					obs_count <= slot + 1;
				end
			end
		end
	end

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

	// Returns the expectation slot matched by an observed write, allowing a
	// bounded number of dropped expectations, or -1 when nothing matches.
	function automatic int resync_slot(input int index, input int label_value);
		for (int slot = obs_count; slot < exp_count && slot < obs_count + 8; slot++)
			if (exp_index[slot] == index && exp_data[slot] == label_value)
				return slot;
		return -1;
	endfunction

	task automatic apply_reset();
		rstn                     = 1'b0;
		vertex_job               = '0;
		edge_data                = '0;
		continue_accum           = '0;
		data_buffer_status       = '0;
		data_buffer_status.empty = 1'b1;
		repeat (4) @(posedge clock);
		rstn = 1'b1;
		repeat (6) @(posedge clock);
		obs_at_reset    = obs_count;
		writes_at_reset = writes_seen;
	endtask

	task automatic stall_gap(input int domain);
		while (domain_stalled(stall_mask, domain, cycle_count))
			@(posedge clock);
	endtask

	// One Shiloach-Vishkin vertex round: stream the forward edge slice of the
	// vertex and hook whenever the current label of the higher component still
	// points at itself.
	task automatic drive_vertex(input int fx, input int v);
		int deg ;
		int k   ;
		int u   ;
		int high;
		int low ;
		int comp_high_label;
		deg = out_degree(fx, v);

		if (deg == 0) begin
			// A zero out-degree vertex job keeps edge_data_counter_accum_internal_S2
			// equal to out_degree for every cycle it is held, which makes the
			// completion counter advance continuously.  Such jobs are covered by
			// the dedicated policy scenario instead of the nominal rounds.
			cover_bin[0] = 1'b1;
			return;
		end
		if (deg == 1)
			cover_bin[1] = 1'b1;
		else
			cover_bin[2] = 1'b1;

		stall_gap(DOMAIN_VERTEX_JOB);
		@(posedge clock);
		vertex_job.valid                 = 1'b1;
		vertex_job.payload.id            = v[VERTEX_SIZE_BITS-1:0];
		vertex_job.payload.out_degree    = deg[VERTEX_SIZE_BITS-1:0];
		vertex_job.payload.edges_idx     = '0;
		@(posedge clock);

		for (k = 0; k < deg; k++) begin
			u    = out_neighbor(fx, v, k);
			high = (label[v] > label[u]) ? label[v] : label[u];
			low  = (label[v] > label[u]) ? label[u] : label[v];
			comp_high_label = label[high];

			if (comp_high_label == high) begin
				if (exp_count >= MAX_EXPECT)
					fail("expected-write storage exhausted");
				exp_index[exp_count] = high;
				exp_data [exp_count] = low ;
				exp_count            = exp_count + 1;
				label[high]          = low ;
				cover_bin[3]         = 1'b1;
			end else begin
				cover_bin[4] = 1'b1;
			end
			if (high == low)
				cover_bin[5] = 1'b1;
			if (k > 0 && out_neighbor(fx, v, k) == out_neighbor(fx, v, k - 1))
				cover_bin[6] = 1'b1;

			stall_gap(DOMAIN_EDGE_READ);
			data_buffer_status.empty              = 1'b0;
			edge_data.valid                       = 1'b1;
			edge_data.payload.comp_high           = high[DATA_SIZE_READ_BITS-1:0];
			edge_data.payload.comp_low            = low [DATA_SIZE_READ_BITS-1:0];
			edge_data.payload.comp_comp_high      = comp_high_label[DATA_SIZE_READ_BITS-1:0];
			vectors                               = vectors + 1;
			@(posedge clock);
			edge_data.valid = 1'b0;
			// the update latch only forwards a hook on a cycle that does not
			// carry another hook, so edges are spaced by the kernel contract
			repeat (EDGE_GAP) @(posedge clock);
		end
		data_buffer_status.empty = 1'b1;

		repeat (24) @(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		repeat (6) @(posedge clock);
	endtask

	function automatic bit partition_matches(input int fx);
		int a;
		int b;
		for (int i = 0; i < FX_NUM_VERTICES[fx]; i++)
			for (int j = 0; j < FX_NUM_VERTICES[fx]; j++) begin
				a = (label[i] == label[j]) ? 1 : 0;
				b = (component_label(fx, i) == component_label(fx, j)) ? 1 : 0;
				if (a != b)
					return 1'b0;
			end
		return 1'b1;
	endfunction


	// ------------------------------------------------------------------
	// Census stimulus: walking-one and walking-zero patterns on every field
	// this testbench drives, plus a bounded acknowledge burst that walks the
	// completion counters through their low order bits.
	// ------------------------------------------------------------------
	task automatic census_vertex_sweep();
		defect_mode = 1'b1;
		for (int i = 0; i < VERTEX_SIZE_BITS; i++) begin
			@(posedge clock);
			vertex_job.valid              = 1'b1;
			vertex_job.payload.id         = (VERTEX_SIZE_BITS)'(1) << i;
			vertex_job.payload.out_degree = ~((VERTEX_SIZE_BITS)'(1) << i);
			vertex_job.payload.edges_idx  = (VERTEX_SIZE_BITS)'(1) << i;
			continue_accum                = (EDGE_SIZE_BITS)'(1) << i;
		end
		@(posedge clock);
		vertex_job     = '0;
		continue_accum = '0;
		apply_reset();
		defect_mode = 1'b0;
	endtask

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

	task automatic census_payload_sweep();
		for (int i = 0; i < 32; i++) begin
			@(posedge clock);
			edge_data.valid = 1'b0;
			edge_data.payload.comp_high      = (DATA_SIZE_READ_BITS)'(1) << (i % DATA_SIZE_READ_BITS);
			edge_data.payload.comp_low       = ~((DATA_SIZE_READ_BITS)'(1) << (i % DATA_SIZE_READ_BITS));
			edge_data.payload.comp_comp_high = (i % 2) ?
				((DATA_SIZE_READ_BITS)'(1) << (i % DATA_SIZE_READ_BITS)) :
				~((DATA_SIZE_READ_BITS)'(1) << (i % DATA_SIZE_READ_BITS));
		end
		@(posedge clock);
		edge_data = '0;
	endtask

	task automatic census_response_burst(input int unsigned events);
		census_drive_response = 1'b1;
		// an unsigned loop: a repeat count at or above 2**31 is read as a
		// negative signed value and would silently skip the burst
		for (int unsigned k = 0; k < events; k++)
			@(posedge clock);
		census_drive_response = 1'b0;
		repeat (8) @(posedge clock);
	endtask

	// The kernel throttles the edge data path with the almost-full flag of its
	// own write buffer, so that flag is only observed while the write bus is
	// held off and hooks are still arriving, which is the write backpressure the
	// engine applies.  The burst stops at the almost-full threshold, which is
	// where the production request signal stops asking for elements, so the
	// buffer is never driven past the level the engine can reach.
	task automatic census_write_backpressure();
		defect_mode       = 1'b1;
		census_hold_grant = 1'b1;
		@(posedge clock);
		vertex_job.valid              = 1'b1;
		vertex_job.payload.id         = 32'd50;
		vertex_job.payload.out_degree = '1;
		@(posedge clock);
		data_buffer_status.empty = 1'b0;
		for (int k = 0; k < (WRITE_CMD_BUFFER_SIZE - 14); k++) begin
			edge_data.valid                  = 1'b1;
			edge_data.payload.comp_high      = 32'd11;
			edge_data.payload.comp_low       = 32'd3 ;
			edge_data.payload.comp_comp_high = 32'd11;
			@(posedge clock);
			edge_data.valid = 1'b0;
			@(posedge clock);
		end
		data_buffer_status.empty = 1'b1;
		repeat (8) @(posedge clock);
		census_hold_grant = 1'b0;
		repeat (WRITE_CMD_BUFFER_SIZE * 4) @(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		apply_reset();
		defect_mode = 1'b0;
	endtask

	// Walks the skip counter, the internal element counter and the latched
	// continue accumulator together: one vertex job whose out degree can never
	// be reached holds the round open while non-hook elements, write
	// acknowledges and a walking continue accumulator are accepted every cycle.
	task automatic census_counter_burst(input int unsigned events);
		defect_mode           = 1'b1;
		census_drive_response = 1'b1;
		@(posedge clock);
		vertex_job.valid              = 1'b1;
		vertex_job.payload.id         = '1;
		vertex_job.payload.out_degree = '1;
		vertex_job.payload.edges_idx  = '1;
		@(posedge clock);
		data_buffer_status.empty = 1'b0;
		for (int unsigned k = 0; k < events; k++) begin
			edge_data.valid                  = 1'b1;
			edge_data.payload.comp_high      = 32'd5;
			edge_data.payload.comp_low       = 32'd1;
			edge_data.payload.comp_comp_high = 32'd1; // 1 != 5: a skipped element
			continue_accum                   = (EDGE_SIZE_BITS)'(k);
			@(posedge clock);
		end
		edge_data.valid          = 1'b0;
		data_buffer_status.empty = 1'b1;
		census_drive_response    = 1'b0;
		continue_accum           = '0;
		repeat (32) @(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		apply_reset();
		defect_mode = 1'b0;
	endtask

	// Walks the retirement counter, which advances once per completed vertex
	// job rather than once per accepted acknowledge: a zero out degree job
	// completes on the cycle it is latched, so the burst re-arms it every two
	// cycles.
	task automatic census_retire_burst(input int unsigned events);
		defect_mode = 1'b1;
		for (int unsigned k = 0; k < events; k++) begin
			@(posedge clock);
			vertex_job.valid              = 1'b1;
			vertex_job.payload.id         = (VERTEX_SIZE_BITS)'(k);
			vertex_job.payload.out_degree = '0;
			vertex_job.payload.edges_idx  = (VERTEX_SIZE_BITS)'(k);
			@(posedge clock);
			vertex_job.valid = 1'b0;
		end
		@(posedge clock);
		vertex_job = '0;
		apply_reset();
		defect_mode = 1'b0;
	endtask

	task automatic run_fixture(input int fx, input int mask, input int max_rounds);
		int round;
		active_fixture                = fx  ;
		stall_mask                    = mask;
		masks_seen[mask % MASK_COUNT] = 1'b1;
		scenarios                     = scenarios + 1;
		for (int v = 0; v < FX_MAX_VERTICES; v++)
			label[v] = v;
		for (round = 0; round < max_rounds; round++) begin
			rounds = rounds + 1;
			for (int v = 0; v < FX_NUM_VERTICES[fx]; v++)
				drive_vertex(fx, v);
			// pointer jumping between rounds, performed by the host in the real
			// flow and modelled here so the partition can converge
			for (int v = 0; v < FX_NUM_VERTICES[fx]; v++)
				label[v] = label[label[v]];
		end
		// drain long enough for every bounded stall profile to release
		// drain far beyond every bounded stall period so a missing update is a
		// genuine loss rather than a late write
		repeat (256) @(posedge clock);
		if (obs_count < exp_count) begin
			if (lost_updates == 0) begin
				lost_first_mask  = stall_mask;
				lost_first_index = exp_index[obs_count];
				lost_first_label = exp_data [obs_count];
				lost_first_phase = scan_phase;
				$display("LOST-UPDATE cc_kernel cycle=%0d fixture=%s mask=%0d phase=%0d expected_index=%0d expected_label=%0d",
					cycle_count, fixture_name(fx), stall_mask, scan_phase,
					exp_index[obs_count], exp_data[obs_count]);
			end
			lost_updates   = lost_updates + (exp_count - obs_count);
			resync_request = exp_count;
			resync_pending = 1'b1;
			@(posedge clock);
			resync_pending = 1'b0;
			@(posedge clock);
		end
		if (FX_NUM_VERTICES[fx] > 0 && !partition_matches(fx))
			fail("converged partition does not match the independent component labelling");
		cover_bin[15] = 1'b1;
		if (mask != 0)
			cover_bin[7 + (mask % 4)] = 1'b1;
	endtask

	// Raw stimulus: a vertex whose edges all report a component that no longer
	// points at itself must produce no update, and must still complete through
	// the skip counter.
	task automatic run_raw_nonhook(input int edges);
		int k;
		scenarios = scenarios + 1;
		@(posedge clock);
		vertex_job.valid              = 1'b1;
		vertex_job.payload.id         = 32'd7;
		vertex_job.payload.out_degree = edges[VERTEX_SIZE_BITS-1:0];
		@(posedge clock);
		for (k = 0; k < edges; k++) begin
			data_buffer_status.empty         = 1'b0;
			edge_data.valid                  = 1'b1;
			edge_data.payload.comp_high      = 32'd5;
			edge_data.payload.comp_low       = 32'd1;
			edge_data.payload.comp_comp_high = 32'd1; // 1 != 5: the root moved
			vectors                          = vectors + 1;
			@(posedge clock);
			edge_data.valid = 1'b0;
			repeat (EDGE_GAP) @(posedge clock);
		end
		data_buffer_status.empty = 1'b1;
		repeat (24) @(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		repeat (8) @(posedge clock);
		if (obs_count != exp_count)
			fail("a non-hook edge produced a component update");
		cover_bin[4] = 1'b1;
	endtask

	// Wide component identifiers so the hook datapath toggles across its full
	// width rather than only over tiny-graph labels.
	task automatic run_raw_hook_sweep();
		logic [0:(DATA_SIZE_READ_BITS-1)] high;
		logic [0:(DATA_SIZE_READ_BITS-1)] low ;
		scenarios = scenarios + 1;
		for (int i = 0; i < DATA_SIZE_READ_BITS; i++) begin
			high = (DATA_SIZE_READ_BITS)'(1) << i;
			low  = ~high;
			if (exp_count >= MAX_EXPECT)
				fail("expected-write storage exhausted");
			exp_index[exp_count] = int'(high);
			exp_data [exp_count] = int'(low) ;
			exp_count            = exp_count + 1;

			@(posedge clock);
			vertex_job.valid              = 1'b1;
			vertex_job.payload.id         = (VERTEX_SIZE_BITS)'(i);
			vertex_job.payload.out_degree = 1;
			vertex_job.payload.edges_idx  = ~((VERTEX_SIZE_BITS)'(1) << i);
			@(posedge clock);
			data_buffer_status.empty         = 1'b0;
			edge_data.valid                  = 1'b1;
			edge_data.payload.comp_high      = high;
			edge_data.payload.comp_low       = low ;
			edge_data.payload.comp_comp_high = high;
			vectors                          = vectors + 1;
			@(posedge clock);
			edge_data.valid          = 1'b0;
			data_buffer_status.empty = 1'b1;
			repeat (24) @(posedge clock);
			vertex_job.valid = 1'b0;
			@(posedge clock);
			vertex_job = '0;
			repeat (6) @(posedge clock);
		end
		repeat (64) @(posedge clock);
		if (obs_count != exp_count)
			fail($sformatf("hook sweep observed %0d writes, expected %0d", obs_count, exp_count));
	endtask

	// Round boundary contract.  The edge data read path accumulates the elements
	// the algorithm skips for the resident vertex and only drops that count when
	// the shell pulses its round reset, which lands after the kernel has already
	// re-armed for the next job.  The element accounting of a vertex job must
	// therefore start from zero, and one accepted job must retire exactly once
	// however long it stays resident after it completed.
	task automatic run_round_boundary_contract();
		int retired_before;
		int guard;
		scenarios   = scenarios + 1;
		defect_mode = 1'b1;
		apply_reset();
		retired_before = int'(vertex_num_counter_resp);

		// round A completes on a standing continue count alone: its single
		// element is skipped by the algorithm before it reaches the data bus
		@(posedge clock);
		continue_accum                = (EDGE_SIZE_BITS)'(1);
		vertex_job.valid              = 1'b1;
		vertex_job.payload.id         = 32'd40;
		vertex_job.payload.out_degree = 1;
		guard = 0;
		while (int'(vertex_num_counter_resp) == retired_before && guard < 64) begin
			@(posedge clock);
			guard = guard + 1;
		end
		if (int'(vertex_num_counter_resp) != (retired_before + 1))
			fail($sformatf("a vertex job completed by the continue count retired %0d times",
				int'(vertex_num_counter_resp) - retired_before));

		// the shell releases the job and hands over the next one while the read
		// path still reports the continue count of the round that just finished
		@(posedge clock);
		vertex_job.valid = 1'b0;
		repeat (2) @(posedge clock);
		vertex_job.valid              = 1'b1;
		vertex_job.payload.id         = 32'd41;
		vertex_job.payload.out_degree = 1;
		repeat (16) @(posedge clock);
		if (int'(edge_data_counter_internal) != 0)
			fail($sformatf("the next vertex job was accounted from the standing continue count (%0d elements)",
				int'(edge_data_counter_internal)));
		if (int'(vertex_num_counter_resp) != (retired_before + 1))
			fail("the next vertex job retired on the continue count of the finished round");

		// the round reset clears the read path, then the job completes on its
		// own element
		continue_accum = '0;
		repeat (4) @(posedge clock);
		data_buffer_status.empty         = 1'b0;
		edge_data.valid                  = 1'b1;
		edge_data.payload.comp_high      = 32'd9;
		edge_data.payload.comp_low       = 32'd2;
		edge_data.payload.comp_comp_high = 32'd9;
		vectors                          = vectors + 1;
		@(posedge clock);
		edge_data.valid          = 1'b0;
		data_buffer_status.empty = 1'b1;
		guard = 0;
		while (int'(vertex_num_counter_resp) == (retired_before + 1) && guard < 64) begin
			@(posedge clock);
			guard = guard + 1;
		end
		if (int'(vertex_num_counter_resp) != (retired_before + 2))
			fail("the vertex job did not retire on its own element");
		@(posedge clock);
		vertex_job.valid = 1'b0;
		repeat (8) @(posedge clock);

		// a zero out degree job is complete for every cycle it is held, and the
		// shell holds it until the completion has travelled back through the
		// engine, so it must still retire exactly once
		@(posedge clock);
		vertex_job.valid              = 1'b1;
		vertex_job.payload.id         = 32'd42;
		vertex_job.payload.out_degree = '0;
		repeat (16) @(posedge clock);
		vertex_job.valid = 1'b0;
		repeat (8) @(posedge clock);
		if (int'(vertex_num_counter_resp) != (retired_before + 3))
			fail($sformatf("a zero out degree job retired %0d times",
				int'(vertex_num_counter_resp) - retired_before - 2));

		vertex_job = '0;
		apply_reset();
		defect_mode  = 1'b0;
		cover_bin[18] = 1'b1;
	endtask

	int unsigned mask_index;
	int unsigned bins_hit  ;
	int unsigned masks_hit ;

	initial begin
		cycle_count    = 0;
		stall_mask     = 0;
		vectors        = 0;
		scenarios      = 0;
		rounds         = 0;
		exp_count      = 0;
		active_fixture = FX_EMPTY;
		defect_mode    = 1'b0;
		scan_phase     = -1;
		for (int b = 0; b < BIN_COUNT; b++)
			cover_bin[b] = 1'b0;
		for (int m = 0; m < MASK_COUNT; m++)
			masks_seen[m] = 1'b0;

		apply_reset();

		active_fixture = FX_EMPTY;
		repeat (32) @(posedge clock);
		if (obs_count != 0 || vertex_num_counter_resp != 0 || edge_data_counter_accum != 0)
			fail("empty graph produced traffic");
		cover_bin[11] = 1'b1;

		run_fixture(FX_SINGLE_VERTEX  , 0, 1);
		run_fixture(FX_CHAIN          , 0, 3);
		run_fixture(FX_STAR           , 0, 2);
		run_fixture(FX_CYCLE          , 0, 3);
		run_fixture(FX_DISCONNECTED   , 0, 2);
		run_fixture(FX_SELF_LOOP      , 0, 2);
		run_fixture(FX_DUPLICATE_EDGE , 0, 2);
		run_fixture(FX_TRIANGLE       , 0, 3);
		run_fixture(FX_K4             , 0, 3);
		run_fixture(FX_SINK           , 0, 3);
		cover_bin[12] = 1'b1;

		run_raw_nonhook(3);
		run_raw_hook_sweep();

		for (mask_index = 0; mask_index < MASK_COUNT; mask_index++)
			run_fixture(FX_CYCLE, mask_index, 2);

		// reset in the middle of a round
		active_fixture = FX_K4;
		stall_mask     = 0;
		@(posedge clock);
		vertex_job.valid              = 1'b1;
		vertex_job.payload.id         = 0;
		vertex_job.payload.out_degree = 3;
		@(posedge clock);
		edge_data.valid                  = 1'b1;
		edge_data.payload.comp_high      = 2;
		edge_data.payload.comp_low       = 0;
		edge_data.payload.comp_comp_high = 2;
		defect_mode                      = 1'b1; // the aborted hook is not scored
		@(posedge clock);
		apply_reset();
		defect_mode = 1'b0;
		repeat (24) @(posedge clock);
		if (vertex_num_counter_resp != 0 || edge_data_counter_accum != 0)
			fail("reset did not clear the completion counters");
		cover_bin[13] = 1'b1;

		run_fixture(FX_TRIANGLE, 0, 3);
		cover_bin[14] = 1'b1;

		if (int'(edge_data_counter_accum) != (writes_seen - writes_at_reset))
			fail($sformatf("write responses %0d != %0d",
				int'(edge_data_counter_accum), writes_seen - writes_at_reset));
		cover_bin[16] = 1'b1;

		run_round_boundary_contract();

		// Deterministic regression scan: the historical update loss depended on
		// the phase between the bounded write/kernel stall profile and the
		// vertex completion, so every phase offset of one bounded window is
		// still exercised and any loss fails the suite.
		for (int phase = 0; phase < 24; phase++) begin
			scan_phase = phase;
			repeat (phase) @(posedge clock);
			run_fixture(FX_CYCLE, 13, 2);
		end
		scan_phase = -1;

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
					$display("MISSING-BIN cc_kernel bin=%0d", b);
			fail($sformatf("functional bins %0d/%0d", bins_hit, BIN_COUNT));
		end

		$display("PASS cc_kernel_unit scenarios=%0d vectors=%0d writes=%0d bins=%0d masks=%0d",
			scenarios, vectors, writes_seen, bins_hit, masks_hit);
		if (writes_seen != exp_count)
			fail($sformatf("observed %0d component updates, expected %0d", writes_seen, exp_count));
		// coverage census stimulus runs last so it can never perturb the
		// algorithm evidence collected above
		census_vertex_sweep();
		census_status_sweep();
		census_payload_sweep();
		census_write_backpressure();
		census_response_burst(census_events());
		census_counter_burst(census_events());
		census_retire_burst(census_events());
		repeat (64) @(posedge clock);

		$finish;
	end

	initial begin
		// two time units per clock period; the census bursts are accepted at
		// one event per cycle and the retirement burst at one per two cycles
		#(64'd12000000 + 12 * 64'(census_events()));
		fail("global timeout");
	end

endmodule
