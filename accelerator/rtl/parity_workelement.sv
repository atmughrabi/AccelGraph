import CAPI_PKG::*;
import CU_PKG::*;

module parity_workelement (
  input logic clock,
  input logic enabled,
  input logic reset,
  input pointer_t wed,
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
  longint unsigned offset;

 

  assign command_out.abt = 0,
         command_out.context_handle = 0,
         buffer_out.read_latency = 1,
         buffer_out.read_parity = ~^buffer_out.read_data;
         // command_out.command_parity = ~^command_out.command,
         // command_out.address_parity = ~^command_out.address,
         // command_out.tag_parity = ~^command_out.tag,
         
         // parity_data = stripe1_data ^ stripe2_data;


  always_ff @ (posedge clock) begin
    if (reset) begin
      current_state <= AFU_IDLE;
    end else begin
      current_state <= next_state;
    end // end else if (enabled)

  end // always_ff @ (posedge clock)

   always_comb begin 
    next_state = XX;

    case(current_state)
        AFU_IDLE: begin

          command_out.valid = 0;

          if (enabled) begin
            next_state = WED_REQ;
          end else begin
            next_state = current_state;
          end
        end

        WED_REQ: begin
          command_out.command = READ_CL_NA;
          command_out.command_parity = ~^command_out.command;

          command_out.tag = WED_TAG;
          command_out.tag_parity = ~^command_out.tag;

          command_out.size = 32;
          command_out.address = wed;
          command_out.address_parity = ~^command_out.address;
          command_out.valid = 1;
          next_state = WAITING_FOR_REQUEST;
          offset = 0;
        end

        WAITING_FOR_REQUEST: begin
          command_out.valid = 0;

          if (buffer_in.write_valid &&
              buffer_in.write_tag == WED_TAG &&
              buffer_in.write_address == 0) begin
            request.size = swap_endianness(buffer_in.write_data[0:63]);
            request.stripe1 = swap_endianness(buffer_in.write_data[64:127]);
            request.stripe2 = swap_endianness(buffer_in.write_data[128:191]);
            request.parity = swap_endianness(buffer_in.write_data[192:255]);
          end

          if (response.valid && response.tag == WED_TAG) begin
            next_state = REQUEST_STRIPES1;
          end
        end

        REQUEST_STRIPES1: begin
          command_out.valid = 1;
          command_out.size = 128;

          command_out.command = READ_CL_NA;
          command_out.command_parity = ~^command_out.command;

          command_out.tag = STRIPE1_READ;
          command_out.tag_parity = ~^command_out.tag;

          command_out.address = request.stripe1 + offset;
          command_out.address_parity = ~^command_out.address;
          next_state = REQUEST_STRIPES2;
           
        end

         REQUEST_STRIPES2: begin
          command_out.valid = 1;
          command_out.size = 128;
          command_out.command = READ_CL_NA;
          command_out.command_parity = ~^command_out.command;
         
          command_out.tag = STRIPE2_READ;
          command_out.tag_parity = ~^command_out.tag;

          command_out.address = request.stripe2 + offset;
          command_out.address_parity = ~^command_out.address;
          next_state = WAITING_FOR_STRIPES;
        
        end
    

        WAITING_FOR_STRIPES: begin

          command_out.valid = 0;

          if (buffer_in.write_valid) begin
            case(buffer_in.write_tag)
              STRIPE1_READ: begin
                if (buffer_in.write_address == 0) begin
                  stripe1_data[0:511] = buffer_in.write_data;
                end else begin
                  stripe1_data[512:1023] = buffer_in.write_data;
                end
              end

              STRIPE2_READ: begin
                if (buffer_in.write_address == 0) begin
                  stripe2_data[0:511] = buffer_in.write_data;
                end else begin
                  stripe2_data[512:1023] = buffer_in.write_data;
                end
              end
            endcase
          end


          if (response.valid) begin
            if (response.tag == STRIPE1_READ) begin
              stripe_received1 = 1;
            end
            if (response.tag == STRIPE2_READ) begin
                stripe_received2 = 1;
            end
            if (stripe_received1 && stripe_received2) begin
                next_state = WRITE_REQ;
            end
          end // if (response.valid)
        end

        WRITE_REQ: begin

          if (command_out.tag != PARITY_WRITE) begin

          command_out.command = WRITE_NA;
          command_out.command_parity = ~^command_out.command;

          command_out.address = request.parity + offset;
          command_out.address_parity = ~^command_out.address;

          command_out.tag = PARITY_WRITE;
          command_out.tag_parity = ~^command_out.tag;

          command_out.valid = 1;
          
          next_state = WRITE_DATA;
          end

        end // WRITE_REQ:

        WRITE_DATA: begin

            command_out.valid = 0;
            // Read half depending on address
            if (buffer_in.read_address == 0)  begin
              write_buffer = parity_data[0:511];
            end else begin
              write_buffer = parity_data[512:1023];
            end


            // Handle response
            if (response.valid &&
                response.tag == PARITY_WRITE) begin
                if (offset + 128 < request.size) begin
                  offset = offset + 128;
                  next_state = REQUEST_STRIPES1;
                end else begin
                  next_state = DONE_REQ;
                end
            end
        
          
        end

        DONE_REQ: begin

          command_out.valid = 0;
          if (command_out.tag != DONE_WRITE) begin

            command_out.tag = DONE_WRITE;
            command_out.tag_parity = ~^command_out.tag;
            command_out.size = 1;
            command_out.address = wed + 32;
            command_out.address_parity = ~^command_out.address;
            command_out.valid = 1;
            write_buffer[256:263] = 1;
            next_state = FINAL; 
          end 

          // if (response.valid &&
          //     response.tag == DONE_WRITE) begin
          //  next_state = FINAL; 
          // end

        end

        FINAL: begin

             command_out.valid = 0;
            // next_state = AFU_IDLE; 

        end // DONE:
      endcase
  end

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
