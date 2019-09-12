import CAPI_PKG::*;
import CREDIT_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module command_buffer_arbiter #(parameter NUM_REQUESTS = 4) (
  input logic clock,    // Clock
  input logic rstn,
  input logic enabled,
  input CommandBufferArbiterInterfaceIn command_arbiter_in,
  input CommandBufferLine read_command_buffer_in,
  input CommandBufferLine write_command_buffer_in,
  input CommandBufferLine wed_command_buffer_in,
  input CommandBufferLine restart_command_buffer_in,
  output CommandBufferArbiterInterfaceOut command_arbiter_out
);



////////////////////////////////////////////////////////////////////////////
//requests
////////////////////////////////////////////////////////////////////////////

  logic [NUM_REQUESTS-1:0] requests;
  logic [NUM_REQUESTS-1:0] grant;

  assign requests[0] = command_arbiter_in.restart_request;
  assign requests[1] = command_arbiter_in.wed_request;
  assign requests[2] = command_arbiter_in.write_request;
  assign requests[3] = command_arbiter_in.read_request;


//------------------------------------------------------------------------
// vc_FixedArb
//------------------------------------------------------------------------
// reqs[0] has the highest priority, reqs[1] has the second highest
// priority, etc.

  vc_FixedArb #(
    .p_num_reqs(NUM_REQUESTS)
  )fixed_arbiter_instance(
    .reqs(requests),
    .grants(grant)
  );

/////////////////////////////////////
// ready the winner if any

  always @(posedge clock or negedge rstn) begin
    if (~rstn) begin
      command_arbiter_out.command_buffer_out.valid    <= 1'b0;
      command_arbiter_out.command_buffer_out.command  <= INVALID; // just zero it out
      command_arbiter_out.command_buffer_out.address  <= 64'h0000_0000_0000_0000;
      command_arbiter_out.command_buffer_out.size     <= 12'h000;
      command_arbiter_out.command_buffer_out.cmd.cu_id     <= 0;
      command_arbiter_out.command_buffer_out.cmd.cmd_type  <= CMD_INVALID;
      command_arbiter_out.command_buffer_out.cmd.vertex_struct  <= STRUCT_INVALID;
    end
    else begin
      if (enabled) begin
        if (grant[1]) begin
          command_arbiter_out.command_buffer_out.valid   <= wed_command_buffer_in.valid;
          command_arbiter_out.command_buffer_out.cmd.cu_id     <= wed_command_buffer_in.cmd.cu_id;
          command_arbiter_out.command_buffer_out.cmd.cmd_type  <= wed_command_buffer_in.cmd.cmd_type;
          command_arbiter_out.command_buffer_out.cmd.vertex_struct  <= wed_command_buffer_in.cmd.vertex_struct;
          command_arbiter_out.command_buffer_out.command <= wed_command_buffer_in.command ;
          command_arbiter_out.command_buffer_out.address <= wed_command_buffer_in.address ;
          command_arbiter_out.command_buffer_out.size    <= wed_command_buffer_in.size;
        end
        else if (grant[2]) begin
          command_arbiter_out.command_buffer_out.valid   <= write_command_buffer_in.valid;
          command_arbiter_out.command_buffer_out.cmd.cu_id     <= write_command_buffer_in.cmd.cu_id;
          command_arbiter_out.command_buffer_out.cmd.cmd_type  <= write_command_buffer_in.cmd.cmd_type;
          command_arbiter_out.command_buffer_out.cmd.vertex_struct  <= write_command_buffer_in.cmd.vertex_struct;
          command_arbiter_out.command_buffer_out.command <= write_command_buffer_in.command ;
          command_arbiter_out.command_buffer_out.address <= write_command_buffer_in.address ;
          command_arbiter_out.command_buffer_out.size    <= write_command_buffer_in.size;
        end
        else if (grant[3]) begin
          command_arbiter_out.command_buffer_out.valid   <= read_command_buffer_in.valid;
          command_arbiter_out.command_buffer_out.cmd.cu_id     <= read_command_buffer_in.cmd.cu_id;
          command_arbiter_out.command_buffer_out.cmd.cmd_type  <= read_command_buffer_in.cmd.cmd_type;
          command_arbiter_out.command_buffer_out.cmd.vertex_struct  <= read_command_buffer_in.cmd.vertex_struct;
          command_arbiter_out.command_buffer_out.command <= read_command_buffer_in.command ;
          command_arbiter_out.command_buffer_out.address <= read_command_buffer_in.address ;
          command_arbiter_out.command_buffer_out.size    <= read_command_buffer_in.size;
        end
        else if (grant[0]) begin
          command_arbiter_out.command_buffer_out.valid   <= restart_command_buffer_in.valid;
          command_arbiter_out.command_buffer_out.cmd.cu_id     <= restart_command_buffer_in.cmd.cu_id;
          command_arbiter_out.command_buffer_out.cmd.cmd_type  <= restart_command_buffer_in.cmd.cmd_type;
          command_arbiter_out.command_buffer_out.cmd.vertex_struct  <= restart_command_buffer_in.cmd.vertex_struct;
          command_arbiter_out.command_buffer_out.command <= restart_command_buffer_in.command ;
          command_arbiter_out.command_buffer_out.address <= restart_command_buffer_in.address ;
          command_arbiter_out.command_buffer_out.size    <= restart_command_buffer_in.size;
        end
        else begin
          command_arbiter_out.command_buffer_out.valid    <= 1'b0;
          command_arbiter_out.command_buffer_out.cmd.cu_id     <= 0;
          command_arbiter_out.command_buffer_out.cmd.cmd_type  <= CMD_INVALID;
          command_arbiter_out.command_buffer_out.cmd.vertex_struct  <= STRUCT_INVALID;
          command_arbiter_out.command_buffer_out.command  <= INVALID; // for debugging purposes
          command_arbiter_out.command_buffer_out.address  <= 64'h0000_0000_0000_0000;
          command_arbiter_out.command_buffer_out.size     <= 12'h000;
        end
      end
      else begin
        command_arbiter_out.command_buffer_out.valid    <= 1'b0;
        command_arbiter_out.command_buffer_out.cmd.cu_id     <= 0;
        command_arbiter_out.command_buffer_out.cmd.cmd_type  <= CMD_INVALID;
        command_arbiter_out.command_buffer_out.cmd.vertex_struct  <= STRUCT_INVALID;
        command_arbiter_out.command_buffer_out.command  <= INVALID; // for debugging purposes
        command_arbiter_out.command_buffer_out.address  <= 64'h0000_0000_0000_0000;
        command_arbiter_out.command_buffer_out.size     <= 12'h000;
      end
    end
  end

  assign command_arbiter_out.wed_ready     = grant[1] & enabled;
  assign command_arbiter_out.write_ready   = grant[2] & enabled;
  assign command_arbiter_out.read_ready    = grant[3] & enabled;
  assign command_arbiter_out.restart_ready = grant[0] & enabled;

endmodule
