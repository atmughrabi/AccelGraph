// -----------------------------------------------------------------------------
//      AccelGraph RTL unit test - sum-reduction family
// -----------------------------------------------------------------------------
// Device under test : sum_reduce
// Oracle            : graph-arbitrary-precision-sum-v1
//
// The oracle accumulates every contributor in 128-bit arbitrary precision and
// then applies one explicit wrap step (truncation to DATA_WIDTH_OUT, that is
// modulo 2**DATA_WIDTH_OUT). The DUT relies on SystemVerilog implicit width
// rules for the same result, so the two disagree as soon as the reduction tree,
// the enable gating or the wrap policy changes.
// -----------------------------------------------------------------------------

import GLOBALS_CU_PKG::*;

module sum_reduce_probe #(
	parameter int INDEX          = 0 ,
	parameter int DATA_WIDTH_IN  = 32,
	parameter int DATA_WIDTH_OUT = 32,
	parameter int BUS_WIDTH      = 8
) (
	input  logic        clock                 ,
	input  logic        rstn                  ,
	input  logic        enabled_in            ,
	input  logic [0:1023] drive_lanes           ,
	input  logic        finalize              ,
	output int unsigned probe_checks          ,
	output int unsigned probe_bins_hit        ,
	output int unsigned probe_bins_total
);
	`include "graph_common_harness.svh"

	localparam logic [0:127] LANE_MAX = (128'd1 << DATA_WIDTH_IN) - 128'd1 ;
	localparam logic [0:127] OUT_SPAN = (128'd1 << DATA_WIDTH_OUT)         ;
	localparam logic [0:127] MAX_SUM  = LANE_MAX * 128'(BUS_WIDTH)         ;

	// Reachability of the overflow bins follows from the parameters alone.
	localparam bit HAS_LAST_LANE   = (BUS_WIDTH > 1)                ;
	localparam bit HAS_EXACT_MAX   = (MAX_SUM >= (OUT_SPAN - 128'd1));
	localparam bit HAS_WRAP_ONCE   = (MAX_SUM >= OUT_SPAN)          ;
	localparam bit HAS_WRAP_MULTI  = (MAX_SUM >= (OUT_SPAN << 1))   ;

	logic [ 0:DATA_WIDTH_IN-1] partial_sums_in[0:BUS_WIDTH-1];
	logic [0:DATA_WIDTH_OUT-1] total_sum_out                 ;

	logic [0:DATA_WIDTH_IN-1] model_latched     [0:BUS_WIDTH-1];
	logic [0:DATA_WIDTH_IN-1] model_latched_prev[0:BUS_WIDTH-1];
	logic                     model_enabled                    ;
	logic [0:DATA_WIDTH_OUT-1] model_total                     ;

	int unsigned cycle           ;
	int unsigned hold_cycles     ;
	logic        enable_history_1;
	logic        enable_history_2;

	// The stimulus bus is packed: Verilator does not keep a continuous
	// assignment sensitive to an unpacked array port element.
	generate
		for (genvar lane = 0; lane < BUS_WIDTH; lane++) begin : generate_lane_input
			assign partial_sums_in[lane] =
				drive_lanes[lane*64 + (64-DATA_WIDTH_IN) +: DATA_WIDTH_IN];
		end
	endgenerate

	sum_reduce #(
		.DATA_WIDTH_IN (DATA_WIDTH_IN ),
		.DATA_WIDTH_OUT(DATA_WIDTH_OUT),
		.BUS_WIDTH     (BUS_WIDTH     )
	) dut (
		.clock          (clock          ),
		.rstn           (rstn           ),
		.enabled_in     (enabled_in     ),
		.partial_sums_in(partial_sums_in),
		.total_sum_out  (total_sum_out  )
	);

	function automatic logic [0:127] arbitrary_precision_sum(input bit use_previous);
		logic [0:127] accumulator;

		accumulator = 128'd0;
		for (int lane = 0; lane < BUS_WIDTH; lane++) begin
			if (use_previous) begin
				accumulator = accumulator + 128'(model_latched_prev[lane]);
			end else begin
				accumulator = accumulator + 128'(model_latched[lane]);
			end
		end
		arbitrary_precision_sum = accumulator;
	endfunction

	// Explicit wrap policy: keep the low DATA_WIDTH_OUT bits of the exact sum.
	function automatic logic [0:DATA_WIDTH_OUT-1] wrap_to_output(input logic [0:127] exact);
		wrap_to_output = exact[128-DATA_WIDTH_OUT:127];
	endfunction

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			// A three state comparison keeps the power on state out of the bin.
			if(arbitrary_precision_sum(1'b0) != 128'd0) begin
				harness_cover("reset_clear");
			end
			model_enabled <= 1'b0;
			model_total   <= '0  ;
			for (int lane = 0; lane < BUS_WIDTH; lane++) begin
				model_latched[lane]      <= '0;
				model_latched_prev[lane] <= '0;
			end
		end else begin
			model_enabled <= enabled_in;
			model_total   <= wrap_to_output(arbitrary_precision_sum(1'b0));
			for (int lane = 0; lane < BUS_WIDTH; lane++) begin
				model_latched_prev[lane] <= model_latched[lane];
				if (model_enabled) begin
					model_latched[lane] <= partial_sums_in[lane];
				end
			end
		end
	end

	task automatic dump_state();
		$display("REDUCTION-JOURNAL %s cycle=%0d", harness_scope, cycle);
		$display("  enabled_in=%b model_enabled=%b hold_cycles=%0d", enabled_in, model_enabled,
			hold_cycles);
		for (int lane = 0; lane < BUS_WIDTH; lane++) begin
			$display("  lane[%0d] driven=%h latched=%h contributing=%h", lane, partial_sums_in[lane],
				model_latched[lane], model_latched_prev[lane]);
		end
		$display("  exact sum of contributors=%h", arbitrary_precision_sum(1'b1));
		$display("  expected total=%h dut total=%h", model_total, total_sum_out);
	endtask

	task automatic check_outputs();
		harness_checks = harness_checks + 1;
		if (total_sum_out !== model_total) begin
			dump_state();
			$error("%s: reduction mismatch on total_sum_out expected=%h actual=%h", harness_scope, model_total,
				total_sum_out);
			$fatal(1, "reduction mismatch");
		end
	endtask

	task automatic cover_contribution();
		logic [0:127] exact;
		int unsigned  nonzero;
		bit           all_max;

		exact   = arbitrary_precision_sum(1'b1);
		nonzero = 0;
		all_max = 1'b1;
		for (int lane = 0; lane < BUS_WIDTH; lane++) begin
			if (model_latched_prev[lane] !== '0) begin
				nonzero = nonzero + 1;
			end
			if (128'(model_latched_prev[lane]) !== LANE_MAX) begin
				all_max = 1'b0;
			end
		end

		if (nonzero == 0) begin
			harness_cover("all_zero");
		end
		if (nonzero == 1 && model_latched_prev[0] !== '0) begin
			harness_cover("single_first");
		end
		if (HAS_LAST_LANE && nonzero == 1 && model_latched_prev[BUS_WIDTH-1] !== '0) begin
			harness_cover("single_last");
		end
		if (all_max) begin
			harness_cover("all_contributors_max");
		end
		if (HAS_EXACT_MAX && exact == (OUT_SPAN - 128'd1)) begin
			harness_cover("exact_output_maximum");
		end
		if (HAS_WRAP_ONCE && exact >= OUT_SPAN && exact < (OUT_SPAN << 1)) begin
			harness_cover("wrap_once");
		end
		if (HAS_WRAP_MULTI && exact >= (OUT_SPAN << 1)) begin
			harness_cover("wrap_multiple");
		end
	endtask

	task automatic declare_bins();
		harness_declare_bin("all_zero"            );
		harness_declare_bin("single_first"        );
		harness_declare_bin("all_contributors_max");
		harness_declare_bin("disabled_hold"       );
		harness_declare_bin("enable_pulse"        );
		harness_declare_bin("reset_clear"         );
		if (HAS_LAST_LANE) begin
			harness_declare_bin("single_last");
		end
		if (HAS_EXACT_MAX) begin
			harness_declare_bin("exact_output_maximum");
		end
		if (HAS_WRAP_ONCE) begin
			harness_declare_bin("wrap_once");
		end
		if (HAS_WRAP_MULTI) begin
			harness_declare_bin("wrap_multiple");
		end
	endtask

	initial begin
		harness_scope  = $sformatf("sum_reduce[%0d] IN=%0d OUT=%0d BUS=%0d", INDEX, DATA_WIDTH_IN,
			DATA_WIDTH_OUT, BUS_WIDTH);
		harness_checks   = 0   ;
		cycle            = 0   ;
		hold_cycles      = 0   ;
		enable_history_1 = 1'b0;
		enable_history_2 = 1'b0;
		if (DATA_WIDTH_IN > 64) begin
			$fatal(1, "%s: contributor width beyond the 64-bit stimulus bus", harness_scope);
		end
		declare_bins();
	end

	always @(negedge clock) begin
		bit lanes_differ;

		cycle = cycle + 1;
		check_outputs();
		if (rstn === 1'b1) begin
			cover_contribution();

			lanes_differ = 1'b0;
			for (int lane = 0; lane < BUS_WIDTH; lane++) begin
				if (partial_sums_in[lane] !== model_latched[lane]) begin
					lanes_differ = 1'b1;
				end
			end
			if (enabled_in === 1'b0) begin
				hold_cycles = hold_cycles + 1;
			end else begin
				hold_cycles = 0;
			end
			if (hold_cycles >= 2 && lanes_differ) begin
				harness_cover("disabled_hold");
			end
			if (enabled_in === 1'b0 && enable_history_1 === 1'b1 && enable_history_2 === 1'b0) begin
				harness_cover("enable_pulse");
			end
		end
		enable_history_2 = enable_history_1;
		enable_history_1 = enabled_in      ;
	end

	always @(posedge finalize) begin
		harness_report_bins();
		probe_checks     = harness_checks    ;
		probe_bins_hit   = harness_bins_hit();
		probe_bins_total = harness_bin_count ;
	end
endmodule

// -----------------------------------------------------------------------------
// Reduction suite top level.
// -----------------------------------------------------------------------------
module graph_sum_reduce_tb;
	`include "graph_common_context.svh"

	localparam int SUM_COUNT = 9;
	localparam int SUM_IN [0:SUM_COUNT-1] = '{32, 1, 1, 5, 8, 4, 32, VERTEX_SIZE_BITS, EDGE_SIZE_BITS};
	localparam int SUM_OUT[0:SUM_COUNT-1] = '{32, 1, 1, 6, 4, 9, 32, VERTEX_SIZE_BITS, EDGE_SIZE_BITS};
	localparam int SUM_BUS[0:SUM_COUNT-1] = '{8, 1, 3, 3, 5, 5, 16, NUM_GRAPH_CU_GLOBAL, NUM_VERTEX_CU_GLOBAL};

	logic        clock      = 1'b0;
	// The reset is asynchronous for the devices under test and sampled
	// synchronously by the stimulus, which is a testbench only pattern.
	/* verilator lint_off SYNCASYNCNET */
	logic        rstn       = 1'b1;
	/* verilator lint_on SYNCASYNCNET */
	logic        enabled_in = 1'b0;
	logic [0:1023] drive_lanes       ;
	logic [0:63]   stimulus_lanes[0:15];
	logic        finalize   = 1'b0;

	int unsigned probe_checks    [0:SUM_COUNT-1];
	int unsigned probe_bins_hit  [0:SUM_COUNT-1];
	int unsigned probe_bins_total[0:SUM_COUNT-1];

	int unsigned total_checks    ;
	int unsigned total_bins_hit  ;
	int unsigned total_bins_total;
	int unsigned cycles          ;

	always #5 clock = ~clock;

	generate
		for (genvar i = 0; i < SUM_COUNT; i++) begin : generate_sum_probe
			sum_reduce_probe #(
				.INDEX         (i         ),
				.DATA_WIDTH_IN (SUM_IN[i] ),
				.DATA_WIDTH_OUT(SUM_OUT[i]),
				.BUS_WIDTH     (SUM_BUS[i])
			) probe (
				.clock           (clock              ),
				.rstn            (rstn               ),
				.enabled_in      (enabled_in         ),
				.drive_lanes     (drive_lanes        ),
				.finalize        (finalize           ),
				.probe_checks    (probe_checks[i]    ),
				.probe_bins_hit  (probe_bins_hit[i]  ),
				.probe_bins_total(probe_bins_total[i])
			);
		end
	endgenerate

	task automatic tick();
		@(negedge clock);
		#1;
		cycles = cycles + 1;
	endtask

	task automatic step(input int count);
		repeat (count) begin
			tick();
		end
	endtask

	task automatic apply_lanes(input logic enable, input int count);
		tick();
		for (int lane = 0; lane < 16; lane++) begin
			drive_lanes[lane*64 +: 64] = stimulus_lanes[lane];
		end
		enabled_in = enable;
		step(count);
	endtask

	task automatic uniform_lanes(input logic [0:63] value);
		for (int lane = 0; lane < 16; lane++) begin
			stimulus_lanes[lane] = value;
		end
	endtask

	task automatic one_hot_lanes(input int index, input logic [0:63] value);
		for (int lane = 0; lane < 16; lane++) begin
			stimulus_lanes[lane] = (lane == index) ? value : 64'd0;
		end
	endtask

	// Distributes an exact target across the contributors of one instance so the
	// overflow boundaries of that instance are reached deterministically. The
	// target is unreachable when the contributors cannot hold it, which matches
	// the reachability rule used to declare the overflow bins.
	function automatic bit target_lanes(input int instance_index, input logic [0:127] target);
		logic [0:127] remaining;
		logic [0:127] lane_max ;

		remaining = target                                     ;
		lane_max  = (128'd1 << SUM_IN[instance_index]) - 128'd1;
		for (int lane = 0; lane < 16; lane++) begin
			stimulus_lanes[lane] = 64'd0;
		end
		for (int lane = 0; lane < SUM_BUS[instance_index]; lane++) begin
			if (remaining > lane_max) begin
				stimulus_lanes[lane] = lane_max[64:127];
				remaining            = remaining - lane_max;
			end else begin
				stimulus_lanes[lane] = remaining[64:127];
				remaining            = 128'd0           ;
			end
		end
		target_lanes = (remaining == 128'd0);
	endfunction

	task automatic drive_target(input int instance_index, input logic [0:127] target);
		if (target_lanes(instance_index, target)) begin
			apply_lanes(1'b1, 3);
		end
	endtask

	initial begin
		logic [0:127] out_span;

		cycles = 0;
		uniform_lanes(64'd0);
		drive_lanes = '0;

		// Asynchronous reset before the first clock edge, then disabled idle.
		#1;
		rstn = 1'b0;
		uniform_lanes(64'hFFFF_FFFF_FFFF_FFFF);
		apply_lanes(1'b1, 3);
		rstn = 1'b1;
		uniform_lanes(64'd0);
		apply_lanes(1'b0, 3);

		// Zero contributors.
		apply_lanes(1'b1, 3);

		// Single contributor per lane index, at one and at the lane maximum.
		for (int lane = 0; lane < 16; lane++) begin
			one_hot_lanes(lane, 64'd1);
			apply_lanes(1'b1, 3);
			one_hot_lanes(lane, 64'hFFFF_FFFF_FFFF_FFFF);
			apply_lanes(1'b1, 3);
		end

		// All contributors at maximum.
		uniform_lanes(64'hFFFF_FFFF_FFFF_FFFF);
		apply_lanes(1'b1, 3);

		// Per instance overflow boundaries.
		for (int instance_index = 0; instance_index < SUM_COUNT; instance_index++) begin
			out_span = 128'd1 << SUM_OUT[instance_index];
			drive_target(instance_index, out_span - 128'd1);
			drive_target(instance_index, out_span         );
			drive_target(instance_index, out_span + 128'd1);
			drive_target(instance_index, (out_span << 1)  );
			drive_target(instance_index, (out_span << 1) + 128'd3);
		end

		// Hold while disabled. The enable is registered inside the reduction, so
		// the contributors are only changed once the capture stage has settled.
		uniform_lanes(64'h1234_5678_9ABC_DEF0);
		apply_lanes(1'b1, 3);
		apply_lanes(1'b0, 3);
		uniform_lanes(64'h0FED_CBA9_8765_4321);
		apply_lanes(1'b0, 6);

		// Single cycle enable pulse.
		uniform_lanes(64'h5555_5555_5555_5555);
		apply_lanes(1'b1, 0);
		apply_lanes(1'b0, 4);

		// Reset with a non zero accumulation in flight.
		uniform_lanes(64'hFFFF_FFFF_FFFF_FFFF);
		apply_lanes(1'b1, 4);
		rstn = 1'b0;
		step(3);
		rstn = 1'b1;
		uniform_lanes(64'd0);
		apply_lanes(1'b0, 4);

		@(negedge clock);
		#1;
		finalize = 1'b1;
		@(negedge clock);
		#1;

		total_checks     = 0;
		total_bins_hit   = 0;
		total_bins_total = 0;
		for (int i = 0; i < SUM_COUNT; i++) begin
			total_checks     = total_checks + probe_checks[i]        ;
			total_bins_hit   = total_bins_hit + probe_bins_hit[i]    ;
			total_bins_total = total_bins_total + probe_bins_total[i];
		end

		if (total_bins_hit != total_bins_total) begin
			$fatal(1, "reduction suite covered %0d of %0d functional bins", total_bins_hit,
				total_bins_total);
		end
		if (total_bins_total != CTX_REDUCTION_BINS) begin
			$fatal(1, "reduction bin denominator %0d differs from the scenario manifest %0d",
				total_bins_total, CTX_REDUCTION_BINS);
		end

		$display("PASS graph_sum_reduce context=%s cycles=%0d checks=%0d bins=%0d/%0d", CTX_LAYOUT,
			cycles, total_checks, total_bins_hit, total_bins_total);
		$finish;
	end
endmodule
