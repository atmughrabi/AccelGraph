module parity #(
  parameter BITS = 1
)(
  input  [0:BITS-1] data,
  input             odd,
  output            parity
);

  assign parity = ^{data, odd};

endmodule
