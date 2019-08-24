
import CAPI_PKG::*;

module error_control (
  input logic clock,    // Clock
  input logic rstn,
  input logic enabled,
  input logic [0:63] external_errors,
  input logic report_errors_ack,
  output logic reset_error,
  output logic [0:63]  report_errors
);

typedef enum int unsigned {
  ERROR_RESET,
  ERROR_IDLE,
  MMIO_REQ,
  WAIT_MMIO_REQ,
  RESET_REQ
} error_state;

error_state current_state, next_state;

always_ff @(posedge clock or negedge rstn) begin
	if(~rstn)
		current_state <= ERROR_RESET;
	else
		current_state <= next_state;
end // always_ff @(posedge clock)

always_comb begin
	next_state = ERROR_IDLE;
	case (current_state)
		ERROR_RESET: begin
		next_state = ERROR_IDLE;
		end 
		ERROR_IDLE: begin
			if(|external_errors)
				next_state = MMIO_REQ;
			else
				next_state = ERROR_IDLE;
		end 
		MMIO_REQ: begin
			if(report_errors_ack)
				next_state = RESET_REQ;
			else
				next_state = MMIO_REQ;
		end 		
		RESET_REQ: begin
			next_state = ERROR_RESET;			
		end 
	endcase
end 

always_ff @(posedge clock) begin
	case (current_state)
        ERROR_RESET: begin
        	report_errors <= external_errors;
        	reset_error	  <= 1'b1;
		end 
		ERROR_IDLE: begin
			report_errors <= external_errors;
        	reset_error	  <= 1'b1;
		end 
		MMIO_REQ: begin
			
		end 		
		RESET_REQ: begin
			reset_error	  <= 1'b0;
		end 
	endcase
end


endmodule