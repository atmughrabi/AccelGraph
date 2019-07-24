module parity #(
  parameter BITS = 1
)(
	input logic clock,    // Clock
  	input logic [0:BITS-1] data,
  	input logic odd,
  	output logic par
);

assign par = ^{data, odd};

endmodule
