import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module tb_vertex_filter_dut;

	logic clock;
	logic rstn;
	logic enabled_in;
	VertexInterface vertex_in;
	logic vertex_request_filtered;
	logic vertex_request_unfiltered;
	VertexInterface vertex_out;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_filtered;
	int i;
	bit observed;

	cu_vertex_job_filter dut (
		.clock                      (clock                      ),
		.rstn                       (rstn                       ),
		.enabled_in                 (enabled_in                 ),
		.vertex_in                  (vertex_in                  ),
		.vertex_request_filtered    (vertex_request_filtered    ),
		.vertex_request_unfiltered  (vertex_request_unfiltered  ),
		.vertex_out                 (vertex_out                 ),
		.vertex_job_counter_filtered(vertex_job_counter_filtered)
	);

	always #5 clock = ~clock;

	task automatic tick;
		begin
			@(posedge clock);
			#1;
		end
	endtask

	task automatic reset_dut;
		begin
			rstn = 0;
			enabled_in = 0;
			vertex_in = '0;
			vertex_request_filtered = 0;
			repeat (4) tick();
			if (vertex_out.valid || vertex_job_counter_filtered != 0)
				$fatal(1, "ASSERT filter reset/disabled idle");
			rstn = 1;
			enabled_in = 1;
			repeat (4) tick();
		end
	endtask

	task automatic drive_vertex(
		input int id,
		input int degree,
		input bit parent_active
	);
		begin
			vertex_in = '0;
			vertex_in.valid = 1;
			vertex_in.payload.id = id;
`ifdef FILTER_CC
			vertex_in.payload.out_degree = degree;
`else
			vertex_in.payload.inverse_out_degree = degree;
`endif
`ifdef FILTER_BFS
			vertex_in.payload.parent[0] = parent_active;
`endif
			tick();
			vertex_in.valid = 0;
		end
	endtask

	task automatic expect_no_vertex(input int limit);
		begin
			for (i = 0; i < limit; i++) begin
				tick();
				if (vertex_out.valid)
					$fatal(1, "ASSERT rejected vertex escaped filter");
			end
		end
	endtask

	task automatic expect_vertex(input int id, input int limit);
		begin
			observed = 0;
			for (i = 0; i < limit; i++) begin
				tick();
				if (vertex_out.valid) begin
					if (vertex_out.payload.id != id)
						$fatal(1, "ASSERT filtered FIFO order expected=%0d actual=%0d",
							id, vertex_out.payload.id);
					observed = 1;
					i = limit;
				end
			end
			if (!observed)
				$fatal(1, "ASSERT accepted vertex not delivered id=%0d", id);
		end
	endtask

	initial begin
		clock = 0;
		reset_dut();
		$display("AG_BIN:filter_reset_disabled_idle");

		vertex_request_filtered = 1;
		drive_vertex(1, 0, 1);
		expect_no_vertex(8);
		if (vertex_job_counter_filtered != 1)
			$fatal(1, "ASSERT isolated vertex filtered count expected=1 actual=%0d",
				vertex_job_counter_filtered);
		$display("AG_BIN:filter_isolated_reject");

`ifdef FILTER_BFS
		drive_vertex(2, 7, 0);
		expect_no_vertex(8);
		if (vertex_job_counter_filtered != 2)
			$fatal(1, "ASSERT BFS inactive-parent filtered count");
`endif

		drive_vertex(3, 7, 1);
		expect_vertex(3, 16);
		$display("AG_BIN:filter_active_accept");

		vertex_in = '1;
		vertex_in.valid = 1;
		tick();
		vertex_in.valid = 0;
		expect_vertex(-1, 16);
		vertex_in = '0;
		vertex_in.valid = 1;
`ifdef FILTER_CC
		vertex_in.payload.out_degree = 1;
`else
		vertex_in.payload.inverse_out_degree = 1;
`endif
`ifdef FILTER_BFS
		vertex_in.payload.parent[0] = 1;
`endif
		tick();
		vertex_in.valid = 0;
		expect_vertex(0, 16);
		$display("AG_BIN:filter_payload_toggle");

		reset_dut();
		vertex_request_filtered = 0;
		observed = 0;
		for (i = 0; i < 56; i++) begin
			drive_vertex(100 + i, 1, 1);
			if (!vertex_request_unfiltered)
				observed = 1;
		end
		repeat (6) begin
			tick();
			if (!vertex_request_unfiltered)
				observed = 1;
		end
		if (!observed)
			$fatal(1, "ASSERT filter queue never reported near-full");
		$display("AG_BIN:filter_queue_near_full");

		vertex_request_filtered = 1;
		observed = 0;
		for (i = 0; i < 96; i++) begin
			tick();
			if (vertex_request_unfiltered)
				observed = 1;
		end
		if (!observed)
			$fatal(1, "ASSERT filter queue did not recover after drain");
		$display("AG_BIN:filter_deterministic_drain");

		$display("AG_RESULT:PASS vertex_filter_dut");
		$finish;
	end

endmodule
