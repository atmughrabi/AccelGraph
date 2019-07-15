import CAPI_PKG::*;

module mmio (
  input logic clock,
  input MMIOInterfaceInput mmio_in,
  output MMIOInterfaceOutput mmio_out);

  logic ack;
  logic [0:63] data;
  AFUDescriptor afu_desc;

  // Set our AFU Descriptor values refer to page 
  assign afu_desc.num_ints_per_process = 0,
         afu_desc.num_of_processes = 1,
         afu_desc.num_of_afu_crs = 0,
         afu_desc.req_prog_model = 16'h8010, // dedicated process
         afu_desc.reserved_1 = 0,
         afu_desc.afu_cr_len = 0,
         afu_desc.afu_cr_offset = 0,
         afu_desc.reserved_2 = 0,
         afu_desc.psa_per_process_required = 0,
         afu_desc.psa_required = 0,
         afu_desc.psa_length = 0,
         afu_desc.psa_offset = 0,
         afu_desc.reserved_3 = 0,
         afu_desc.afu_eb_len = 0,
         afu_desc.afu_eb_offset = 0;

  // Set parity bit for MMIO output
  assign mmio_out.data_parity = ~^mmio_out.data;

  always_ff @(posedge clock) begin
    if(mmio_in.valid) begin
      if(mmio_in.cfg) begin
        if(mmio_in.read) begin
          mmio_out.ack <= 1;
          mmio_out.data <= read_afu_descriptor(afu_desc, mmio_in.address);
        end
      end
    end else begin
      mmio_out.ack <= 0;
      mmio_out.data <= 0;
    end
  end

endmodule
