// -----------------------------------------------------------------------------
//      AccelGraph RTL unit harness - graph common families
// -----------------------------------------------------------------------------
// Included inside a module scope. Provides an explicit functional-bin registry
// (declare up front, cover during stimulus, prove closure at the end) and the
// structural checkers shared by the routing, reduction and package suites.
//
// Every bin must be declared before it can be covered, so the functional
// denominator of a run is fixed by the declaration pass and cannot be widened
// or narrowed by the stimulus.
// -----------------------------------------------------------------------------

// The widest value a checker has to carry is the descriptor interface, which is
// one valid bit plus a 64-bit address plus the 1152-bit BFS descriptor.
localparam int HARNESS_MAX_BINS  = 512 ;
localparam int HARNESS_WIDE_BITS = 1280;

string       harness_bin_name[0:HARNESS_MAX_BINS-1];
bit          harness_bin_seen[0:HARNESS_MAX_BINS-1];
int unsigned harness_bin_count;
int unsigned harness_checks;
string       harness_scope;

function automatic int harness_bin_index(input string name);
	harness_bin_index = -1;
	for (int i = 0; i < int'(harness_bin_count); i++) begin
		if (harness_bin_name[i] == name) begin
			harness_bin_index = i;
		end
	end
endfunction

task automatic harness_declare_bin(input string name);
	if (harness_bin_index(name) >= 0) begin
		$fatal(1, "%s: duplicate functional bin '%s'", harness_scope, name);
	end
	if (int'(harness_bin_count) >= HARNESS_MAX_BINS) begin
		$fatal(1, "%s: functional bin capacity exceeded", harness_scope);
	end
	harness_bin_name[harness_bin_count] = name;
	harness_bin_seen[harness_bin_count] = 1'b0;
	harness_bin_count                   = harness_bin_count + 1;
endtask

task automatic harness_cover(input string name);
	int index;
	index = harness_bin_index(name);
	if (index < 0) begin
		$fatal(1, "%s: undeclared functional bin '%s'", harness_scope, name);
	end
	harness_bin_seen[index] = 1'b1;
endtask

function automatic int unsigned harness_bins_hit();
	harness_bins_hit = 0;
	for (int i = 0; i < int'(harness_bin_count); i++) begin
		if (harness_bin_seen[i]) begin
			harness_bins_hit = harness_bins_hit + 1;
		end
	end
endfunction

task automatic harness_report_bins();
	int unsigned missing;
	missing = 0;
	for (int i = 0; i < int'(harness_bin_count); i++) begin
		if (!harness_bin_seen[i]) begin
			missing = missing + 1;
			$display("MISSING-BIN %s %s", harness_scope, harness_bin_name[i]);
		end
	end
	if (missing != 0) begin
		$fatal(1, "%s: %0d of %0d functional bins were not covered", harness_scope,
			missing, harness_bin_count);
	end
endtask

task automatic harness_check_int(
		input string        label ,
		input longint       expected,
		input longint       actual,
		input string        detail
	);
	harness_checks = harness_checks + 1;
	if (expected !== actual) begin
		$error("%s: %s expected=%0d actual=%0d %s", harness_scope, label, expected, actual, detail);
		$fatal(1, "unit contract check failed");
	end
endtask

task automatic harness_check_bits(
		input string                       label ,
		input logic [0:HARNESS_WIDE_BITS-1] expected,
		input logic [0:HARNESS_WIDE_BITS-1] actual,
		input string                       detail
	);
	harness_checks = harness_checks + 1;
	if (expected !== actual) begin
		$error("%s: %s expected=%h actual=%h %s", harness_scope, label, expected, actual, detail);
		$fatal(1, "unit contract check failed");
	end
endtask

task automatic harness_check_string(
		input string label ,
		input string expected,
		input string actual,
		input string detail
	);
	harness_checks = harness_checks + 1;
	if (expected != actual) begin
		$error("%s: %s expected='%s' actual='%s' %s", harness_scope, label, expected, actual, detail);
		$fatal(1, "unit contract check failed");
	end
endtask

// Locates a packed field inside its parent by probing a one-hot-filled copy of
// the parent. `flat` arrives right justified inside HARNESS_WIDE_BITS, so the
// parent bit index is recovered with the `base` offset below.
task automatic harness_check_span(
		input string                        label      ,
		input logic [0:HARNESS_WIDE_BITS-1] flat       ,
		input int                           parent_bits,
		input int                           expect_lsb ,
		input int                           expect_bits
	);
	int base;
	int first;
	int last;
	int population;

	base       = HARNESS_WIDE_BITS - parent_bits;
	first      = -1;
	last       = -1;
	population = 0;
	for (int b = 0; b < parent_bits; b++) begin
		if (flat[base+b] === 1'b1) begin
			if (first < 0) begin
				first = b;
			end
			last       = b;
			population = population + 1;
		end
	end
	harness_checks = harness_checks + 1;
	if (first != expect_lsb || population != expect_bits || (last - first + 1) != expect_bits) begin
		$error(
			"%s: %s field span offset=%0d width=%0d population=%0d expected offset=%0d width=%0d",
			harness_scope, label, first, (last - first + 1), population, expect_lsb, expect_bits);
		$fatal(1, "unit contract check failed");
	end
endtask
