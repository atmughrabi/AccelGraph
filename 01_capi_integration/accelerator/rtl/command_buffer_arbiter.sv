import CAPI_PKG::*;
import CREDIT_PKG::*;
import COMMAND_PKG::*;


module command_buffer_arbiter #(
  parameter NUM_REQUESTS = 4
)(
	input logic clock,    // Clock
	input logic rstn,
  input logic ready,
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

 logic [0:NUM_REQUESTS-1] requests;
 logic [0:NUM_REQUESTS-1] grant;

 assign requests = {command_arbiter_in.wed_request,1'b0,1'b0,1'b0};
 
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
    command_arbiter_out.command_buffer_out <= 0;
    command_arbiter_out.valid <= 1'b0;
    command_arbiter_out.wed_ready <= 1'b0;
    command_arbiter_out.write_ready <= 1'b0;
    command_arbiter_out.read_ready <= 1'b0;
    command_arbiter_out.restart_ready <= 1'b0;
  end
  else begin
    if (ready) begin
      if (grant ==   4'b1000) begin
        command_arbiter_out.valid <= 1'b1;
        command_arbiter_out.wed_ready <= 1'b1;
        command_arbiter_out.command_buffer_out.tag <= wed_command_buffer_in.tag;
        command_arbiter_out.command_buffer_out.command <= wed_command_buffer_in.command ;
        command_arbiter_out.command_buffer_out.address <= wed_command_buffer_in.address ;
        command_arbiter_out.command_buffer_out.size <= wed_command_buffer_in.size;
      end
      else if (grant == 4'b0100) begin
        command_arbiter_out.valid <= 1'b1;
        command_arbiter_out.wed_ready <= 1'b1;
        command_arbiter_out.command_buffer_out.tag <= write_command_buffer_in.tag;
        command_arbiter_out.command_buffer_out.command <= write_command_buffer_in.command ;
        command_arbiter_out.command_buffer_out.address <= write_command_buffer_in.address ;
        command_arbiter_out.command_buffer_out.size <= write_command_buffer_in.size;
      end
      else if (grant == 4'b0010) begin
        command_arbiter_out.valid <= 1'b1;
        command_arbiter_out.wed_ready <= 1'b1;
        command_arbiter_out.command_buffer_out.tag <= read_command_buffer_in.tag;
        command_arbiter_out.command_buffer_out.command <= read_command_buffer_in.command ;
        command_arbiter_out.command_buffer_out.address <= read_command_buffer_in.address ;
        command_arbiter_out.command_buffer_out.size <= read_command_buffer_in.size;
      end
      else if (grant == 4'b0001) begin
        command_arbiter_out.valid <= 1'b1;
        command_arbiter_out.wed_ready <= 1'b1;
        command_arbiter_out.command_buffer_out.tag <= restart_command_buffer_in.tag;
        command_arbiter_out.command_buffer_out.command <= restart_command_buffer_in.command ;
        command_arbiter_out.command_buffer_out.address <= restart_command_buffer_in.address ;
        command_arbiter_out.command_buffer_out.size <= restart_command_buffer_in.size;
      end   
      else begin
        command_arbiter_out.command_buffer_out <= 0;
        command_arbiter_out.valid <= 1'b0;
        command_arbiter_out.wed_ready <= 1'b0;
        command_arbiter_out.write_ready <= 1'b0;
        command_arbiter_out.read_ready <= 1'b0;
        command_arbiter_out.restart_ready <= 1'b0;
      end
    end
    else begin
      command_arbiter_out.command_buffer_out <= 0;
      command_arbiter_out.valid <= 1'b0;
      command_arbiter_out.wed_ready <= 1'b0;
      command_arbiter_out.write_ready <= 1'b0;
      command_arbiter_out.read_ready <= 1'b0;
      command_arbiter_out.restart_ready <= 1'b0;
    end
  end
end

endmodule