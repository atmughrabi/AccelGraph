// -----------------------------------------------------------------------------
//
//    "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : ram.sv
// Create : 2019-09-26 15:24:35
// Revise : 2019-09-26 15:24:35
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

module ram #(
  parameter WIDTH     = 64,
  parameter DEPTH     = 32,
  parameter ADDR_BITS = $clog2(DEPTH)
) (
  input  logic                  clock,
  input  logic                  we,
  input  logic [0:ADDR_BITS-1]  wr_addr,
  input  logic [0:WIDTH-1]      data_in,
  input  logic [0:ADDR_BITS-1]  rd_addr,
  output logic [0:WIDTH-1]      data_out
);
  logic [0:WIDTH-1] memory [0:DEPTH-1];

  always @ (posedge clock) begin
    if (we)
      memory[wr_addr] <= data_in;
  end

  always @ (posedge clock) begin
    data_out          <= memory[rd_addr];
  end
endmodule





module ram_2xrd #(
  parameter WIDTH     = 64,
  parameter DEPTH     = 32,
  parameter ADDR_BITS = $clog2(DEPTH)
) (
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

// Quartus Prime SystemVerilog Template
// 
// Mixed-width RAM with separate read and write addresses and data widths
// that are controlled by the parameters RW and WW.  RW and WW must specify a
// read/write ratio supported by the memory blocks in your target device.
// Otherwise, Quartus Prime will not infer a RAM.

module mixed_width_ram
  #(parameter int
    WORDS             = 256,
    RW                = 8,
    WW                = 32)
(
  input we, 
  input clock,
  input [0:$clog2((RW < WW) ? WORDS : (WORDS * RW)/WW) - 1] wr_addr, 
  input [0:WW-1] data_in, 
  input [0:$clog2((RW < WW) ? (WORDS * WW)/RW : WORDS) - 1] rd_addr, 
  output logic [0:RW-1] data_out
);
   
  // Use a multi-dimensional packed array to model the different read/write
  // width
  localparam int R    = (RW < WW) ? WW/RW : RW/WW;
  localparam int B    = (RW < WW) ? RW: WW;

  logic [0:R-1][0:B-1] ram[0:WORDS-1];

  generate if(RW < WW) begin
    // Smaller read?
    always_ff@(posedge clock)
    begin
      if(we) ram[wr_addr] <= data_in;
      data_out        <= ram[rd_addr / R][rd_addr % R];
    end
  end
  else begin 
    // Smaller write?
    always_ff@(posedge clock)
    begin
      if(we) ram[wr_addr / R][wr_addr % R] <= data_in;
      data_out        <= ram[rd_addr];
    end
  end 
  endgenerate
   
endmodule : mixed_width_ram