import CAPI_PKG::*;
import AFU_PKG::*;

module read_data_control (
  input logic clock,    // Clock
  input logic rstn,
  input logic enabled,
  input ReadDataControlInterface buffer_in,
  input CommandTagLine data_read_tag_id_in,
  output logic [0:1] data_read_error,
  output DataControlInterfaceOut read_data_control_out_0,
  output DataControlInterfaceOut read_data_control_out_1
);

  logic odd_parity;
  logic tag_parity;
  logic tag_parity_link;
  logic [0:7] data_write_parity_latched;
  logic write_valid_latched;
  logic [0:7] data_write_parity_link;
  logic [0:7] data_write_parity_link_s2;
  ReadDataControlInterface buffer_in_latched;

  logic enable_errors;
  logic [0:1] detected_errors;
  logic data_parity_error;
  logic data_parity_error_latched;
  logic tag_parity_error;


  assign odd_parity    = 1'b1; // Odd parity
  assign enable_errors = 1'b1; // enable errors

////////////////////////////////////////////////////////////////////////////
//input latching Logic
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      buffer_in_latched <= 0;
    end else begin
      if(enabled && buffer_in.write_valid) begin
        buffer_in_latched  <= buffer_in;
      end 
    end
  end


////////////////////////////////////////////////////////////////////////////
//Read Data Buffer switch Logic LSB
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      read_data_control_out_0 <= 0;
    end else begin
      if(enabled && buffer_in_latched.write_valid && ~(|buffer_in_latched.write_address)) begin

        case (data_read_tag_id_in.cmd_type)
          CMD_READ: begin
            read_data_control_out_0.read_data    <= 1'b1;
            read_data_control_out_0.wed_data     <= 1'b0;
          end
          CMD_WED: begin
            read_data_control_out_0.read_data    <= 1'b0;
            read_data_control_out_0.wed_data     <= 1'b1;
          end
          default : begin
            read_data_control_out_0.read_data    <= 1'b0;
            read_data_control_out_0.wed_data     <= 1'b0;
          end
        endcase

        read_data_control_out_0.line.valid              <= buffer_in_latched.write_valid;
        read_data_control_out_0.line.cmd                <= data_read_tag_id_in;
        read_data_control_out_0.line.data               <= buffer_in_latched.write_data;

      end else begin
        read_data_control_out_0  <= 0;
      end
    end
  end


////////////////////////////////////////////////////////////////////////////
//Read Data Buffer switch Logic MSB
////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      read_data_control_out_1 <= 0;
    end else begin
      if(enabled && buffer_in_latched.write_valid && (|buffer_in_latched.write_address)) begin

        case (data_read_tag_id_in.cmd_type)
          CMD_READ: begin
            read_data_control_out_1.read_data    <= 1'b1;
            read_data_control_out_1.wed_data     <= 1'b0;
          end
          CMD_WED: begin
            read_data_control_out_1.read_data    <= 1'b0;
            read_data_control_out_1.wed_data     <= 1'b1;
          end
          default : begin
            read_data_control_out_1.read_data    <= 1'b0;
            read_data_control_out_1.wed_data     <= 1'b0;
          end
        endcase

        read_data_control_out_1.line.valid              <= buffer_in_latched.write_valid;
        read_data_control_out_1.line.cmd                <= data_read_tag_id_in;
        read_data_control_out_1.line.data               <= buffer_in_latched.write_data;

      end else begin
        read_data_control_out_1  <= 0;
      end
    end
  end

////////////////////////////////////////////////////////////////////////////
//partity check Logic tag
////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity  <= odd_parity;
    end else begin
      if(buffer_in.write_valid) begin
        tag_parity  <= buffer_in.write_tag_parity;
      end 
    end
  end

  parity #(
    .BITS(8)
  ) write_tag_parity_instant (
    .data(buffer_in_latched.write_tag),
    .odd(odd_parity),
    .par(tag_parity_link)
  );

  
////////////////////////////////////////////////////////////////////////////
//partity check Logic Data
////////////////////////////////////////////////////////////////////////////

  always @ (posedge clock)
      write_valid_latched <= buffer_in.write_valid;

  always @ (posedge clock or negedge rstn) begin
    if (~rstn)
      data_write_parity_latched <= 8'hff;
    else  begin
      if (write_valid_latched)
        data_write_parity_latched <= buffer_in.write_parity;
    end
  end

  dw_parity #(
    .DOUBLE_WORDS(8)
  ) read_data_parity_instant (
    .data(buffer_in_latched.write_data),
    .odd(odd_parity),
    .par(data_write_parity_link)
  );

  always @ (posedge clock or negedge rstn) begin
    if (~rstn)
      data_write_parity_link_s2 <= 8'hff;
    else begin
      data_write_parity_link_s2 <= data_write_parity_link;
    end
  end

  assign data_parity_error_latched = |(data_write_parity_link_s2 ^ data_write_parity_latched);

////////////////////////////////////////////////////////////////////////////
// Error Logic
////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity_error    <= 1'b0;
      data_parity_error   <= 1'b0;
      detected_errors     <= 2'b00;
    end else begin
      tag_parity_error    <= tag_parity_link ^ tag_parity;

      data_parity_error   <= data_parity_error_latched;
    
      detected_errors     <= {tag_parity_error, data_parity_error};
    end
  end

  always_ff @(posedge clock) begin
    if(enable_errors) begin
      data_read_error  <= detected_errors;
    end else  begin
      data_read_error  <= 2'b00;
    end
  end



endmodule