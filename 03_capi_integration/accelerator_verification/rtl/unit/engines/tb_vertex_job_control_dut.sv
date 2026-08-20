import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module tb_vertex_job_control_dut;

	logic clock;
	logic rstn;
	logic enabled_in;
	logic [0:63] cu_configure;
	WEDInterface wed_request_in;
	ResponseBufferLine read_response_in;
	ReadWriteDataLine read_data_0_in;
	ReadWriteDataLine read_data_1_in;
	BufferStatus read_buffer_status;
	logic vertex_request;
	logic read_command_bus_grant;
	logic read_command_bus_request;
	CommandBufferLine read_command_out;
	VertexInterface vertex;
	logic [0:63] expected_address[0:2];
	int expected_commands;
	int observed_commands;
	int i;

	cu_vertex_job_control dut (
		.clock                   (clock                   ),
		.rstn                    (rstn                    ),
		.enabled_in              (enabled_in              ),
		.cu_configure            (cu_configure            ),
		.wed_request_in          (wed_request_in          ),
		.read_response_in        (read_response_in        ),
		.read_data_0_in          (read_data_0_in          ),
		.read_data_1_in          (read_data_1_in          ),
		.read_buffer_status      (read_buffer_status      ),
		.vertex_request          (vertex_request          ),
		.read_command_bus_grant  (read_command_bus_grant  ),
		.read_command_bus_request(read_command_bus_request),
		.read_command_out        (read_command_out        ),
		.vertex                  (vertex                  )
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
			cu_configure = 0;
			wed_request_in = '0;
			read_response_in = '0;
			read_data_0_in = '0;
			read_data_1_in = '0;
			read_buffer_status = '0;
			read_buffer_status.empty = 1;
			vertex_request = 0;
			read_command_bus_grant = 0;
			repeat (5) tick();
			if (read_command_out.valid || vertex.valid || read_command_bus_request)
				$fatal(1, "ASSERT vertex-job reset/disabled idle");
			rstn = 1;
			repeat (3) tick();
			enabled_in = 1;
			cu_configure = 64'h1;
			read_command_bus_grant = 1;
			repeat (5) tick();
		end
	endtask

	task automatic configure_wed(input int vertices);
		begin
			wed_request_in = '0;
			wed_request_in.valid = 1;
			wed_request_in.payload.wed.num_vertices = vertices;
			wed_request_in.payload.wed.inverse_vertex_out_degree = 64'h1000;
			wed_request_in.payload.wed.inverse_vertex_edges_idx = 64'h2000;
			wed_request_in.payload.wed.vertex_out_degree = 64'h3000;
			wed_request_in.payload.wed.vertex_edges_idx = 64'h4000;
			wed_request_in.payload.wed.auxiliary1 = 64'h5000;
`ifdef LAYOUT_BFS
			expected_commands = 3;
			expected_address[0] = 64'h1000;
			expected_address[1] = 64'h2000;
			expected_address[2] = 64'h5000;
`elsif LAYOUT_CC
			expected_commands = 2;
			expected_address[0] = 64'h3000;
			expected_address[1] = 64'h4000;
`else
			expected_commands = 2;
			expected_address[0] = 64'h1000;
			expected_address[1] = 64'h2000;
`endif
		end
	endtask

	task automatic toggle_inputs;
		begin
			cu_configure = '1;
			wed_request_in = '1;
			read_response_in = '1;
			read_data_0_in = '1;
			read_data_1_in = '1;
			read_buffer_status = '1;
			vertex_request = 1;
			read_command_bus_grant = 0;
			repeat (4) tick();
			cu_configure = '0;
			wed_request_in = '0;
			read_response_in = '0;
			read_data_0_in = '0;
			read_data_1_in = '0;
			read_buffer_status = '0;
			read_buffer_status.empty = 1;
			vertex_request = 0;
			read_command_bus_grant = 1;
			repeat (4) tick();
		end
	endtask

	task automatic expect_commands(input int vertices, input bit full_cacheline);
		begin
			configure_wed(vertices);
			observed_commands = 0;
			for (i = 0; i < 160; i++) begin
				tick();
				if (read_command_out.valid) begin
					if (observed_commands >= expected_commands)
						$fatal(1, "ASSERT duplicate vertex command");
					if (read_command_out.payload.address !==
						expected_address[observed_commands])
						$fatal(1,
							"ASSERT vertex command address index=%0d expected=%h actual=%h",
							observed_commands,
							expected_address[observed_commands],
							read_command_out.payload.address);
					if (full_cacheline) begin
						if ((read_command_out.payload.size != 12'h080) ||
							(read_command_out.payload.cmd.real_size !=
								CACHELINE_VERTEX_NUM))
							$fatal(1, "ASSERT vertex full-cacheline command");
					end else begin
						if (read_command_out.payload.cmd.real_size != vertices)
							$fatal(1,
								"ASSERT vertex tail size expected=%0d actual=%0d",
								vertices,
								read_command_out.payload.cmd.real_size);
					end
					observed_commands++;
				end
				if (observed_commands == expected_commands)
					i = 160;
			end
			if (observed_commands != expected_commands)
				$fatal(1, "ASSERT vertex command count expected=%0d actual=%0d",
					expected_commands, observed_commands);
		end
	endtask

	task automatic exercise_response_shift_drain(
		input int vertices,
		input bit coherent,
		input bit stall_to_near_full
	);
		int command_count;
		int vertex_count;
		bit saw_near_full;
		begin
			cu_configure = 0;
			cu_configure[3] = coherent;
			cu_configure[0:2] = '1;
			repeat (4) tick();
			configure_wed(vertices);
			if (coherent)
				wed_request_in.payload.wed.auxiliary0 =
					64'h00000000ffffffe0;
			vertex_request = !stall_to_near_full;
			command_count = 0;
			vertex_count = 0;
			saw_near_full = 0;
			for (i = 0; i < 1200; i++) begin
				tick();
				read_response_in.valid = 0;
				read_data_0_in.valid = 0;
				read_data_1_in.valid = 0;
				if (vertex.valid && vertex_request)
					vertex_count++;
				if (stall_to_near_full &&
					dut.vertex_buffer_status.alfull) begin
					saw_near_full = 1;
					vertex_request = 1;
				end
				if (read_command_out.valid) begin
					if (coherent &&
						((read_command_out.payload.command != READ_CL_S) ||
						(read_command_out.payload.size != 12'h080)))
						$fatal(1,
							"ASSERT coherent vertex command opcode=%h size=%h",
							read_command_out.payload.command,
							read_command_out.payload.size);
					read_response_in = '0;
					read_data_0_in = '0;
					read_data_1_in = '0;
					read_response_in.valid = 1;
					read_response_in.payload.cmd =
						read_command_out.payload.cmd;
					read_data_0_in.valid = 1;
					read_data_1_in.valid = 1;
					read_data_0_in.payload.cmd =
						read_command_out.payload.cmd;
					read_data_1_in.payload.cmd =
						read_command_out.payload.cmd;
					if (command_count[0]) begin
						read_data_0_in.payload.data = '0;
						read_data_1_in.payload.data = '1;
					end else begin
						read_data_0_in.payload.data = '1;
						read_data_1_in.payload.data = '0;
					end
					command_count++;
				end
				if (vertex_count >= vertices)
					i = 1200;
			end
			read_response_in = '0;
			read_data_0_in = '0;
			read_data_1_in = '0;
			if (vertex_count != vertices)
				$fatal(1,
					"ASSERT vertex response/shift/drain expected=%0d actual=%0d commands=%0d",
					vertices, vertex_count, command_count);
			if (command_count < expected_commands)
				$fatal(1,
					"ASSERT vertex response command count expected-at-least=%0d actual=%0d",
					expected_commands, command_count);
			if (stall_to_near_full && !saw_near_full)
				$fatal(1,
					"ASSERT vertex job queue never reached near-full");
		end
	endtask

	initial begin
		clock = 0;
		reset_dut();
		$display("AG_BIN:vertex_job_reset_disabled_idle");
		toggle_inputs();
		$display("AG_BIN:vertex_job_toggle_sweep");
		reset_dut();

		configure_wed(0);
		repeat (60) begin
			tick();
			if (read_command_out.valid)
				$fatal(1, "ASSERT zero-vertex command issued");
		end
		$display("AG_BIN:vertex_job_zero");

		reset_dut();
		expect_commands(1, 0);
		$display("AG_BIN:vertex_job_single_tail");

		reset_dut();
		expect_commands(CACHELINE_VERTEX_NUM + 1, 1);
		$display("AG_BIN:vertex_job_high_degree");

		reset_dut();
		exercise_response_shift_drain(
			CACHELINE_VERTEX_NUM + 1, 0, 0);
		$display("AG_BIN:vertex_job_response_shift_drain");

		reset_dut();
		exercise_response_shift_drain(
			CACHELINE_VERTEX_NUM + 1, 1, 0);
		$display("AG_BIN:vertex_job_coherent_commands");

		reset_dut();
		exercise_response_shift_drain(
			CU_VERTEX_JOB_BUFFER_SIZE, 0, 1);
		$display("AG_BIN:vertex_job_queue_near_full");
		$display("AG_RESULT:PASS vertex_job_control_dut");
		$finish;
	end

endmodule
