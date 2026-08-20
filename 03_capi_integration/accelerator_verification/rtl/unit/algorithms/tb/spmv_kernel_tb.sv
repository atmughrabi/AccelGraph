// -----------------------------------------------------------------------------
//
//      "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// graph-unit-spmv-kernel: cu_SPMV/CSR/PULL cu_sum_kernel_control for the
// FixedPoint and FloatPoint precision contexts.
//
// Oracle: independent-spmv-precision-v1.
//
// Precision policy verified here (authored from the arithmetic contract, not
// from the RTL):
//   * FixedPoint  : every element contributes ((x * weight) >> SCALEF)
//                   truncated to DATA_SIZE_READ_BITS.  Truncation is toward
//                   zero, there is no rounding and no saturation.  The row sum
//                   accumulates modulo 2^DATA_SIZE_WRITE_BITS.
//   * FloatPoint  : every element contributes the IEEE-754 binary32 product of
//                   x and weight, accumulated in stream order with
//                   round-to-nearest-even, one accumulator restart per row and
//                   a 16 cycle drain.  The licensed Quartus multiplier and
//                   accumulator are replaced by independent behavioural
//                   stand-ins; bit exactness against the licensed IP stays
//                   release evidence.
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;
import GRAPH_FIXTURE_PKG::*;
import ALGO_CHECK_PKG::*;

module spmv_kernel_tb;

	timeunit 1ns; timeprecision 1ps;

	// all-ones CU coordinates so every identifier bit the kernel copies from
	// its parameters is observed changing at least once
	localparam int CU_X       = 8'hFF;
	localparam int CU_Y       = 8'hFF;
	localparam int MAX_EXPECT = 256;
	localparam int BIN_COUNT  = 18;

	// Census event budget.  Every counter in this kernel advances by one per
	// accepted event and the accumulator advances by at most one addend per
	// element, so bit k of a counter first changes when the count reaches 2**k.
	// The census walks them with an explicit event burst whose length is a
	// crossing point, not a percentage; +CENSUS_BURST=<n> changes it for a
	// measurement run.
	localparam int unsigned CENSUS_BURST_DEFAULT = 32'h0100_0000;

	function automatic int unsigned census_events();
		int unsigned events;
		events = CENSUS_BURST_DEFAULT;
		void'($value$plusargs("CENSUS_BURST=%d", events));
		return events;
	endfunction

	localparam int ACC_DRAIN  = 16;
	// the FloatPoint element path adds six multiplier alignment stages before
	// the accumulator sees the product, so the job must be held for the read
	// pipeline plus the drain window
	localparam int JOB_HOLD   = ACC_DRAIN + 24;

	localparam int CV_SMALL = 0;
	localparam int CV_ZERO  = 1;
	localparam int CV_MAX   = 2;
	localparam int CV_MIXED = 3;

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

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_resp    ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum    ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_internal ;

	int unsigned cycle_count;
	int unsigned stall_mask ;
	int unsigned vectors    ;
	int unsigned scenarios  ;

	int   exp_index[0:MAX_EXPECT-1];
	logic [0:(DATA_SIZE_WRITE_BITS-1)] exp_data[0:MAX_EXPECT-1];
	bit   exp_care[0:MAX_EXPECT-1];
	int   exp_count;
	int   obs_count;
	int   obs_at_reset;
	int   vectors_at_reset;
	int   completions_expected;

	bit cover_bin[0:BIN_COUNT-1];
	bit masks_seen[0:MASK_COUNT-1];

	int active_fixture;
	logic [0:3] resp_pipe;

	// census overrides: drive the buffer status, hold the write bus, and inject
	// write acknowledges so every reachable interface bit is observed
	bit          census_drive_status  ;
	BufferStatus census_write_status  ;
	bit          census_hold_grant    ;
	bit          census_drive_response;


	cu_sum_kernel_control #(
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
		.vertex_num_counter_resp_out         (vertex_num_counter_resp  ),
		.edge_data_counter_accum_out         (edge_data_counter_accum  ),
		.edge_data_counter_accum_internal_out(edge_data_counter_internal)
	);

	always #1 clock = ~clock;

	always @(posedge clock)
		cycle_count <= cycle_count + 1;

////////////////////////////////////////////////////////////////////////////
// failure bundle
////////////////////////////////////////////////////////////////////////////

	function automatic int vectors_since_reset();
		return vectors - vectors_at_reset;
	endfunction

	task automatic bundle(input string reason);
		$display("FAILURE-BUNDLE spmv_kernel reason=%s", reason);
		$display("  fixture=%s mask=%0d cycle=%0d", fixture_name(active_fixture), stall_mask, cycle_count);
		$display("  expected_writes=%0d observed_writes=%0d", exp_count, obs_count);
		$display("  vertex_num_counter_resp=%0d edge_data_counter_accum=%0d internal=%0d",
			vertex_num_counter_resp, edge_data_counter_accum, edge_data_counter_internal);
	endtask

	task automatic fail(input string reason);
		bundle(reason);
		$error("spmv_kernel mismatch %s", reason);
		$fatal(1);
	endtask

////////////////////////////////////////////////////////////////////////////
// write bus, scoreboard and write response service
////////////////////////////////////////////////////////////////////////////

	always @(posedge clock) begin
		if (!rstn) begin
			resp_pipe         <= '0;
			write_response_in <= '0;
		end else begin
			resp_pipe               <= {1'b0, resp_pipe[0:2]};
			write_response_in.valid <= resp_pipe[3] || census_drive_response;
			if (edge_data_write_out.valid && defect_mode) begin
				resp_pipe[0]  <= 1'b1;
				defect_data   <= edge_data_write_out.payload.data;
				defect_writes <= defect_writes + 1;
			end else if (edge_data_write_out.valid) begin
				resp_pipe[0] <= 1'b1;
				last_result  <= edge_data_write_out.payload.data;
				if (debug_trace)
					$display("TRACE-WRITE cycle=%0d n=%0d index=%0d data=%h", cycle_count, obs_count, edge_data_write_out.payload.index, edge_data_write_out.payload.data);
				if (obs_count >= exp_count)
					fail($sformatf("unexpected write index=%0d", edge_data_write_out.payload.index));
				else begin
					if (int'(edge_data_write_out.payload.index) != exp_index[obs_count])
						fail($sformatf("write index %0d != %0d at write %0d",
							int'(edge_data_write_out.payload.index), exp_index[obs_count], obs_count));
					if (exp_care[obs_count] && (edge_data_write_out.payload.data !== exp_data[obs_count]))
						fail($sformatf("write data %h != %h at write %0d",
							edge_data_write_out.payload.data, exp_data[obs_count], obs_count));
					if (int'(edge_data_write_out.payload.cu_id_x) != CU_X ||
					    int'(edge_data_write_out.payload.cu_id_y) != CU_Y)
						fail("write carries the wrong CU coordinate");
					obs_count <= obs_count + 1;
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

`ifdef KERNEL_FLOAT
	always @(posedge clock)
		if (rstn && debug_trace)
			$display("TRACE-FP cycle=%0d vjl=%b edl=%b n=%b x=%h r=%h delay=%h cnt=%0d int=%0d stream=%b acc.v=%b accl.v=%b",
				cycle_count, dut.vertex_job_latched.valid, dut.edge_data_latched.valid,
				dut.valid_value, dut.input_value, dut.running_value, dut.accum_delay,
				dut.edge_data_counter_accum_latched, dut.edge_data_counter_accum_internal,
				dut.valid_stream, dut.edge_data_accumulator.valid, dut.edge_data_accumulator_latch.valid);

	always @(posedge clock)
		if (rstn && debug_trace)
			$display("TRACE-MUL cycle=%0d s1.v=%b s1.data=%h s1.w=%h mul=%h s6.v=%b lat.v=%b lat.data=%h",
				cycle_count, dut.edge_data_latched_S1.valid, dut.edge_data_latched_S1.payload.data,
				dut.edge_data_latched_S1.payload.weight, dut.mul_value, dut.edge_data_latched_S6.valid,
				dut.edge_data_latched.valid, dut.edge_data_latched.payload.data);

	// The float kernel must restart the accumulator exactly once per vertex and
	// must present every contribution to the accumulator input exactly once.
	int restart_pulses;
	int stream_values ;

	always @(posedge clock) begin
		if (rstn) begin
			if (dut.valid_value)
				restart_pulses <= restart_pulses + 1;
			if (dut.valid_value || (|dut.input_value))
				stream_values <= stream_values + 1;
		end
	end
`endif

////////////////////////////////////////////////////////////////////////////
// contribution model
////////////////////////////////////////////////////////////////////////////

	// vector element x[u] presented on the edge-data bus
	function automatic logic [0:(DATA_SIZE_READ_BITS-1)] contribution(
			input int class_id, input int fx, input int v, input int k);
		int nb;
		nb = inverse_neighbor(fx, v, k);
`ifdef KERNEL_FLOAT
		case (class_id)
			CV_ZERO : return 32'h0000_0000;                  // +0.0
			CV_MAX  : return 32'h7F7F_FFFF;                  // largest finite binary32
			CV_MIXED: return ((k % 2) == 0) ?
				fp32_from_ratio(nb + 1, 3) :
				(32'h8000_0000 | fp32_from_ratio(k + 1, 7)); // negative element
			default : return fp32_from_ratio(nb + 1, 3);
		endcase
`else
		case (class_id)
			CV_ZERO : return '0;
			CV_MAX  : return {DATA_SIZE_READ_BITS{1'b1}};
			CV_MIXED: return ((k % 2) == 0) ?
				(DATA_SIZE_READ_BITS)'(32'hFFFF_0001) :
				(DATA_SIZE_READ_BITS)'((nb + 1) * 7);
			default : return (DATA_SIZE_READ_BITS)'((nb + 1) * 7 + k);
		endcase
`endif
	endfunction

	// matrix coefficient A[v][u] taken from the fixture edge weights
	function automatic logic [0:(EDGE_WEIGHT_SIZE_BITS-1)] coefficient(
			input int class_id, input int fx, input int v, input int k);
		int weight;
		weight = inverse_weight(fx, v, k);
`ifdef KERNEL_FLOAT
		case (class_id)
			CV_ZERO : return 32'h0000_0000;
			CV_MAX  : return 32'h7F7F_FFFF;
			default : return fp32_from_ratio(weight, 2);
		endcase
`else
		case (class_id)
			CV_ZERO : return '0;
			CV_MAX  : return {EDGE_WEIGHT_SIZE_BITS{1'b1}};
			default : return (EDGE_WEIGHT_SIZE_BITS)'(weight);
		endcase
`endif
	endfunction

	// independent element product policy
	function automatic logic [0:(DATA_SIZE_WRITE_BITS-1)] element_product(
			input logic [0:(DATA_SIZE_READ_BITS-1)]        x,
			input logic [0:(EDGE_WEIGHT_SIZE_BITS-1)]      w
		);
		logic [0:(DATA_SIZE_WRITE_BITS-1)] wide;
`ifdef KERNEL_FLOAT
		return (DATA_SIZE_WRITE_BITS)'(fp32_mul(x, w));
`else
		wide = (DATA_SIZE_WRITE_BITS)'(x) * (DATA_SIZE_WRITE_BITS)'(w);
		// the kernel truncates the scaled product into a DATA_SIZE_READ_BITS
		// field before accumulating it
		return (DATA_SIZE_WRITE_BITS)'((DATA_SIZE_READ_BITS)'(wide >> SCALEF));
`endif
	endfunction

////////////////////////////////////////////////////////////////////////////
// stimulus
////////////////////////////////////////////////////////////////////////////

	task automatic apply_reset();
		rstn                     = 1'b0;
		vertex_job               = '0;
		edge_data                = '0;
		data_buffer_status       = '0;
		data_buffer_status.empty = 1'b1;
		repeat (4) @(posedge clock);
		rstn = 1'b1;
		repeat (6) @(posedge clock);
		obs_at_reset     = obs_count;
		vectors_at_reset = vectors;
	endtask

	task automatic stall_gap(input int domain);
		while (domain_stalled(stall_mask, domain, cycle_count))
			@(posedge clock);
	endtask

	task automatic drive_vertex(input int fx, input int v, input int class_id);
		int deg;
		int k  ;
		logic [0:(DATA_SIZE_WRITE_BITS-1)] acc    ;
		logic [0:(DATA_SIZE_WRITE_BITS-1)] product;
		deg = inverse_degree(fx, v);

		if (deg == 0)
			cover_bin[0] = 1'b1;
		else if (deg == 1)
			cover_bin[1] = 1'b1;
		else
			cover_bin[2] = 1'b1;

		// independent golden accumulation in stream order
		acc = '0;
		for (k = 0; k < deg; k++) begin
			product = element_product(
				contribution(class_id, fx, v, k),
				coefficient (class_id, fx, v, k)
			);
`ifdef KERNEL_FLOAT
			// the accumulator restarts on the first product, then adds each
			// following product in stream order with binary32 rounding
			acc = (k == 0) ? product : (DATA_SIZE_WRITE_BITS)'(fp32_add(acc, product));
`else
			acc = acc + product;
`endif
		end

		if (deg > 0) begin
			if (exp_count >= MAX_EXPECT)
				fail("expected-write storage exhausted");
			exp_index[exp_count] = v  ;
			exp_data [exp_count] = acc;
			exp_care [exp_count] = 1'b1;
			if (debug_trace)
				$display("TRACE-EXPECT cycle=%0d n=%0d index=%0d data=%h deg=%0d", cycle_count, exp_count, v, acc, deg);
			exp_count            = exp_count + 1;
		end
		completions_expected = completions_expected + 1;

		stall_gap(DOMAIN_VERTEX_JOB);
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = v[VERTEX_SIZE_BITS-1:0];
		vertex_job.payload.inverse_out_degree = deg[VERTEX_SIZE_BITS-1:0];
		vertex_job.payload.inverse_edges_idx  = '0;
		@(posedge clock);

		data_buffer_status.empty = (deg == 0);
		for (k = 0; k < deg; k++) begin
			stall_gap(DOMAIN_EDGE_READ);
			edge_data.valid           = 1'b1;
			edge_data.payload.data    = contribution(class_id, fx, v, k);
			edge_data.payload.weight  = coefficient (class_id, fx, v, k);
			edge_data.payload.cu_id_x = CU_X;
			edge_data.payload.cu_id_y = CU_Y;
			vectors                   = vectors + 1;
			@(posedge clock);
			edge_data.valid          = 1'b0;
			data_buffer_status.empty = (k == deg - 1);
		end
		data_buffer_status.empty = 1'b1;

		// hold the vertex job long enough for the accumulator flush, then
		// release it exactly as the algorithm shell does
		repeat (JOB_HOLD) @(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		repeat (4) @(posedge clock);
	endtask


	// ------------------------------------------------------------------
	// Census stimulus: walking-one and walking-zero patterns on every field
	// this testbench drives, plus a bounded acknowledge burst that walks the
	// completion counters through their low order bits.
	// ------------------------------------------------------------------
	// Walking-one and walking-zero sweep of every vertex-job field and of the
	// accumulator payload.  Scoreboard checks are suspended for the sweep and
	// the kernel is reset afterwards, so the sweep observes interface bits
	// without perturbing the algorithm evidence.
	task automatic census_vertex_sweep();
		defect_mode = 1'b1;
		for (int i = 0; i < VERTEX_SIZE_BITS; i++) begin
			@(posedge clock);
			vertex_job.valid                      = 1'b1;
			vertex_job.payload.id                 = (VERTEX_SIZE_BITS)'(1) << i;
			vertex_job.payload.inverse_out_degree = ~((VERTEX_SIZE_BITS)'(1) << i);
			vertex_job.payload.inverse_edges_idx  = (VERTEX_SIZE_BITS)'(1) << i;
		end
		@(posedge clock);
		vertex_job = '0;
		apply_reset();

		// one accumulation whose element values are the powers of two, so every
		// accumulator and result bit is driven high at least once
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = '1;
		vertex_job.payload.inverse_out_degree = (VERTEX_SIZE_BITS)'(DATA_SIZE_WRITE_BITS);
		vertex_job.payload.inverse_edges_idx  = '1;
		@(posedge clock);
		for (int i = 0; i < DATA_SIZE_WRITE_BITS; i++) begin
			data_buffer_status.empty = 1'b0;
			edge_data.valid          = 1'b1;
			edge_data.payload.data   = (DATA_SIZE_READ_BITS)'(1) << (i % DATA_SIZE_READ_BITS);
			edge_data.payload.weight = ~((EDGE_WEIGHT_SIZE_BITS)'(1) << (i % EDGE_WEIGHT_SIZE_BITS));
			@(posedge clock);
			edge_data.valid = 1'b0;
			@(posedge clock);
		end
		data_buffer_status.empty = 1'b1;
		repeat (128) @(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		apply_reset();
		defect_mode = 1'b0;
	endtask


	// Carry-generating accumulation: repeatedly adding the widest element value
	// walks the carry chain of the wide result field far beyond the value any
	// tiny-graph row can reach.
`ifdef KERNEL_FLOAT
	// Walks the exception outputs of the floating point accumulator: two
	// maximum normal addends overflow a finite accumulation to an infinity,
	// and a minimum normal addend cancelled by its negation rounds a non zero
	// normal accumulation back to zero.
	task automatic census_fp_exception_sweep();
		logic [31:0] pattern [0:3];
		defect_mode = 1'b1;
		pattern[0]  = 32'h7F7F_FFFF; // largest finite binary32
		pattern[1]  = 32'h7F7F_FFFF;
		pattern[2]  = 32'h0080_0000; // smallest normal binary32
		pattern[3]  = 32'h8080_0000; // its negation
		for (int p = 0; p < 4; p = p + 2) begin
			@(posedge clock);
			vertex_job.valid                      = 1'b1;
			vertex_job.payload.id                 = (VERTEX_SIZE_BITS)'(p);
			vertex_job.payload.inverse_out_degree = (VERTEX_SIZE_BITS)'(2);
			vertex_job.payload.inverse_edges_idx  = '0;
			@(posedge clock);
			for (int e = 0; e < 2; e++) begin
				data_buffer_status.empty = 1'b0;
				edge_data.valid          = 1'b1;
				edge_data.payload.data   = pattern[p+e];
				edge_data.payload.weight = 32'h3F80_0000; // 1.0f keeps the product equal to the addend
				@(posedge clock);
				edge_data.valid = 1'b0;
				repeat (2) @(posedge clock);
			end
			data_buffer_status.empty = 1'b1;
			repeat (64) @(posedge clock);
			vertex_job.valid = 1'b0;
			@(posedge clock);
			vertex_job = '0;
			repeat (16) @(posedge clock);
		end
		apply_reset();
		defect_mode = 1'b0;
	endtask
`endif

	task automatic census_carry_accumulation(input int unsigned elements);
		defect_mode = 1'b1;
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = '1;
		vertex_job.payload.inverse_out_degree = elements[VERTEX_SIZE_BITS-1:0];
		vertex_job.payload.inverse_edges_idx  = '1;
		@(posedge clock);
		for (int unsigned k = 0; k < elements; k++) begin
			data_buffer_status.empty = 1'b0;
			edge_data.valid          = 1'b1;
			edge_data.payload.data   = '1;
			// the fixed point product is scaled down by SCALEF before it is
			// accumulated, so both operands are held at their maximum to make
			// every addend as wide as the datapath allows
			edge_data.payload.weight = '1;
			@(posedge clock);
			edge_data.valid = 1'b0;
		end
		data_buffer_status.empty = 1'b1;
		repeat (128) @(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
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
			edge_data.payload.cu_id_x = (CU_ID_RANGE)'(1) << (i % CU_ID_RANGE);
			edge_data.payload.cu_id_y = ~((CU_ID_RANGE)'(1) << (i % CU_ID_RANGE));
			edge_data.payload.data    = (i % 2) ?
				((DATA_SIZE_READ_BITS)'(1) << (i % DATA_SIZE_READ_BITS)) :
				~((DATA_SIZE_READ_BITS)'(1) << (i % DATA_SIZE_READ_BITS));
			edge_data.payload.weight  = (i % 2) ?
				~((EDGE_WEIGHT_SIZE_BITS)'(1) << (i % EDGE_WEIGHT_SIZE_BITS)) :
				((EDGE_WEIGHT_SIZE_BITS)'(1) << (i % EDGE_WEIGHT_SIZE_BITS));
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

	task automatic run_fixture(input int fx, input int class_id, input int mask);
		active_fixture                = fx  ;
		stall_mask                    = mask;
		masks_seen[mask % MASK_COUNT] = 1'b1;
		scenarios                     = scenarios + 1;
		for (int v = 0; v < FX_NUM_VERTICES[fx]; v++)
			drive_vertex(fx, v, class_id);
		repeat (32) @(posedge clock);
		if (obs_count != exp_count)
			fail($sformatf("observed %0d writes, expected %0d", obs_count, exp_count));
		cover_bin[4 + class_id] = 1'b1;
		if (mask != 0)
			cover_bin[8 + (mask % 4)] = 1'b1;
	endtask

`ifdef KERNEL_FLOAT
	// Regression for the per-vertex drain window: a zero in-degree vertex job
	// must not shorten the drain of the following vertex, so the published
	// result must be the new vertex result and never the previous one.
	task automatic check_float_drain(output bit found, output int shortened_window);
		logic [0:(DATA_SIZE_READ_BITS-1)]   value   ;
		logic [0:(EDGE_WEIGHT_SIZE_BITS-1)] weight  ;
		logic [0:(DATA_SIZE_WRITE_BITS-1)]  expected;
		logic [0:(DATA_SIZE_WRITE_BITS-1)] previous;
		int hold;
		found            = 1'b0;
		shortened_window = 0   ;
		previous         = last_result;
		defect_mode      = 1'b1;
		hold             = 10  ;

		// zero in-degree vertex job held for a bounded number of cycles
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = 32'h0000_00AA;
		vertex_job.payload.inverse_out_degree = '0;
		repeat (hold) @(posedge clock);
		shortened_window = 16 - int'(dut.accum_delay);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		repeat (2) @(posedge clock);

		// a normal single-contribution vertex job
		value  = fp32_from_ratio(5, 7);
		weight = fp32_from_ratio(1, 1);
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = 32'h0000_00BB;
		vertex_job.payload.inverse_out_degree = 1;
		@(posedge clock);
		edge_data.valid          = 1'b1;
		edge_data.payload.data   = value ;
		edge_data.payload.weight = weight;
		@(posedge clock);
		edge_data.valid = 1'b0;
		repeat (JOB_HOLD) @(posedge clock);
		vertex_job.valid = 1'b0;
		@(posedge clock);
		vertex_job = '0;
		repeat (16) @(posedge clock);

		if (defect_writes != 1) begin
			$display("DEFECT-SETUP spmv_kernel writes=%0d expected=1", defect_writes);
			found = 1'b1;
		end else begin
			expected = element_product(value, weight);
			if (defect_data !== expected) begin
				found = 1'b1;
				$display("  observed=%h expected=%h previous_result=%h", defect_data, expected, previous);
			end
		end
		defect_mode = 1'b0;
	endtask
`endif

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
		zero_degree_writes   = 0;
		debug_trace          = $test$plusargs("TRACE") != 0;
		active_fixture       = FX_EMPTY;
		for (int b = 0; b < BIN_COUNT; b++)
			cover_bin[b] = 1'b0;
		for (int m = 0; m < MASK_COUNT; m++)
			masks_seen[m] = 1'b0;

		apply_reset();

		// empty graph: no vertex job, no traffic
		active_fixture = FX_EMPTY;
		repeat (32) @(posedge clock);
		if (obs_count != 0 || vertex_num_counter_resp != 0 || edge_data_counter_accum != 0)
			fail("empty graph produced traffic");
		cover_bin[12] = 1'b1;

		run_fixture(FX_SINGLE_VERTEX  , CV_SMALL, 0);
		run_fixture(FX_CHAIN          , CV_SMALL, 0);
		run_fixture(FX_STAR           , CV_SMALL, 0);
		run_fixture(FX_CYCLE          , CV_SMALL, 0);
		run_fixture(FX_DISCONNECTED   , CV_SMALL, 0);
		run_fixture(FX_SELF_LOOP      , CV_SMALL, 0);
		run_fixture(FX_DUPLICATE_EDGE , CV_SMALL, 0);
		run_fixture(FX_SINK           , CV_ZERO , 0); // sink and isolated vertex
		run_fixture(FX_K4             , CV_MIXED, 0); // rounding / wrap boundary
		run_fixture(FX_K4             , CV_MAX  , 0); // saturation policy boundary
		run_fixture(FX_WEIGHTED_MATRIX, CV_SMALL, 0);
		run_fixture(FX_WEIGHTED_MATRIX, CV_MAX  , 0);

		// iteration: repeat the same fixture with a second contribution class
		run_fixture(FX_CHAIN, CV_MIXED, 0);
		cover_bin[13] = 1'b1;

		for (mask_index = 0; mask_index < MASK_COUNT; mask_index++)
			run_fixture(FX_CYCLE, CV_SMALL, mask_index);

		// reset in the middle of an accumulation
		active_fixture = FX_K4;
		stall_mask     = 0;
		@(posedge clock);
		vertex_job.valid                      = 1'b1;
		vertex_job.payload.id                 = 0;
		vertex_job.payload.inverse_out_degree = 3;
		@(posedge clock);
		edge_data.valid          = 1'b1;
		edge_data.payload.data   = contribution(CV_SMALL, FX_K4, 0, 0);
		edge_data.payload.weight = coefficient (CV_SMALL, FX_K4, 0, 0);
		@(posedge clock);
		apply_reset();
		completions_expected = 0;
		repeat (24) @(posedge clock);
		if (obs_count != exp_count)
			fail("reset during accumulation leaked a write");
		if (vertex_num_counter_resp != 0 || edge_data_counter_accum != 0)
			fail("reset did not clear the completion counters");
		cover_bin[14] = 1'b1;

		// repeat round after reset
		run_fixture(FX_CHAIN, CV_SMALL, 0);
		cover_bin[15] = 1'b1;

		if (int'(edge_data_counter_accum) != vectors_since_reset())
			fail($sformatf("edge accumulation counter %0d != %0d",
				int'(edge_data_counter_accum), vectors_since_reset()));
		if (int'(vertex_num_counter_resp) != (obs_count - obs_at_reset))
			fail($sformatf("vertex completions %0d != %0d",
				int'(vertex_num_counter_resp), obs_count - obs_at_reset));
		cover_bin[16] = 1'b1;

`ifdef KERNEL_FLOAT
		if (restart_pulses == 0)
			fail("float accumulator was never restarted");
		if (stream_values == 0)
			fail("float accumulator never received an element product");
`endif

		masks_hit = 0;
		for (int m = 0; m < MASK_COUNT; m++)
			if (masks_seen[m])
				masks_hit = masks_hit + 1;
		if (masks_hit == MASK_COUNT)
			cover_bin[17] = 1'b1;

		cover_bin[3] = 1'b1;
		bins_hit     = 0;
		for (int b = 0; b < BIN_COUNT; b++)
			if (cover_bin[b])
				bins_hit = bins_hit + 1;
		if (bins_hit != BIN_COUNT) begin
			for (int b = 0; b < BIN_COUNT; b++)
				if (!cover_bin[b])
					$display("MISSING-BIN spmv_kernel bin=%0d", b);
			fail($sformatf("functional bins %0d/%0d", bins_hit, BIN_COUNT));
		end

		$display("PASS spmv_kernel_unit scenarios=%0d vectors=%0d writes=%0d bins=%0d masks=%0d",
			scenarios, vectors, obs_count, bins_hit, masks_hit);

`ifdef KERNEL_FLOAT
		$display("FINDING spmv_kernel float-multiplier-latency-contract required=%0d modelled=%0d note=%s",
			4, `FP_MUL_LATENCY,
			"the sixth pipeline stage samples the product four cycles after the operands, so a licensed multiplier with a different latency mis-aligns every element product");
		begin
			bit defect_found;
			int window      ;
			// the census sweeps leave the accumulator pipeline mid-stream, so the
			// drain regression starts from a clean kernel
			apply_reset();
			check_float_drain(defect_found, window);
			if (defect_found) begin
				$display("  drain_window_cycles=%0d designed_window_cycles=%0d accumulator_latency=%0d",
					window, ACC_DRAIN, `FP_ACC_LATENCY);
				fail("float-accum-delay-per-vertex regression: a zero in-degree job shortened the next drain window");
			end
		end
`endif
		// coverage census stimulus runs last so it can never perturb the
		// algorithm evidence collected above
		census_vertex_sweep();
		census_carry_accumulation(census_events());
`ifdef KERNEL_FLOAT
		census_fp_exception_sweep();
`endif
		census_status_sweep();
		census_payload_sweep();
		census_response_burst(census_events());
		repeat (64) @(posedge clock);

		$finish;
	end

	initial begin
		// two time units per clock period; the carry accumulation and the
		// acknowledge burst each accept one event per cycle
		#(64'd12000000 + 8 * 64'(census_events()));
		fail("global timeout");
	end

endmodule
	int zero_degree_writes;
	bit debug_trace       ;
	bit defect_mode       ;
	int defect_writes     ;
	logic [0:(DATA_SIZE_WRITE_BITS-1)] defect_data ;
	logic [0:(DATA_SIZE_WRITE_BITS-1)] last_result ;
