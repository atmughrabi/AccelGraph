import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module tb_edge_job_control_dut;

	logic clock;
	logic rstn_in;
	logic enabled_in;
	logic [0:63] cu_configure;
	WEDInterface wed_request_in;
	ResponseBufferLine read_response_in;
	ReadWriteDataLine read_data_0_in;
	ReadWriteDataLine read_data_1_in;
	BufferStatus read_buffer_status;
	logic edge_request;
	VertexInterface vertex_job;
	logic read_command_bus_grant;
	logic read_command_bus_request;
	CommandBufferLine read_command_out;
	EdgeInterface edge_job;
	logic [0:63] edge_base;
	int i;
	bit observed;

	cu_edge_job_control #(
		.CU_ID_X(2),
		.CU_ID_Y(3)
	) dut (
		.clock                   (clock                   ),
		.rstn_in                 (rstn_in                 ),
		.enabled_in              (enabled_in              ),
		.cu_configure            (cu_configure            ),
		.wed_request_in          (wed_request_in          ),
		.read_response_in        (read_response_in        ),
		.read_data_0_in          (read_data_0_in          ),
		.read_data_1_in          (read_data_1_in          ),
		.read_buffer_status      (read_buffer_status      ),
		.edge_request            (edge_request            ),
		.vertex_job              (vertex_job              ),
		.read_command_bus_grant  (read_command_bus_grant  ),
		.read_command_bus_request(read_command_bus_request),
		.read_command_out        (read_command_out        ),
		.edge_job                (edge_job                )
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
			rstn_in = 0;
			enabled_in = 0;
			cu_configure = 0;
			wed_request_in = '0;
			read_response_in = '0;
			read_data_0_in = '0;
			read_data_1_in = '0;
			read_buffer_status = '0;
			read_buffer_status.empty = 1;
			edge_request = 0;
			vertex_job = '0;
			read_command_bus_grant = 0;
			repeat (6) tick();
			if (read_command_out.valid || edge_job.valid || read_command_bus_request)
				$fatal(1, "ASSERT edge-job reset/disabled idle");
			rstn_in = 1;
			repeat (3) tick();
			enabled_in = 1;
			cu_configure = 64'h1;
			read_command_bus_grant = 1;
			wed_request_in.valid = 1;
			wed_request_in.payload.wed.inverse_edges_array_dest = 64'h8000;
`ifdef LAYOUT_WEIGHTED
			wed_request_in.payload.wed.inverse_edges_array_weight = 64'h8000;
`endif
			wed_request_in.payload.wed.edges_array_dest = 64'h9000;
`ifdef LAYOUT_CC
			edge_base = 64'h9000;
`else
			edge_base = 64'h8000;
`endif
			repeat (8) tick();
		end
	endtask

	task automatic drive_vertex(
		input int degree,
		input int edge_index,
		input int vertex_id
	);
		begin
			vertex_job = '0;
			vertex_job.valid = 1;
			vertex_job.payload.id = vertex_id;
`ifdef LAYOUT_CC
			vertex_job.payload.out_degree = degree;
			vertex_job.payload.edges_idx = edge_index;
`else
			vertex_job.payload.inverse_out_degree = degree;
			vertex_job.payload.inverse_edges_idx = edge_index;
`endif
			repeat (3) tick();
			vertex_job.valid = 0;
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
			vertex_job = '1;
			edge_request = 1;
			read_command_bus_grant = 0;
			repeat (4) tick();
			cu_configure = '0;
			wed_request_in = '0;
			read_response_in = '0;
			read_data_0_in = '0;
			read_data_1_in = '0;
			read_buffer_status = '0;
			read_buffer_status.empty = 1;
			vertex_job = '0;
			edge_request = 0;
			read_command_bus_grant = 1;
			repeat (4) tick();
		end
	endtask

	task automatic expect_command(
		input int degree,
		input int edge_index,
		input int expected_real_size,
		input int expected_offset
	);
		logic [0:63] byte_offset;
		logic [0:63] expected_address;
		begin
			drive_vertex(degree, edge_index, 32'hfffffffe);
			byte_offset = edge_index << $clog2(EDGE_SIZE);
			expected_address = edge_base +
				(byte_offset & ADDRESS_EDGE_ALIGN_MASK);
			observed = 0;
			for (i = 0; i < 160; i++) begin
				tick();
				if (read_command_out.valid) begin
					if (read_command_out.payload.address !== expected_address)
						$fatal(1,
							"ASSERT edge command address expected=%h actual=%h",
							expected_address, read_command_out.payload.address);
					if (read_command_out.payload.cmd.real_size != expected_real_size)
						$fatal(1,
							"ASSERT edge command size expected=%0d actual=%0d",
							expected_real_size,
							read_command_out.payload.cmd.real_size);
					if (read_command_out.payload.cmd.cacheline_offset != expected_offset)
						$fatal(1,
							"ASSERT edge cacheline offset expected=%0d actual=%0d",
							expected_offset,
							read_command_out.payload.cmd.cacheline_offset);
					observed = 1;
					i = 160;
				end
			end
			if (!observed)
				$fatal(1, "ASSERT edge command missing");
		end
	endtask

	task automatic exercise_response_shift_drain(
		input int degree,
		input int edge_index,
		input bit coherent,
		input bit stall_to_near_full,
		input int vertex_id
	);
		int command_count;
		int edge_count;
		bit saw_near_full;
		begin
			cu_configure = 0;
			cu_configure[8] = coherent;
			cu_configure[5:7] = '1;
			repeat (4) tick();
			drive_vertex(degree, edge_index, vertex_id);
			edge_request = !stall_to_near_full;
			command_count = 0;
			edge_count = 0;
			saw_near_full = 0;
			for (i = 0; i < 1200; i++) begin
				tick();
				read_response_in.valid = 0;
				read_data_0_in.valid = 0;
				read_data_1_in.valid = 0;
				if (edge_job.valid && edge_request)
					edge_count++;
				if (stall_to_near_full &&
					dut.edge_buffer_status.alfull) begin
					saw_near_full = 1;
					edge_request = 1;
				end
				if (read_command_out.valid) begin
					if (coherent &&
						(read_command_out.payload.command != READ_CL_S))
						$fatal(1,
							"ASSERT coherent edge command opcode=%h",
							read_command_out.payload.command);
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
				if (edge_count >= degree)
					i = 1200;
			end
			read_response_in = '0;
			read_data_0_in = '0;
			read_data_1_in = '0;
			if (edge_count != degree)
				$fatal(1,
					"ASSERT edge response/shift/drain expected=%0d actual=%0d commands=%0d",
					degree, edge_count, command_count);
			if (command_count == 0)
				$fatal(1, "ASSERT edge response pipeline issued no command");
			if (stall_to_near_full && !saw_near_full)
				$fatal(1, "ASSERT edge job queue never reached near-full");
		end
	endtask

	task automatic exercise_back_to_back_vertex;
		begin
			vertex_job = '0;
			vertex_job.valid = 1;
			vertex_job.payload.id = 32'hffffffff;
`ifdef LAYOUT_CC
			vertex_job.payload.out_degree = 1;
			vertex_job.payload.edges_idx = 0;
`else
			vertex_job.payload.inverse_out_degree = 1;
			vertex_job.payload.inverse_edges_idx = 0;
`endif
			repeat (3) tick();
			vertex_job.valid = 0;
			observed = 0;
			for (i = 0; i < 160; i++) begin
				tick();
				if (read_command_out.valid) begin
					observed = 1;
					i = 160;
				end
			end
			if (!observed)
				$fatal(1,
					"ASSERT back-to-back vertex issued no edge command");
		end
	endtask

	initial begin
		clock = 0;
		reset_dut();
		toggle_inputs();
		$display("AG_BIN:edge_job_toggle_sweep");
		reset_dut();
		drive_vertex(0, 0, 32'hfffffffe);
		repeat (50) begin
			tick();
			if (read_command_out.valid)
				$fatal(1, "ASSERT zero-degree edge command issued");
		end
		$display("AG_BIN:edge_job_zero_degree");

		reset_dut();
		expect_command(1, 0, 1, 0);
		$display("AG_BIN:edge_job_single_degree");

		reset_dut();
		expect_command(2, CACHELINE_EDGE_NUM-1, 1,
			CACHELINE_EDGE_NUM-1);
		$display("AG_BIN:edge_job_cacheline_tail");

		reset_dut();
		expect_command(CACHELINE_EDGE_NUM+1, 0,
			CACHELINE_EDGE_NUM, 0);
		$display("AG_BIN:edge_job_high_degree");

		reset_dut();
		exercise_response_shift_drain(CACHELINE_EDGE_NUM+1,
			CACHELINE_EDGE_NUM-1, 0, 0, 32'hfffffffe);
		$display("AG_BIN:edge_job_response_shift_drain");
		exercise_back_to_back_vertex();
		$display("AG_BIN:edge_job_back_to_back_vertices");

		reset_dut();
		exercise_response_shift_drain(
			CACHELINE_EDGE_NUM+1, 0, 1, 0, 32'hfffffffe);
		reset_dut();
		exercise_response_shift_drain(
			CACHELINE_EDGE_NUM+1, CACHELINE_EDGE_NUM-1, 1, 0,
			32'hfffffffe);
		reset_dut();
		exercise_response_shift_drain(
			1, CACHELINE_EDGE_NUM-1, 1, 0, 1);
		$display("AG_BIN:edge_job_coherent_commands");

		reset_dut();
		exercise_response_shift_drain(
			CU_EDGE_JOB_BUFFER_SIZE, 0, 0, 1, 32'hfffffffe);
		$display("AG_BIN:edge_job_queue_near_full");
		$display("AG_RESULT:PASS edge_job_control_dut");
		$finish;
	end

endmodule
