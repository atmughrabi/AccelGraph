package CAPI_PKG;
  typedef longint unsigned pointer_t;

  typedef enum byte {
    RESET=8'h80,
    START=8'h90
  } job_command_t;

  typedef enum bit [0:12] {
    // Cache-directed commands
    READ_CL_S=13'h0A50,
    READ_CL_M=13'h0A60,
    READ_CL_LCK=13'h0A6B,
    READ_CL_RES=13'h0A67,
    TOUCH_I=13'h0240,
    TOUCH_S=13'h0250,
    TOUCH_M=13'h0260,
    WRITE_MI=13'h0D60,
    WRITE_MS=13'h0D70,
    WRITE_UNLOCK=13'h0D6B,
    WRITE_C=13'h0D67,
    PUSH_I=13'h0140,
    PUSH_S=13'h0150,
    EVICT_I=13'h1140,
    LOCK=13'h016B,
    UNLOCK=13'h017B,
    // Commands that don't allocate in PSL cache
    READ_CL_NA=13'h0A00,
    READ_PNA=13'h0E00,
    WRITE_NA=13'h0D00,
    WRITE_INJ=13'h0D10,
    // Management commands
    FLUSH=13'h0100,
    INTREQ=13'h0000,
    RESTART=13'h0001
  } afu_command_t;

  typedef struct packed {
    bit valid;
    job_command_t command;
    bit command_parity;
    pointer_t address;
    bit address_parity;
  } JobInterfaceInput;

  typedef struct packed {
    bit running;
    bit done;
    bit cack;
    pointer_t error;
    bit yield;
  } JobInterfaceOutput;

  typedef struct packed {
    byte unsigned room;
  } CommandInterfaceInput;

  typedef struct packed {
    bit valid;
    byte tag;
    bit tag_parity;
    afu_command_t command;
    bit command_parity;
    bit [0:2] abt;
    pointer_t address;
    bit address_parity;
    bit [0:15] context_handle;
    bit [0:11] size;
  } CommandInterfaceOutput;

  typedef struct packed {
    bit read_valid;
    byte read_tag;
    bit read_tag_parity;
    bit [0:5] read_address;
    bit write_valid;
    byte write_tag;
    bit write_tag_parity;
    bit [0:5] write_address;
    bit [0:511] write_data;
    byte write_parity;
  } BufferInterfaceInput;

  typedef struct packed {
    bit [0:3] read_latency;
    bit [0:511] read_data;
    byte read_parity;
  } BufferInterfaceOutput;

  typedef struct packed {
    bit valid;
    byte tag;
    bit tag_parity;
    byte response;
    bit [0:8] credits;
    bit [0:1] cache_state;
    bit [0:12] cache_pos;
  } ResponseInterface;

  typedef struct packed {
    bit valid;
    bit cfg;
    bit read;
    bit doubleword;
    bit [0:23] address;
    bit address_parity;
    bit [0:63] data;
    bit data_parity;
  } MMIOInterfaceInput;

  typedef struct packed {
    bit ack;
    bit [0:63] data;
    bit data_parity;
  } MMIOInterfaceOutput;

  typedef struct packed {
    bit [0:15] num_ints_per_process;
    bit [0:15] num_of_processes;
    bit [0:15] num_of_afu_crs;
    bit [0:15] req_prog_model;
    bit [0:199] reserved_1;
    bit [0:55] afu_cr_len;
    bit [0:63] afu_cr_offset;
    bit [0:5] reserved_2;
    bit psa_per_process_required;
    bit psa_required;
    bit [0:55] psa_length;
    bit [0:63] psa_offset;
    bit [0:7] reserved_3;
    bit [0:55] afu_eb_len;
    bit [0:63] afu_eb_offset;
  } AFUDescriptor;

  function bit [0:63] read_afu_descriptor(AFUDescriptor descriptor,
                                          bit [0:23] address);
    case(address)
      'h0: begin
        return {descriptor.num_ints_per_process,
                descriptor.num_of_processes,
                descriptor.num_of_afu_crs,
                descriptor.req_prog_model};
      end
      default: begin
        return 0;
      end
    endcase
  endfunction


  function logic [0:63] swap_endianness(logic [0:63] in);
  return {in[56:63], in[48:55], in[40:47], in[32:39], in[24:31], in[16:23],
          in[8:15], in[0:7]};
  endfunction

endpackage
