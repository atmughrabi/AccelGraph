import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module tb_edge_write_common_dut;

	logic clock;
	logic rstn;
	logic enabled_in;
	logic [0:63] cu_configure;
	WEDInterface wed_request_in;
	EdgeDataWrite edge_data_write;
	ReadWriteDataLine write_data_0_out;
	ReadWriteDataLine write_data_1_out;
	CommandBufferLine write_command_out;
	int i;
	bit observed;

	cu_edge_data_write_command_control #(
		.CU_ID_X(2),
		.CU_ID_Y(3)
	) dut (
		.clock            (clock            ),
		.rstn             (rstn             ),
		.enabled_in       (enabled_in       ),
		.cu_configure     (cu_configure     ),
		.wed_request_in   (wed_request_in   ),
		.edge_data_write  (edge_data_write  ),
		.write_data_0_out (write_data_0_out ),
		.write_data_1_out (write_data_1_out ),
		.write_command_out(write_command_out)
	);

	always #5 clock = ~clock;

	function automatic logic [0:(DATA_SIZE_WRITE_BITS-1)] model_swap(
		input logic [0:(DATA_SIZE_WRITE_BITS-1)] value
	);
		logic [0:(DATA_SIZE_WRITE_BITS-1)] result;
		int byte_index;
		begin
			for (byte_index = 0; byte_index < DATA_SIZE_WRITE; byte_index++)
				result[byte_index*8 +: 8] =
					value[(DATA_SIZE_WRITE-byte_index-1)*8 +: 8];
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
			cu_configure = 0;
			wed_request_in = '0;
			edge_data_write = '0;
			repeat (5) tick();
			if (write_command_out.valid || write_data_0_out.valid ||
				write_data_1_out.valid)
				$fatal(1, "ASSERT edge-write reset/disabled idle");
			rstn = 1;
			enabled_in = 1;
			cu_configure = 64'h1;
			wed_request_in.valid = 1;
			wed_request_in.payload.wed.auxiliary2 = 64'hc000;
			repeat (5) tick();
		end
	endtask

	task automatic toggle_inputs;
		begin
			cu_configure = '1;
			wed_request_in = '1;
			edge_data_write = '1;
			repeat (4) tick();
			cu_configure = '0;
			wed_request_in = '0;
			edge_data_write = '0;
			repeat (4) tick();
		end
	endtask

	task automatic check_write(input int index, input logic [0:(DATA_SIZE_WRITE_BITS-1)] data);
		int offset;
		logic [0:63] expected_address;
		begin
			edge_data_write = '0;
			edge_data_write.valid = 1;
			edge_data_write.payload.index = index;
			edge_data_write.payload.data = data;
			edge_data_write.payload.cu_id_x = 2;
			edge_data_write.payload.cu_id_y = 3;
			tick();
			edge_data_write.valid = 0;
			expected_address = 64'hc000 + (index << $clog2(DATA_SIZE_WRITE));
			offset = index % CACHELINE_DATA_WRITE_NUM_HF;
			observed = 0;
			for (i = 0; i < 16; i++) begin
				tick();
				if (write_command_out.valid) begin
					if (write_command_out.payload.address !== expected_address)
						$fatal(1, "ASSERT edge-write address");
					if (write_data_0_out.payload.data[offset*DATA_SIZE_WRITE_BITS +:
						DATA_SIZE_WRITE_BITS] !== model_swap(data))
						$fatal(1, "ASSERT edge-write lower data coupling");
					if (write_data_1_out.payload.data[offset*DATA_SIZE_WRITE_BITS +:
						DATA_SIZE_WRITE_BITS] !== model_swap(data))
						$fatal(1, "ASSERT edge-write upper data coupling");
					observed = 1;
					i = 16;
				end
			end
			if (!observed)
				$fatal(1, "ASSERT edge-write command missing");
		end
	endtask

	initial begin
		logic [0:(DATA_SIZE_WRITE_BITS-1)] data;
		clock = 0;
		reset_dut();
		toggle_inputs();
		$display("AG_BIN:edge_write_toggle_sweep");
		reset_dut();
		data = 'h1234;
		check_write(0, data);
		$display("AG_BIN:edge_write_lower_half");
		reset_dut();
		data = 'h5678;
		check_write(CACHELINE_DATA_WRITE_NUM_HF+1, data);
		$display("AG_BIN:edge_write_upper_half");
		$display("AG_RESULT:PASS edge_write_common_dut");
		$finish;
	end

endmodule
