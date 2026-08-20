import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module tb_edge_read_command_dut;

	logic clock;
	logic rstn_in;
	logic enabled_in;
	logic [0:63] cu_configure;
	WEDInterface wed_request_in;
	ResponseBufferLine read_response_in;
	EdgeDataRead edge_data_read_in;
	BufferStatus read_buffer_status;
	logic edge_data_request;
	EdgeInterface edge_job;
	logic edge_request;
	logic read_command_bus_grant;
	logic read_command_bus_request;
	CommandBufferLine read_command_out;
	BufferStatus data_buffer_status;
`ifdef LAYOUT_CC
	logic [0:(EDGE_SIZE_BITS-1)] edge_data_continue_accum_out;
	EdgeComponentUpdate edge_data;
`else
	EdgeDataRead edge_data;
`endif
	logic [0:63] data_base;
	int i;
	bit observed;

	cu_edge_data_read_command_control #(
		.CU_ID_X(2),
		.CU_ID_Y(3)
	) dut (
		.clock                   (clock                   ),
		.rstn_in                 (rstn_in                 ),
		.enabled_in              (enabled_in              ),
		.cu_configure            (cu_configure            ),
		.wed_request_in          (wed_request_in          ),
		.read_response_in        (read_response_in        ),
		.edge_data_read_in       (edge_data_read_in       ),
		.read_buffer_status      (read_buffer_status      ),
		.edge_data_request       (edge_data_request       ),
		.edge_job                (edge_job                ),
		.edge_request            (edge_request            ),
		.read_command_bus_grant  (read_command_bus_grant  ),
		.read_command_bus_request(read_command_bus_request),
		.read_command_out        (read_command_out        ),
		.data_buffer_status      (data_buffer_status      ),
`ifdef LAYOUT_CC
		.edge_data_continue_accum_out(edge_data_continue_accum_out),
`endif
		.edge_data               (edge_data               )
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
			edge_data_read_in = '0;
			read_buffer_status = '0;
			read_buffer_status.empty = 1;
			edge_data_request = 0;
			edge_job = '0;
			read_command_bus_grant = 0;
			repeat (6) tick();
			if (read_command_out.valid || read_command_bus_request)
				$fatal(1, "ASSERT edge-read reset/disabled idle");
			rstn_in = 1;
			enabled_in = 1;
			cu_configure = 64'h1;
			read_command_bus_grant = 1;
			wed_request_in.valid = 1;
			wed_request_in.payload.wed.auxiliary1 = 64'ha000;
`ifdef LAYOUT_BFS
			wed_request_in.payload.wed.auxiliary3 = 64'hb000;
			data_base = 64'hb000;
`else
			data_base = 64'ha000;
`endif
			repeat (8) tick();
		end
	endtask

	task automatic toggle_inputs;
		begin
			cu_configure = '1;
			wed_request_in = '1;
			read_response_in = '1;
			edge_data_read_in = '1;
			read_buffer_status = '1;
			edge_data_request = 1;
			edge_job = '1;
			read_command_bus_grant = 0;
			repeat (4) tick();
			cu_configure = '0;
			wed_request_in = '0;
			read_response_in = '0;
			edge_data_read_in = '0;
			read_buffer_status = '0;
			read_buffer_status.empty = 1;
			edge_data_request = 0;
			edge_job = '0;
			read_command_bus_grant = 1;
			repeat (4) tick();
		end
	endtask

`ifdef LAYOUT_CC
	task automatic exercise_component_path(
		input bit equal_components,
		input bit alternate_pattern
	);
		int command_count;
		int output_count;
		logic [0:(DATA_SIZE_READ_BITS-1)] src_component;
		logic [0:(DATA_SIZE_READ_BITS-1)] dest_component;
		logic [0:(DATA_SIZE_READ_BITS-1)] high_component;
		begin
			reset_dut();
			edge_data_request = 1;
			if (equal_components) begin
				src_component = '1;
				dest_component = '1;
				high_component = '1;
			end else if (alternate_pattern) begin
				src_component = 32'haaaaaaaa;
				dest_component = 32'hffffffff;
				high_component = 32'h55555555;
			end else begin
				src_component = 32'h55555555;
				dest_component = 32'haaaaaaaa;
				high_component = 32'hffffffff;
			end
			edge_job = '0;
			edge_job.valid = 1;
			edge_job.payload.id = '1;
			edge_job.payload.src = alternate_pattern
				? 32'haaaaaaaa : 32'h55555555;
			edge_job.payload.dest = alternate_pattern
				? 32'hffffffff : 32'haaaaaaaa;
			tick();
			edge_job.valid = 0;
			command_count = 0;
			output_count = 0;
			for (i = 0; i < 320; i++) begin
				tick();
				read_response_in.valid = 0;
				edge_data_read_in.valid = 0;
				if (read_command_out.valid) begin
					read_response_in = '0;
					read_response_in.valid = 1;
					read_response_in.payload.cmd =
						read_command_out.payload.cmd;
					edge_data_read_in = '0;
					edge_data_read_in.valid = 1;
					edge_data_read_in.payload.array_struct =
						read_command_out.payload.cmd.array_struct;
					case (read_command_out.payload.cmd.array_struct)
						READ_GRAPH_DATA_SRC :
							edge_data_read_in.payload.data = src_component;
						READ_GRAPH_DATA_DEST :
							edge_data_read_in.payload.data = dest_component;
						READ_GRAPH_DATA_HIGH :
							edge_data_read_in.payload.data = high_component;
					endcase
					command_count++;
				end
				if (edge_data.valid) begin
					if (equal_components)
						$fatal(1,
							"ASSERT equal components produced an update");
					if ((edge_data.payload.comp_high != dest_component) ||
						(edge_data.payload.comp_low != src_component) ||
						(edge_data.payload.comp_comp_high !=
							high_component))
						$fatal(1,
							"ASSERT component update high=%0d low=%0d comp=%0d",
							edge_data.payload.comp_high,
							edge_data.payload.comp_low,
							edge_data.payload.comp_comp_high);
					output_count++;
				end
				if ((!equal_components && (output_count == 1)) ||
					(equal_components &&
						(edge_data_continue_accum_out == 1)))
					i = 320;
			end
			read_response_in = '0;
			edge_data_read_in = '0;
			if (equal_components) begin
				if ((command_count != 2) ||
					(edge_data_continue_accum_out != 1))
					$fatal(1,
						"ASSERT equal component path commands=%0d continue=%0d",
						command_count, edge_data_continue_accum_out);
			end else begin
				if ((command_count != 3) || (output_count != 1))
					$fatal(1,
						"ASSERT unequal component path commands=%0d outputs=%0d",
						command_count, output_count);
			end
		end
	endtask

	task automatic exercise_component_queue_near_full;
		int job;
		int local_commands;
		bit saw_near_full;
		begin
			reset_dut();
			edge_data_request = 0;
			saw_near_full = 0;
			for (job = 0; job < CU_EDGE_JOB_BUFFER_SIZE; job++) begin
				for (i = 0; i < 40; i++) begin
					tick();
					if (edge_request)
						i = 40;
				end
				if (!edge_request)
					$fatal(1,
						"ASSERT component queue source did not request edge");
				edge_job = '0;
				edge_job.valid = 1;
				edge_job.payload.src = job;
				edge_job.payload.dest = job + 1;
				tick();
				edge_job.valid = 0;
				local_commands = 0;
				for (i = 0; i < 160; i++) begin
					tick();
					read_response_in.valid = 0;
					edge_data_read_in.valid = 0;
					if (read_command_out.valid) begin
						read_response_in = '0;
						read_response_in.valid = 1;
						read_response_in.payload.cmd =
							read_command_out.payload.cmd;
						edge_data_read_in = '0;
						edge_data_read_in.valid = 1;
						edge_data_read_in.payload.array_struct =
							read_command_out.payload.cmd.array_struct;
						case (read_command_out.payload.cmd.array_struct)
							READ_GRAPH_DATA_SRC :
								edge_data_read_in.payload.data =
									(2*job) + 1;
							READ_GRAPH_DATA_DEST :
								edge_data_read_in.payload.data =
									(2*job) + 2;
							READ_GRAPH_DATA_HIGH :
								edge_data_read_in.payload.data =
									(2*job) + 3;
						endcase
						local_commands++;
					end
					if (local_commands == 3)
						i = 160;
				end
				tick();
				read_response_in = '0;
				edge_data_read_in = '0;
				if (local_commands != 3)
					$fatal(1,
						"ASSERT component queue command count job=%0d count=%0d",
						job, local_commands);
				repeat (8) tick();
				if (data_buffer_status.alfull) begin
					saw_near_full = 1;
					job = CU_EDGE_JOB_BUFFER_SIZE;
				end
			end
			if (!saw_near_full)
				$fatal(1,
					"ASSERT component result queue never reached near-full");
			edge_data_request = 1;
			repeat (CU_EDGE_JOB_BUFFER_SIZE + 20) tick();
			if (!data_buffer_status.empty)
				$fatal(1,
					"ASSERT component result queue did not drain");
		end
	endtask
`endif

	initial begin
		logic [0:63] element_index;
		logic [0:63] expected_address;
		logic [0:7] expected_offset;
		clock = 0;
		reset_dut();
		$display("AG_BIN:edge_read_reset_disabled_idle");
		toggle_inputs();
		$display("AG_BIN:edge_read_toggle_sweep");
		reset_dut();

		edge_job.valid = 1;
		edge_job.payload.src = 3;
		edge_job.payload.dest = CACHELINE_DATA_READ_NUM_HF + 1;
		tick();
		edge_job.valid = 0;
`ifdef LAYOUT_CC
		element_index = 3;
`else
		element_index = CACHELINE_DATA_READ_NUM_HF + 1;
`endif
		expected_address = data_base +
			((element_index << $clog2(DATA_SIZE_READ)) &
				ADDRESS_DATA_READ_ALIGN_MASK);
		expected_offset =
			((element_index << $clog2(DATA_SIZE_READ)) &
				ADDRESS_DATA_READ_MOD_MASK) >> $clog2(DATA_SIZE_READ);
		observed = 0;
		for (i = 0; i < 100; i++) begin
			tick();
			if (read_command_out.valid) begin
				if (read_command_out.payload.address !== expected_address)
					$fatal(1,
						"ASSERT edge-read address expected=%h actual=%h",
						expected_address, read_command_out.payload.address);
				if (read_command_out.payload.cmd.cacheline_offset !=
					expected_offset)
					$fatal(1,
						"ASSERT edge-read offset expected=%0d actual=%0d",
						expected_offset,
						read_command_out.payload.cmd.cacheline_offset);
				observed = 1;
				i = 100;
			end
		end
		if (!observed)
			$fatal(1, "ASSERT edge-read command missing");
		$display("AG_BIN:edge_read_upper_offset");

`ifdef LAYOUT_CC
		exercise_component_path(0, 0);
		exercise_component_path(0, 1);
		$display("AG_BIN:edge_read_component_unequal");
		exercise_component_path(1, 0);
		$display("AG_BIN:edge_read_component_equal");
		exercise_component_queue_near_full();
		$display("AG_BIN:edge_read_component_queue_near_full");
`endif

`ifndef LAYOUT_CC
		edge_data_request = 0;
		observed = 0;
		for (i = 0; i < 80; i++) begin
			edge_data_read_in = '0;
			edge_data_read_in.valid = 1;
			edge_data_read_in.payload.cu_id_x = 2;
			edge_data_read_in.payload.cu_id_y = 3;
			edge_data_read_in.payload.data = i;
			tick();
			if (data_buffer_status.alfull)
				observed = 1;
			if (data_buffer_status.alfull)
				i = 80;
		end
		edge_data_read_in.valid = 0;
		if (!observed)
			$fatal(1, "ASSERT edge-read data queue never reached near-full");
		edge_data_request = 1;
		repeat (100) tick();
		if (!data_buffer_status.empty)
			$fatal(1, "ASSERT edge-read data queue did not drain");
		$display("AG_BIN:edge_read_data_queue_near_full");

		edge_data_read_in = '0;
		edge_data_read_in.valid = 1;
		edge_data_read_in.payload.cu_id_x = 2;
		edge_data_read_in.payload.cu_id_y = 3;
		edge_data_read_in.payload.data = 'h55;
		tick();
		edge_data_read_in.valid = 0;
		edge_data_request = 1;
		observed = 0;
		for (i = 0; i < 20; i++) begin
			tick();
			if (edge_data.valid) begin
				if (edge_data.payload.data !== 'h55)
					$fatal(1, "ASSERT edge-read queue payload");
				observed = 1;
				i = 20;
			end
		end
		if (!observed)
			$fatal(1, "ASSERT edge-read queued data missing");
		$display("AG_BIN:edge_read_data_queue");
`endif
		$display("AG_RESULT:PASS edge_read_command_dut");
		$finish;
	end

endmodule
