import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module tb_edge_write_bfs_dut;

	logic clock;
	logic rstn;
	logic enabled_in;
	logic edge_data_write_bus_grant_out;
	logic edge_data_write_bus_request_in;
	logic write_command_bus_request_out;
	logic write_command_bus_grant_in;
	logic [0:63] cu_configure;
	WEDInterface wed_request_in;
	EdgeDataWrite edge_data_write;
	ReadWriteDataLine write_data_0_out;
	ReadWriteDataLine write_data_1_out;
	CommandBufferLine write_command_out;
	int i;
	int observed;

	cu_edge_data_write_command_control #(
		.CU_ID_X(2),
		.CU_ID_Y(3)
	) dut (
		.clock                         (clock                         ),
		.rstn                          (rstn                          ),
		.enabled_in                    (enabled_in                    ),
		.edge_data_write_bus_grant_out (edge_data_write_bus_grant_out ),
		.edge_data_write_bus_request_in(edge_data_write_bus_request_in),
		.write_command_bus_request_out (write_command_bus_request_out ),
		.write_command_bus_grant_in    (write_command_bus_grant_in    ),
		.cu_configure                  (cu_configure                  ),
		.wed_request_in                (wed_request_in                ),
		.edge_data_write               (edge_data_write               ),
		.write_data_0_out              (write_data_0_out              ),
		.write_data_1_out              (write_data_1_out              ),
		.write_command_out             (write_command_out             )
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
		edge_data_write_bus_request_in = 0;
		write_command_bus_grant_in = 0;
		cu_configure = 0;
		wed_request_in = '0;
		edge_data_write = '0;
		repeat (6) tick();
		if (write_command_out.valid || write_command_bus_request_out)
			$fatal(1, "ASSERT BFS edge-write reset/disabled idle");
		rstn = 1;
		enabled_in = 1;
		cu_configure = 64'h1;
		wed_request_in.valid = 1;
		wed_request_in.payload.wed.auxiliary4 = 64'hd000;
		wed_request_in.payload.wed.auxiliary1 = 64'he000;
		write_command_bus_grant_in = 1;
		edge_data_write_bus_request_in = 1;
		repeat (6) tick();
		if (!edge_data_write_bus_grant_out)
			$fatal(1, "ASSERT BFS edge-write input grant");

		cu_configure = '1;
		wed_request_in = '1;
		edge_data_write = '1;
		edge_data_write_bus_request_in = 1;
		write_command_bus_grant_in = 0;
		repeat (4) tick();
		cu_configure = 64'h1;
		wed_request_in = '0;
		wed_request_in.valid = 1;
		wed_request_in.payload.wed.auxiliary4 = 64'hd000;
		wed_request_in.payload.wed.auxiliary1 = 64'he000;
		edge_data_write = '0;
		write_command_bus_grant_in = 1;
		repeat (4) tick();
		$display("AG_BIN:edge_write_toggle_sweep");

		rstn = 0;
		edge_data_write_bus_request_in = 0;
		write_command_bus_grant_in = 0;
		cu_configure = 0;
		wed_request_in = '0;
		edge_data_write = '0;
		repeat (6) tick();
		rstn = 1;
		enabled_in = 1;
		cu_configure = 64'h1;
		wed_request_in.valid = 1;
		wed_request_in.payload.wed.auxiliary4 = 64'hd000;
		wed_request_in.payload.wed.auxiliary1 = 64'he000;
		write_command_bus_grant_in = 1;
		edge_data_write_bus_request_in = 1;
		repeat (6) tick();

		write_command_bus_grant_in = 0;
		observed = 0;
		for (i = 0; i < 96; i++) begin
			edge_data_write = '0;
			edge_data_write.valid = edge_data_write_bus_grant_out;
			edge_data_write.payload.index = i;
			edge_data_write.payload.data_1 = i;
			edge_data_write.payload.data_2 = ~i;
			edge_data_write.payload.cu_id_x = 2;
			edge_data_write.payload.cu_id_y = 3;
			tick();
			if (!edge_data_write_bus_grant_out)
				observed = 1;
			if (observed)
				i = 96;
		end
		edge_data_write.valid = 0;
		if (!observed)
			$fatal(1, "ASSERT BFS edge-write queue never reached near-full");
		write_command_bus_grant_in = 1;
		repeat (200) tick();
		if (!edge_data_write_bus_grant_out)
			$fatal(1, "ASSERT BFS edge-write queue did not recover");
		$display("AG_BIN:edge_write_queue_near_full");

		rstn = 0;
		edge_data_write_bus_request_in = 0;
		write_command_bus_grant_in = 0;
		cu_configure = 0;
		wed_request_in = '0;
		edge_data_write = '0;
		repeat (6) tick();
		rstn = 1;
		enabled_in = 1;
		cu_configure = 64'h1;
		wed_request_in.valid = 1;
		wed_request_in.payload.wed.auxiliary4 = 64'hd000;
		wed_request_in.payload.wed.auxiliary1 = 64'he000;
		write_command_bus_grant_in = 1;
		edge_data_write_bus_request_in = 1;
		repeat (6) tick();

		cu_configure = 0;
		cu_configure[19] = 1;
		cu_configure[15:17] = '1;
		repeat (4) tick();
		edge_data_write = '0;
		edge_data_write.valid = 1;
		edge_data_write.payload.index = 7;
		edge_data_write.payload.data_1 = 8'ha5;
		edge_data_write.payload.data_2 = 32'h5aa55aa5;
		edge_data_write.payload.cu_id_x = 2;
		edge_data_write.payload.cu_id_y = 3;
		tick();
		edge_data_write.valid = 0;
		observed = 0;
		for (i = 0; i < 80; i++) begin
			tick();
			if (write_command_out.valid) begin
				if (write_command_out.payload.command != WRITE_MS)
					$fatal(1,
						"ASSERT BFS coherent write opcode=%h",
						write_command_out.payload.command);
				observed++;
			end
			if (observed == 2)
				i = 80;
		end
		if (observed != 2)
			$fatal(1,
				"ASSERT BFS coherent dual-property write count=%0d",
				observed);
		$display("AG_BIN:edge_write_bfs_coherent");

		rstn = 0;
		edge_data_write_bus_request_in = 0;
		write_command_bus_grant_in = 0;
		cu_configure = 0;
		wed_request_in = '0;
		edge_data_write = '0;
		repeat (6) tick();
		rstn = 1;
		enabled_in = 1;
		cu_configure = 64'h1;
		wed_request_in.valid = 1;
		wed_request_in.payload.wed.auxiliary4 = 64'hd000;
		wed_request_in.payload.wed.auxiliary1 = 64'he000;
		write_command_bus_grant_in = 1;
		edge_data_write_bus_request_in = 1;
		repeat (6) tick();

		edge_data_write.valid = 1;
		edge_data_write.payload.index = 3;
		edge_data_write.payload.data_1 = 8'h5a;
		edge_data_write.payload.data_2 = 32'h12345678;
		edge_data_write.payload.cu_id_x = 2;
		edge_data_write.payload.cu_id_y = 3;
		tick();
		edge_data_write.valid = 0;
		observed = 0;
		for (i = 0; i < 80; i++) begin
			tick();
			if (write_command_out.valid) begin
				if (observed == 0) begin
					if (write_command_out.payload.address !==
						(64'hd000 + (3 << $clog2(DATA_SIZE_WRITE))))
						$fatal(1, "ASSERT BFS frontier write address");
				end else if (observed == 1) begin
					if (write_command_out.payload.address !==
						(64'he000 + (3 << $clog2(DATA_SIZE_WRITE_PARENT))))
						$fatal(1, "ASSERT BFS parent write address");
				end
				observed++;
			end
			if (observed == 2)
				i = 80;
		end
		if (observed != 2)
			$fatal(1, "ASSERT BFS dual-property write count=%0d", observed);
		$display("AG_BIN:edge_write_bfs_dual_property");
		$display("AG_RESULT:PASS edge_write_bfs_dut");
		$finish;
	end

endmodule
