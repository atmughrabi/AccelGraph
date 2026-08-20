// -----------------------------------------------------------------------------
//
//      "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Independent tiny-graph fixture registry and golden helpers.
//
// This package is authored independently of the production RTL and of the
// OpenGraph host library.  It never calls OpenGraph, AccelGraph host, or DUT
// preprocessing/arithmetic functions.  Fixtures are hand authored source edge
// lists; CSR / inverse-CSR views are derived here by an independent counting
// implementation so that a DUT-side CSR defect cannot hide behind a shared
// helper.
// -----------------------------------------------------------------------------

package GRAPH_FIXTURE_PKG;

	parameter int FIXTURE_COUNT   = 13;
	parameter int FX_MAX_VERTICES = 5 ;
	parameter int FX_MAX_EDGES    = 12;

	parameter int FX_EMPTY            = 0 ;
	parameter int FX_SINGLE_VERTEX    = 1 ;
	parameter int FX_CHAIN            = 2 ;
	parameter int FX_STAR             = 3 ;
	parameter int FX_CYCLE            = 4 ;
	parameter int FX_DISCONNECTED     = 5 ;
	parameter int FX_SELF_LOOP        = 6 ;
	parameter int FX_DUPLICATE_EDGE   = 7 ;
	parameter int FX_TRIANGLE         = 8 ;
	parameter int FX_SHARED_TRIANGLES = 9 ;
	parameter int FX_K4               = 10;
	parameter int FX_WEIGHTED_MATRIX  = 11;
	parameter int FX_SINK             = 12;

	// Vertex counts of every fixture.
	parameter int FX_NUM_VERTICES[0:FIXTURE_COUNT-1] = '{
		0, // empty
		1, // single vertex
		4, // directed chain
		5, // star
		3, // directed cycle
		4, // disconnected components
		2, // self loop
		2, // duplicate edge
		3, // one triangle (bidirectional)
		4, // shared-edge triangles
		4, // K4
		3, // weighted toy matrix
		4  // dangling sink plus isolated vertex
	};

	parameter int FX_NUM_EDGES[0:FIXTURE_COUNT-1] = '{
		0, 0, 3, 4, 3, 2, 2, 2, 6, 10, 12, 5, 2
	};

	// Source endpoint of every hand authored edge.
	parameter int FX_EDGE_SRC[0:FIXTURE_COUNT-1][0:FX_MAX_EDGES-1] = '{
		'{0,0,0,0,0,0,0,0,0,0,0,0},                 // empty
		'{0,0,0,0,0,0,0,0,0,0,0,0},                 // single vertex
		'{0,1,2,0,0,0,0,0,0,0,0,0},                 // chain 0->1->2->3
		'{0,0,0,0,0,0,0,0,0,0,0,0},                 // star 0->{1,2,3,4}
		'{0,1,2,0,0,0,0,0,0,0,0,0},                 // cycle 0->1->2->0
		'{0,2,0,0,0,0,0,0,0,0,0,0},                 // 0->1, 2->3
		'{0,0,0,0,0,0,0,0,0,0,0,0},                 // 0->0, 0->1
		'{0,0,0,0,0,0,0,0,0,0,0,0},                 // 0->1, 0->1
		'{0,1,1,2,0,2,0,0,0,0,0,0},                 // triangle 0-1-2
		'{0,1,0,2,1,2,1,3,2,3,0,0},                 // triangles 0-1-2 and 1-2-3
		'{0,1,0,2,0,3,1,2,1,3,2,3},                 // K4
		'{0,0,1,2,2,0,0,0,0,0,0,0},                 // weighted toy matrix
		'{0,1,0,0,0,0,0,0,0,0,0,0}                  // 0->1->2, vertex 3 isolated
	};

	// Destination endpoint of every hand authored edge.
	parameter int FX_EDGE_DEST[0:FIXTURE_COUNT-1][0:FX_MAX_EDGES-1] = '{
		'{0,0,0,0,0,0,0,0,0,0,0,0},
		'{0,0,0,0,0,0,0,0,0,0,0,0},
		'{1,2,3,0,0,0,0,0,0,0,0,0},
		'{1,2,3,4,0,0,0,0,0,0,0,0},
		'{1,2,0,0,0,0,0,0,0,0,0,0},
		'{1,3,0,0,0,0,0,0,0,0,0,0},
		'{0,1,0,0,0,0,0,0,0,0,0,0},
		'{1,1,0,0,0,0,0,0,0,0,0,0},
		'{1,0,2,1,2,0,0,0,0,0,0,0},
		'{1,0,2,0,2,1,3,1,3,2,0,0},
		'{1,0,2,0,3,0,2,1,3,1,3,2},
		'{0,1,2,0,2,0,0,0,0,0,0,0},
		'{1,2,0,0,0,0,0,0,0,0,0,0}
	};

	// Edge weights.  Unweighted fixtures use 1 so that a weighted kernel that
	// ignores the weight array is still distinguishable from one that reads it.
	parameter int FX_EDGE_WEIGHT[0:FIXTURE_COUNT-1][0:FX_MAX_EDGES-1] = '{
		'{0,0,0,0,0,0,0,0,0,0,0,0},
		'{0,0,0,0,0,0,0,0,0,0,0,0},
		'{1,2,3,0,0,0,0,0,0,0,0,0},
		'{1,2,3,4,0,0,0,0,0,0,0,0},
		'{2,3,4,0,0,0,0,0,0,0,0,0},
		'{5,6,0,0,0,0,0,0,0,0,0,0},
		'{7,8,0,0,0,0,0,0,0,0,0,0},
		'{3,3,0,0,0,0,0,0,0,0,0,0},
		'{1,1,1,1,1,1,0,0,0,0,0,0},
		'{1,1,1,1,1,1,1,1,1,1,0,0},
		'{1,1,1,1,1,1,1,1,1,1,1,1},
		'{65535,3,100,7,2,0,0,0,0,0,0,0},
		'{1,1,0,0,0,0,0,0,0,0,0,0}
	};

	function automatic string fixture_name(input int fx);
		case (fx)
			FX_EMPTY            : return "empty";
			FX_SINGLE_VERTEX    : return "single-vertex";
			FX_CHAIN            : return "directed-chain";
			FX_STAR             : return "star";
			FX_CYCLE            : return "directed-cycle";
			FX_DISCONNECTED     : return "disconnected";
			FX_SELF_LOOP        : return "self-loop";
			FX_DUPLICATE_EDGE   : return "duplicate-edge";
			FX_TRIANGLE         : return "one-triangle";
			FX_SHARED_TRIANGLES : return "shared-edge-triangles";
			FX_K4               : return "k4";
			FX_WEIGHTED_MATRIX  : return "weighted-toy-matrix";
			FX_SINK             : return "dangling-sink";
			default             : return "unknown";
		endcase
	endfunction

	// Number of edges that terminate at `vertex` (inverse CSR out degree of the
	// PULL traversal).  Derived from the source edge list only.
	function automatic int inverse_degree(input int fx, input int vertex);
		int count;
		count = 0;
		for (int e = 0; e < FX_NUM_EDGES[fx]; e++)
			if (FX_EDGE_DEST[fx][e] == vertex)
				count++;
		return count;
	endfunction

	// Edge-list index of the k-th incoming edge of `vertex`, or -1.
	function automatic int inverse_edge_index(input int fx, input int vertex, input int k);
		int count;
		count = 0;
		for (int e = 0; e < FX_NUM_EDGES[fx]; e++) begin
			if (FX_EDGE_DEST[fx][e] == vertex) begin
				if (count == k)
					return e;
				count++;
			end
		end
		return -1;
	endfunction

	function automatic int inverse_neighbor(input int fx, input int vertex, input int k);
		int e;
		e = inverse_edge_index(fx, vertex, k);
		return (e < 0) ? -1 : FX_EDGE_SRC[fx][e];
	endfunction

	function automatic int inverse_weight(input int fx, input int vertex, input int k);
		int e;
		e = inverse_edge_index(fx, vertex, k);
		return (e < 0) ? 0 : FX_EDGE_WEIGHT[fx][e];
	endfunction

	function automatic int out_degree(input int fx, input int vertex);
		int count;
		count = 0;
		for (int e = 0; e < FX_NUM_EDGES[fx]; e++)
			if (FX_EDGE_SRC[fx][e] == vertex)
				count++;
		return count;
	endfunction

	function automatic int out_edge_index(input int fx, input int vertex, input int k);
		int count;
		count = 0;
		for (int e = 0; e < FX_NUM_EDGES[fx]; e++) begin
			if (FX_EDGE_SRC[fx][e] == vertex) begin
				if (count == k)
					return e;
				count++;
			end
		end
		return -1;
	endfunction

	function automatic int out_neighbor(input int fx, input int vertex, input int k);
		int e;
		e = out_edge_index(fx, vertex, k);
		return (e < 0) ? -1 : FX_EDGE_DEST[fx][e];
	endfunction

	function automatic bit has_edge(input int fx, input int src, input int dest);
		for (int e = 0; e < FX_NUM_EDGES[fx]; e++)
			if (FX_EDGE_SRC[fx][e] == src && FX_EDGE_DEST[fx][e] == dest)
				return 1'b1;
		return 1'b0;
	endfunction

	// Independent per-vertex triangle count over the undirected simple graph
	// implied by the fixture: neighbours of `vertex` that are themselves
	// adjacent, counted once per unordered pair.  Self loops are excluded.
	function automatic int triangle_count_vertex(input int fx, input int vertex);
		int total;
		total = 0;
		for (int a = 0; a < FX_NUM_VERTICES[fx]; a++) begin
			if (a == vertex)
				continue;
			if (!(has_edge(fx, vertex, a) || has_edge(fx, a, vertex)))
				continue;
			for (int b = a + 1; b < FX_NUM_VERTICES[fx]; b++) begin
				if (b == vertex)
					continue;
				if (!(has_edge(fx, vertex, b) || has_edge(fx, b, vertex)))
					continue;
				if (has_edge(fx, a, b) || has_edge(fx, b, a))
					total++;
			end
		end
		return total;
	endfunction

	function automatic bit adjacent(input int fx, input int a, input int b);
		if (a == b)
			return 1'b0;
		return has_edge(fx, a, b) || has_edge(fx, b, a);
	endfunction

	// Distinct undirected neighbours of a vertex, in ascending identifier order.
	function automatic int neighbour_count(input int fx, input int v);
		int count;
		count = 0;
		for (int u = 0; u < FX_NUM_VERTICES[fx]; u++)
			if (adjacent(fx, v, u))
				count++;
		return count;
	endfunction

	function automatic int neighbour_at(input int fx, input int v, input int k);
		int count;
		count = 0;
		for (int u = 0; u < FX_NUM_VERTICES[fx]; u++) begin
			if (adjacent(fx, v, u)) begin
				if (count == k)
					return u;
				count++;
			end
		end
		return -1;
	endfunction

	// Candidate pairs of neighbours the sorted-neighbour intersection walk
	// compares for a vertex: one element per unordered pair.
	function automatic int pair_count(input int fx, input int v);
		int n;
		n = neighbour_count(fx, v);
		return (n * (n - 1)) / 2;
	endfunction

	function automatic int pair_a(input int fx, input int v, input int k);
		int n;
		int index;
		n     = neighbour_count(fx, v);
		index = 0;
		for (int i = 0; i < n; i++)
			for (int j = i + 1; j < n; j++) begin
				if (index == k)
					return neighbour_at(fx, v, i);
				index++;
			end
		return -1;
	endfunction

	function automatic int pair_b(input int fx, input int v, input int k);
		int n;
		int index;
		n     = neighbour_count(fx, v);
		index = 0;
		for (int i = 0; i < n; i++)
			for (int j = i + 1; j < n; j++) begin
				if (index == k)
					return neighbour_at(fx, v, j);
				index++;
			end
		return -1;
	endfunction

	// Normalised total triangle count: sum of per-vertex counts divided by 3.
	function automatic int triangle_count_total(input int fx);
		int total;
		total = 0;
		for (int v = 0; v < FX_NUM_VERTICES[fx]; v++)
			total += triangle_count_vertex(fx, v);
		return total / 3;
	endfunction

	// Independent breadth-first distances from `root` over the forward edge
	// list.  Returns -1 for unreachable vertices through `distance_of`.
	function automatic int bfs_distance(input int fx, input int root, input int vertex);
		int distance[FX_MAX_VERTICES];
		int frontier;
		int level;
		int changed;
		for (int v = 0; v < FX_MAX_VERTICES; v++)
			distance[v] = -1;
		if (FX_NUM_VERTICES[fx] == 0 || root >= FX_NUM_VERTICES[fx])
			return -1;
		distance[root] = 0;
		level          = 0;
		frontier       = 1;
		while (frontier > 0) begin
			changed = 0;
			for (int e = 0; e < FX_NUM_EDGES[fx]; e++) begin
				if (distance[FX_EDGE_SRC[fx][e]] == level &&
				    distance[FX_EDGE_DEST[fx][e]] == -1 &&
				    FX_EDGE_DEST[fx][e] != FX_EDGE_SRC[fx][e]) begin
					distance[FX_EDGE_DEST[fx][e]] = level + 1;
					changed                       = 1;
				end
			end
			level++;
			frontier = changed;
		end
		return distance[vertex];
	endfunction

	// Independent connected-component label (minimum reachable vertex id over
	// the undirected closure) used to canonicalise partitions.
	function automatic int component_label(input int fx, input int vertex);
		int label[FX_MAX_VERTICES];
		bit changed;
		for (int v = 0; v < FX_MAX_VERTICES; v++)
			label[v] = v;
		changed = 1'b1;
		while (changed) begin
			changed = 1'b0;
			for (int e = 0; e < FX_NUM_EDGES[fx]; e++) begin
				int a;
				int b;
				a = label[FX_EDGE_SRC[fx][e]];
				b = label[FX_EDGE_DEST[fx][e]];
				if (a < b) begin
					label[FX_EDGE_DEST[fx][e]] = a;
					changed                    = 1'b1;
				end else if (b < a) begin
					label[FX_EDGE_SRC[fx][e]] = b;
					changed                   = 1'b1;
				end
			end
			for (int v = 0; v < FX_NUM_VERTICES[fx]; v++) begin
				if (label[v] != label[label[v]]) begin
					label[v] = label[label[v]];
					changed  = 1'b1;
				end
			end
		end
		return label[vertex];
	endfunction

endpackage
