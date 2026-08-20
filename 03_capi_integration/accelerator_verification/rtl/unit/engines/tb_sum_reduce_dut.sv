module tb_sum_reduce_dut #(
	parameter int BUS_WIDTH = 4,
	parameter int DATA_WIDTH = 32
);

	logic clock;
	logic rstn;
	logic enabled_in;
	logic [0:DATA_WIDTH-1] partial_sums_in [0:BUS_WIDTH-1];
	logic [0:DATA_WIDTH-1] total_sum_out;
	logic [DATA_WIDTH-1:0] expected;
	int i;

	sum_reduce #(
		.DATA_WIDTH_IN (DATA_WIDTH),
		.DATA_WIDTH_OUT(DATA_WIDTH),
		.BUS_WIDTH     (BUS_WIDTH)
	) dut (
		.clock          (clock          ),
		.rstn           (rstn           ),
		.enabled_in     (enabled_in     ),
		.partial_sums_in(partial_sums_in),
		.total_sum_out  (total_sum_out  )
	);

	always #5 clock = ~clock;

	task automatic tick;
		begin
			@(posedge clock);
			#1;
		end
	endtask

	initial begin
		clock = 0;
		rstn = 0;
		enabled_in = 0;
		expected = 0;
		for (i = 0; i < BUS_WIDTH; i++)
			partial_sums_in[i] = 0;
		repeat (4) tick();
		if (total_sum_out != 0)
			$fatal(1, "ASSERT reduction reset value");
		rstn = 1;
		enabled_in = 1;
		for (i = 0; i < BUS_WIDTH; i++) begin
			partial_sums_in[i] = (i * 11) + (i % 3);
			expected += (i * 11) + (i % 3);
		end
		repeat (4) tick();
		if (total_sum_out !== expected)
			$fatal(1, "ASSERT reduction expected=%h actual=%h",
				expected, total_sum_out);
		$display("AG_BIN:reduction_uneven_completion");

		expected = '1;
		for (i = 0; i < BUS_WIDTH; i++)
			partial_sums_in[i] = '1;
		expected = BUS_WIDTH * {DATA_WIDTH{1'b1}};
		repeat (3) tick();
		if (total_sum_out !== expected)
			$fatal(1, "ASSERT reduction wrap policy expected=%h actual=%h",
				expected, total_sum_out);
		$display("AG_BIN:reduction_wrap");
		$display("AG_RESULT:PASS sum_reduce_dut BUS_WIDTH=%0d", BUS_WIDTH);
		$finish;
	end

endmodule
