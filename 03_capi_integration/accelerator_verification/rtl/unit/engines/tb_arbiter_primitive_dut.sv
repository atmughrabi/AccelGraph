module tb_arbiter_primitive_dut #(
	parameter int REQUESTS = 4,
	parameter int WIDTH = 32
);

	logic clock;
	logic rstn;
	logic enabled;
	logic [0:WIDTH-1] buffer_in [0:REQUESTS-1];
	logic [REQUESTS-1:0] submit;
	logic [REQUESTS-1:0] requests;
	logic [0:WIDTH-1] arbiter_out;
	logic [REQUESTS-1:0] ready;
	logic [REQUESTS-1:0] ready_d1;
	logic [REQUESTS-1:0] ready_d2;
	logic [REQUESTS-1:0] seen;
	int owner;
	int cycle;
	int i;

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(REQUESTS),
		.WIDTH       (WIDTH   )
	) dut (
		.clock      (clock      ),
		.rstn       (rstn       ),
		.enabled    (enabled    ),
		.buffer_in  (buffer_in  ),
		.submit     (submit     ),
		.requests   (requests   ),
		.arbiter_out(arbiter_out),
		.ready      (ready      )
	);

	always #5 clock = ~clock;

	task automatic tick;
		begin
			@(posedge clock);
			#1;
		end
	endtask

	function automatic int ready_owner(input logic [REQUESTS-1:0] value);
		int index;
		begin
			ready_owner = -1;
			for (index = 0; index < REQUESTS; index++) begin
				if (value[index])
					ready_owner = index;
			end
		end
	endfunction

	task automatic check_owner_payload;
		begin
			if ($countones(ready) > 1)
				$fatal(1, "ASSERT arbiter ready is not one-hot ready=%h", ready);
			owner = ready_owner(ready_d2);
			if (owner < 0)
				owner = ready_owner(ready);
			if ((owner >= 0) && (arbiter_out != 0)) begin
				if (!requests[owner])
					$fatal(1, "ASSERT arbiter granted non-requester owner=%0d", owner);
				if (arbiter_out !== buffer_in[owner])
					$fatal(1,
						"ASSERT arbiter payload/grant mismatch owner=%0d expected=%h actual=%h ready=%h submit=%h",
						owner, buffer_in[owner], arbiter_out, ready, submit);
			end
			ready_d2 = ready_d1;
			ready_d1 = ready;
		end
	endtask

	initial begin
		clock = 0;
		rstn = 0;
		enabled = 0;
		submit = 0;
		requests = 0;
		seen = 0;
		ready_d1 = 0;
		ready_d2 = 0;
		for (i = 0; i < REQUESTS; i++)
			buffer_in[i] = i + 32'h100;
		repeat (4) tick();
		if (ready != 0 || arbiter_out != 0)
			$fatal(1, "ASSERT arbiter reset/disabled idle");
		rstn = 1;
		enabled = 1;
		repeat (3) tick();
		$display("AG_BIN:arbiter_reset_disabled_idle");

		for (i = 0; i < REQUESTS; i++) begin
			requests = '0;
			submit = '0;
			requests[i] = 1'b1;
			submit[i] = 1'b1;
			repeat (2) tick();
			check_owner_payload();
		end
		$display("AG_BIN:arbiter_single_requests");

		requests = '1;
		submit = '1;
		repeat (3) begin
			tick();
			ready_d2 = ready_d1;
			ready_d1 = ready;
		end
		seen = '0;
		for (cycle = 0; cycle < 2*REQUESTS; cycle++) begin
			tick();
			check_owner_payload();
			owner = ready_owner(ready);
			if (owner >= 0)
				seen[owner] = 1'b1;
		end
		if (seen != '1)
			$fatal(1, "ASSERT arbiter bounded fairness seen=%h", seen);
		$display("AG_BIN:arbiter_all_requests");
		$display("AG_BIN:arbiter_bounded_fairness");
		$display("AG_RESULT:PASS arbiter_primitive_dut REQUESTS=%0d", REQUESTS);
		$finish;
	end

endmodule
