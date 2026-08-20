// -----------------------------------------------------------------------------
//
//      "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Shared, DUT independent helpers for the graph algorithm unit suites:
// deterministic backpressure profiles, a canonical seeded PRNG, and the
// failure-bundle print helpers.  Nothing here imports a production package.
// -----------------------------------------------------------------------------

package ALGO_CHECK_PKG;

	// Graph backpressure domains observable at algorithm-kernel and shell
	// boundaries.  The integration suite adds graph.edge_job on top of these.
	parameter int DOMAIN_VERTEX_JOB = 0; // graph.vertex_job
	parameter int DOMAIN_EDGE_READ  = 1; // graph.edge_read
	parameter int DOMAIN_WRITE      = 2; // graph.write
	parameter int DOMAIN_KERNEL     = 3; // graph.kernel
	parameter int DOMAIN_COUNT      = 4;
	parameter int MASK_COUNT        = 16;

	// Bounded stall period per domain: every stalled domain releases within
	// STALL_PERIOD cycles, so no profile can hide a lost transaction behind a
	// permanent stall.
	parameter int STALL_PERIOD[0:DOMAIN_COUNT-1] = '{3, 2, 5, 4};

	function automatic string domain_name(input int domain);
		case (domain)
			DOMAIN_VERTEX_JOB : return "graph.vertex_job";
			DOMAIN_EDGE_READ  : return "graph.edge_read";
			DOMAIN_WRITE      : return "graph.write";
			DOMAIN_KERNEL     : return "graph.kernel";
			default           : return "graph.unknown";
		endcase
	endfunction

	// Deterministic bounded stall: domain `d` of profile `mask` is stalled for
	// STALL_PERIOD[d] cycles and released for STALL_PERIOD[d] cycles.
	function automatic bit domain_stalled(input int mask, input int domain, input int cycle);
		if (((mask >> domain) & 1) == 0)
			return 1'b0;
		return bit'(((cycle / STALL_PERIOD[domain]) % 2) == 1);
	endfunction

	// Canonical 32-bit xorshift used for the seeded random overlay so that a
	// seed alone reproduces a run.
	function automatic int unsigned prng_next(input int unsigned state);
		int unsigned s;
		s = state;
		s ^= (s << 13);
		s ^= (s >> 17);
		s ^= (s << 5);
		return s;
	endfunction

endpackage
