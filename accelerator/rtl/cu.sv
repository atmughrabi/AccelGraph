module cu #(parameter width = 1024) (
	input logic [0:width-1] stripe1_data,
	input logic [0:width-1] stripe2_data,
 	output logic [0:width-1] parity_data
	
);

assign parity_data = stripe1_data ^ stripe2_data;
 

endmodule