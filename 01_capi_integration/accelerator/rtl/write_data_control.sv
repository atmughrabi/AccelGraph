import CAPI_PKG::*;
import AFU_PKG::*;

module write_data_control (
  input logic clock,    // Clock
  input logic rstn,
  input logic enabled,
  input WriteDataControlInterface buffer_in,
  input logic command_write_valid,
  input logic [0:7] command_tag_in,
  input ReadWriteDataLine write_data_0_in,
  input ReadWriteDataLine write_data_1_in,
  output logic data_write_error,
  output BufferInterfaceOutput buffer_out
);

  logic odd_parity;
  logic tag_parity;
  logic tag_parity_link;

  logic enable_errors;
  logic detected_errors;
  logic tag_parity_error;

  logic command_write_valid_latched;
  ReadWriteDataLine write_data_0_in_latched;
  ReadWriteDataLine write_data_1_in_latched;

  ReadWriteDataLine write_data_0_out;
  ReadWriteDataLine write_data_1_out;
// ReadWriteDataLine write_data;

  logic read_valid;           // ha_brvalid,     // Buffer Read valid
  logic [0:7] read_tag;       // ha_brtag,       // Buffer Read tag
  logic [0:5] read_address;   // ha_brad,        // Buffer Read address

  assign buffer_out.read_latency = 4'h1;
  assign odd_parity              = 1'b1; // Odd parity
  assign enable_errors           = 1'b1; // enable errors

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      command_write_valid_latched <= 0;
      write_data_0_in_latched  <= 0;
      write_data_1_in_latched  <= 0;
    end else begin
      command_write_valid_latched <= command_write_valid;
      write_data_0_in_latched   <= write_data_0_in;
      write_data_1_in_latched   <= write_data_1_in;
    end
  end

////////////////////////////////////////////////////////////////////////////
//Read Buffer data tag requests
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      read_valid <= 0;
      read_tag  <= 0;
      read_address   <= 0;
    end else begin
      if(buffer_in.read_valid && enabled) begin
        read_valid     <= buffer_in.read_valid;
        read_tag       <= buffer_in.read_tag;
        read_address   <= buffer_in.read_address;
      end else begin
        read_valid <= 0;
        read_tag  <= 0;
        read_address<= 0;
      end
    end
  end

////////////////////////////////////////////////////////////////////////////
//Read Buffer out data parity check
////////////////////////////////////////////////////////////////////////////

  dw_parity #(
    .DOUBLE_WORDS(8)
  ) write_data_parity_instant (
    .data(buffer_out.read_data),
    .odd(odd_parity),
    .par(buffer_out.read_parity)
  );

////////////////////////////////////////////////////////////////////////////
//partity check Logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity  <= odd_parity;
    end else begin
      if(enabled && buffer_in.read_valid) begin
        tag_parity  <= buffer_in.read_tag_parity;
      end else begin
        tag_parity  <= odd_parity;
      end
    end
  end

  parity #(
    .BITS(8)
  ) write_tag_parity_instant (
    .data(read_tag),
    .odd(odd_parity),
    .par(tag_parity_link)
  );

////////////////////////////////////////////////////////////////////////////
//Ram Data each hold half cache line
////////////////////////////////////////////////////////////////////////////
// uncoment for latency 4 cycles
// always_ff @(posedge clock or negedge rstn) begin
//  if(~rstn)
//         write_data<=  ~0;
//     else if(~(|read_address) && read_valid)
//    write_data <= write_data_0_out.data;
//  else if((|read_address) && read_valid)
//    write_data <= write_data_1_out.data;
//  else
//    write_data <=  ~0;
// end

// always_ff @(posedge clock) begin
//    buffer_out.read_data <=  write_data;
// end


  always_comb begin
    if(~(|read_address) && read_valid)
      buffer_out.read_data  = write_data_0_out.data;
    else if((|read_address) && read_valid)
      buffer_out.read_data  = write_data_1_out.data;
    else
      buffer_out.read_data  =  ~0;
  end

  ram #(
    .WIDTH($bits(ReadWriteDataLine)),
    .DEPTH( 256 )
  )write_data_0_ram_instant
  (
    .clock( clock ),
    .we( command_write_valid_latched ),
    .wr_addr( command_tag_in ),
    .data_in( write_data_0_in_latched ),

    .rd_addr( buffer_in.read_tag ),
    .data_out( write_data_0_out )
  );


  ram #(
    .WIDTH($bits(ReadWriteDataLine)),
    .DEPTH( 256 )
  )write_data_1_ram_instant
  (
    .clock( clock ),
    .we( command_write_valid_latched ),
    .wr_addr( command_tag_in ),
    .data_in( write_data_1_in_latched ),

    .rd_addr( buffer_in.read_tag ),
    .data_out( write_data_1_out )
  );

////////////////////////////////////////////////////////////////////////////
// Error Logic
////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity_error    <= 1'b0;
      detected_errors     <= 1'b0;
    end else begin
      tag_parity_error    <= tag_parity_link ^ tag_parity;
      detected_errors     <= {tag_parity_error};
    end
  end

  always_ff @(posedge clock) begin
    if(enable_errors) begin
      data_write_error  <= detected_errors;
    end else  begin
      data_write_error  <= 1'b0;
    end
  end


endmodule