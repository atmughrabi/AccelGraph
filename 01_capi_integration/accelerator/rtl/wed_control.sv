import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;


module wed_control (
  
  input logic clock,
  input logic enabled,
  input logic rstn,
  input logic [0:63] wed_address,
  input ReadWriteDataLine wed_data_0_in,
  input ReadWriteDataLine wed_data_1_in,
  input ResponseBufferLine wed_response_in,
  input BufferStatus command_buffer_status,
  output CommandBufferLine command_out,
  output WEDInterface wed_request_out
);

	wed_state current_state, next_state;
  logic [0:1023] wed_cacheline128;

  BufferInterfaceInput buffer_in_latched;
////////////////////////////////////////////////////////////////////////////
//latch the inputs from the PSL 
////////////////////////////////////////////////////////////////////////////
 
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= WED_RESET;
		else
			current_state <= next_state;
	end // always_ff @(posedge clock)

	always_comb begin
    next_state = current_state;
		case (current_state)
      WED_RESET: begin
          next_state = WED_IDLE;
      end // WED_RESET
			WED_IDLE: begin
				if(enabled && ~wed_request_out.valid && ~command_buffer_status.alfull)
						next_state = WED_REQ;
				else
						next_state = WED_IDLE;
			end // WED_IDLE
			WED_REQ: begin
						next_state = WED_WAITING_FOR_REQUEST;
			end // WED_REQ
			WED_WAITING_FOR_REQUEST: begin
				 if (wed_response_in.valid && wed_response_in.cu_id == WED_ID && wed_response_in.response == DONE) begin
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
          command_out.size     <= 12'h000;
          command_out.cu_id    <= INVALID_ID;
          command_out.cmd_type <= CMD_INVALID;

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
          command_out.address <= wed_address;
          command_out.cu_id    <= WED_ID;
          command_out.cmd_type <= CMD_WED;


          wed_request_out.address <= wed_address;
        end // WED_REQ
        WED_WAITING_FOR_REQUEST: begin
          command_out.valid   <= 0;
    	  	if (wed_data_0_in.cu_id == WED_ID) begin
              wed_cacheline128 [0:511]   <= wed_data_0_in.data;
    			end
          if (wed_data_1_in.cu_id == WED_ID) begin
              wed_cacheline128[512:1023] <= wed_data_1_in.data;
          end
        end // WED_WAITING_FOR_REQUEST
        WED_DONE_REQ: begin
           wed_request_out.valid <= 1'b1;
           wed_request_out.wed   <= map_to_WED(wed_cacheline128);
        end // WED_WAITING_FOR_REQUEST
			endcase // next_state
	end // always_ff @(posedge clock)

endmodule