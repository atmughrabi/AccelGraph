module parity #(parameter BITS = 1) (
  input logic [0:BITS-1] data,
  input logic odd,
  output logic par
);

  assign par = ^{data, odd};

endmodule



module dw_parity #(parameter DOUBLE_WORDS = 1) (
  input logic [0:64*DOUBLE_WORDS-1] data,
  input logic                       odd,
  output logic [0:DOUBLE_WORDS-1]   par
);

  genvar i;
  generate
    for (i = 0; i < DOUBLE_WORDS; i = i + 1) begin: block
      assign par[i] = ^{data[64*i +: 64], odd};
    end
  endgenerate

endmodule