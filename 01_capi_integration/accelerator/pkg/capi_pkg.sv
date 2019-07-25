package CAPI_PKG;
 
  typedef enum logic [0:7] {
    RESET=8'h80,
    START=8'h90
  } job_command_t;

  typedef enum logic [0:12] {
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
    logic valid;              // ha_jval,        // Job valid
    job_command_t command;    // ha_jcom,        // Job command
    logic command_parity;     // ha_jcompar,     // Job command parity
    logic [0:63] address;     // ha_jea,         // Job address
    logic address_parity;     // ha_jeapar,      // Job address parity
  } JobInterfaceInput;

  typedef struct packed {
    logic running;            // ha_jval,        // Job valid
    logic done;               // ha_jcom,        // Job command
    logic cack;               // ha_jcompar,     // Job command parity
    logic [0:63] error;       // ha_jea,         // Job address
    logic yield;              // ha_jeapar,      // Job address parity
  } JobInterfaceOutput;

  typedef struct packed {
    logic [0:7] room;         // ha_croom,       // Command room
  } CommandInterfaceInput;

  typedef struct packed {
    logic valid;                // ah_cvalid,      // Command valid
    logic [0:7] tag;            // ah_ctag,        // Command tag
    logic tag_parity;           // ah_ctagpar,     // Command tag parity
    afu_command_t command;      // ah_com,         // Command code
    logic command_parity;       // ah_compar,      // Command code parity
    logic [0:2] abt;            // ah_cabt,        // Command ABT
    logic [0:63] address;       // ah_cea,         // Command address
    logic address_parity;       // ah_ceapar,      // Command address parity
    logic [0:15] context_handle;// ah_cch,         // Command context handle
    logic [0:11] size;          // ah_csize,       // Command size
  } CommandInterfaceOutput;

  typedef struct packed {
    logic read_valid;           // ha_brvalid,     // Buffer Read valid
    logic [0:7] read_tag;       // ha_brtag,       // Buffer Read tag
    logic read_tag_parity;      // ha_brtagpar,    // Buffer Read tag parity
    logic [0:5] read_address;   // ha_brad,        // Buffer Read address
    logic write_valid;          // ha_bwvalid,     // Buffer Write valid
    logic [0:7] write_tag;      // ha_bwtag,       // Buffer Write tag
    logic write_tag_parity;     // ha_bwtagpar,    // Buffer Write tag parity
    logic [0:5] write_address;  // ha_bwad,        // Buffer Write address
    logic [0:511] write_data;   // ha_bwdata,      // Buffer Write data
    logic [0:7] write_parity;   // ha_bwpar,       // Buffer Write parity
  } BufferInterfaceInput;

  typedef struct packed {
    logic [0:3] read_latency;   //ah_brlat,       // Buffer Read latency
    logic [0:511] read_data;    //ah_brdata,      // Buffer Read data
    logic [0:7] read_parity;    //ah_brpar,       // Buffer Read parity
  } BufferInterfaceOutput;


    
  typedef struct packed {
    logic valid;              // ha_rvalid,     // Response valid
    logic [0:7] tag;          // ha_rtag,       // Response tag
    logic tag_parity;         // ha_rtagpar,    // Response tag parity
    logic [0:7] response;     // ha_response,   // Response
    logic [0:8] credits;      // ha_rcredits,   // Response credits
    logic [0:1] cache_state;  // ha_rcachestate,// Response cache state
    logic [0:12] cache_pos;   // ha_rcachepos   // Response cache pos
  } ResponseInterface;

  typedef struct packed {
    logic valid;            // ha_mmval,       // A valid MMIO is present
    logic cfg;              // ha_mmcfg,       // MMIO is AFU descriptor space access
    logic read;             // ha_mmrnw,       // 1 = read, 0 = write
    logic doubleword;       // ha_mmdw,        // 1 = doubleword, 0 = word
    logic [0:23] address;   // ha_mmad,        // mmio address
    logic address_parity;   // ha_mmadpar,     // mmio address parity
    logic [0:63] data;      // ha_mmdata,      // Write data
    logic data_parity;      // ha_mmdatapar,   // Write data parity
  } MMIOInterfaceInput;

  typedef struct packed {
    logic ack;              // ah_mmack,       // Write is complete or Read is valid
    logic [0:63] data;      // ah_mmdata,      // Read data
    logic data_parity;      // ah_mmdatapar,   // Read data parity
  } MMIOInterfaceOutput;

  typedef struct packed {
    logic [0:15] num_ints_per_process;
    logic [0:15] num_of_processes;
    logic [0:15] num_of_afu_crs;
    logic [0:15] req_prog_model;
    logic [0:63] reserved_1;
    logic [0:7] reserved_2; //0x20
    logic [0:55] afu_cr_len;
    logic [0:63] afu_cr_offset;
    logic [0:5] reserved_3;
    logic psa_per_process_required;
    logic psa_required;
    logic [0:55] psa_length;
    logic [0:63] psa_offset;
    logic [0:7] reserved_4;
    logic [0:55] afu_eb_len;
    logic [0:63] afu_eb_offset;
  } AFUDescriptor;

  
    // MMIO Registers mapping
    parameter REG_1= 26'h 3FFFFF8 >> 2;
    parameter REG_2= 26'h 3FFFFF0 >> 2;
 

    // AFU descriptor
  // Offset 0x00(0), bit 31 -> AFU supports only 1 process at a time
  // Offset 0x00(0), bit 47 -> AFU has one Configuration Record (CR).
  // Offset 0x00(0), bit 59 -> AFU supports dedicated process
  // Offset 0x20(4), bits 0:7 -> 0x00 to indicate implementation specific CR.
  // bits 8:63 -> 0x1 to indicate minimum possible length of 256 bytes per CR. 
  // Offset 0x28(5), bits 0:63 -> point to next descr read offset for CR.
  // the lowest 8 bits are 0 because it must be 256 byte aligned address.
  // Offset 0x30(6), bit 07 -> AFU Problem State Area Required
  // Offset 0x100(32), start of little endian CR data as per pointer at 0x28.
  // First 4 bytes for device ID, vendor id set to DEAD in ascii.
  // Next 4 bytes 0.
  // Offset 0x108(33), next little endian data
  // First 4 bytes BEEF in ascii for rev ID, class code. 
  // Next 4 bytes 0.
  // Though 256 bytes allocated, don't care about rest.

  function logic [0:63] read_afu_descriptor(AFUDescriptor descriptor, logic [0:22] address);
    case(address)
      0: begin //Offset 0x00
        return {descriptor.num_ints_per_process,
                descriptor.num_of_processes,
                descriptor.num_of_afu_crs,
                descriptor.req_prog_model};
      end
      4: begin //Offset 0x20
        return {descriptor.reserved_2,
                descriptor.afu_cr_len};
      end
      5: begin //Offset 0x28
        return {descriptor.afu_cr_offset};
      end
      6: begin //Offset 0x30
        return {descriptor.reserved_3,
                descriptor.psa_per_process_required,
                descriptor.psa_required,
                descriptor.psa_length};
      end
      7: begin //Offset 0x38
        return {descriptor.psa_offset};
      end
      8: begin //Offset 0x40
        return {descriptor.reserved_4,
                descriptor.afu_eb_len};
      end
      9: begin //Offset 0x48
        return {descriptor.afu_eb_offset};
      end
      32: begin //Offset 0x100
        return 64'h4441_4544_0000_0000;
      end
      33: begin //Offset 0x108
        return 64'h4645_4542_0000_0000;
      end
      default: begin
        return 64'h0000_0000_0000_0000;
      end
    endcase
  endfunction


  function logic [0:63] swap_endianness(logic [0:63] in);
    return {in[56:63], in[48:55], in[40:47], in[32:39], in[24:31], in[16:23],
            in[8:15], in[0:7]};
  endfunction

endpackage