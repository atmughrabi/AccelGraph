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





module ram_2xrd #(
  parameter WIDTH = 64,
  parameter DEPTH = 32,
  parameter ADDR_BITS = $clog2(DEPTH)
)(
  input  logic                  clock,
  input  logic                  we,
  input  logic [0:ADDR_BITS-1]  wr_addr,
  input  logic [0:WIDTH-1]      data_in,
  input  logic [0:ADDR_BITS-1]  rd_addr1,
  output logic [0:WIDTH-1]      data_out1,
  input  logic [0:ADDR_BITS-1]  rd_addr2,
  output logic [0:WIDTH-1]      data_out2 
);

ram #(
    .WIDTH( WIDTH ),
    .DEPTH( DEPTH )
)ram1_instant
(
    .clock( clock ),
    .we( we ),
    .wr_addr( wr_addr ),
    .data_in( data_in ),
  
    .rd_addr( rd_addr1 ),
    .data_out( data_out1 )
);


ram #(
    .WIDTH( WIDTH ),
    .DEPTH( DEPTH )
)ram2_instant
(
    .clock( clock ),
    .we( we ),
    .wr_addr( wr_addr ),
    .data_in( data_in ),
  
    .rd_addr( rd_addr2 ),
    .data_out( data_out2 )
);

endmodule