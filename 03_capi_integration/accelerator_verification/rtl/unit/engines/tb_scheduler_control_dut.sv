import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

`ifndef DUT_MODULE
`define DUT_MODULE cu_graph_algorithm_control
`endif

module tb_scheduler_control_dut #(
	parameter int VERTEX_CUS = 4,
	parameter int GRAPH_CUS = 4,
	parameter int GRAPH_Y = 1
);

	logic clock;
	logic rstn_in;
	logic enabled_in;
	logic [0:63] cu_configure;
	WEDInterface wed_request_in;
	ResponseBufferLine read_response_in;
	ResponseBufferLine write_response_in;
	ReadWriteDataLine read_data_0_in;
	ReadWriteDataLine read_data_1_in;
	BufferStatus read_buffer_status;
	logic read_command_bus_grant;
	logic read_command_bus_request;
	CommandBufferLine read_command_out;
	BufferStatus write_buffer_status;
	logic write_command_bus_grant;
	logic write_command_bus_request;
	EdgeDataWrite edge_data_write_out;
	VertexInterface vertex_job;
	logic vertex_job_request;
	logic [0:(VERTEX_SIZE_BITS-1)] vertex_job_counter_done;
	logic [0:(EDGE_SIZE_BITS-1)] edge_job_counter_done;
	int i;
	bit observed;

	`DUT_MODULE #(
		.NUM_VERTEX_CU(VERTEX_CUS),
		.NUM_GRAPH_CU (GRAPH_CUS ),
		.CU_ID_Y      (GRAPH_Y   )
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
		vertex_job = '0;
		repeat (8) tick();
		if (read_command_bus_request || write_command_bus_request ||
			edge_data_write_out.valid)
			$fatal(1, "ASSERT scheduler-control reset/disabled idle");
		rstn_in = 1;
		enabled_in = 1;
		repeat (3) tick();
		enabled_in = 0;
		repeat (3) tick();
		enabled_in = 1;
		cu_configure = '1;
		wed_request_in = '1;
		read_response_in = '1;
		write_response_in = '1;
		read_data_0_in = '1;
		read_data_1_in = '1;
		read_buffer_status = '1;
		write_buffer_status = '1;
		vertex_job = '1;
		read_command_bus_grant = 0;
		write_command_bus_grant = 0;
		repeat (5) tick();
		rstn_in = 0;
		repeat (5) tick();
		rstn_in = 1;
		enabled_in = 1;
		cu_configure = '1;
		read_response_in = '0;
		write_response_in = '0;
		read_data_0_in = '0;
		read_data_1_in = '0;
		read_buffer_status = '0;
		read_buffer_status.empty = 1;
		write_buffer_status = '0;
		write_buffer_status.empty = 1;
		vertex_job = '0;
		read_command_bus_grant = 1;
		write_command_bus_grant = 1;
		wed_request_in = '0;
		wed_request_in.valid = 1;
		wed_request_in.payload.wed.num_vertices = 1;
		observed = 0;
		for (i = 0; i < 160; i++) begin
			tick();
			if (vertex_job_request)
				observed = 1;
			if (read_command_bus_request)
				i = 160;
		end
		if (!observed)
			$fatal(1, "ASSERT scheduler-control vertex readiness");
		$display("AG_BIN:scheduler_control_activation");
		$display("AG_RESULT:PASS scheduler_control_dut");
		$finish;
	end

endmodule
