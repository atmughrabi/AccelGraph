import CAPI_PKG::*;
import WED_PKG::*;

module wed_control (
  
  input logic clock,
  input logic enabled,
  input logic rstn,
  input logic [0:63] wed_address,
  input BufferInterfaceInput buffer_in,
  input ResponseInterface response,
  output CommandInterfaceOutput command_out,
  output WEDInterfaceOutput wed_request_out
);

	wed_state current_state, next_state;
	WED_request wed_request;
  logic [0:63] offset;
 

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
				if(enabled && ~wed_request_out.valid)
						next_state = WED_REQ;
				else
						next_state = WED_IDLE;
			end // WED_IDLE
			WED_REQ: begin
						next_state = WED_WAITING_FOR_REQUEST;
			end // WED_REQ
			WED_WAITING_FOR_REQUEST: begin
				 if (response.valid && response.tag == WED_TAG && response.response == DONE) begin
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

  assign command_out.command_parity  = ~^command_out.command;
  assign command_out.address_parity  = ~^command_out.address;
  assign command_out.tag_parity      = ~^command_out.tag;
  assign command_out.abt             = STRICT;
  assign command_out.context_handle  = 16'h00;

	always_ff @(posedge clock) begin
			case (current_state)
        WED_RESET: begin
          command_out.valid    <= 0;
          command_out.command  <= RESTART; // just zero it out
          command_out.address  <= 0;
          command_out.tag      <= WED_TAG;
          command_out.size     <= 0;

          wed_request.size      <= 0;
          wed_request.stripe1   <= 0;
          wed_request.stripe2   <= 0;
          wed_request.parity    <= 0;

          wed_request_out.wed   <= 0;
          wed_request_out.valid <= 0;
        end // WED_RESET:
				WED_IDLE: begin
          command_out.valid     <= 0;
					wed_request.size 		  <= 0;
      		wed_request.stripe1 	<= 0;
      		wed_request.stripe2 	<= 0;
      		wed_request.parity 		<= 0;
				end // WED_IDLE:
				WED_REQ: begin
		      command_out.command <= READ_CL_NA;
          command_out.tag 		<= WED_TAG;
          command_out.size 		<= 32;
          command_out.address <= wed_address;
          command_out.valid 	<= 1;
          offset 				      <= 0;
          wed_request.address <= wed_address;
        end // WED_REQ
        WED_WAITING_FOR_REQUEST: begin
            command_out.valid   <= 0;
      	  	if (buffer_in.write_valid &&
         	  	 	buffer_in.write_tag == WED_TAG &&
          	 		buffer_in.write_address == 0) begin
     					  wed_request.size 	  <= swap_endianness(buffer_in.write_data[0:63]);
        				wed_request.stripe1 <= swap_endianness(buffer_in.write_data[64:127]);
        				wed_request.stripe2 <= swap_endianness(buffer_in.write_data[128:191]);
        				wed_request.parity 	<= swap_endianness(buffer_in.write_data[192:255]);
      			end
        end // WED_WAITING_FOR_REQUEST
        WED_DONE_REQ: begin
           wed_request_out.wed   <= wed_request;
           wed_request_out.valid <= 1'b1;
        end // WED_WAITING_FOR_REQUEST
			endcase // next_state
	end // always_ff @(posedge clock)

endmodule