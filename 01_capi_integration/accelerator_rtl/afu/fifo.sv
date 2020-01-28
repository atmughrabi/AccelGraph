// -----------------------------------------------------------------------------
//
//      "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Gregory Walter https://github.com/gsw73/sync_fifo_0.git
// File   : fifo.sv
// Create : 2019-09-26 15:21:09
// Revise : 2019-09-26 15:21:09
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

module fifo #(
    parameter WIDTH     = 32,
    parameter DEPTH     = 32,
    parameter ADDR_BITS = $clog2(DEPTH),
    parameter HEADROOM  = ((DEPTH > 16)?16:3)
) (
    input logic clock,
    input logic rstn,
    input logic push,
    input logic [ WIDTH - 1:0 ] data_in,
    output logic full,
    output logic alFull,
    input logic pop,
    output logic valid,
    output logic [ WIDTH - 1:0 ] data_out,
    output logic empty
);

// =======================================================================
// Declarations & Parameters

    localparam CW       = ADDR_BITS + 1;

    logic [ CW - 1:0 ] count;
    logic [ WIDTH - 1:0 ] rd_data;
    logic [ WIDTH - 1:0 ] wr_data;
    logic wen;
    logic wen_q;
    logic ren;
    logic [ ADDR_BITS - 1:0 ] wr_addr;
    logic [ ADDR_BITS - 1:0 ] rd_addr;
    logic [ ADDR_BITS - 1:0 ] rd_addr_q;
    logic [ ADDR_BITS - 1:0 ] rd_addr_c;

// =======================================================================
// Combinational Logic

// only pop a non-empty FIFO... note that user may assert pop without regard
// to empty.  Data will be should be sampled only when pop and !empty are
// asserted together i.e., pop && valid
    assign ren          = pop && !empty;

    // assign data_out  = rd_data;
    always_comb begin 
        if(ren)
            data_out    = rd_data;
        else
            data_out    = 0;
    end

// user samples data when pop && valid are both true... user drives pop, FIFO
// logic determines valid here
    assign valid        = !empty;

// the combinational version of the read address is used to immediately
// change the address into memory on a pop since there's a one-cycle delay
// to get the data out
    assign rd_addr_c    = rd_addr_q + 'd1;

// this is the signal into memory; the mux ensures that the next read
// data is available on the next cycle
    assign rd_addr      = ren ? rd_addr_c : rd_addr_q;

// =======================================================================
// Registered Logic

// Register:  wen
//
// Only push data into a non-full FIFO to avoid corrupting data already
// in FIFO.  User must, however, avoid pushing data into an emtpy FIFO
// using the almost full signal, alFull

    always @( posedge clock or negedge rstn)

        if ( !rstn )
            wen         <= 1'b0;

        else
            wen         <= push && !full;

// Register:  wr_data
//
// push and data input are registered before going into memory for timing.

    always @( posedge clock or negedge rstn)

        if ( !rstn )
            wr_data     <= {WIDTH{1'b0}};

        else
            wr_data     <= data_in;

// Register:  wen_q
//
// Use a delayed version of write enable for count calculations to ensure
// data is really in memory and it is, therefore, not popped out too early.

    always @( posedge clock or negedge rstn)

        if ( !rstn )
            wen_q       <= 1'b0;

        else
            wen_q       <= wen;

// Register: count
//
// Track number of elements in the FIFO.

    always @( posedge clock or negedge rstn)

        if ( !rstn )
            count       <= {CW{1'b0}};

        else if ( wen_q && ~ren )
            count       <= count + 'd1;

        else if ( ~wen_q && ren )
            count       <= count - 'd1;

// Register: empty
//
// Empty on the next clock when no elements and no write or one element
// and no write but a read.

    always @( posedge clock or negedge rstn)

        if ( !rstn )
            empty       <= 1'b1;

        else if ( count == 'd0 && ~wen_q ||
            count == 'd1 && ~wen_q && ren )
        empty           <= 1'b1;

        else
            empty       <= 1'b0;

// Register: alFull
//
// External logic should use alFull to determine when to stop pushing into
// the FIFO.

    always @( posedge clock or negedge rstn)

        if ( !rstn )
            alFull      <= 1'b0;

        else if ( count >= DEPTH - HEADROOM )
            alFull      <= 1'b1;

        else
            alFull      <= 1'b0;

// Register: full
//
// FIFO goes full if it's already full and there's no read or if it's one less
// than full and there's a write and no read.

    always @( posedge clock or negedge rstn)

        if ( !rstn )
            full        <= 1'b0;

        else if ( count == DEPTH && ~ren ||
            count == DEPTH - 1 && wen_q && ~ren )
        full            <= 1'b1;

        else
            full        <= 1'b0;

// Register:  wr_addr
//
// Write address into memory.

    always @( posedge clock or negedge rstn)

        if ( !rstn )
            wr_addr     <= {ADDR_BITS{1'b0}};

        else if ( wen )
            wr_addr     <= wr_addr + 'd1;

// Register:  red_addr
//
// Since there's a one-clock read latency through memory, this signal is muxed
// with the combination version.  When the data is popped from the FIFO, the
// address has to change in the same clock cycle to ensure the new data is
// available on the next clock cycle.

    always @( posedge clock or negedge rstn)

        if ( !rstn )
            rd_addr_q   <= {ADDR_BITS{1'b0}};

        else if ( ren )
            rd_addr_q   <= rd_addr_c;

// =======================================================================
// Module Instantiations
    ram #(
        .WIDTH( WIDTH ),
        .DEPTH( DEPTH ),
        .ADDR_BITS( ADDR_BITS )
    )ram_instant
    (
        .clock( clock ),
        .we( wen ),
        .wr_addr( wr_addr ),
        .data_in( wr_data ),

        .rd_addr( rd_addr ),
        .data_out( rd_data )
    );

endmodule