import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

`ifndef DUT_MODULE
`define DUT_MODULE cu_vertex_cluster_arbiter_control
`endif

module tb_cluster_arbiter_dut #(
	parameter int GRAPH_CUS = 4,
	parameter int VERTEX_CUS = 4
);

	logic clock;
	logic rstn_in;
	logic enabled_in;
	logic [GRAPH_CUS-1:0] enable_cu_out;
	logic [0:63] cu_configure;
	logic [0:63] cu_configure_out[0:GRAPH_CUS-1];
	WEDInterface wed_request_in;
	WEDInterface cu_wed_request_out[0:GRAPH_CUS-1];
	ResponseBufferLine read_response_in;
	ResponseBufferLine read_response_cu_out[0:GRAPH_CUS-1];
	ResponseBufferLine write_response_in;
	ResponseBufferLine write_response_cu_out[0:GRAPH_CUS-1];
	ReadWriteDataLine read_data_0_in;
	ReadWriteDataLine read_data_1_in;
	ReadWriteDataLine read_data_0_cu_out[0:GRAPH_CUS-1];
	ReadWriteDataLine read_data_1_cu_out[0:GRAPH_CUS-1];
	BufferStatus read_buffer_status;
	BufferStatus read_buffer_status_cu_out[0:GRAPH_CUS-1];
	BufferStatus write_buffer_status;
	BufferStatus write_buffer_status_cu_out[0:GRAPH_CUS-1];
	logic read_command_bus_grant;
	logic [GRAPH_CUS-1:0] read_command_bus_grant_cu_out;
	logic read_command_bus_request;
	logic [GRAPH_CUS-1:0] read_command_bus_request_cu_in;
	CommandBufferLine read_command_out;
	CommandBufferLine read_command_out_cu_in[0:GRAPH_CUS-1];
	logic write_command_bus_grant;
	logic [GRAPH_CUS-1:0] write_command_bus_grant_cu_out;
	logic write_command_bus_request;
	logic [GRAPH_CUS-1:0] write_command_bus_request_cu_in;
	EdgeDataWrite edge_data_write_cu_in[0:GRAPH_CUS-1];
	EdgeDataWrite edge_data_write_out;
	VertexInterface vertex_job;
	VertexInterface vertex_job_cu_out[0:GRAPH_CUS-1];
	logic vertex_job_request;
	logic [GRAPH_CUS-1:0] vertex_job_request_cu_in;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done;
	logic [0:(EDGE_SIZE_BITS-1)] edge_job_counter_done;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done_cu_in[0:GRAPH_CUS-1];
	logic [0:(EDGE_SIZE_BITS-1)] edge_job_counter_done_cu_in[0:GRAPH_CUS-1];
	logic [GRAPH_CUS-1:0] seen;
	logic [GRAPH_CUS-1:0] ready_d1;
	logic [GRAPH_CUS-1:0] ready_d2;
	int expected_vertex_sum;
	int expected_edge_sum;
	int owner;
	int pending_owner;
	int i;
	logic [GRAPH_CUS-1:0] write_seen;
	bit saw_read_alfull;
	bit saw_write_alfull;
	bit saw_vertex_alfull;
	bit observed;
	int delivered_reads;
	int submitted_reads;
	int delivered_writes;
	int submitted_writes;
	int guard;
	bit stalled_owner;

	`DUT_MODULE #(
		.NUM_GRAPH_CU (GRAPH_CUS ),
		.NUM_VERTEX_CU(VERTEX_CUS)
	) dut (
		.*
	);

	always #5 clock = ~clock;

	task automatic tick;
		begin
			@(posedge clock);
			#1;
		end
	endtask

	function automatic int onehot_owner(input logic [GRAPH_CUS-1:0] value);
		int index;
		begin
			onehot_owner = -1;
			for (index = 0; index < GRAPH_CUS; index++)
				if (value[index])
					onehot_owner = index;
		end
	endfunction

	// Commands the arbiter published on the shared bus during the release and
	// recovery scenario, sampled every cycle so nothing is missed between ticks.
	bit recovery_active;
	int recovery_read_out;
	int recovery_write_out;

	always @(posedge clock) begin
		if (recovery_active) begin
			if (read_command_out.valid)
				recovery_read_out <= recovery_read_out + 1;
			if (edge_data_write_out.valid)
				recovery_write_out <= recovery_write_out + 1;
		end
	end

	// Quiesces the previous scenario and drains the shared buses.
	task automatic settle_buses;
		begin
			read_command_bus_request_cu_in  = 0;
			write_command_bus_request_cu_in = 0;
			vertex_job_request_cu_in        = 0;
			vertex_job                      = '0;
			for (i = 0; i < GRAPH_CUS; i++) begin
				read_command_out_cu_in[i] = '0;
				edge_data_write_cu_in[i]  = '0;
			end
			read_response_in  = '0;
			write_response_in = '0;
			read_data_0_in    = '0;
			read_data_1_in    = '0;
			read_buffer_status        = '0;
			read_buffer_status.empty  = 1;
			write_buffer_status       = '0;
			write_buffer_status.empty = 1;
			read_command_bus_grant  = 1;
			write_command_bus_grant = 1;
			repeat (400) tick();
		end
	endtask

	// A requester that only submits what it was granted: it drives one command
	// on the cycle after it observes its grant, which is the handshake every
	// cluster implements.
	task automatic submit_read(input int index);
		begin
			read_command_out_cu_in[index]                 = '0;
			read_command_out_cu_in[index].valid           = 1;
			read_command_out_cu_in[index].payload.address = 64'h5000 + submitted_reads;
			submitted_reads                               = submitted_reads + 1;
			tick();
			read_command_out_cu_in[index].valid = 0;
		end
	endtask

	task automatic submit_write(input int index);
		begin
			edge_data_write_cu_in[index]                = '0;
			edge_data_write_cu_in[index].valid          = 1;
			edge_data_write_cu_in[index].payload.index  = submitted_writes;
			submitted_writes                            = submitted_writes + 1;
			tick();
			edge_data_write_cu_in[index].valid = 0;
		end
	endtask

	// Ownership of the read bus taken while the outgoing command buffer is
	// almost full: the grant of the owner is masked by the same almost-full flag
	// one stage later, so a requester that only submits what it was granted
	// never submits and the bus never leaves that owner.  The bus has to recover
	// once the backpressure clears, and every granted command has to reach the
	// shared bus exactly once.
	task automatic release_recovery_read();
		begin
			settle_buses();
			recovery_read_out = 0;
			recovery_active   = 1;
			submitted_reads   = 0;
			stalled_owner     = 0;

			// the downstream bus never grants, so the arbiter command buffer
			// fills up while the cluster keeps asking for the bus
			read_command_bus_grant            = 0;
			read_command_bus_request_cu_in[0] = 1;
			guard                             = 0;
			while ((guard < 2000) && !dut.read_buffer_status_cu_out_internal.alfull) begin
				tick();
				guard = guard + 1;
				if (read_command_bus_grant_cu_out[0])
					submit_read(0);
			end
			if (!dut.read_buffer_status_cu_out_internal.alfull)
				$fatal(1,
					"ASSERT cluster-arbiter read release setup reached %0d commands without almost full",
					submitted_reads);

			// the cluster keeps its request asserted while the buffer is almost
			// full: no grant may be issued that the requester cannot observe
			for (guard = 0; guard < 64; guard++) begin
				tick();
`ifdef HELD_OWNER_PROTOCOL
				if (dut.read_buffer_status_cu_out_internal.alfull &&
					(|dut.read_command_owner) && !read_command_bus_grant_cu_out[0])
					stalled_owner = 1;
`endif
				if (read_command_bus_grant_cu_out[0])
					submit_read(0);
			end

			// the backpressure clears and the bus has to serve the cluster again
			read_command_bus_grant = 1;
			observed               = 0;
			for (guard = 0; guard < 600; guard++) begin
				tick();
				if (read_command_bus_grant_cu_out[0]) begin
					observed = 1;
					submit_read(0);
				end
			end
			if (!observed)
				$fatal(1,
					"ASSERT cluster-arbiter read bus never granted again after the almost full window granted=%0d",
					submitted_reads);

			read_command_bus_request_cu_in[0] = 0;
			repeat (400) tick();
			recovery_active = 0;
			if (recovery_read_out != submitted_reads)
				$fatal(1,
					"ASSERT cluster-arbiter read conservation published=%0d granted=%0d",
					recovery_read_out, submitted_reads);
			$display("AG_TRACE:cluster_release_recovery read granted=%0d published=%0d stalled_owner=%0d",
				submitted_reads, recovery_read_out, stalled_owner);
		end
	endtask

	// The write bus carries the same ownership protocol and the same almost-full
	// mask on its grant, so it is exercised the same way.
	task automatic release_recovery_write();
		begin
			settle_buses();
			recovery_write_out = 0;
			recovery_active    = 1;
			submitted_writes   = 0;

			write_command_bus_grant            = 0;
			write_command_bus_request_cu_in[0] = 1;
			guard                              = 0;
			while ((guard < 2000) && !dut.burst_edge_data_write_cu_buffer_states_cu.alfull) begin
				tick();
				guard = guard + 1;
				if (write_command_bus_grant_cu_out[0])
					submit_write(0);
			end
			if (!dut.burst_edge_data_write_cu_buffer_states_cu.alfull)
				$fatal(1,
					"ASSERT cluster-arbiter write release setup reached %0d commands without almost full",
					submitted_writes);

			for (guard = 0; guard < 64; guard++) begin
				tick();
				if (write_command_bus_grant_cu_out[0])
					submit_write(0);
			end

			write_command_bus_grant = 1;
			observed                = 0;
			for (guard = 0; guard < 600; guard++) begin
				tick();
				if (write_command_bus_grant_cu_out[0]) begin
					observed = 1;
					submit_write(0);
				end
			end
			if (!observed)
				$fatal(1,
					"ASSERT cluster-arbiter write bus never granted again after the almost full window granted=%0d",
					submitted_writes);

			write_command_bus_request_cu_in[0] = 0;
			repeat (400) tick();
			recovery_active = 0;
			if (recovery_write_out != submitted_writes)
				$fatal(1,
					"ASSERT cluster-arbiter write conservation published=%0d granted=%0d",
					recovery_write_out, submitted_writes);
			$display("AG_TRACE:cluster_release_recovery write granted=%0d published=%0d",
				submitted_writes, recovery_write_out);
		end
	endtask

	initial begin
		clock = 0;
		rstn_in = 0;
		enabled_in = 0;
		cu_configure = 0;
		wed_request_in = '0;
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
		read_command_bus_request_cu_in = 0;
		write_command_bus_request_cu_in = 0;
		vertex_job = '0;
		vertex_job_request_cu_in = 0;
		expected_vertex_sum = 0;
		expected_edge_sum = 0;
		for (i = 0; i < GRAPH_CUS; i++) begin
			read_command_out_cu_in[i] = '0;
			edge_data_write_cu_in[i] = '0;
			vertex_job_counter_done_cu_in[i] = i + 2;
			edge_job_counter_done_cu_in[i] = (i + 2) * 5;
			expected_vertex_sum += i + 2;
			expected_edge_sum += (i + 2) * 5;
		end
		repeat (6) tick();
		if (enable_cu_out || read_command_bus_request ||
			write_command_bus_request)
			$fatal(1, "ASSERT cluster-arbiter reset/disabled idle");
		rstn_in = 1;
		enabled_in = 1;
		cu_configure = 0;
		repeat (3) tick();
		cu_configure = '1;
		wed_request_in.valid = 1;
		repeat (10) tick();
		if (enable_cu_out != '1)
			$fatal(1, "ASSERT cluster-arbiter topology enable=%h",
				enable_cu_out);
		if ((vertex_job_counter_done != expected_vertex_sum) ||
			(edge_job_counter_done != expected_edge_sum))
			$fatal(1, "ASSERT cluster-arbiter reduction");
		$display("AG_BIN:cluster_arbiter_reduction");

		// The lower half of the configuration word is the host kernel CU count
		// (-K), counted over the whole topology.  Every cluster receives the
		// word unchanged and selects its own CUs from the global index, so a
		// count of one activates the first cluster only.
		cu_configure = 64'h1;
		repeat (4) tick();
		for (i = 0; i < GRAPH_CUS; i++) begin
			if (cu_configure_out[i] != 64'h1)
				$fatal(1,
					"ASSERT cluster-arbiter config broadcast cluster=%0d value=%h",
					i, cu_configure_out[i]);
			if (enable_cu_out[i] != ((i*VERTEX_CUS) < 1))
				$fatal(1,
					"ASSERT cluster-arbiter enable for one kernel CU enable=%b",
					enable_cu_out);
		end
		cu_configure = 64'(VERTEX_CUS + 1);
		repeat (4) tick();
		for (i = 0; i < GRAPH_CUS; i++) begin
			if (cu_configure_out[i] != 64'(VERTEX_CUS + 1))
				$fatal(1,
					"ASSERT cluster-arbiter config broadcast cluster=%0d value=%h",
					i, cu_configure_out[i]);
			if (enable_cu_out[i] != ((i*VERTEX_CUS) < (VERTEX_CUS + 1)))
				$fatal(1,
					"ASSERT cluster-arbiter enable for %0d kernel CUs enable=%b",
					VERTEX_CUS + 1, enable_cu_out);
		end
		$display("AG_BIN:cluster_arbiter_kernel_cu_count");
		cu_configure = '1;
		repeat (4) tick();

`ifdef HELD_OWNER_PROTOCOL
		read_command_bus_request_cu_in = 1;
		read_command_out_cu_in[0] = '0;
		observed = 0;
		repeat (8) begin
			tick();
			if(read_command_bus_grant_cu_out[0])
				observed = 1;
		end
		if(!observed)
			$fatal(1, "ASSERT cluster delayed read submit grant missing");
		read_command_out_cu_in[0].valid = 1;
		read_command_out_cu_in[0].payload.address = 64'habc;
		tick();
		read_command_out_cu_in[0].valid = 0;
		read_command_bus_request_cu_in = 0;
		observed = 0;
		repeat (8) begin
			tick();
			if(dut.read_command_out_internal.valid)
				observed = 1;
		end
		if(!observed)
			$fatal(1, "ASSERT cluster delayed read submit payload missing");

		write_command_bus_request_cu_in = 1;
		edge_data_write_cu_in[0] = '0;
		observed = 0;
		repeat (8) begin
			tick();
			if(write_command_bus_grant_cu_out[0])
				observed = 1;
		end
		if(!observed)
			$fatal(1, "ASSERT cluster delayed write submit grant missing");
		edge_data_write_cu_in[0].valid = 1;
		edge_data_write_cu_in[0].payload.index = 32'habc;
		tick();
		edge_data_write_cu_in[0].valid = 0;
		write_command_bus_request_cu_in = 0;
		observed = 0;
		repeat (10) begin
			tick();
			if(dut.edge_data_write_arbiter_out.valid)
				observed = 1;
		end
		if(!observed)
			$fatal(1, "ASSERT cluster delayed write submit payload missing");
`endif
		$display("AG_BIN:cluster_arbiter_delayed_submit");

		enabled_in = 0;
		repeat (3) tick();
		enabled_in = 1;
		for (i = 0; i < GRAPH_CUS; i++) begin
			read_command_out_cu_in[i] = '1;
			edge_data_write_cu_in[i] = '1;
			vertex_job_counter_done_cu_in[i] = '1;
			edge_job_counter_done_cu_in[i] = '1;
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
		read_command_bus_request_cu_in = '1;
		write_command_bus_request_cu_in = '1;
		vertex_job_request_cu_in = '1;
		repeat (2*GRAPH_CUS+4) tick();
		for (i = 0; i < GRAPH_CUS; i++) begin
			read_command_out_cu_in[i] = '0;
			edge_data_write_cu_in[i] = '0;
			vertex_job_counter_done_cu_in[i] = '0;
			edge_job_counter_done_cu_in[i] = '0;
		end
		read_response_in = '0;
		write_response_in = '0;
		read_data_0_in = '0;
		read_data_1_in = '0;
		vertex_job = '0;
		read_command_bus_request_cu_in = '0;
		write_command_bus_request_cu_in = '0;
		vertex_job_request_cu_in = '0;
		repeat (8) tick();
		$display("AG_BIN:cluster_arbiter_payload_toggle");

		for (i = 0; i < GRAPH_CUS; i++) begin
			read_command_out_cu_in[i].valid = 1;
			read_command_out_cu_in[i].payload.address = 64'h200 + i;
		end
		read_command_bus_request_cu_in = '1;
		seen = '0;
`ifdef HELD_OWNER_PROTOCOL
		pending_owner = -1;
		for (i = 0; i < 12*GRAPH_CUS; i++) begin
			tick();
			if ($countones(read_command_bus_grant_cu_out) > 1)
				$fatal(1, "ASSERT cluster-arbiter one-hot grant");
			owner = onehot_owner(read_command_bus_grant_cu_out);
			if (owner >= 0) begin
				if (pending_owner >= 0)
					$fatal(1,
						"ASSERT cluster-arbiter overlapping owners old=%0d new=%0d",
						pending_owner, owner);
				pending_owner = owner;
				seen[owner] = 1;
			end
			if (dut.read_command_out_internal.valid) begin
				if (pending_owner < 0)
					$fatal(1,
						"ASSERT cluster-arbiter payload without owner");
				if (dut.read_command_out_internal.payload.address !==
					read_command_out_cu_in[pending_owner].payload.address)
					$fatal(1,
						"ASSERT cluster-arbiter payload owner=%0d expected=%h actual=%h",
						pending_owner,
						read_command_out_cu_in[pending_owner].payload.address,
						dut.read_command_out_internal.payload.address);
				pending_owner = -1;
			end
			if ((seen == '1) && (pending_owner < 0))
				i = 12*GRAPH_CUS;
		end
`else
		ready_d1 = '0;
		ready_d2 = '0;
		for (i = 0; i < 2*GRAPH_CUS; i++) begin
			tick();
			if ($countones(read_command_bus_grant_cu_out) > 1)
				$fatal(1, "ASSERT cluster-arbiter one-hot grant");
			owner = onehot_owner(read_command_bus_grant_cu_out);
			if (owner >= 0)
				seen[owner] = 1;
			owner = onehot_owner(ready_d1);
			if ((owner >= 0) && dut.read_command_out_internal.valid) begin
				if (dut.read_command_out_internal.payload.address !==
					read_command_out_cu_in[owner].payload.address)
					$fatal(1,
						"ASSERT cluster-arbiter payload owner=%0d expected=%h actual=%h",
						owner,
						read_command_out_cu_in[owner].payload.address,
						dut.read_command_out_internal.payload.address);
			end
			ready_d2 = ready_d1;
			ready_d1 = read_command_bus_grant_cu_out;
		end
`endif
		if (seen != '1)
			$fatal(1, "ASSERT cluster-arbiter fairness seen=%h", seen);
		$display("AG_BIN:cluster_arbiter_all_held_fair");

		read_command_bus_request_cu_in = '1;
		write_command_bus_request_cu_in = '1;
		write_seen = '0;
		for (i = 0; i < GRAPH_CUS; i++) begin
			edge_data_write_cu_in[i].valid = 1;
			edge_data_write_cu_in[i].payload.index = i;
		end
		for (i = 0; i < 12*GRAPH_CUS; i++) begin
			tick();
			if (($countones(read_command_bus_grant_cu_out) > 1) ||
				($countones(write_command_bus_grant_cu_out) > 1))
				$fatal(1, "ASSERT cluster-arbiter contention one-hot");
			owner = onehot_owner(write_command_bus_grant_cu_out);
			if (owner >= 0)
				write_seen[owner] = 1;
		end
		if (write_seen != '1)
			$fatal(1,
				"ASSERT cluster-arbiter write fairness seen=%h",
				write_seen);
		$display("AG_BIN:cluster_arbiter_read_write_contention");

		read_buffer_status = '1;
		write_buffer_status = '1;
		repeat (3) tick();
		read_buffer_status = '0;
		read_buffer_status.empty = 1;
		write_buffer_status = '0;
		write_buffer_status.empty = 1;
		for (i = 0; i < GRAPH_CUS; i++) begin
			read_response_in = '0;
			read_response_in.valid = 1;
			read_response_in.payload.cmd.cu_id_y = i;
			write_response_in = '0;
			write_response_in.valid = 1;
			write_response_in.payload.cmd.cu_id_y = i;
			read_data_0_in = '0;
			read_data_0_in.valid = 1;
			read_data_0_in.payload.cmd.cu_id_y = i;
			read_data_0_in.payload.cmd.cmd_type = CMD_READ;
			read_data_0_in.payload.cmd.array_struct = READ_GRAPH_DATA;
			read_data_0_in.payload.cmd.tag = i;
			read_data_0_in.payload.data = '1;
			read_data_1_in = read_data_0_in;
			repeat (4) tick();
		end
		read_response_in = '0;
		write_response_in = '0;
		read_data_0_in = '0;
		read_data_1_in = '0;

		read_command_bus_grant = 0;
		write_command_bus_grant = 0;
		read_command_bus_request_cu_in = '1;
		write_command_bus_request_cu_in = '1;
		vertex_job_request_cu_in = '0;
		vertex_job = '1;
		for (i = 0; i < GRAPH_CUS; i++) begin
			read_command_out_cu_in[i].valid = 1;
			edge_data_write_cu_in[i] = '1;
		end
		saw_read_alfull = 0;
		saw_write_alfull = 0;
		saw_vertex_alfull = 0;
		for (i = 0; i < 160; i++) begin
			tick();
			if (dut.read_buffer_status_cu_out_internal.alfull)
				saw_read_alfull = 1;
			if (dut.burst_edge_data_write_cu_buffer_states_cu.alfull)
				saw_write_alfull = 1;
			if (dut.vertex_buffer_status_internal.alfull)
				saw_vertex_alfull = 1;
		end
		if (!saw_read_alfull || !saw_write_alfull || !saw_vertex_alfull)
			$fatal(1,
				"ASSERT cluster-arbiter near-full read=%0d write=%0d vertex=%0d",
				saw_read_alfull, saw_write_alfull, saw_vertex_alfull);
		$display("AG_BIN:cluster_arbiter_near_full_stall");

		release_recovery_read();
		release_recovery_write();
		$display("AG_BIN:cluster_arbiter_backpressure_release_recovery");
		$display("AG_RESULT:PASS cluster_arbiter_dut");
		$finish;
	end

endmodule
