module ram #(
  parameter WIDTH = 64,
  parameter DEPTH = 32,
  parameter ADDR_BITS = $clog2(DEPTH)
)(
  input  logic                  clock,
  input  logic                  we,
  input  logic [0:ADDR_BITS-1]  wr_addr,
  input  logic [0:WIDTH-1]      data_in,
  input  logic [0:ADDR_BITS-1]  rd_addr,
  output logic [0:WIDTH-1]      data_out  
);

  logic [0:WIDTH-1] out;
  logic [0:WIDTH-1] memory [0:DEPTH-1];

  always @ (posedge clock) begin
    if (we)
      memory[wr_addr] <= data_in;
  end

  always @ (posedge clock) begin
    data_out <= memory[rd_addr];
  end
endmodule
