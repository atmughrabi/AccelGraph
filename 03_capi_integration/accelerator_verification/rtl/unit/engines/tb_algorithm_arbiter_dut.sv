import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

`ifndef DUT_MODULE
`define DUT_MODULE cu_vertex_pagerank_arbiter_control
`endif

module tb_algorithm_arbiter_dut #(
	parameter int NUM_CUS = 4,
	parameter int GRAPH_CUS = 4,
	parameter int GRAPH_Y = 0
);

	logic clock;
	logic rstn_in;
	logic enabled_in;
	WEDInterface wed_request_in;
	WEDInterface cu_wed_request_out[0:NUM_CUS-1];
	logic [NUM_CUS-1:0] enable_cu_out;
	logic [0:63] cu_configure;
	logic [0:63] cu_configure_out[0:NUM_CUS-1];
	ResponseBufferLine read_response_in;
	ReadWriteDataLine read_data_0_in;
	ReadWriteDataLine read_data_1_in;
	BufferStatus read_buffer_status;
	BufferStatus write_buffer_status;
	logic read_command_bus_grant;
	logic read_command_bus_request;
	logic write_command_bus_grant;
	logic write_command_bus_request;
	ResponseBufferLine read_response_cu_out[0:NUM_CUS-1];
	ResponseBufferLine write_response_in;
	ResponseBufferLine write_response_cu_out[0:NUM_CUS-1];
	CommandBufferLine read_command_cu_in[0:NUM_CUS-1];
	logic [NUM_CUS-1:0] request_read_command_cu_in;
	logic [NUM_CUS-1:0] ready_read_command_cu_out;
	CommandBufferLine read_command_out;
	logic [NUM_CUS-1:0] request_edge_data_write_cu_in;
	logic [NUM_CUS-1:0] ready_edge_data_write_cu_out;
	EdgeDataWrite edge_data_write_cu_in[0:NUM_CUS-1];
	EdgeDataWrite burst_edge_data_out;
	ReadWriteDataLine read_data_0_cu_out[0:NUM_CUS-1];
	ReadWriteDataLine read_data_1_cu_out[0:NUM_CUS-1];
	EdgeDataRead edge_data_read_cu_out[0:NUM_CUS-1];
	BufferStatus burst_read_command_buffer_states_cu_out[0:NUM_CUS-1];
	BufferStatus burst_edge_data_write_cu_buffer_states_cu_out[0:NUM_CUS-1];
	VertexInterface vertex_job_cu_out[0:NUM_CUS-1];
	logic [NUM_CUS-1:0] request_vertex_job_cu_in;
	VertexInterface vertex_job;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_cu_in[0:NUM_CUS-1];
	logic [0:(EDGE_SIZE_BITS-1)] edge_num_counter_cu_in[0:NUM_CUS-1];
	logic vertex_job_request;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_out;
	logic [0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_out;
	logic [NUM_CUS-1:0] seen;
	logic [NUM_CUS-1:0] ready_d1;
	logic [NUM_CUS-1:0] ready_d2;
	int expected_vertex_sum;
	int expected_edge_sum;
	int owner;
	int i;
	logic [NUM_CUS-1:0] write_seen;
	bit saw_read_alfull;
	bit saw_write_alfull;
	bit saw_vertex_alfull;

	`DUT_MODULE #(
		.NUM_VERTEX_CU(NUM_CUS  ),
		.NUM_GRAPH_CU (GRAPH_CUS),
		.CU_ID_Y      (GRAPH_Y  )
	) dut (
		.clock                                      (clock                                      ),
		.rstn_in                                    (rstn_in                                    ),
		.enabled_in                                 (enabled_in                                 ),
		.wed_request_in                             (wed_request_in                             ),
		.cu_wed_request_out                        (cu_wed_request_out                        ),
		.enable_cu_out                              (enable_cu_out                              ),
		.cu_configure                               (cu_configure                               ),
		.cu_configure_out                          (cu_configure_out                          ),
		.read_response_in                           (read_response_in                           ),
		.read_data_0_in                             (read_data_0_in                             ),
		.read_data_1_in                             (read_data_1_in                             ),
		.read_buffer_status                         (read_buffer_status                         ),
		.write_buffer_status                        (write_buffer_status                        ),
		.read_command_bus_grant                     (read_command_bus_grant                     ),
		.read_command_bus_request                   (read_command_bus_request                   ),
		.write_command_bus_grant                    (write_command_bus_grant                    ),
		.write_command_bus_request                  (write_command_bus_request                  ),
		.read_response_cu_out                       (read_response_cu_out                       ),
		.write_response_in                          (write_response_in                          ),
		.write_response_cu_out                      (write_response_cu_out                      ),
		.read_command_cu_in                         (read_command_cu_in                         ),
		.request_read_command_cu_in                 (request_read_command_cu_in                 ),
		.ready_read_command_cu_out                  (ready_read_command_cu_out                  ),
		.read_command_out                           (read_command_out                           ),
		.request_edge_data_write_cu_in              (request_edge_data_write_cu_in              ),
		.ready_edge_data_write_cu_out               (ready_edge_data_write_cu_out               ),
		.edge_data_write_cu_in                      (edge_data_write_cu_in                      ),
		.burst_edge_data_out                        (burst_edge_data_out                        ),
		.read_data_0_cu_out                         (read_data_0_cu_out                         ),
		.read_data_1_cu_out                         (read_data_1_cu_out                         ),
		.edge_data_read_cu_out                      (edge_data_read_cu_out                      ),
		.burst_read_command_buffer_states_cu_out    (burst_read_command_buffer_states_cu_out    ),
		.burst_edge_data_write_cu_buffer_states_cu_out(burst_edge_data_write_cu_buffer_states_cu_out),
		.vertex_job_cu_out                          (vertex_job_cu_out                          ),
		.request_vertex_job_cu_in                   (request_vertex_job_cu_in                   ),
		.vertex_job                                 (vertex_job                                 ),
		.vertex_num_counter_cu_in                   (vertex_num_counter_cu_in                   ),
		.edge_num_counter_cu_in                     (edge_num_counter_cu_in                     ),
		.vertex_job_request                         (vertex_job_request                         ),
		.vertex_job_counter_done_out                (vertex_job_counter_done_out                ),
		.edge_job_counter_done_out                  (edge_job_counter_done_out                  )
	);

	always #5 clock = ~clock;

	task automatic tick;
		begin
			@(posedge clock);
			#1;
		end
	endtask

	function automatic int onehot_owner(input logic [NUM_CUS-1:0] value);
		int index;
		begin
			onehot_owner = -1;
			for (index = 0; index < NUM_CUS; index++)
				if (value[index])
					onehot_owner = index;
		end
	endfunction

	initial begin
		clock = 0;
		rstn_in = 0;
		enabled_in = 0;
		wed_request_in = '0;
		cu_configure = 0;
		read_response_in = '0;
		write_response_in = '0;
		read_data_0_in = '0;
		read_data_1_in = '0;
		read_buffer_status = '0;
		read_buffer_status.empty = 1;
		write_buffer_status = '0;
		write_buffer_status.empty = 1;
		read_command_bus_grant = 1;
		write_command_bus_grant = 1;
		request_read_command_cu_in = 0;
		request_edge_data_write_cu_in = 0;
		request_vertex_job_cu_in = 0;
		vertex_job = '0;
		expected_vertex_sum = 0;
		expected_edge_sum = 0;
		for (i = 0; i < NUM_CUS; i++) begin
			read_command_cu_in[i] = '0;
			edge_data_write_cu_in[i] = '0;
			vertex_num_counter_cu_in[i] = i + 1;
			edge_num_counter_cu_in[i] = (i + 1) * 3;
			expected_vertex_sum += i + 1;
			expected_edge_sum += (i + 1) * 3;
		end
		repeat (7) tick();
		if (enable_cu_out || read_command_bus_request ||
			write_command_bus_request)
			$fatal(1, "ASSERT algorithm-arbiter reset/disabled idle");
		rstn_in = 1;
		enabled_in = 1;
		cu_configure = '1;
		wed_request_in.valid = 1;
		repeat (12) tick();
		if (enable_cu_out != '1)
			$fatal(1, "ASSERT algorithm-arbiter topology enable=%h",
				enable_cu_out);
		if ((vertex_job_counter_done_out != expected_vertex_sum) ||
			(edge_job_counter_done_out != expected_edge_sum))
			$fatal(1,
				"ASSERT algorithm-arbiter reduction vertex=%0d/%0d edge=%0d/%0d",
				vertex_job_counter_done_out, expected_vertex_sum,
				edge_job_counter_done_out, expected_edge_sum);
		$display("AG_BIN:algorithm_arbiter_reduction");

		enabled_in = 0;
		repeat (3) tick();
		enabled_in = 1;
		for (i = 0; i < NUM_CUS; i++) begin
			read_command_cu_in[i] = '1;
			edge_data_write_cu_in[i] = '1;
			vertex_num_counter_cu_in[i] = '1;
			edge_num_counter_cu_in[i] = '1;
		end
		read_response_in = '1;
		write_response_in = '1;
		read_data_0_in = '1;
		read_data_1_in = '1;
		read_buffer_status = '0;
		read_buffer_status.empty = 1;
		write_buffer_status = '0;
		write_buffer_status.empty = 1;
		vertex_job = '1;
		request_read_command_cu_in = '1;
		request_edge_data_write_cu_in = '1;
		request_vertex_job_cu_in = '1;
		repeat (2*NUM_CUS+4) tick();
		for (i = 0; i < NUM_CUS; i++) begin
			read_command_cu_in[i] = '0;
			edge_data_write_cu_in[i] = '0;
			vertex_num_counter_cu_in[i] = '0;
			edge_num_counter_cu_in[i] = '0;
		end
		read_response_in = '0;
		write_response_in = '0;
		read_data_0_in = '0;
		read_data_1_in = '0;
		vertex_job = '0;
		request_read_command_cu_in = '0;
		request_edge_data_write_cu_in = '0;
		request_vertex_job_cu_in = '0;
		repeat (8) tick();
		$display("AG_BIN:algorithm_arbiter_payload_toggle");

		for (i = 0; i < NUM_CUS; i++) begin
			read_command_cu_in[i].valid = 1;
			read_command_cu_in[i].payload.address = 64'h100 + i;
		end
		request_read_command_cu_in = '1;
		seen = '0;
		ready_d1 = '0;
		ready_d2 = '0;
		for (i = 0; i < 2*NUM_CUS; i++) begin
			tick();
			if ($countones(ready_read_command_cu_out) > 1)
				$fatal(1, "ASSERT algorithm-arbiter one-hot ready");
			owner = onehot_owner(ready_read_command_cu_out);
			if (owner >= 0)
				seen[owner] = 1;
			owner = onehot_owner(ready_d1);
			if ((owner >= 0) && dut.read_command_out_arbiter_latched.valid) begin
				if (dut.read_command_out_arbiter_latched.payload.address !==
					read_command_cu_in[owner].payload.address)
					$fatal(1,
						"ASSERT algorithm-arbiter payload owner=%0d expected=%h actual=%h",
						owner,
						read_command_cu_in[owner].payload.address,
						dut.read_command_out_arbiter_latched.payload.address);
			end
			ready_d2 = ready_d1;
			ready_d1 = ready_read_command_cu_out;
		end
		if (seen != '1)
			$fatal(1, "ASSERT algorithm-arbiter fairness seen=%h", seen);
		for (i = 0; i < NUM_CUS; i++)
			$display("AG_COORD:%0d:%0d", GRAPH_Y, i);
		$display("AG_BIN:algorithm_arbiter_all_held_fair");

		request_read_command_cu_in = '1;
		request_edge_data_write_cu_in = '1;
		write_seen = '0;
		for (i = 0; i < 2*NUM_CUS; i++) begin
			tick();
			if (($countones(ready_read_command_cu_out) > 1) ||
				($countones(ready_edge_data_write_cu_out) > 1))
				$fatal(1, "ASSERT algorithm-arbiter contention one-hot");
			owner = onehot_owner(ready_edge_data_write_cu_out);
			if (owner >= 0)
				write_seen[owner] = 1;
		end
		if (write_seen != '1)
			$fatal(1,
				"ASSERT algorithm-arbiter write fairness seen=%h",
				write_seen);
		$display("AG_BIN:algorithm_arbiter_read_write_contention");

		read_buffer_status = '1;
		write_buffer_status = '1;
		repeat (3) tick();
		read_buffer_status = '0;
		read_buffer_status.empty = 1;
		write_buffer_status = '0;
		write_buffer_status.empty = 1;
		for (i = 0; i < NUM_CUS; i++) begin
			read_response_in = '0;
			read_response_in.valid = 1;
			read_response_in.payload.cmd.cu_id_x = i;
			write_response_in = '0;
			write_response_in.valid = 1;
			write_response_in.payload.cmd.cu_id_x = i;
			read_data_0_in = '0;
			read_data_0_in.valid = 1;
			read_data_0_in.payload.cmd.cu_id_x = i;
			read_data_0_in.payload.cmd.cu_id_y = GRAPH_Y;
			read_data_0_in.payload.cmd.cmd_type = CMD_READ;
			read_data_0_in.payload.cmd.array_struct = READ_GRAPH_DATA;
			read_data_0_in.payload.cmd.tag = i;
			read_data_0_in.payload.data = '1;
			read_data_1_in = read_data_0_in;
			repeat (8) tick();
		end
		read_response_in = '0;
		write_response_in = '0;
		read_data_0_in = '0;
		read_data_1_in = '0;

		read_command_bus_grant = 0;
		write_command_bus_grant = 0;
		request_read_command_cu_in = '1;
		request_edge_data_write_cu_in = '1;
		request_vertex_job_cu_in = '0;
		vertex_job = '1;
		for (i = 0; i < NUM_CUS; i++) begin
			read_command_cu_in[i].valid = 1;
			edge_data_write_cu_in[i] = '1;
		end
		saw_read_alfull = 0;
		saw_write_alfull = 0;
		saw_vertex_alfull = 0;
		for (i = 0; i < 160; i++) begin
			tick();
			if (dut.burst_read_command_buffer_states_cu.alfull)
				saw_read_alfull = 1;
			if (dut.burst_edge_data_write_cu_buffer_states_cu.alfull)
				saw_write_alfull = 1;
			if (dut.vertex_buffer_status_internal.alfull)
				saw_vertex_alfull = 1;
		end
		if (!saw_read_alfull || !saw_write_alfull || !saw_vertex_alfull)
			$fatal(1,
				"ASSERT algorithm-arbiter near-full read=%0d write=%0d vertex=%0d",
				saw_read_alfull, saw_write_alfull, saw_vertex_alfull);
		$display("AG_BIN:algorithm_arbiter_near_full_stall");
		$display("AG_RESULT:PASS algorithm_arbiter_dut");
		$finish;
	end

endmodule
