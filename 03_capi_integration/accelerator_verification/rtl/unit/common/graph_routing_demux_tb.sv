// -----------------------------------------------------------------------------
//      AccelGraph RTL unit test - routing-demux family
// -----------------------------------------------------------------------------
// Devices under test : demux_bus, array_struct_type_demux_bus
// Oracle             : graph-route-payload-model-v1
//
// The oracle is an independent three-stage route/payload journal. It is built
// from the published contract (a demux presents the payload on every output and
// qualifies exactly one output with the selected identifier, three clocks after
// the input is presented) and never reads DUT internals. For the struct-typed
// demux the selector to destination table comes from scenarios.json, not from
// the RTL case list, so a route change in the RTL fails the test.
// -----------------------------------------------------------------------------

import CU_PKG::*;
import GLOBALS_CU_PKG::*;

// -----------------------------------------------------------------------------
// demux_bus probe: drives one parameterisation and self checks it every cycle.
// -----------------------------------------------------------------------------
module demux_bus_probe #(
	parameter int INDEX      = 0 ,
	parameter int DATA_WIDTH = 32,
	parameter int BUS_WIDTH  = 8
) (
	input  logic         clock           ,
	input  logic         rstn            ,
	input  logic [0:63]  drive_sel       ,
	input  logic [0:255] drive_data      ,
	input  logic         drive_valid     ,
	input  int unsigned  phase           ,
	input  logic         finalize        ,
	output int unsigned  probe_checks    ,
	output int unsigned  probe_bins_hit  ,
	output int unsigned  probe_bins_total
);
	`include "graph_common_harness.svh"

	// $clog2(1) is 0, which is a null selector range, so a single destination
	// bus is driven with the smallest legal selector instead.
	localparam int SEL_WIDTH       = (BUS_WIDTH <= 1) ? 1 : $clog2(BUS_WIDTH);
	localparam int SEL_SPACE       = 1 << SEL_WIDTH                          ;
	localparam bit HAS_INVALID_SEL = (SEL_SPACE > BUS_WIDTH)                 ;

	logic [ 0:SEL_WIDTH-1] sel_in                       ;
	logic [0:DATA_WIDTH-1] data_in                      ;
	logic                  data_in_valid                ;
	logic [0:DATA_WIDTH-1] data_out      [0:BUS_WIDTH-1];
	logic                  data_out_valid[0:BUS_WIDTH-1];

	logic [ 0:SEL_WIDTH-1] model_sel  [0:2];
	logic [0:DATA_WIDTH-1] model_data [0:2];
	logic                  model_valid[0:2];

	logic [0:DATA_WIDTH-1] previous_data;
	logic [ 0:SEL_WIDTH-1] previous_sel ;
	int unsigned           cycle        ;

	assign sel_in        = drive_sel[64-SEL_WIDTH:63];
	assign data_in       = drive_data[0:DATA_WIDTH-1];
	assign data_in_valid = drive_valid               ;

	demux_bus #(
		.DATA_WIDTH(DATA_WIDTH),
		.BUS_WIDTH (BUS_WIDTH ),
		.SEL_WIDTH (SEL_WIDTH )
	) dut (
		.clock         (clock         ),
		.rstn          (rstn          ),
		.sel_in        (sel_in        ),
		.data_in       (data_in       ),
		.data_in_valid (data_in_valid ),
		.data_out      (data_out      ),
		.data_out_valid(data_out_valid)
	);

	// Independent route journal: payload and qualified destination, delayed by
	// the contractual three clocks, in the same asynchronous reset domain.
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			if(model_valid[0] === 1'b1 || model_valid[1] === 1'b1 || model_valid[2] === 1'b1) begin
				harness_cover("reset_flush");
			end
			for (int stage = 0; stage < 3; stage++) begin
				model_sel[stage]   <= '0;
				model_data[stage]  <= '0;
				model_valid[stage] <= 1'b0;
			end
		end else begin
			model_sel[0]   <= sel_in       ;
			model_data[0]  <= data_in      ;
			model_valid[0] <= data_in_valid;
			for (int stage = 1; stage < 3; stage++) begin
				model_sel[stage]   <= model_sel[stage-1]  ;
				model_data[stage]  <= model_data[stage-1] ;
				model_valid[stage] <= model_valid[stage-1];
			end
		end
	end

	task automatic dump_state(input int destination);
		$display("ROUTE-JOURNAL %s cycle=%0d", harness_scope, cycle);
		$display("  driven      sel=%0d data=%h valid=%b phase=%0d", sel_in, data_in,
			data_in_valid, phase);
		for (int stage = 0; stage < 3; stage++) begin
			$display("  model[%0d]    sel=%0d data=%h valid=%b", stage, model_sel[stage],
				model_data[stage], model_valid[stage]);
		end
		for (int i = 0; i < BUS_WIDTH; i++) begin
			$display("  dut  out[%0d] data=%h valid=%b", i, data_out[i], data_out_valid[i]);
		end
		$display("  failing destination=%0d", destination);
	endtask

	task automatic check_outputs();
		int unsigned qualified;
		logic        expect_valid;

		qualified = 0;
		for (int i = 0; i < BUS_WIDTH; i++) begin
			expect_valid = model_valid[2] & (int'(model_sel[2]) == i);
			harness_checks = harness_checks + 1;
			if (data_out[i] !== model_data[2]) begin
				dump_state(i);
				$error("%s: route payload mismatch on destination %0d expected=%h actual=%h",
					harness_scope, i, model_data[2], data_out[i]);
				$fatal(1, "route payload mismatch");
			end
			harness_checks = harness_checks + 1;
			if (data_out_valid[i] !== expect_valid) begin
				dump_state(i);
				$error("%s: route qualifier mismatch on destination %0d expected=%b actual=%b", harness_scope, i,
					expect_valid, data_out_valid[i]);
				$fatal(1, "route qualifier mismatch");
			end
			if (data_out_valid[i] === 1'b1) begin
				qualified = qualified + 1;
			end
		end
		harness_checks = harness_checks + 1;
		if (qualified > 1) begin
			dump_state(-1);
			$error("%s: route exclusivity violated, %0d destinations qualified", harness_scope, qualified);
			$fatal(1, "route exclusivity violated");
		end
	endtask

	task automatic declare_bins();
		for (int value = 0; value < SEL_SPACE; value++) begin
			harness_declare_bin($sformatf("sel%0d.routed", value));
			harness_declare_bin($sformatf("sel%0d.idle", value));
		end
		harness_declare_bin("reset_flush" );
		harness_declare_bin("payload_zero");
		harness_declare_bin("payload_ones");
		harness_declare_bin("payload_held");
		if (HAS_INVALID_SEL) begin
			harness_declare_bin("invalid_sel_no_destination");
		end
	endtask

	initial begin
		harness_scope  = $sformatf("demux_bus[%0d] DATA_WIDTH=%0d BUS_WIDTH=%0d SEL_WIDTH=%0d",
			INDEX, DATA_WIDTH, BUS_WIDTH, SEL_WIDTH);
		harness_checks = 0;
		cycle          = 0;
		declare_bins();
		if (BUS_WIDTH > 1 && SEL_WIDTH != $clog2(BUS_WIDTH)) begin
			$fatal(1, "%s: selector width does not follow the module default", harness_scope);
		end
	end

	always @(negedge clock) begin
		cycle = cycle + 1;
		check_outputs();
		if (rstn === 1'b1) begin
			if (data_in_valid === 1'b1) begin
				harness_cover($sformatf("sel%0d.routed", sel_in));
				if (data_in === '0) begin
					harness_cover("payload_zero");
				end
				if (&data_in) begin
					harness_cover("payload_ones");
				end
				if (HAS_INVALID_SEL && (int'(sel_in) >= BUS_WIDTH)) begin
					harness_cover("invalid_sel_no_destination");
				end
				if (phase == 1 && cycle > 1 && data_in === previous_data && sel_in !== previous_sel) begin
					harness_cover("payload_held");
				end
			end else begin
				harness_cover($sformatf("sel%0d.idle", sel_in));
			end
		end
		previous_data = data_in;
		previous_sel  = sel_in ;
	end

	always @(posedge finalize) begin
		harness_report_bins();
		probe_checks     = harness_checks    ;
		probe_bins_hit   = harness_bins_hit();
		probe_bins_total = harness_bin_count ;
	end
endmodule

// -----------------------------------------------------------------------------
// array_struct_type_demux_bus probe: the selector is the layout CU_PKG enum.
// -----------------------------------------------------------------------------
module array_struct_demux_probe #(
	parameter int INDEX      = 0 ,
	parameter int DATA_WIDTH = 32
) (
	input  logic         clock           ,
	input  logic         rstn            ,
	input  logic [0:63]  drive_sel       ,
	input  logic [0:255] drive_data      ,
	input  logic         drive_valid     ,
	input  int unsigned  phase           ,
	input  logic         finalize        ,
	output int unsigned  probe_checks    ,
	output int unsigned  probe_bins_hit  ,
	output int unsigned  probe_bins_total
);
	`include "graph_common_harness.svh"
	`include "graph_common_context.svh"

	// The RTL hardcodes two destinations, so BUS_WIDTH is not a sweep axis.
	localparam int BUS_WIDTH = 2;

	array_struct_type      sel_in                       ;
	logic [0:DATA_WIDTH-1] data_in                      ;
	logic                  data_in_valid                ;
	logic [0:DATA_WIDTH-1] data_out      [0:BUS_WIDTH-1];
	logic                  data_out_valid[0:BUS_WIDTH-1];

	int                    model_dest [0:2];
	logic [0:DATA_WIDTH-1] model_data [0:2];
	logic                  model_valid[0:2];

	logic [0:DATA_WIDTH-1] previous_data;
	int                    previous_sel ;
	int unsigned           cycle        ;

	assign sel_in        = array_struct_type'(drive_sel[32:63]);
	assign data_in       = drive_data[0:DATA_WIDTH-1]          ;
	assign data_in_valid = drive_valid                         ;

	array_struct_type_demux_bus #(
		.DATA_WIDTH(DATA_WIDTH),
		.BUS_WIDTH (BUS_WIDTH )
	) dut (
		.clock         (clock         ),
		.rstn          (rstn          ),
		.sel_in        (sel_in        ),
		.data_in       (data_in       ),
		.data_in_valid (data_in_valid ),
		.data_out      (data_out      ),
		.data_out_valid(data_out_valid)
	);

	// Independent selector decode taken from the reviewed scenario manifest.
	function automatic int oracle_destination(input logic [0:31] selector);
		oracle_destination = -1;
		for (int literal = 0; literal < ROUTE_LITERAL_COUNT; literal++) begin
			if (route_literal_value[literal] == selector) begin
				oracle_destination = route_literal_dest[literal];
			end
		end
	endfunction

	function automatic string oracle_selector_label(input logic [0:31] selector);
		bit found;

		found                = 1'b0;
		oracle_selector_label = "";
		for (int literal = 0; literal < ROUTE_LITERAL_COUNT; literal++) begin
			if (route_literal_value[literal] == selector) begin
				oracle_selector_label = route_literal_name[literal];
				found                 = 1'b1;
			end
		end
		if (!found) begin
			oracle_selector_label = (selector == 32'hFFFF_FFFF) ? "invalid_max" : "invalid_first";
		end
	endfunction

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			if(model_valid[0] === 1'b1 || model_valid[1] === 1'b1 || model_valid[2] === 1'b1) begin
				harness_cover("reset_flush");
			end
			for (int stage = 0; stage < 3; stage++) begin
				model_dest[stage]  <= -1  ;
				model_data[stage]  <= '0  ;
				model_valid[stage] <= 1'b0;
			end
		end else begin
			model_dest[0]  <= oracle_destination(drive_sel[32:63]);
			model_data[0]  <= data_in                             ;
			model_valid[0] <= data_in_valid                       ;
			for (int stage = 1; stage < 3; stage++) begin
				model_dest[stage]  <= model_dest[stage-1] ;
				model_data[stage]  <= model_data[stage-1] ;
				model_valid[stage] <= model_valid[stage-1];
			end
		end
	end

	task automatic dump_state(input int destination);
		$display("ROUTE-JOURNAL %s cycle=%0d", harness_scope, cycle);
		$display("  driven      sel=%0d(%s) data=%h valid=%b phase=%0d", drive_sel[32:63],
			oracle_selector_label(drive_sel[32:63]), data_in, data_in_valid, phase);
		for (int stage = 0; stage < 3; stage++) begin
			$display("  model[%0d]    destination=%0d data=%h valid=%b", stage, model_dest[stage],
				model_data[stage], model_valid[stage]);
		end
		for (int i = 0; i < BUS_WIDTH; i++) begin
			$display("  dut  out[%0d] data=%h valid=%b", i, data_out[i], data_out_valid[i]);
		end
		$display("  failing destination=%0d", destination);
	endtask

	task automatic check_outputs();
		int unsigned qualified;
		logic        expect_valid;

		qualified = 0;
		for (int i = 0; i < BUS_WIDTH; i++) begin
			expect_valid = model_valid[2] & (model_dest[2] == i);
			harness_checks = harness_checks + 1;
			if (data_out[i] !== model_data[2]) begin
				dump_state(i);
				$error("%s: route payload mismatch on destination %0d expected=%h actual=%h",
					harness_scope, i, model_data[2], data_out[i]);
				$fatal(1, "route payload mismatch");
			end
			harness_checks = harness_checks + 1;
			if (data_out_valid[i] !== expect_valid) begin
				dump_state(i);
				$error("%s: route qualifier mismatch on destination %0d expected=%b actual=%b", harness_scope, i,
					expect_valid, data_out_valid[i]);
				$fatal(1, "route qualifier mismatch");
			end
			if (data_out_valid[i] === 1'b1) begin
				qualified = qualified + 1;
			end
		end
		harness_checks = harness_checks + 1;
		if (qualified > 1) begin
			dump_state(-1);
			$error("%s: route exclusivity violated, %0d destinations qualified", harness_scope, qualified);
			$fatal(1, "route exclusivity violated");
		end
	endtask

	task automatic check_enum_contract();
		array_struct_type literal;

		harness_check_int("array_struct_type literal count", ROUTE_LITERAL_COUNT, literal.num(),
			"CU_PKG enum size differs from the scenario manifest");
		literal = literal.first();
		for (int index = 0; index < ROUTE_LITERAL_COUNT; index++) begin
			harness_check_string($sformatf("array_struct_type[%0d] name", index),
				route_literal_name[index], literal.name(), "CU_PKG enum order changed");
			harness_check_int($sformatf("array_struct_type[%0d] value", index),
				route_literal_value[index], int'(literal), "CU_PKG enum encoding changed");
			literal = literal.next();
		end
	endtask

	task automatic declare_bins();
		for (int literal = 0; literal < ROUTE_LITERAL_COUNT; literal++) begin
			harness_declare_bin($sformatf("sel.%s.routed", route_literal_name[literal]));
			harness_declare_bin($sformatf("sel.%s.idle", route_literal_name[literal]));
		end
		harness_declare_bin("sel.invalid_first.routed");
		harness_declare_bin("sel.invalid_first.idle"  );
		harness_declare_bin("sel.invalid_max.routed"  );
		harness_declare_bin("sel.invalid_max.idle"    );
		harness_declare_bin("reset_flush" );
		harness_declare_bin("payload_zero");
		harness_declare_bin("payload_ones");
		harness_declare_bin("payload_held");
	endtask

	initial begin
		harness_scope  = $sformatf("array_struct_type_demux_bus[%0d] DATA_WIDTH=%0d BUS_WIDTH=%0d",
			INDEX, DATA_WIDTH, BUS_WIDTH);
		harness_checks = 0;
		cycle          = 0;
		route_oracle_load();
		declare_bins();
		check_enum_contract();
	end

	always @(negedge clock) begin
		string label;

		cycle = cycle + 1;
		check_outputs();
		if (rstn === 1'b1) begin
			label = oracle_selector_label(drive_sel[32:63]);
			if (data_in_valid === 1'b1) begin
				harness_cover($sformatf("sel.%s.routed", label));
				if (data_in === '0) begin
					harness_cover("payload_zero");
				end
				if (&data_in) begin
					harness_cover("payload_ones");
				end
				if (phase == 1 && cycle > 1 && data_in === previous_data &&
						int'(drive_sel[32:63]) != previous_sel) begin
					harness_cover("payload_held");
				end
			end else begin
				harness_cover($sformatf("sel.%s.idle", label));
			end
		end
		previous_data = data_in              ;
		previous_sel  = int'(drive_sel[32:63]);
	end

	always @(posedge finalize) begin
		harness_report_bins();
		probe_checks     = harness_checks    ;
		probe_bins_hit   = harness_bins_hit();
		probe_bins_total = harness_bin_count ;
	end
endmodule

// -----------------------------------------------------------------------------
// Routing suite top level.
// -----------------------------------------------------------------------------
module graph_routing_demux_tb;
	`include "graph_common_context.svh"

	localparam int DEMUX_COUNT                = 7                                                        ;
	localparam int DEMUX_DATA[0:DEMUX_COUNT-1] = '{32, 1, 33, 7, 64, VERTEX_SIZE_BITS, EDGE_SIZE_BITS}    ;
	localparam int DEMUX_BUS [0:DEMUX_COUNT-1] = '{8, 1, 3, 5, 2, NUM_GRAPH_CU_GLOBAL, NUM_VERTEX_CU_GLOBAL};

	localparam int STRUCT_COUNT                 = 3           ;
	localparam int STRUCT_DATA[0:STRUCT_COUNT-1] = '{32, 1, 33};

	localparam int SELECTOR_SWEEP = 256;

	logic         clock       = 1'b0;
	// The reset is asynchronous for the devices under test and sampled
	// synchronously by the stimulus, which is a testbench only pattern.
	/* verilator lint_off SYNCASYNCNET */
	logic         rstn        = 1'b1;
	/* verilator lint_on SYNCASYNCNET */
	logic [0:63]  drive_sel   = '0  ;
	logic [0:255] drive_data  = '0  ;
	logic         drive_valid = 1'b0;
	int unsigned  phase       = 0   ;
	logic         finalize    = 1'b0;

	int unsigned demux_checks    [0:DEMUX_COUNT-1];
	int unsigned demux_bins_hit  [0:DEMUX_COUNT-1];
	int unsigned demux_bins_total[0:DEMUX_COUNT-1];

	int unsigned struct_checks    [0:STRUCT_COUNT-1];
	int unsigned struct_bins_hit  [0:STRUCT_COUNT-1];
	int unsigned struct_bins_total[0:STRUCT_COUNT-1];

	int unsigned total_checks    ;
	int unsigned total_bins_hit  ;
	int unsigned total_bins_total;
	int unsigned cycles          ;

	always #5 clock = ~clock;

	generate
		for (genvar i = 0; i < DEMUX_COUNT; i++) begin : generate_demux_probe
			demux_bus_probe #(
				.INDEX     (i            ),
				.DATA_WIDTH(DEMUX_DATA[i]),
				.BUS_WIDTH (DEMUX_BUS[i] )
			) probe (
				.clock           (clock              ),
				.rstn            (rstn               ),
				.drive_sel       (drive_sel          ),
				.drive_data      (drive_data         ),
				.drive_valid     (drive_valid        ),
				.phase           (phase              ),
				.finalize        (finalize           ),
				.probe_checks    (demux_checks[i]    ),
				.probe_bins_hit  (demux_bins_hit[i]  ),
				.probe_bins_total(demux_bins_total[i])
			);
		end
	endgenerate

	generate
		for (genvar i = 0; i < STRUCT_COUNT; i++) begin : generate_struct_probe
			array_struct_demux_probe #(
				.INDEX     (i             ),
				.DATA_WIDTH(STRUCT_DATA[i])
			) probe (
				.clock           (clock               ),
				.rstn            (rstn                ),
				.drive_sel       (drive_sel           ),
				.drive_data      (drive_data          ),
				.drive_valid     (drive_valid         ),
				.phase           (phase               ),
				.finalize        (finalize            ),
				.probe_checks    (struct_checks[i]    ),
				.probe_bins_hit  (struct_bins_hit[i]  ),
				.probe_bins_total(struct_bins_total[i])
			);
		end
	endgenerate

	function automatic logic [0:255] payload_pattern(input int kind, input int seed);
		case (kind)
			0      : payload_pattern = '0;
			1      : payload_pattern = '1;
			2      : payload_pattern = {8{32'h5A5A_A5A5}} ^ {8{seed}};
			default: payload_pattern = {8{32'hDEAD_BEEF}} + {8{seed}};
		endcase
	endfunction

	task automatic drive_cycle(
			input logic [0:63]  selector,
			input logic [0:255] payload ,
			input logic         valid
		);
		@(negedge clock);
		#1;
		drive_sel   = selector  ;
		drive_data  = payload   ;
		drive_valid = valid     ;
		cycles      = cycles + 1;
	endtask

	initial begin
		logic [0:255] payload;

		cycles = 0;
		phase  = 2;

		// Asynchronous reset before the first clock edge, then disabled idle.
		#1;
		rstn = 1'b0;
		repeat (4) drive_cycle(64'h0000_0000_0000_0003, '1, 1'b1);
		rstn = 1'b1;
		repeat (4) drive_cycle(64'd0, '0, 1'b0);

		// Every selector value of every instance, with and without a qualifier,
		// crossed with boundary and pseudo random payloads.
		phase = 0;
		for (int selector = 0; selector < SELECTOR_SWEEP; selector++) begin
			for (int kind = 0; kind < 4; kind++) begin
				payload = payload_pattern(kind, selector);
				drive_cycle(64'(selector), payload, 1'b1);
				drive_cycle(64'(selector), payload, 1'b0);
			end
		end

		// Out of range struct selectors: first unassigned encoding and all ones.
		for (int kind = 0; kind < 4; kind++) begin
			payload = payload_pattern(kind, 7);
			drive_cycle(64'(ROUTE_LITERAL_COUNT), payload, 1'b1);
			drive_cycle(64'(ROUTE_LITERAL_COUNT), payload, 1'b0);
			drive_cycle(64'h0000_0000_FFFF_FFFF, payload, 1'b1);
			drive_cycle(64'h0000_0000_FFFF_FFFF, payload, 1'b0);
		end

		// Held payload while the selector walks the whole space.
		phase   = 1;
		payload = {8{32'h0F0F_F0F0}};
		for (int pass = 0; pass < 2; pass++) begin
			for (int selector = 0; selector < SELECTOR_SWEEP; selector++) begin
				drive_cycle(64'(selector), payload, 1'b1);
			end
		end

		// Reset asserted with traffic in flight.
		phase = 2;
		repeat (3) drive_cycle(64'd1, '1, 1'b1);
		rstn = 1'b0;
		repeat (3) drive_cycle(64'd1, '1, 1'b1);
		rstn = 1'b1;
		repeat (6) drive_cycle(64'd0, '0, 1'b0);

		@(negedge clock);
		#1;
		finalize = 1'b1;
		@(negedge clock);
		#1;

		total_checks     = 0;
		total_bins_hit   = 0;
		total_bins_total = 0;
		for (int i = 0; i < DEMUX_COUNT; i++) begin
			total_checks     = total_checks + demux_checks[i]        ;
			total_bins_hit   = total_bins_hit + demux_bins_hit[i]    ;
			total_bins_total = total_bins_total + demux_bins_total[i];
		end
		for (int i = 0; i < STRUCT_COUNT; i++) begin
			total_checks     = total_checks + struct_checks[i]        ;
			total_bins_hit   = total_bins_hit + struct_bins_hit[i]    ;
			total_bins_total = total_bins_total + struct_bins_total[i];
		end

		if (total_bins_hit != total_bins_total) begin
			$fatal(1, "routing suite covered %0d of %0d functional bins", total_bins_hit,
				total_bins_total);
		end
		if (total_bins_total != CTX_ROUTING_BINS) begin
			$fatal(1, "routing bin denominator %0d differs from the scenario manifest %0d",
				total_bins_total, CTX_ROUTING_BINS);
		end

		$display("PASS graph_routing_demux context=%s cycles=%0d checks=%0d bins=%0d/%0d",
			CTX_LAYOUT, cycles, total_checks, total_bins_hit, total_bins_total);
		$finish;
	end
endmodule
