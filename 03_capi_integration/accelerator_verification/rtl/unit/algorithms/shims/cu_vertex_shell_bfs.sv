// Thin verification shim: exposes cu_vertex_bfs under a single name so one
// algorithm-shell testbench covers every algorithm shell module.

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_shell_dut #(
	parameter CU_ID_X      = 1,
	parameter CU_ID_Y      = 1,
	parameter NUM_REQUESTS = 2
) (
	input  logic                          clock                      ,
	input  logic                          rstn_in                    ,
	input  logic                          enabled_in                 ,
	input  WEDInterface                   wed_request_in             ,
	input  logic [                  0:63] cu_configure               ,
	input  ResponseBufferLine             read_response_in           ,
	input  ResponseBufferLine             write_response_in          ,
	input  logic                          read_command_bus_grant     ,
	output logic                          read_command_bus_request   ,
	input  logic                          edge_data_write_bus_grant  ,
	output logic                          edge_data_write_bus_request,
	input  ReadWriteDataLine              read_data_0_in             ,
	input  ReadWriteDataLine              read_data_1_in             ,
	input  EdgeDataRead                   edge_data_read_in          ,
	input  BufferStatus                   read_buffer_status         ,
	output CommandBufferLine              read_command_out           ,
	input  BufferStatus                   write_buffer_status        ,
	output EdgeDataWrite                  edge_data_write_out        ,
	input  VertexInterface                vertex_job                 ,
	output logic                          vertex_job_request         ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter         ,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_num_counter
);

	cu_vertex_bfs #(
		.CU_ID_X     (CU_ID_X     ),
		.CU_ID_Y     (CU_ID_Y     ),
		.NUM_REQUESTS(NUM_REQUESTS)
	) cu_vertex_shell_instant (
		.clock                      (clock                      ),
		.rstn_in                    (rstn_in                    ),
		.enabled_in                 (enabled_in                 ),
		.wed_request_in             (wed_request_in             ),
		.cu_configure               (cu_configure               ),
		.read_response_in           (read_response_in           ),
		.write_response_in          (write_response_in          ),
		.read_command_bus_grant     (read_command_bus_grant     ),
		.read_command_bus_request   (read_command_bus_request   ),
		.edge_data_write_bus_grant  (edge_data_write_bus_grant  ),
		.edge_data_write_bus_request(edge_data_write_bus_request),
		.read_data_0_in             (read_data_0_in             ),
		.read_data_1_in             (read_data_1_in             ),
		.edge_data_read_in          (edge_data_read_in          ),
		.read_buffer_status         (read_buffer_status         ),
		.read_command_out           (read_command_out           ),
		.write_buffer_status        (write_buffer_status        ),
		.edge_data_write_out        (edge_data_write_out        ),
		.vertex_job                 (vertex_job                 ),
		.vertex_job_request         (vertex_job_request         ),
		.vertex_num_counter         (vertex_num_counter         ),
		.edge_num_counter           (edge_num_counter           )
	);

endmodule
