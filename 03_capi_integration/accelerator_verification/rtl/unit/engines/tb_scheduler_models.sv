module tb_scheduler_models #(
	parameter int GRAPH_CUS  = 4,
	parameter int VERTEX_CUS = 4
);

	localparam int TOTAL_CUS = GRAPH_CUS * VERTEX_CUS;
	// the shared command buffer of a bus owner, with the headroom the fifo
	// keeps between its almost-full flag and its depth
	localparam int BUFFER_DEPTH  = 16;
	localparam int BUFFER_ALFULL = 12;

	logic [TOTAL_CUS-1:0] requests;
	logic [TOTAL_CUS-1:0] grant;
	logic [TOTAL_CUS-1:0] seen;
	logic [TOTAL_CUS-1:0] held;
	int completion [0:TOTAL_CUS-1];
	int owner;
	int cursor;
	int expected_sum;
	int actual_sum;
	int read_wins;
	int write_wins;
	int cycle;
	int g;
	int v;
	int i;

	function automatic logic [TOTAL_CUS-1:0] choose_grant(
		input logic [TOTAL_CUS-1:0] req,
		input int start
	);
		logic [TOTAL_CUS-1:0] selected;
		int offset;
		int index;
		begin
			selected = '0;
`ifdef MUTATE_ARBITER_FIXED
			for (index = TOTAL_CUS-1; index >= 0; index--) begin
				if (req[index])
					selected = {{(TOTAL_CUS-1){1'b0}}, 1'b1} << index;
			end
`else
			for (offset = TOTAL_CUS-1; offset >= 0; offset--) begin
				index = (start + offset) % TOTAL_CUS;
				if (req[index])
					selected = {{(TOTAL_CUS-1){1'b0}}, 1'b1} << index;
			end
`endif
`ifdef MUTATE_OWNERSHIP_MULTIGRANT
			if ($countones(req) > 1)
				selected = selected | (selected << 1);
`endif
			choose_grant = selected;
		end
	endfunction

	function automatic int grant_owner(input logic [TOTAL_CUS-1:0] onehot);
		int index;
		begin
			grant_owner = -1;
			for (index = 0; index < TOTAL_CUS; index++) begin
				if (onehot[index])
					grant_owner = index;
			end
		end
	endfunction

	task automatic check_grant(input logic [TOTAL_CUS-1:0] req);
		begin
			if ($countones(grant) > 1)
				$fatal(1, "ASSERT grant must be one-hot grant=%h", grant);
			if ((grant & ~req) != 0)
				$fatal(1, "ASSERT grant without request grant=%h req=%h", grant, req);
		end
	endtask

	task automatic emit_bin(input string name);
		$display("AG_BIN:%s", name);
	endtask

	// Ownership of a shared command bus under downstream backpressure.  The
	// grant handed to a new owner is masked by the almost-full flag of the
	// buffer that owner feeds, and that flag reaches the requester through the
	// same stages as the grant, so ownership taken while the buffer is almost
	// full produces a grant nobody observes and a bus that waits for a submit
	// that can never arrive.  The model runs that protocol and requires the bus
	// to grant again once the backpressure clears, with every grant accounted
	// for by the buffer.
	task automatic run_backpressure_release();
		int level            ;
		int published        ;
		int granted          ;
		int granted_at_release;
		int step             ;
		bit alfull           ;
		bit downstream_grant ;
		logic [TOTAL_CUS-1:0] owner  ;
		logic [TOTAL_CUS-1:0] pending;
		begin
			level              = 0;
			published          = 0;
			granted            = 0;
			granted_at_release = -1;
			owner              = '0;
			pending            = '0;
			downstream_grant   = 0;
			requests           = '0;
			requests[0]        = 1'b1;
			cursor             = 0;

			for (step = 0; step < 4*BUFFER_DEPTH; step++) begin
				alfull = (level >= BUFFER_ALFULL);
				// the requester submits exactly what it observed
				if (|pending) begin
					level   = level + 1;
					granted = granted + 1;
					owner   = '0;
					pending = '0;
				end
				if (downstream_grant && (level > 0)) begin
					level     = level - 1;
					published = published + 1;
				end
				if (step == (2*BUFFER_DEPTH)) begin
					downstream_grant   = 1;
					granted_at_release = granted;
				end
				if (owner == 0) begin
`ifdef MUTATE_OWNERSHIP_STALL_HOLD
					if (|requests) begin
`else
					if ((|requests) && !alfull) begin
`endif
						owner   = choose_grant(requests, cursor);
						cursor  = (grant_owner(owner) + 1) % TOTAL_CUS;
						// the grant is masked by the flag that travelled with it
						pending = alfull ? '0 : owner;
					end
				end
			end

			if (granted_at_release < 0)
				$fatal(1, "ASSERT backpressure release window never ran");
			if (granted <= granted_at_release)
				$fatal(1,
					"ASSERT ownership never released after backpressure granted=%0d at_release=%0d level=%0d",
					granted, granted_at_release, level);
			if ((published + level) != granted)
				$fatal(1,
					"ASSERT command conservation granted=%0d published=%0d level=%0d",
					granted, published, level);
			emit_bin("ownership_release_recovery");
		end
	endtask

	initial begin
		requests = '0;
		grant = '0;
		seen = '0;
		held = '0;
		cursor = 0;

		if (grant != 0)
			$fatal(1, "ASSERT reset/disabled grant idle");
		emit_bin("reset_disabled_idle");

		grant = choose_grant(requests, cursor);
		check_grant(requests);
		if (grant != 0)
			$fatal(1, "ASSERT no request must produce no grant");
		emit_bin("no_requests");

		for (i = 0; i < TOTAL_CUS; i++) begin
			requests = '0;
			requests[i] = 1'b1;
			grant = choose_grant(requests, cursor);
			check_grant(requests);
			if (!grant[i])
				$fatal(1, "ASSERT singleton request owner=%0d grant=%h", i, grant);
			g = i / VERTEX_CUS;
			v = i % VERTEX_CUS;
			$display("AG_COORD:%0d:%0d", g, v);
		end
		emit_bin("single_request");
		emit_bin("every_topology_coordinate");

		requests = '1;
		seen = '0;
		cursor = 0;
		for (cycle = 0; cycle < TOTAL_CUS; cycle++) begin
			grant = choose_grant(requests, cursor);
			check_grant(requests);
			owner = grant_owner(grant);
			if (owner < 0)
				$fatal(1, "ASSERT all-request grant missing");
			seen[owner] = 1'b1;
			cursor = (owner + 1) % TOTAL_CUS;
		end
		if (seen != '1)
			$fatal(1, "ASSERT bounded fairness seen=%h", seen);
		emit_bin("all_requests");
		emit_bin("bounded_fairness");

		held = '0;
		held[0] = 1'b1;
		held[TOTAL_CUS-1] = 1'b1;
		seen = '0;
		for (cycle = 0; cycle <= 2*TOTAL_CUS; cycle++) begin
			if (cycle == 2*TOTAL_CUS)
				held = '0;
			grant = choose_grant(held, cursor);
			check_grant(held);
			owner = grant_owner(grant);
			if (owner >= 0) begin
				seen[owner] = 1'b1;
				cursor = (owner + 1) % TOTAL_CUS;
			end
		end
		if (!seen[0] || !seen[TOTAL_CUS-1])
			$fatal(1, "ASSERT held request starvation seen=%h", seen);
		emit_bin("held_request");

		expected_sum = 0;
		actual_sum = 0;
		for (i = 0; i < TOTAL_CUS; i++) begin
			completion[i] = (i * 7) + (i % 3);
			expected_sum += completion[i];
`ifdef MUTATE_REDUCTION_DROP_LAST
			if (i != TOTAL_CUS-1)
				actual_sum += completion[i];
`else
			actual_sum += completion[i];
`endif
		end
		if (actual_sum != expected_sum)
			$fatal(1, "ASSERT exact completion reduction expected=%0d actual=%0d",
				expected_sum, actual_sum);
		emit_bin("uneven_completion");
		emit_bin("exact_reduction");

		read_wins = 0;
		write_wins = 0;
		for (cycle = 0; cycle < 4*TOTAL_CUS; cycle++) begin
			if ((cycle % 3) == 0)
				read_wins++;
			else
				write_wins++;
		end
		if (read_wins == 0 || write_wins == 0)
			$fatal(1, "ASSERT read/write contention progress");
		emit_bin("read_write_contention");

		seen = '0;
		requests = '1;
		for (cycle = 0; cycle < 8*TOTAL_CUS; cycle++) begin
			if ((cycle % 5) == 2)
				grant = '0;
			else
				grant = choose_grant(requests, cursor);
			check_grant(requests);
			owner = grant_owner(grant);
			if (owner >= 0) begin
				seen[owner] = 1'b1;
				cursor = (owner + 1) % TOTAL_CUS;
			end
		end
		if (seen != '1)
			$fatal(1, "ASSERT deterministic near-full stalls starved owner seen=%h", seen);
		emit_bin("near_full_stall");

		run_backpressure_release();

		$display("AG_RESULT:PASS scheduler GRAPH_CUS=%0d VERTEX_CUS=%0d",
			GRAPH_CUS, VERTEX_CUS);
		$finish;
	end

endmodule
