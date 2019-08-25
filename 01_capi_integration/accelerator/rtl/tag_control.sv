import CAPI_PKG::*;

module tag_control (
  input logic clock,    // Clock
  input logic rstn,
  input logic enabled,

  input response tag
  output response ID

  input read data tag
  output response ID

  input  wr_write data tag
  output wr_cachelinedata

  input  rd_write data tag
  output rd_cachelinedata

  input CommandTagLine
  output command tag
 
);

// reset state machine 
// reset signal
// start state empty tag fifo
// push tags to fifo till full
// ready signal tag fifo is not empty and full 

// if tag fifo is ready and not empty you can send tags other wise command buffer need to stall. 


////////////////////////////////////////////////////////////////////////////
// Tag -> CU bookeeping for response/read buffer interface
////////////////////////////////////////////////////////////////////////////

// we keep each tag associated with the command type and CU ID so we send the response to the right compute unite

ram_2xrd #(
    .WIDTH($bits(CommandTagLine)),
    .DEPTH(256)
)tag_ram_instant
(
    .clock( clock ),
    .we( wen ),
    .wr_addr( wr_addr ),
    .data_in( wr_data ),
  
    .rd_addr1( rd_addr1 ),
    .data_out1( rd_data1 ),

    .rd_addr2( rd_addr2 ),
    .data_out2( rd_data2 )
);

////////////////////////////////////////////////////////////////////////////
// Tag fifo
////////////////////////////////////////////////////////////////////////////

// The PSL porvided 256 tags so we keem them in a fifo structure as a ticket to be issued and returned

fifo  #(
    .WIDTH(8),
    .DEPTH(256)
    )tag_buffer_fifo_instant(
	.clock(clock),
	.rstn(rstn),

	.push(response_control_out.wed_response),
	.data_in(response_control_out.response),
	.full(response_buffer_status.wed_buffer.full),
	.alFull(response_buffer_status.wed_buffer.alfull),

	.pop(wed_buffer_pop),
	.valid(response_buffer_status.wed_buffer.valid),
	.data_out(wed_response_out),
	.empty(response_buffer_status.wed_buffer.empty)
	);

endmodule