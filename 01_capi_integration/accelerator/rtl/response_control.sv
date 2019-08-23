import CAPI_PKG::*;
import CREDIT_PKG::*;
import COMMAND_PKG::*;
import CREDIT_PKG::*;

module response_control (
	input logic clock,    // Clock
	input logic rstn, 	
	input logic enabled, 
  	input ResponseInterface response,
  	output ResponseControlInterfaceOut response_control_out
);


logic odd_parity;
logic tag_parity;
logic tag_parity_link;
ResponseInterface response_in;

logic enable_errors;
logic [0:6] detected_errors;
logic [0:5] cmd_response_error;
logic tag_parity_error;

assign odd_parity = 1'b1; // Odd parity
assign enable_errors    = 1'b1; // enable errors


////////////////////////////////////////////////////////////////////////////
//input latching Logic
////////////////////////////////////////////////////////////////////////////

always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
        response_in <= 0;
    end else if(enabled && response.valid) begin
        response_in  <= response;
        response_in.tag  		<= 2'b11;
    	response_in.response  	<= AERROR;
    end else begin
    	response_in  <= 0;
    end
end

////////////////////////////////////////////////////////////////////////////
//Response Buffer switch Logic
////////////////////////////////////////////////////////////////////////////

always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
        response_control_out <= 0;
    end else if(enabled && response_in.valid) begin
        if(response_in.tag == WED_TAG) begin
    		response_control_out.wed_response 		<= response_in.valid;
    		response_control_out.response.valid  	<= response_in.valid;
    		response_control_out.response.tag  		<= response_in.tag;
    		response_control_out.response.response  <= response_in.response;
		end 
		else if(response_in.tag == RESTART_TAG) begin
			response_control_out.restart_response   <= response_in.valid;
			response_control_out.response.valid  	<= response_in.valid;
    		response_control_out.response.tag  		<= response_in.tag;
    		response_control_out.response.response  <= response_in.response;
		end 
		else if(response_in.tag >= WRITE_TAG_BASE 	&& response_in.tag < READ_TAG_BASE) begin // write tag ranges
			response_control_out.write_response  	<= response_in.valid;
			response_control_out.response.valid  	<= response_in.valid;
    		response_control_out.response.tag  		<= response_in.tag;
    		response_control_out.response.response  <= response_in.response;
		end 
		else if(response_in.tag >= READ_TAG_BASE	&& response_in.tag <= TAG_UPPER) begin // read tag ranges
			response_control_out.read_response 		<= response_in.valid;
			response_control_out.response.valid  	<= response_in.valid;
    		response_control_out.response.tag  		<= response_in.tag;
    		response_control_out.response.response  <= response_in.response;
		end else begin
			response_control_out  <= 0;
		end 

    end else begin
    	response_control_out  <= 0;
    end
  end

////////////////////////////////////////////////////////////////////////////
//partity check Logic
////////////////////////////////////////////////////////////////////////////
 always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
        tag_parity  <= odd_parity;
    end else if(enabled && response.valid) begin
        tag_parity  <= response.tag_parity;
    end else begin
        tag_parity  <= odd_parity;
    end
  end

 parity #(
    .BITS(8)
  ) response_tag_parity_instant (
    .data(response_in.tag),
    .odd(odd_parity),
    .par(tag_parity_link)
  );

////////////////////////////////////////////////////////////////////////////
// Error Logic
////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity_error    <= 1'b0;
      cmd_response_error  <= 6'h00;
      detected_errors     <= 7'h00;
    end else begin
      tag_parity_error   	<= tag_parity_link ^ tag_parity;
      cmd_response_error 	<= cmd_response_error_type(response_in.response);
      detected_errors    	<= {tag_parity_error, cmd_response_error};
    end
  end

  always_ff @(posedge clock) begin
    if(enable_errors) begin
      response_control_out.response_error  <= detected_errors;
    end else  begin
      response_control_out.response_error  <= 7'h00;
    end
  end



endmodule