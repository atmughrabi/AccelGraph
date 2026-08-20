import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module tb_edge_extract_dut;

	logic clock;
	logic rstn;
	logic enabled_in;
	ReadWriteDataLine read_data_0_in;
	ReadWriteDataLine read_data_1_in;
	EdgeDataRead edge_data;
	logic [0:(DATA_SIZE_READ_BITS-1)] expected_data;
	logic [0:(DATA_SIZE_READ_BITS-1)] raw_data;
	cu_id_t expected_cu_id_x;
	cu_id_t expected_cu_id_y;
	int i;
	bit observed;

	cu_edge_data_read_extract_control #(
		.CU_ID_X(3),
		.CU_ID_Y(2)
	) dut (
		.clock         (clock         ),
		.rstn          (rstn          ),
		.enabled_in    (enabled_in    ),
		.read_data_0_in(read_data_0_in),
		.read_data_1_in(read_data_1_in),
		.edge_data     (edge_data     )
	);

	always #5 clock = ~clock;

	function automatic logic [0:(DATA_SIZE_READ_BITS-1)] model_swap(
		input logic [0:(DATA_SIZE_READ_BITS-1)] value
	);
		logic [0:(DATA_SIZE_READ_BITS-1)] result;
		int byte_index;
		begin
			for (byte_index = 0; byte_index < DATA_SIZE_READ; byte_index++)
				result[byte_index*8 +: 8] =
					value[(DATA_SIZE_READ-byte_index-1)*8 +: 8];
			model_swap = result;
		end
	endfunction

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
			read_data_0_in = '0;
			read_data_1_in = '0;
			repeat (4) tick();
			if (edge_data.valid)
				$fatal(1, "ASSERT extract reset/disabled idle");
			rstn = 1;
			enabled_in = 1;
			repeat (4) tick();
		end
	endtask

	task automatic expect_data(input int limit);
		begin
			observed = 0;
			for (i = 0; i < limit; i++) begin
				tick();
				if (edge_data.valid) begin
					if (edge_data.payload.data !== expected_data)
						$fatal(1,
							"ASSERT extract data mismatch expected=%h actual=%h",
							expected_data, edge_data.payload.data);
					if ((edge_data.payload.cu_id_x !== expected_cu_id_x) ||
						(edge_data.payload.cu_id_y !== expected_cu_id_y))
						$fatal(1,
							"ASSERT extract metadata mismatch expected_cu=(%h,%h) actual_cu=(%h,%h)",
							expected_cu_id_x, expected_cu_id_y,
							edge_data.payload.cu_id_x, edge_data.payload.cu_id_y);
					observed = 1;
					i = limit;
				end
			end
			if (!observed)
				$fatal(1, "ASSERT extract result missing");
		end
	endtask

	task automatic send_pair(
		input int offset,
		input logic [0:(DATA_SIZE_READ_BITS-1)] value,
		input int valid_cycles
	);
		int local_offset;
		begin
			read_data_0_in = '0;
			read_data_1_in = '0;
			read_data_0_in.valid = 1;
			read_data_1_in.valid = 1;
			read_data_0_in.payload.cmd.cacheline_offset = offset;
			read_data_1_in.payload.cmd.cacheline_offset = offset;
			read_data_0_in.payload.cmd.tag = 8'h2a;
			read_data_1_in.payload.cmd.tag = 8'h2a;
			read_data_0_in.payload.cmd.cu_id_x = 8'h03;
			read_data_0_in.payload.cmd.cu_id_y = 8'h02;
			read_data_1_in.payload.cmd.cu_id_x = 8'h03;
			read_data_1_in.payload.cmd.cu_id_y = 8'h02;
			if (offset < CACHELINE_DATA_READ_NUM_HF) begin
				read_data_0_in.payload.data[offset*DATA_SIZE_READ_BITS +:
					DATA_SIZE_READ_BITS] = value;
			end else begin
				local_offset = offset - CACHELINE_DATA_READ_NUM_HF;
				read_data_1_in.payload.data[local_offset*DATA_SIZE_READ_BITS +:
					DATA_SIZE_READ_BITS] = value;
			end
			expected_data = model_swap(value);
			expected_cu_id_x = 8'h03;
			expected_cu_id_y = 8'h02;
			repeat (valid_cycles) tick();
			read_data_0_in.valid = 0;
			read_data_1_in.valid = 0;
		end
	endtask

	task automatic send_reordered_pair(
		input int offset,
		input logic [0:(DATA_SIZE_READ_BITS-1)] value
	);
		int local_offset;
		begin
			local_offset = offset - CACHELINE_DATA_READ_NUM_HF;
			read_data_0_in = '0;
			read_data_1_in = '0;
			read_data_1_in.valid = 1;
			read_data_1_in.payload.cmd.cacheline_offset = offset;
			read_data_1_in.payload.cmd.tag = 8'h6d;
			read_data_1_in.payload.cmd.cu_id_x = 8'h05;
			read_data_1_in.payload.cmd.cu_id_y = 8'h04;
			read_data_1_in.payload.data[local_offset*DATA_SIZE_READ_BITS +:
				DATA_SIZE_READ_BITS] = value;
			tick();
			read_data_1_in.valid = 0;

			read_data_0_in.valid = 1;
			read_data_0_in.payload.cmd.cacheline_offset = offset;
			read_data_0_in.payload.cmd.tag = 8'h6d;
			read_data_0_in.payload.cmd.cu_id_x = 8'h05;
			read_data_0_in.payload.cmd.cu_id_y = 8'h04;
			tick();
			read_data_0_in.valid = 0;
			expected_data = model_swap(value);
			expected_cu_id_x = 8'h05;
			expected_cu_id_y = 8'h04;
		end
	endtask

	task automatic send_two_tag_reorder;
		logic [0:(DATA_SIZE_READ_BITS-1)] value_a;
		logic [0:(DATA_SIZE_READ_BITS-1)] value_b;
		logic [0:(DATA_SIZE_READ_BITS-1)] expected_a;
		logic [0:(DATA_SIZE_READ_BITS-1)] expected_b;
		int observed_count;
		begin
			value_a = '0;
			value_b = '0;
			value_a[0 +: 8] = 8'h3c;
			value_b[0 +: 8] = 8'h96;
			if (DATA_SIZE_READ > 1) begin
				value_a[DATA_SIZE_READ_BITS-8 +: 8] = 8'ha5;
				value_b[DATA_SIZE_READ_BITS-8 +: 8] = 8'he7;
			end
			expected_a = model_swap(value_a);
			expected_b = model_swap(value_b);

			read_data_0_in = '0;
			read_data_1_in = '0;
			read_data_1_in.valid = 1;
			read_data_1_in.payload.cmd.tag = 8'h00;
			read_data_1_in.payload.cmd.cacheline_offset =
				CACHELINE_DATA_READ_NUM_HF + 2;
			read_data_1_in.payload.data[2*DATA_SIZE_READ_BITS +:
				DATA_SIZE_READ_BITS] = value_b;
			tick();
			read_data_1_in.valid = 0;

			read_data_0_in.valid = 1;
			read_data_0_in.payload.cmd.tag = 8'hff;
			read_data_0_in.payload.cmd.cacheline_offset = 2;
			read_data_0_in.payload.cmd.cu_id_x = 8'h01;
			read_data_0_in.payload.cmd.cu_id_y = 8'h06;
			read_data_0_in.payload.data[2*DATA_SIZE_READ_BITS +:
				DATA_SIZE_READ_BITS] = value_a;
			tick();
			read_data_0_in.valid = 0;

			read_data_0_in = '0;
			read_data_0_in.valid = 1;
			read_data_0_in.payload.cmd.tag = 8'h00;
			read_data_0_in.payload.cmd.cacheline_offset =
				CACHELINE_DATA_READ_NUM_HF + 2;
			read_data_0_in.payload.cmd.cu_id_x = 8'h07;
			read_data_0_in.payload.cmd.cu_id_y = 8'h03;
			tick();
			read_data_0_in.valid = 0;

			read_data_1_in = '0;
			read_data_1_in.valid = 1;
			read_data_1_in.payload.cmd.tag = 8'hff;
			read_data_1_in.payload.cmd.cacheline_offset = 2;
			tick();
			read_data_1_in.valid = 0;

			observed_count = 0;
			for (i = 0; i < 32; i++) begin
				tick();
				if (edge_data.valid) begin
					if (observed_count == 0) begin
						if ((edge_data.payload.data !== expected_b) ||
							(edge_data.payload.cu_id_x !== 8'h07) ||
							(edge_data.payload.cu_id_y !== 8'h03))
							$fatal(1,
								"ASSERT tag B ownership data=%h cu=(%h,%h)",
								edge_data.payload.data,
								edge_data.payload.cu_id_x,
								edge_data.payload.cu_id_y);
					end else if (observed_count == 1) begin
						if ((edge_data.payload.data !== expected_a) ||
							(edge_data.payload.cu_id_x !== 8'h01) ||
							(edge_data.payload.cu_id_y !== 8'h06))
							$fatal(1,
								"ASSERT tag A ownership data=%h cu=(%h,%h)",
								edge_data.payload.data,
								edge_data.payload.cu_id_x,
								edge_data.payload.cu_id_y);
					end
					observed_count++;
				end
			end
			if (observed_count != 2)
				$fatal(1, "ASSERT reordered tag result count expected=2 actual=%0d",
					observed_count);
		end
	endtask

	task automatic send_toggle_sweep;
		begin
			read_data_0_in = '1;
			read_data_1_in = '1;
			read_data_0_in.valid = 1;
			read_data_1_in.valid = 1;
			read_data_0_in.payload.cmd.tag = 8'hff;
			read_data_1_in.payload.cmd.tag = 8'hff;
			read_data_0_in.payload.cmd.cacheline_offset = 0;
			read_data_1_in.payload.cmd.cacheline_offset = 0;
			expected_data = '1;
			expected_cu_id_x = '1;
			expected_cu_id_y = '1;
			tick();
			read_data_0_in.valid = 0;
			read_data_1_in.valid = 0;
			expect_data(20);

			read_data_0_in = '0;
			read_data_1_in = '0;
			read_data_0_in.valid = 1;
			read_data_1_in.valid = 1;
			read_data_0_in.payload.cmd.tag = 8'h00;
			read_data_1_in.payload.cmd.tag = 8'h00;
			read_data_0_in.payload.cmd.cacheline_offset = 0;
			read_data_1_in.payload.cmd.cacheline_offset = 0;
			expected_data = '0;
			expected_cu_id_x = '0;
			expected_cu_id_y = '0;
			tick();
			read_data_0_in.valid = 0;
			read_data_1_in.valid = 0;
			expect_data(20);
		end
	endtask

	task automatic exercise_allocator_full;
		int output_count;
		begin
			read_data_0_in = '0;
			read_data_1_in = '0;
			read_data_1_in.valid = 1;
			read_data_1_in.payload.cmd.tag = 8'h10;
			tick();
			read_data_1_in.payload.cmd.tag = 8'h20;
			tick();
			read_data_1_in.valid = 0;

			read_data_0_in.valid = 1;
			read_data_0_in.payload.cmd.tag = 8'h30;
			tick();
			read_data_0_in.payload.cmd.tag = 8'h20;
			tick();
			read_data_0_in.payload.cmd.tag = 8'h10;
			tick();
			read_data_0_in.valid = 0;

			output_count = 0;
			for (i = 0; i < 24; i++) begin
				tick();
				if (edge_data.valid)
					output_count++;
			end
			if (output_count != 2)
				$fatal(1,
					"ASSERT full allocator retained pair count expected=2 actual=%0d",
					output_count);
		end
	endtask

	task automatic exercise_allocator_decisions;
		int output_count;
		begin
			read_data_0_in = '0;
			read_data_1_in = '0;

			read_data_1_in.valid = 1;
			read_data_1_in.payload.cmd.tag = 8'h11;
			tick();
			read_data_1_in.payload.cmd.tag = 8'h22;
			tick();
			read_data_1_in.valid = 0;

			read_data_0_in.valid = 1;
			read_data_0_in.payload.cmd.tag = 8'h22;
			tick();
			read_data_0_in.valid = 0;

			read_data_0_in = '0;
			read_data_1_in = '0;
			read_data_0_in.valid = 1;
			read_data_1_in.valid = 1;
			read_data_0_in.payload.cmd.tag = 8'h33;
			read_data_1_in.payload.cmd.tag = 8'h44;
			tick();
			read_data_0_in.valid = 0;
			read_data_1_in.valid = 0;

			read_data_0_in = '0;
			read_data_0_in.valid = 1;
			read_data_0_in.payload.cmd.tag = 8'h11;
			tick();
			read_data_0_in.valid = 0;

			read_data_1_in = '0;
			read_data_1_in.valid = 1;
			read_data_1_in.payload.cmd.tag = 8'h55;
			tick();
			read_data_1_in.valid = 0;
			read_data_0_in = '0;
			read_data_0_in.valid = 1;
			read_data_0_in.payload.cmd.tag = 8'h55;
			tick();
			read_data_0_in.valid = 0;

			read_data_0_in = '0;
			read_data_0_in.valid = 1;
			read_data_0_in.payload.cmd.tag = 8'h66;
			tick();
			read_data_0_in.payload.cmd.tag = 8'h77;
			tick();
			read_data_0_in.payload.cmd.tag = 8'h88;
			tick();
			read_data_0_in.valid = 0;

			read_data_1_in = '0;
			read_data_1_in.valid = 1;
			read_data_1_in.payload.cmd.tag = 8'h77;
			tick();
			read_data_1_in.payload.cmd.tag = 8'h66;
			tick();
			read_data_1_in.valid = 0;

			output_count = 0;
			for (i = 0; i < 32; i++) begin
				tick();
				if (edge_data.valid)
					output_count++;
			end
			if (output_count < 1)
				$fatal(1,
					"ASSERT allocator decision outputs expected-at-least=1 actual=%0d",
					output_count);
		end
	endtask

	initial begin
		clock = 0;
		reset_dut();
		$display("AG_BIN:extract_reset_disabled_idle");

		raw_data = '0;
		raw_data[0 +: 8] = 8'h31;
		if (DATA_SIZE_READ > 1)
			raw_data[DATA_SIZE_READ_BITS-8 +: 8] = 8'ha7;
		send_pair(0, raw_data, 2);
		expect_data(20);
		$display("AG_BIN:extract_lower_half");

		reset_dut();
		raw_data = '0;
		raw_data[0 +: 8] = 8'h52;
		if (DATA_SIZE_READ > 1)
			raw_data[DATA_SIZE_READ_BITS-8 +: 8] = 8'hc4;
		send_pair((2*CACHELINE_DATA_READ_NUM_HF)-1, raw_data, 2);
		expect_data(20);
		$display("AG_BIN:extract_upper_half");

		reset_dut();
		send_toggle_sweep();
		$display("AG_BIN:extract_toggle_sweep");

		reset_dut();
		exercise_allocator_full();
		$display("AG_BIN:extract_allocator_full");

		reset_dut();
		exercise_allocator_decisions();
		$display("AG_BIN:extract_allocator_decisions");

		if ($test$plusargs("PULSE_UPPER")) begin
			reset_dut();
			raw_data = '0;
			raw_data[0 +: 8] = 8'h68;
			if (DATA_SIZE_READ > 1)
				raw_data[DATA_SIZE_READ_BITS-8 +: 8] = 8'hd2;
			send_pair(CACHELINE_DATA_READ_NUM_HF + 1, raw_data, 1);
			expect_data(24);
			$display("AG_BIN:extract_one_cycle_upper");
		end

		if ($test$plusargs("REORDER")) begin
			reset_dut();
			raw_data = '0;
			raw_data[0 +: 8] = 8'h7b;
			if (DATA_SIZE_READ > 1)
				raw_data[DATA_SIZE_READ_BITS-8 +: 8] = 8'he1;
			send_reordered_pair(CACHELINE_DATA_READ_NUM_HF + 1, raw_data);
			expect_data(24);
			$display("AG_BIN:extract_tag_reorder");

			reset_dut();
			send_two_tag_reorder();
			$display("AG_BIN:extract_two_tag_reorder");
		end

		$display("AG_RESULT:PASS edge_extract_dut");
		$finish;
	end

endmodule
