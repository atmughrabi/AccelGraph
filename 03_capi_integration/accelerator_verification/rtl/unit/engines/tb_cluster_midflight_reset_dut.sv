import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module tb_cluster_midflight_reset_dut #(
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
	logic post_reset_counting;
	logic [GRAPH_CUS-1:0] config_seen;
	int wed_count[0:GRAPH_CUS-1];
	int config_count[0:GRAPH_CUS-1];
	int work_count[0:GRAPH_CUS-1];
	int i;
	int cycle;
	// the lower half of the configuration word is the host -K argument: the
	// total number of graph kernel CUs of the whole topology the round may use
	logic [0:63] configure_word;
	int kernel_cus;
	logic [GRAPH_CUS-1:0] expected_enable;

	cu_vertex_cluster_arbiter_control #(
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

	always_ff @(posedge clock) begin
		if(!post_reset_counting) begin
			config_seen <= 0;
			for (i = 0; i < GRAPH_CUS; i++) begin
				wed_count[i] <= 0;
				config_count[i] <= 0;
				work_count[i] <= 0;
			end
		end else begin
			for (i = 0; i < GRAPH_CUS; i++) begin
				if(cu_wed_request_out[i].valid)
					wed_count[i] <= wed_count[i] + 1;
				if((|cu_configure_out[i]) && !config_seen[i]) begin
					config_seen[i] <= 1;
					config_count[i] <= config_count[i] + 1;
				end
				if(vertex_job_cu_out[i].valid)
					work_count[i] <= work_count[i] + 1;
			end
		end
	end

	task automatic initialize_inputs;
		begin
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
			post_reset_counting = 0;
			for (i = 0; i < GRAPH_CUS; i++) begin
				read_command_out_cu_in[i] = '0;
				edge_data_write_cu_in[i] = '0;
				vertex_job_counter_done_cu_in[i] = 0;
				edge_job_counter_done_cu_in[i] = 0;
			end
		end
	endtask

	task automatic push_vertex(input int id);
		begin
			for (cycle = 0; cycle < 80; cycle++) begin
				tick();
				if(vertex_job_request)
					cycle = 80;
			end
			if(!vertex_job_request)
				$fatal(1, "ASSERT cluster did not request relaunched work");
			vertex_job = '0;
			vertex_job.valid = 1;
			vertex_job.payload.id = id;
			tick();
			vertex_job.valid = 0;
		end
	endtask

	// The configuration word the host publishes: the upper half is the CU
	// configuration and the lower half is the total kernel CU count.
	function automatic logic [0:63] configure_of(input int cus);
		logic [0:63] word;
		word         = 0;
		word[0:31]   = '1;
		word[32:63]  = cus[31:0];
		return word;
	endfunction

	// The cluster enable contract: the count is global, so cluster i is active
	// only while the first of its vertex CUs is below the requested count.
	function automatic logic [GRAPH_CUS-1:0] enable_of(input int cus);
		logic [GRAPH_CUS-1:0] mask;
		mask = 0;
		for (int cluster = 0; cluster < GRAPH_CUS; cluster++)
			mask[cluster] = ((cluster * VERTEX_CUS) < cus);
		return mask;
	endfunction

	// Restarts the counting window so a phase counts its own deliveries.
	task automatic restart_counting;
		begin
			post_reset_counting = 0;
			repeat (2) tick();
			post_reset_counting = 1;
		end
	endtask

	initial begin
		clock = 0;
		rstn_in = 0;
		initialize_inputs();
		kernel_cus     = GRAPH_CUS * VERTEX_CUS;
		configure_word = configure_of(kernel_cus);
		repeat (6) tick();

		rstn_in = 1;
		enabled_in = 1;
		cu_configure = configure_word;
		wed_request_in.valid = 1;
		wed_request_in.payload.address = 64'h1111;
		vertex_job_request_cu_in = {{(GRAPH_CUS-1){1'b0}}, 1'b1};
		repeat (5) tick();
		vertex_job.valid = 1;
		vertex_job.payload.id = 32'hdead;
		repeat (2) tick();

		rstn_in = 0;
		vertex_job = '0;
		wed_request_in = '0;
		cu_configure = 0;
		vertex_job_request_cu_in = '1;
		repeat (7) tick();

		post_reset_counting = 1;
		rstn_in = 1;
		enabled_in = 1;
		cu_configure = configure_word;
		repeat (5) tick();
		wed_request_in = '0;
		wed_request_in.valid = 1;
		wed_request_in.payload.address = 64'h2222;
		tick();
		wed_request_in.valid = 0;

		for (i = 0; i < GRAPH_CUS; i++)
			push_vertex(32'h100 + i);

		repeat (80) tick();
		$display("AG_TRACE:cluster_reset wed=%0d,%0d,%0d,%0d config=%0d,%0d,%0d,%0d work=%0d,%0d,%0d,%0d",
			wed_count[0], wed_count[1], wed_count[2], wed_count[3],
			config_count[0], config_count[1], config_count[2], config_count[3],
			work_count[0], work_count[1], work_count[2], work_count[3]);
		for (i = 0; i < GRAPH_CUS; i++) begin
			if(wed_count[i] != 1)
				$fatal(1,
					"ASSERT cluster %0d WED deliveries expected=1 actual=%0d",
					i, wed_count[i]);
			if(config_count[i] != 1)
				$fatal(1,
					"ASSERT cluster %0d config deliveries expected=1 actual=%0d",
					i, config_count[i]);
			if(work_count[i] != 1)
				$fatal(1,
					"ASSERT cluster %0d work deliveries expected=1 actual=%0d",
					i, work_count[i]);
			if(cu_wed_request_out[i].payload.address != 64'h2222)
				$fatal(1, "ASSERT cluster %0d WED payload ownership", i);
			// the configuration word reaches every cluster unchanged: the kernel
			// CU count it carries is a total over the whole topology and each
			// cluster selects its own CUs from the global index
			if(cu_configure_out[i] != configure_word)
				$fatal(1,
					"ASSERT cluster %0d config payload ownership value=%h expected=%h",
					i, cu_configure_out[i], configure_word);
		end
		if(enable_cu_out != enable_of(kernel_cus))
			$fatal(1,
				"ASSERT cluster enable mask %b expected=%b for %0d kernel CUs",
				enable_cu_out, enable_of(kernel_cus), kernel_cus);
		$display("AG_BIN:cluster_midflight_reset_relaunch_all");

		// The host may ask for fewer kernel CUs than the topology holds.  The
		// count is a total, so a partial count activates the leading clusters
		// only and every cluster it leaves out stays idle.
		for (int requested = 1; requested <= (GRAPH_CUS * VERTEX_CUS);
			requested = requested + VERTEX_CUS) begin
			rstn_in        = 0;
			vertex_job     = '0;
			wed_request_in = '0;
			cu_configure   = 0;
			repeat (7) tick();

			kernel_cus      = requested;
			configure_word  = configure_of(kernel_cus);
			expected_enable = enable_of(kernel_cus);
			rstn_in         = 1;
			cu_configure    = configure_word;
			repeat (5) tick();
			wed_request_in                 = '0;
			wed_request_in.valid           = 1;
			wed_request_in.payload.address = 64'h3333;
			tick();
			wed_request_in.valid = 0;
			repeat (8) tick();

			if(enable_cu_out != expected_enable)
				$fatal(1,
					"ASSERT cluster enable mask %b expected=%b for %0d kernel CUs",
					enable_cu_out, expected_enable, kernel_cus);

			restart_counting();
			for (i = 0; i < GRAPH_CUS; i++)
				push_vertex(32'h200 + i);
			repeat (80) tick();
			for (i = 0; i < GRAPH_CUS; i++) begin
				if(!expected_enable[i] && (work_count[i] != 0))
					$fatal(1,
						"ASSERT cluster %0d is outside %0d kernel CUs but took %0d vertices",
						i, kernel_cus, work_count[i]);
				if(cu_configure_out[i] != configure_word)
					$fatal(1,
						"ASSERT cluster %0d config payload value=%h expected=%h",
						i, cu_configure_out[i], configure_word);
			end
			$display("AG_TRACE:cluster_kernel_cus requested=%0d enable=%b work=%0d,%0d,%0d,%0d",
				kernel_cus, enable_cu_out,
				work_count[0], work_count[1], work_count[2], work_count[3]);
		end
		$display("AG_BIN:cluster_kernel_cu_count_contract");
		$display("AG_RESULT:PASS cluster_midflight_reset_dut");
		$finish;
	end

endmodule
