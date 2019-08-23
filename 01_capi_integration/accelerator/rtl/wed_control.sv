import CAPI_PKG::*;
import WED_PKG::*;
import COMMAND_PKG::*;


module wed_control (
  
  input logic clock,
  input logic enabled,
  input logic rstn,
  input logic [0:63] wed_address,
  input BufferInterfaceInput buffer_in,
  input ResponseBufferLine response_in,
  input BufferStatus response_buffer,
  input BufferStatus wed_buffer,
  output CommandBufferLine command_out,
  output WEDInterface wed_request_out
);

	wed_state current_state, next_state;
  logic [0:1023] wed_cacheline128;
 
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= WED_RESET;
		else
			current_state <= next_state;
	end // always_ff @(posedge clock)

	always_comb begin
    next_state = WED_IDLE;
		case (current_state)
      WED_RESET: begin
          next_state = WED_IDLE;
      end // WED_RESET
			WED_IDLE: begin
				if(enabled && ~wed_request_out.valid && ~wed_buffer.full)
						next_state = WED_REQ;
				else
						next_state = WED_IDLE;
			end // WED_IDLE
			WED_REQ: begin
						next_state = WED_WAITING_FOR_REQUEST;
			end // WED_REQ
			WED_WAITING_FOR_REQUEST: begin
				 if (response_in.valid && response_in.tag == WED_TAG && response_in.response == DONE) begin
						next_state = WED_DONE_REQ;
				 end
				 else
				 		next_state = WED_WAITING_FOR_REQUEST;	
			end 
			WED_DONE_REQ: begin
				// if (command_out.tag != DONE_WRITE) begin
					next_state = WED_IDLE;
				// end
			end // WED_DONE_REQ	
		endcase
	end // always_comb

	always_ff @(posedge clock) begin
			case (current_state)
        WED_RESET: begin
          command_out.valid    <= 1'b0;
          command_out.command  <= INVALID; // just zero it out
          command_out.address  <= 64'h0000_0000_0000_0000;
          command_out.tag      <= INVALID_TAG;
          command_out.size     <= 12'h000;
        
          wed_cacheline128        <= 1024'h0;
          wed_request_out.wed     <= 512'h0;
          wed_request_out.valid   <= 1'b0;
          wed_request_out.address <= 64'h0000_0000_0000_0000;
        end // WED_RESET:
				WED_IDLE: begin
          command_out.valid       <= 1'b0;
				end // WED_IDLE:
				WED_REQ: begin
          command_out.valid   <= 1'b1;
          command_out.size    <= 12'h080;
		      command_out.command <= READ_CL_NA;
          command_out.tag 		<= WED_TAG;
          command_out.address <= wed_address;
          wed_request_out.address <= wed_address;
        end // WED_REQ
        WED_WAITING_FOR_REQUEST: begin
          command_out.valid   <= 0;
    	  	if (buffer_in.write_valid &&
       	  	 	buffer_in.write_tag == WED_TAG &&
        	 		buffer_in.write_address == 6'h00) begin;
              wed_cacheline128 [0:511] <= buffer_in.write_data;
    			end
          if (buffer_in.write_valid &&
              buffer_in.write_tag == WED_TAG &&
              buffer_in.write_address == 6'h01) begin 
              wed_cacheline128[512:1023] <= buffer_in.write_data;
          end
        end // WED_WAITING_FOR_REQUEST
        WED_DONE_REQ: begin
           wed_request_out.valid <= 1'b1;
           wed_request_out.wed   <= map_to_WED(wed_cacheline128);
        end // WED_WAITING_FOR_REQUEST
			endcase // next_state
	end // always_ff @(posedge clock)

endmodule