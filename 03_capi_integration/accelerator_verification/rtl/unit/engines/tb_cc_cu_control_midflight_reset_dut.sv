import GLOBALS_CU_PKG::*;
import WED_PKG::*;
import CU_PKG::*;

module cc_cu_control_midflight_reset_monitor #(
	parameter int GRAPH_CUS = 4
) (
	input logic clock,
	input logic rstn,
	input logic cu_done,
	input cu_return_type cu_return,
	input logic [GRAPH_CUS-1:0] enable_cu,
	input logic [GRAPH_CUS-1:0] request_cu,
	input logic dispatch_armed,
	input logic [0:63] configure_cu[0:GRAPH_CUS-1],
	input WEDInterface wed_cu[0:GRAPH_CUS-1],
	input ResponseBufferLine response_cu[0:GRAPH_CUS-1],
	input ReadWriteDataLine data_cu[0:GRAPH_CUS-1],
	input VertexInterface work_cu[0:GRAPH_CUS-1],
	input logic [0:(VERTEX_SIZE_BITS-1)] done_cu[0:GRAPH_CUS-1],
	input logic [3:0] lane_enable_0,
	input logic [3:0] lane_enable_1,
	input logic [3:0] lane_enable_2,
	input logic [3:0] lane_enable_3,
	input logic lane_work_0,
	input logic lane_work_1,
	input logic lane_work_2,
	input logic lane_work_3,
	input VertexInterface lane_job_0,
	input VertexInterface lane_job_1,
	input VertexInterface lane_job_2,
	input VertexInterface lane_job_3,
	input logic [0:(VERTEX_SIZE_BITS-1)] lane_done_0,
	input logic [0:(VERTEX_SIZE_BITS-1)] lane_done_1,
	input logic [0:(VERTEX_SIZE_BITS-1)] lane_done_2,
	input logic [0:(VERTEX_SIZE_BITS-1)] lane_done_3,
	input logic cluster0_job_latched,
	input logic cluster0_buffer_valid,
	input logic cluster0_arbiter_valid,
	input logic [3:0] cluster0_ready,
	input logic unit0_vertex_valid,
	input logic unit0_processing,
	input logic unit0_enabled_cmd,
	input logic unit0_wed_valid,
	input logic unit0_edge_command_valid,
	input logic unit0_data_command_valid,
	input logic unit0_command_arbiter_valid,
	input logic unit0_command_out_valid,
	input logic cluster0_read_valid,
	input logic cluster0_read_request,
	input logic cluster0_read_grant,
	input logic cluster0_arbiter_read_valid
);

	logic [GRAPH_CUS-1:0] previous_enable;
	logic [GRAPH_CUS-1:0] previous_wed;
	logic [GRAPH_CUS-1:0] previous_configure;
	int enable_count[0:GRAPH_CUS-1];
	int wed_count[0:GRAPH_CUS-1];
	int configure_count[0:GRAPH_CUS-1];
	int work_count[0:GRAPH_CUS-1];
	int response_count[0:GRAPH_CUS-1];
	int data_count[0:GRAPH_CUS-1];
	bit completion_seen;
	int i;
	int cycles;
	int total_work;
	int total_done;

	always @(posedge clock) begin
		if(!rstn) begin
			previous_enable <= 0;
			previous_wed <= 0;
			previous_configure <= 0;
			completion_seen <= 0;
			cycles <= 0;
			for (i = 0; i < GRAPH_CUS; i++) begin
				enable_count[i] <= 0;
				wed_count[i] <= 0;
				configure_count[i] <= 0;
				work_count[i] <= 0;
				response_count[i] <= 0;
				data_count[i] <= 0;
			end
		end else begin
			cycles <= cycles + 1;
			for (i = 0; i < GRAPH_CUS; i++) begin
				if(enable_cu[i] && !previous_enable[i])
					enable_count[i] <= enable_count[i] + 1;
				if(wed_cu[i].valid && !previous_wed[i])
					wed_count[i] <= wed_count[i] + 1;
				if((|configure_cu[i]) && !previous_configure[i])
					configure_count[i] <= configure_count[i] + 1;
				if(work_cu[i].valid)
					work_count[i] <= work_count[i] + 1;
				if(response_cu[i].valid)
					response_count[i] <= response_count[i] + 1;
				if(data_cu[i].valid)
					data_count[i] <= data_count[i] + 1;
				previous_enable[i] <= enable_cu[i];
				previous_wed[i] <= wed_cu[i].valid;
				previous_configure[i] <= |configure_cu[i];
			end
			if(cu_done)
				completion_seen <= 1;
			if((cycles % 4000) == 0)
				$display(
					"AG_CC_TOP_TRACE cycle=%0d enable=%b request=%b armed=%0d wed=%0d%0d%0d%0d config=%0d,%0d,%0d,%0d lanes=%b,%b,%b,%b work=%b lane_work=%0d%0d%0d%0d work_count=%0d,%0d,%0d,%0d responses=%0d,%0d,%0d,%0d data=%0d,%0d,%0d,%0d done=%0d,%0d,%0d,%0d lane_done=%0d,%0d,%0d,%0d",
					cycles, enable_cu, request_cu, dispatch_armed,
					wed_cu[3].valid, wed_cu[2].valid,
					wed_cu[1].valid, wed_cu[0].valid,
					configure_cu[0][32:63], configure_cu[1][32:63],
					configure_cu[2][32:63], configure_cu[3][32:63],
					lane_enable_0, lane_enable_1,
					lane_enable_2, lane_enable_3,
					{work_cu[3].valid, work_cu[2].valid,
						work_cu[1].valid, work_cu[0].valid},
					lane_work_3, lane_work_2, lane_work_1, lane_work_0,
					work_count[0], work_count[1], work_count[2], work_count[3],
					response_count[0], response_count[1],
					response_count[2], response_count[3],
					data_count[0], data_count[1], data_count[2], data_count[3],
					done_cu[0], done_cu[1], done_cu[2], done_cu[3],
					lane_done_0, lane_done_1, lane_done_2, lane_done_3);
		end
	end

	final begin
		total_work = 0;
		total_done = 0;
		for (i = 0; i < GRAPH_CUS; i++) begin
			$display(
				"AG_CC_TOP_CU:%0d enabled=%0d enable=%0d wed=%0d config=%0d work=%0d done=%0d",
				i, enable_cu[i], enable_count[i], wed_count[i], configure_count[i],
				work_count[i], done_cu[i]);
			// the relaunch asks for the whole topology, so every cluster of the
			// top is enabled and is re-armed exactly once by the reset
			if(!enable_cu[i])
				$fatal(1,
					"ASSERT CC real top cluster %0d was not enabled by the relaunch",
					i);
			if(enable_count[i] != 1)
				$fatal(1,
					"ASSERT CC real top cluster %0d enable edges expected=1 actual=%0d",
					i, enable_count[i]);
			if(wed_count[i] != 1)
				$fatal(1,
					"ASSERT CC real top cluster %0d WED edges expected=1 actual=%0d",
					i, wed_count[i]);
			if(configure_count[i] != 1)
				$fatal(1,
					"ASSERT CC real top cluster %0d config edges expected=1 actual=%0d",
					i, configure_count[i]);
			// every vertex a cluster accepts is retired by that cluster: a
			// dropped job and a job counted twice are both caught here
			if(done_cu[i] != work_count[i])
				$fatal(1,
					"ASSERT CC real top cluster %0d retired=%0d for dispatched=%0d",
					i, done_cu[i], work_count[i]);
			total_work = total_work + work_count[i];
			total_done = total_done + done_cu[i];
		end
		$display("AG_CC_TOP_TOTAL work=%0d done=%0d return=%0d",
			total_work, total_done, cu_return.var1);
		// the fixture of the relaunch has no filtered vertex, so every vertex of
		// the graph is dispatched to a cluster and retired by it
		if(total_work != GRAPH_CUS)
			$fatal(1,
				"ASSERT CC real top dispatched %0d vertices expected=%0d",
				total_work, GRAPH_CUS);
		if(total_done != GRAPH_CUS)
			$fatal(1,
				"ASSERT CC real top retired %0d vertices expected=%0d",
				total_done, GRAPH_CUS);
		if(!completion_seen || (cu_return.var1 != GRAPH_CUS))
			$fatal(1,
				"ASSERT CC real top completion seen=%0d return=%0d expected=%0d",
				completion_seen, cu_return.var1, GRAPH_CUS);
		$display("AG_BIN:cc_cu_control_midflight_reset_relaunch_all");
	end

endmodule

bind graph_integration_tb cc_cu_control_midflight_reset_monitor #(
	.GRAPH_CUS(NUM_GRAPH_CU_GLOBAL)
) cc_cu_control_midflight_reset_monitor_instant (
	.clock       (clock                             ),
	.rstn        (rstn                              ),
	.cu_done     (cu_done                           ),
	.cu_return   (cu_return                         ),
	.enable_cu   (dut.enable_cu_out                 ),
	.request_cu  (dut.vertex_job_request_cu_in      ),
	.dispatch_armed(
		dut.cu_vertex_cluster_arbiter_control_instant.vertex_dispatch_armed),
	.configure_cu(dut.cu_configure_out              ),
	.wed_cu      (dut.cu_wed_request_out            ),
	.response_cu (dut.read_response_cu_out          ),
	.data_cu     (dut.read_data_0_cu_out            ),
	.work_cu     (dut.vertex_job_cu_out             ),
	.done_cu     (dut.vertex_job_counter_done_cu_in )
	,
	.lane_enable_0(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.enable_cu),
	.lane_enable_1(
		dut.generate_vertex_cluster[1].cu_vertex_cluster_control_instant.enable_cu),
	.lane_enable_2(
		dut.generate_vertex_cluster[2].cu_vertex_cluster_control_instant.enable_cu),
	.lane_enable_3(
		dut.generate_vertex_cluster[3].cu_vertex_cluster_control_instant.enable_cu),
	.lane_work_0(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.vertex_job_cu[0].valid),
	.lane_work_1(
		dut.generate_vertex_cluster[1].cu_vertex_cluster_control_instant.vertex_job_cu[0].valid),
	.lane_work_2(
		dut.generate_vertex_cluster[2].cu_vertex_cluster_control_instant.vertex_job_cu[0].valid),
	.lane_work_3(
		dut.generate_vertex_cluster[3].cu_vertex_cluster_control_instant.vertex_job_cu[0].valid),
	.lane_job_0(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.vertex_job_cu[0]),
	.lane_job_1(
		dut.generate_vertex_cluster[1].cu_vertex_cluster_control_instant.vertex_job_cu[0]),
	.lane_job_2(
		dut.generate_vertex_cluster[2].cu_vertex_cluster_control_instant.vertex_job_cu[0]),
	.lane_job_3(
		dut.generate_vertex_cluster[3].cu_vertex_cluster_control_instant.vertex_job_cu[0]),
	.lane_done_0(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.vertex_num_counter_cu[0]),
	.lane_done_1(
		dut.generate_vertex_cluster[1].cu_vertex_cluster_control_instant.vertex_num_counter_cu[0]),
	.lane_done_2(
		dut.generate_vertex_cluster[2].cu_vertex_cluster_control_instant.vertex_num_counter_cu[0]),
	.lane_done_3(
		dut.generate_vertex_cluster[3].cu_vertex_cluster_control_instant.vertex_num_counter_cu[0]),
	.cluster0_job_latched(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.cu_vertex_connectedComponents_arbiter_control_instant.vertex_job_latched.valid),
	.cluster0_buffer_valid(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.cu_vertex_connectedComponents_arbiter_control_instant.vertex_job_buffer_out.valid),
	.cluster0_arbiter_valid(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.cu_vertex_connectedComponents_arbiter_control_instant.vertex_job_arbiter_in.valid),
	.cluster0_ready(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.cu_vertex_connectedComponents_arbiter_control_instant.ready_vertex_job_cu),
	.unit0_vertex_valid(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.generate_connectedComponents_cu[0].cu_vertex_connectedComponents_instant.vertex_job_latched.valid),
	.unit0_processing(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.generate_connectedComponents_cu[0].cu_vertex_connectedComponents_instant.processing_vertex),
	.unit0_enabled_cmd(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.generate_connectedComponents_cu[0].cu_vertex_connectedComponents_instant.enabled_cmd),
	.unit0_wed_valid(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.generate_connectedComponents_cu[0].cu_vertex_connectedComponents_instant.wed_request_in_latched.valid),
	.unit0_edge_command_valid(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.generate_connectedComponents_cu[0].cu_vertex_connectedComponents_instant.read_command_edge_job_buffer.valid),
	.unit0_data_command_valid(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.generate_connectedComponents_cu[0].cu_vertex_connectedComponents_instant.read_command_edge_data_buffer.valid),
	.unit0_command_arbiter_valid(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.generate_connectedComponents_cu[0].cu_vertex_connectedComponents_instant.command_arbiter_out.valid),
	.unit0_command_out_valid(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.generate_connectedComponents_cu[0].cu_vertex_connectedComponents_instant.read_command_out.valid),
	.cluster0_read_valid(
		dut.read_command_out_cu_in[0].valid),
	.cluster0_read_request(
		dut.read_command_bus_request_cu_in[0]),
	.cluster0_read_grant(
		dut.read_command_bus_grant_cu_out[0]),
	.cluster0_arbiter_read_valid(
		dut.generate_vertex_cluster[0].cu_vertex_cluster_control_instant.cu_vertex_connectedComponents_arbiter_control_instant.read_command_out_arbiter_latched.valid)
);
