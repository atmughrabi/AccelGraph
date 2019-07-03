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
    bit valid;              // ha_jval,        // Job valid
    job_command_t command;  // ha_jcom,        // Job command
    bit command_parity;     // ha_jcompar,     // Job command parity
    pointer_t address;      // ha_jea,         // Job address
    bit address_parity;     // ha_jeapar,      // Job address parity
  } JobInterfaceInput;

  typedef struct packed {
    bit running;            // ha_jval,        // Job valid
    bit done;               // ha_jcom,        // Job command
    bit cack;               // ha_jcompar,     // Job command parity
    pointer_t error;        // ha_jea,         // Job address
    bit yield;              // ha_jeapar,      // Job address parity
  } JobInterfaceOutput;

  typedef struct packed {
    byte unsigned room;       // ha_croom,       // Command room
  } CommandInterfaceInput;

  typedef struct packed {
    bit valid;                // ah_cvalid,      // Command valid
    byte tag;                 // ah_ctag,        // Command tag
    bit tag_parity;           // ah_ctagpar,     // Command tag parity
    afu_command_t command;    // ah_com,         // Command code
    bit command_parity;       // ah_compar,      // Command code parity
    bit [0:2] abt;            // ah_cabt,        // Command ABT
    pointer_t address;        // ah_cea,         // Command address
    bit address_parity;       // ah_ceapar,      // Command address parity
    bit [0:15] context_handle;// ah_cch,         // Command context handle
    bit [0:11] size;          // ah_csize,       // Command size
  } CommandInterfaceOutput;

  typedef struct packed {
    bit read_valid;           // ha_brvalid,     // Buffer Read valid
    byte read_tag;            // ha_brtag,       // Buffer Read tag
    bit read_tag_parity;      // ha_brtagpar,    // Buffer Read tag parity
    bit [0:5] read_address;   // ha_brad,        // Buffer Read address
    bit write_valid;          // ha_bwvalid,     // Buffer Write valid
    byte write_tag;           // ha_bwtag,       // Buffer Write tag
    bit write_tag_parity;     // ha_bwtagpar,    // Buffer Write tag parity
    bit [0:5] write_address;  // ha_bwad,        // Buffer Write address
    bit [0:511] write_data;   // ha_bwdata,      // Buffer Write data
    byte write_parity;        // ha_bwpar,       // Buffer Write parity
  } BufferInterfaceInput;

  typedef struct packed {
    bit [0:3] read_latency;   //ah_brlat,       // Buffer Read latency
    bit [0:511] read_data;    //ah_brdata,      // Buffer Read data
    byte read_parity;         //ah_brpar,       // Buffer Read parity
  } BufferInterfaceOutput;


    
  typedef struct packed {
    bit valid;              // ha_rvalid,     // Response valid
    byte tag;               // ha_rtag,       // Response tag
    bit tag_parity;         // ha_rtagpar,    // Response tag parity
    byte response;          // ha_response,   // Response
    bit [0:8] credits;      // ha_rcredits,   // Response credits
    bit [0:1] cache_state;  // ha_rcachestate,// Response cache state
    bit [0:12] cache_pos;   // ha_rcachepos   // Response cache pos
  } ResponseInterface;

  typedef struct packed {
    bit valid;            // ha_mmval,       // A valid MMIO is present
    bit cfg;              // ha_mmcfg,       // MMIO is AFU descriptor space access
    bit read;             // ha_mmrnw,       // 1 = read, 0 = write
    bit doubleword;       // ha_mmdw,        // 1 = doubleword, 0 = word
    bit [0:23] address;   // ha_mmad,        // mmio address
    bit address_parity;   // ha_mmadpar,     // mmio address parity
    bit [0:63] data;      // ha_mmdata,      // Write data
    bit data_parity;      // ha_mmdatapar,   // Write data parity
  } MMIOInterfaceInput;

  typedef struct packed {
    bit ack;              // ah_mmack,       // Write is complete or Read is valid
    bit [0:63] data;      // ah_mmdata,      // Read data
    bit data_parity;      // ah_mmdatapar,   // Read data parity
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
