import CAPI_PKG::*;
import COMMAND_PKG::*;

module tag_control (
  input logic clock,    // Clock
  input logic rstn,
  input logic enabled,

  input logic tag_response_valid,
  input logic [0:7] response_tag,
  output CommandTagLine response_tag_id,

  input logic [0:7] data_read_tag,
  output CommandTagLine data_read_tag_id,

  input logic tag_command_valid,
  input CommandTagLine tag__command_id,
  output logic [0:7] command_tag,

  output BufferStatus tag_buffer,
  output logic tag_buffer_ready
);

typedef enum int unsigned {
  TAG_BUFFER_RESET,
  TAG_BUFFER_INIT,
  TAG_BUFFER_READY
} tag_buffer_state;

// reset state machine 
// reset signal
// start state empty tag fifo
// push tags to fifo till full
// ready signal tag fifo is not empty and full 

////////////////////////////////////////////////////////////////////////////
// Tag Initialization Flush logic.
////////////////////////////////////////////////////////////////////////////
// if tag fifo is ready and not empty you can send tags other wise command buffer need to stall. 

tag_buffer_state current_state, next_state;
CommandTagLine tag_ram_read;
CommandTagLine tag_ram_write;


logic tag_buffer_push;
logic [0:7] tag_fifo_input;

logic [0:7] tag_counter_valid;
logic [0:7] tag_counter;


logic tag_buffer_pop;



logic tag_init_flag;



always_ff @(posedge clock or negedge rstn) begin
	if(~rstn)
		current_state <= TAG_BUFFER_RESET;
	else
		current_state <= next_state;
end // always_ff @(posedge clock)


always_comb begin
	next_state = TAG_BUFFER_RESET;
	case (current_state)
		TAG_BUFFER_RESET: begin
			next_state = TAG_BUFFER_INIT;
		end 
		TAG_BUFFER_INIT: begin
			if(tag_buffer.full)
				next_state = TAG_BUFFER_READY;
		end
		TAG_BUFFER_READY: begin
			next_state = TAG_BUFFER_READY;
		end 
	endcase
end 

always_ff @(posedge clock) begin
	case (current_state)
        TAG_BUFFER_RESET: begin
        	tag_counter 	 <= 8'b0;
        	tag_buffer_ready <= 1'b0;
        	tag_init_flag	 <= 1'b1;
        	tag_counter_valid<= 1'b0;
		end 
		TAG_BUFFER_INIT: begin
			tag_counter 	   	 <= tag_counter + 1'b1;
      		tag_counter_valid    <= 1'b1;
		end
		TAG_BUFFER_READY: begin
			tag_counter 	  <= 8'b0;
        	tag_buffer_ready  <= 1'b1;
        	tag_init_flag	  <= 1'b0;
        	tag_counter_valid <= 1'b0;
		end 
	endcase
end


always_comb begin
	if(tag_init_flag) begin
		tag_buffer_push = tag_counter_valid;
		tag_fifo_input 	= tag_counter;
	end else begin
		tag_buffer_push = tag_response_valid;
		tag_fifo_input  = response_tag;
	end
end

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
    .we(tag_command_valid),
    .wr_addr(tag_fifo_input),
    .data_in( tag__command_id ),
  
    .rd_addr1( response_tag ),
    .data_out1( response_tag_id ),

    .rd_addr2( data_read_tag ),
    .data_out2( data_read_tag_id )
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

	.push(tag_buffer_push),
	.data_in(tag_fifo_input),
	.full(tag_buffer.full),
	.alFull(tag_buffer.alfull),

	.pop(wed_buffer_pop),
	.valid(tag_buffer.valid),
	.data_out(wed_response_out),
	.empty(tag_buffer.empty)
	);

endmodule