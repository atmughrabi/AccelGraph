import CAPI_PKG::*;
import CU_PKG::*;

module control (
  
  input logic clock,
  input logic enabled,
  input logic reset,
  input logic [0:63] wed,
  input BufferInterfaceInput buffer_in,
  input ResponseInterface response,
  output CommandInterfaceOutput command_out,
  output BufferInterfaceOutput buffer_out
	
);

	state current_state, next_state;

	parity_request request;
  	logic [0:1023] stripe1_data;
  	logic [0:1023] stripe2_data;
  	logic [0:1023] parity_data;
  	logic stripe_received1;
  	logic stripe_received2;
  	logic [0:511] write_buffer;
  	logic [0:63] offset;


  assign command_out.abt = 0,
         command_out.context_handle = 0,
         buffer_out.read_latency = 1;



	always_ff @(posedge clock) begin
		if(reset)
			current_state <= AFU_IDLE;
		else
			current_state <= next_state;
	end // always_ff @(posedge clock)


	always_comb begin
		next_state = XX; // debug value

		case (current_state)

			AFU_IDLE: begin
				if(enabled)
						next_state = WED_REQ;
				else
						next_state = AFU_IDLE;
			end // AFU_IDLE:
			WED_REQ: begin
						next_state = WAITING_FOR_REQUEST;
			end // WED_REQ:
			WAITING_FOR_REQUEST: begin
				 if (response.valid && response.tag == WED_TAG) begin
						next_state = REQUEST_STRIPES1;
				 end
				 else
				 		next_state = WAITING_FOR_REQUEST;	
			end // WAITING_FOR_REQUEST:
			REQUEST_STRIPES1: begin
						next_state = REQUEST_STRIPES2;
			end // REQUEST_STRIPES1:
			REQUEST_STRIPES2: begin
						next_state = WAITING_FOR_STRIPES;
			end // REQUEST_STRIPES2:
			WAITING_FOR_STRIPES: begin
				if (stripe_received1 && stripe_received2) begin
                		next_state = WRITE_REQ;
            	 end else
            	 		next_state = WAITING_FOR_STRIPES;

			end // WAITING_FOR_STRIPES:
			WRITE_REQ: begin
				// if (command_out.tag != PARITY_WRITE) begin
						next_state = WRITE_DATA;
				// end else
				// 		next_state = WRITE_REQ;
			end // WRITE_REQ:
			WRITE_DATA:begin
				if (response.valid &&
             	  	response.tag == PARITY_WRITE) begin

              	  			if (offset + 128 < request.size)
                				next_state = REQUEST_STRIPES1;
               	 			else 
                  				next_state = DONE_REQ;
               				
               	end else 
                  		next_state = WRITE_DATA;
               		
       	       
			end // WRITE_DATA:
			DONE_REQ: begin
				// if (command_out.tag != DONE_WRITE) begin
					next_state = FINAL;
				// end
			end // DONE_REQ:
		
			
		endcase

	end // always_comb


	always_ff @(posedge clock) begin
		if(reset) begin
			command_out.valid 			<= 0;
			buffer_out.read_parity 		<= 0;
			command_out.command_parity 	<= 0;
			command_out.address_parity 	<= 0;
			command_out.tag_parity 		<= 0;

		end // if(reset)
		else begin
			command_out.valid 			<= 0;
			buffer_out.read_parity 		<= ~^buffer_out.read_data;
			command_out.command_parity 	<= ~^command_out.command;
			command_out.address_parity 	<= ~^command_out.address;
			command_out.tag_parity 	 	<= ~^command_out.tag;
			// stripe_received1 			<= 0;
			// stripe_received2 			<= 0;

			case (current_state)
				AFU_IDLE: begin
					write_buffer 		<= 0;
					request.size 		<= 0;
            		request.stripe1 	<= 0;
            		request.stripe2 	<= 0;
            		request.parity 		<= 0;
            		stripe_received1 	<= 0;
            		stripe_received2 	<= 0;
				end // AFU_IDLE:
				WED_REQ: begin
		          command_out.command <= READ_CL_NA;
		          command_out.tag 		<= WED_TAG;
		          command_out.size 		<= 32;
		          command_out.address 	<= wed;
		          command_out.valid 	<= 1;
		          offset 				<= 0;
		        end
		        WAITING_FOR_REQUEST: begin
		      	  	if (buffer_in.write_valid &&
             	  	 	buffer_in.write_tag == WED_TAG &&
              	 		buffer_in.write_address == 0) begin
         					  request.size 	  <= swap_endianness(buffer_in.write_data[0:63]);
            				request.stripe1 <= swap_endianness(buffer_in.write_data[64:127]);
            				request.stripe2 <= swap_endianness(buffer_in.write_data[128:191]);
            				request.parity 	<= swap_endianness(buffer_in.write_data[192:255]);
          			end
		        end // WAITING_FOR_REQUEST:        
        		REQUEST_STRIPES1: begin
          			command_out.valid 	<= 1;
          			command_out.size 	<= 128;
          			command_out.command <= READ_CL_S;
          			command_out.tag 	<= STRIPE1_READ;
       				command_out.address <= request.stripe1 + offset;
       				stripe_received1 	<= 0;

        		end // REQUEST_STRIPES1:
        		REQUEST_STRIPES2: begin
          			command_out.valid 	<= 1;
          			command_out.size 	<= 128;
          			command_out.command <= READ_CL_S;
          			command_out.tag 	<= STRIPE2_READ;
       				command_out.address <= request.stripe2 + offset;  
       				stripe_received2 	<= 0;

        		end // REQUEST_STRIPES1:
        		WAITING_FOR_STRIPES: begin
        			if (buffer_in.write_valid) begin
            			case(buffer_in.write_tag)
              				STRIPE1_READ: begin
                				if (buffer_in.write_address == 0) begin
                  					stripe1_data[0:511] 	<= buffer_in.write_data;
                				end else begin
                  					stripe1_data[512:1023]	<= buffer_in.write_data;
                				end
              				end

              				STRIPE2_READ: begin
                				if (buffer_in.write_address == 0) begin
                  					stripe2_data[0:511]		<= buffer_in.write_data;
                				end else begin
                  					stripe2_data[512:1023] 	<= buffer_in.write_data;
                				end
              				end
            			endcase
          			end

          			if (response.valid) begin
          				if (response.tag == STRIPE1_READ) begin
             				stripe_received1 <= 1;
           				end
           				if (response.tag == STRIPE2_READ) begin
              				stripe_received2 <= 1;
          				end
        			end
        		end // WAITING_FOR_STRIPES:
        		WRITE_REQ: begin
         				if (command_out.tag != PARITY_WRITE) begin
        				  	command_out.command <= WRITE_MS;
          					command_out.address <= request.parity + offset;
         					command_out.tag 	<= PARITY_WRITE;
          					command_out.valid 	<= 1;
         				 end
       			 end // WRITE_REQ:
       			WRITE_DATA: begin
		         	if (buffer_in.read_address == 0)  begin
		              write_buffer <= parity_data[0:511];
		        	end else begin
		              write_buffer <= parity_data[512:1023];
		            end
            		// Handle response
         	  		if (response.valid &&
             	  		response.tag == PARITY_WRITE) begin
              	  			if (offset + 128 < request.size) begin
               	   				offset <= offset + 128;	
               				end
       	        	end
        
          		end
          		DONE_REQ: begin
          			 // if (command_out.tag != DONE_WRITE) begin
        			    command_out.tag 		<= DONE_WRITE;
            			command_out.size 		<= 1;
            			command_out.address 	<= wed + 32;
            			command_out.valid 		<= 1;
            			write_buffer[256:263] 	<= 1;    
          			// end 
          		end // DONE_REQ: 	

			endcase // next_state

		end // else


	end // always_ff @(posedge clock)


cu #(1024 ) cu_parity(
    .stripe1_data(stripe1_data),
    .stripe2_data(stripe2_data),
    .parity_data (parity_data)
    );

shift_register #(512) write_shift (
    .clock(clock),
    .in(write_buffer),
    .out(buffer_out.read_data));  




endmodule