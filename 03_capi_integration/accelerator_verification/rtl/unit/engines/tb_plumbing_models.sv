module tb_plumbing_models #(
	parameter int READ_BYTES  = 4,
	parameter int WRITE_BYTES = 4,
	parameter int FILTER_MODE = 0
);

	localparam int CACHELINE_BYTES = 128;
	localparam int HALF_BYTES      = CACHELINE_BYTES / 2;
	localparam int READ_BITS       = READ_BYTES * 8;
	localparam int READ_PER_HALF   = HALF_BYTES / READ_BYTES;
	localparam int WRITE_BITS      = WRITE_BYTES * 8;
	localparam int QUEUE_DEPTH     = 64;
	localparam int QUEUE_HEADROOM  = 16;

	logic [HALF_BYTES*8-1:0] lower_half;
	logic [HALF_BYTES*8-1:0] upper_half;
	logic [CACHELINE_BYTES*8-1:0] property_line;
	logic [CACHELINE_BYTES-1:0] property_mask;
	logic [63:0] expected_value;
	logic [63:0] actual_value;
	logic [63:0] pending_lower [0:15];
	logic [63:0] pending_upper [0:15];
	bit pending_lower_valid [0:15];
	bit pending_upper_valid [0:15];
	int queue [0:QUEUE_DEPTH-1];
	int q_head;
	int q_tail;
	int q_count;
	int produced;
	int consumed;
	int cycle;
	int tag;
	int i;

	function automatic int csr_cachelines(
		input int start_edge,
		input int degree,
		input int edges_per_line
	);
		int first_line;
		int last_edge;
		begin
			if (degree == 0) begin
				csr_cachelines = 0;
			end else begin
				first_line = start_edge / edges_per_line;
`ifdef MUTATE_CSR_TAIL
				last_edge = start_edge + degree - 2;
`else
				last_edge = start_edge + degree - 1;
`endif
				csr_cachelines = (last_edge / edges_per_line) - first_line + 1;
			end
		end
	endfunction

	function automatic bit filter_accept(
		input int degree,
		input bit parent_active
	);
		bit accepted;
		begin
			case (FILTER_MODE)
				1: accepted = (degree != 0) && parent_active;
				default: accepted = (degree != 0);
			endcase
`ifdef MUTATE_FILTER_POLARITY
			filter_accept = ~accepted;
`else
			filter_accept = accepted;
`endif
		end
	endfunction

	function automatic logic [63:0] extract_element(input int index);
		logic [63:0] value;
		int local_index;
		begin
			value = 0;
			if (index < READ_PER_HALF) begin
`ifdef MUTATE_EXTRACT_HALF
				value[READ_BITS-1:0] = upper_half[index*READ_BITS +: READ_BITS];
`else
				value[READ_BITS-1:0] = lower_half[index*READ_BITS +: READ_BITS];
`endif
			end else begin
				local_index = index - READ_PER_HALF;
`ifdef MUTATE_EXTRACT_HALF
				value[READ_BITS-1:0] = lower_half[local_index*READ_BITS +: READ_BITS];
`else
				value[READ_BITS-1:0] = upper_half[local_index*READ_BITS +: READ_BITS];
`endif
			end
			extract_element = value;
		end
	endfunction

	task automatic write_property(
		input int index,
		input logic [63:0] value
	);
		int byte_offset;
		int byte_index;
		begin
			byte_offset = (index * WRITE_BYTES) % CACHELINE_BYTES;
			for (byte_index = 0; byte_index < WRITE_BYTES; byte_index++) begin
				property_line[(byte_offset + byte_index)*8 +: 8] =
					value[byte_index*8 +: 8];
`ifdef MUTATE_WRITE_MASK
				property_mask = '1;
`else
				property_mask[byte_offset + byte_index] = 1'b1;
`endif
			end
		end
	endtask

	task automatic queue_push(input int value);
		begin
			if (q_count >= QUEUE_DEPTH)
				$fatal(1, "ASSERT queue overflow");
			queue[q_tail] = value;
			q_tail = (q_tail + 1) % QUEUE_DEPTH;
			q_count++;
			produced++;
		end
	endtask

	task automatic queue_pop;
		int value;
		begin
			if (q_count == 0)
				$fatal(1, "ASSERT queue underflow");
			value = queue[q_head];
			if (value < 0)
				$fatal(1, "ASSERT queue payload legality");
			q_head = (q_head + 1) % QUEUE_DEPTH;
			q_count--;
			consumed++;
		end
	endtask

	task automatic emit_bin(input string name);
		$display("AG_BIN:%s", name);
	endtask

	initial begin
		lower_half = '0;
		upper_half = '0;
		property_line = '0;
		property_mask = '0;
		q_head = 0;
		q_tail = 0;
		q_count = 0;
		produced = 0;
		consumed = 0;
		for (i = 0; i < 16; i++) begin
			pending_lower_valid[i] = 0;
			pending_upper_valid[i] = 0;
		end

		if (q_count != 0 || property_mask != 0)
			$fatal(1, "ASSERT reset/disabled idle");
		emit_bin("reset_disabled_idle");

		if (filter_accept(0, 1))
			$fatal(1, "ASSERT isolated vertex must be rejected");
		emit_bin("vertex_isolated");
		emit_bin("filter_reject");

		if (!filter_accept(7, 1))
			$fatal(1, "ASSERT active vertex must be accepted");
		emit_bin("vertex_active");
		emit_bin("filter_accept");

		if (FILTER_MODE == 1 && filter_accept(7, 0))
			$fatal(1, "ASSERT inactive BFS parent must be rejected");

		if (csr_cachelines(0, 0, 32) != 0)
			$fatal(1, "ASSERT zero degree must issue no cachelines");
		emit_bin("csr_zero_degree");

		if (csr_cachelines(9, 1, 32) != 1)
			$fatal(1, "ASSERT single degree must issue one cacheline");
		emit_bin("csr_single_degree");

		if (csr_cachelines(5, 95, 32) != 4)
			$fatal(1, "ASSERT high degree cacheline count");
		emit_bin("csr_high_degree");

		if (csr_cachelines(31, 2, 32) != 2)
			$fatal(1, "ASSERT cacheline crossing");
		emit_bin("csr_cacheline_boundary");

		if (csr_cachelines(32, 33, 32) != 2)
			$fatal(1, "ASSERT final partial cacheline");
		emit_bin("csr_tail_boundary");

		for (i = 0; i < QUEUE_DEPTH - QUEUE_HEADROOM; i++)
			queue_push(i);
		if (q_count != QUEUE_DEPTH - QUEUE_HEADROOM)
			$fatal(1, "ASSERT near-full occupancy");
		emit_bin("queue_near_full");

		for (cycle = 0; cycle < 96; cycle++) begin
			if ((cycle % 5) != 1 && q_count != 0)
				queue_pop();
			if ((cycle % 3) == 0 && q_count < QUEUE_DEPTH - QUEUE_HEADROOM) begin
`ifdef MUTATE_QUEUE_DROP
				produced++;
`else
				queue_push(1000 + cycle);
`endif
			end
		end
		while (q_count != 0)
			queue_pop();
		if (produced != consumed)
			$fatal(1, "ASSERT queue conservation produced=%0d consumed=%0d",
				produced, consumed);
		emit_bin("queue_deterministic_stall");

		expected_value = 64'h0123_4567_89ab_cdef;
		lower_half[0 +: READ_BITS] = expected_value[READ_BITS-1:0];
		actual_value = extract_element(0);
		if (actual_value[READ_BITS-1:0] != expected_value[READ_BITS-1:0])
			$fatal(1, "ASSERT lower-half extraction");
		emit_bin("extract_lower_half");

		expected_value = 64'hfedc_ba98_7654_3210;
		upper_half[(READ_PER_HALF-1)*READ_BITS +: READ_BITS] =
			expected_value[READ_BITS-1:0];
		actual_value = extract_element((2*READ_PER_HALF)-1);
		if (actual_value[READ_BITS-1:0] != expected_value[READ_BITS-1:0])
			$fatal(1, "ASSERT upper-half extraction");
		emit_bin("extract_upper_half");

		pending_upper[9] = 64'h99;
		pending_upper_valid[9] = 1;
		pending_lower[3] = 64'h33;
		pending_lower_valid[3] = 1;
		pending_lower[9] = 64'h19;
		pending_lower_valid[9] = 1;
		pending_upper[3] = 64'h13;
		pending_upper_valid[3] = 1;
		for (tag = 0; tag < 16; tag++) begin
			if (pending_lower_valid[tag] != pending_upper_valid[tag])
				$fatal(1, "ASSERT split response ownership tag=%0d", tag);
		end
		if (pending_lower[9] != 64'h19 || pending_upper[9] != 64'h99 ||
			pending_lower[3] != 64'h33 || pending_upper[3] != 64'h13)
			$fatal(1, "ASSERT tag reorder pairing");
		emit_bin("extract_tag_reorder");

		expected_value = 64'h0102_0304_0506_0708;
		write_property(0, expected_value);
		if (property_mask[0] != 1'b1 ||
			property_line[0 +: WRITE_BITS] !=
				expected_value[WRITE_BITS-1:0])
			$fatal(1, "ASSERT lower-half property write coupling");
		emit_bin("write_lower_half");

		property_line = '0;
		property_mask = '0;
		write_property((HALF_BYTES / WRITE_BYTES) + 1, 64'h1112_1314_1516_1718);
		if (property_mask[HALF_BYTES + WRITE_BYTES] != 1'b1)
			$fatal(1, "ASSERT upper-half property mask");
		emit_bin("write_upper_half");

		if ($countones(property_mask) != WRITE_BYTES)
			$fatal(1, "ASSERT exact property byte mask");
		emit_bin("write_mask");

		expected_value = 64'ha1a2_a3a4_a5a6_a7a8;
		write_property((HALF_BYTES / WRITE_BYTES) + 1, expected_value);
		if (property_line[(HALF_BYTES + WRITE_BYTES)*8 +: WRITE_BITS] !=
			expected_value[WRITE_BITS-1:0])
			$fatal(1, "ASSERT conflicting write latest-wins policy");
		emit_bin("write_conflict_latest_wins");

		$display("AG_RESULT:PASS plumbing READ_BYTES=%0d WRITE_BYTES=%0d FILTER_MODE=%0d",
			READ_BYTES, WRITE_BYTES, FILTER_MODE);
		$finish;
	end

endmodule
