module shift_register #(parameter WIDTH = 1) (
  input logic clock,
  input logic [0:WIDTH-1] in,
  output logic [0:WIDTH-1] out
  );

  logic [0:WIDTH-1] stage1;
  logic [0:WIDTH-1] stage2;

  always_ff @ (posedge clock) begin
    // stage1 	<= in;
    // stage2	<= stage1;
    // out 	<= stage2;
      out <= in;
  end
endmodule
