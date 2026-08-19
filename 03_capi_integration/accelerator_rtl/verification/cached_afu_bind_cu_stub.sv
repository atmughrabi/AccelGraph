import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;

module cu_control (
    input  logic              clock,
    input  logic              rstn_in,
    input  logic              enabled_in,
    input  WEDInterface       wed_request_in,
    input  ResponseBufferLine read_response_in,
    input  ResponseBufferLine prefetch_read_response_in,
    input  ResponseBufferLine prefetch_write_response_in,
    input  ResponseBufferLine write_response_in,
    input  ReadWriteDataLine  read_data_0_in,
    input  ReadWriteDataLine  read_data_1_in,
    input  BufferStatus       read_buffer_status,
    input  BufferStatus       prefetch_read_buffer_status,
    input  BufferStatus       prefetch_write_buffer_status,
    input  BufferStatus       write_buffer_status,
    input  cu_configure_type  cu_configure,
    output cu_return_type     cu_return,
    output logic              cu_done,
    output logic [0:63]       cu_status,
    output CommandBufferLine  read_command_out,
    output CommandBufferLine  prefetch_read_command_out,
    output CommandBufferLine  prefetch_write_command_out,
    output CommandBufferLine  write_command_out,
    output ReadWriteDataLine  write_data_0_out,
    output ReadWriteDataLine  write_data_1_out
);

    assign cu_return                  = 0;
    assign cu_done                    = 0;
    assign cu_status                  = 0;
    assign read_command_out           = 0;
    assign prefetch_read_command_out  = 0;
    assign prefetch_write_command_out = 0;
    assign write_command_out          = 0;
    assign write_data_0_out           = 0;
    assign write_data_1_out           = 0;

endmodule
