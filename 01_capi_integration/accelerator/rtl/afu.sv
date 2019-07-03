// This provides an abstracted view of the SystemVerilog AFU to top.v
module afu (
  // Command interface
  output         ah_cvalid,      // Command valid
  output [0:7]   ah_ctag,        // Command tag
  output         ah_ctagpar,     // Command tag parity
  output [0:12]  ah_com,         // Command code
  output         ah_compar,      // Command code parity
  output [0:2]   ah_cabt,        // Command ABT
  output [0:63]  ah_cea,         // Command address
  output         ah_ceapar,      // Command address parity
  output [0:15]  ah_cch,         // Command context handle
  output [0:11]  ah_csize,       // Command size
  input  [0:7]   ha_croom,       // Command room
  // Buffer interface
  input          ha_brvalid,     // Buffer Read valid
  input  [0:7]   ha_brtag,       // Buffer Read tag
  input          ha_brtagpar,    // Buffer Read tag parity
  input  [0:5]   ha_brad,        // Buffer Read address
  output [0:3]   ah_brlat,       // Buffer Read latency
  output [0:511] ah_brdata,      // Buffer Read data
  output [0:7]   ah_brpar,       // Buffer Read parity
  input          ha_bwvalid,     // Buffer Write valid
  input  [0:7]   ha_bwtag,       // Buffer Write tag
  input          ha_bwtagpar,    // Buffer Write tag parity
  input  [0:5]   ha_bwad,        // Buffer Write address
  input  [0:511] ha_bwdata,      // Buffer Write data
  input  [0:7]   ha_bwpar,       // Buffer Write parity
  // Response interface
  input          ha_rvalid,      // Response valid
  input  [0:7]   ha_rtag,        // Response tag
  input          ha_rtagpar,     // Response tag parity
  input  [0:7]   ha_response,    // Response
  input  [0:8]   ha_rcredits,    // Response credits
  input  [0:1]   ha_rcachestate, // Response cache state
  input  [0:12]  ha_rcachepos,   // Response cache pos
  // MMIO interface
  input          ha_mmval,       // A valid MMIO is present
  input          ha_mmcfg,       // MMIO is AFU descriptor space access
  input          ha_mmrnw,       // 1 = read, 0 = write
  input          ha_mmdw,        // 1 = doubleword, 0 = word
  input  [0:23]  ha_mmad,        // mmio address
  input          ha_mmadpar,     // mmio address parity
  input  [0:63]  ha_mmdata,      // Write data
  input          ha_mmdatapar,   // Write data parity
  output         ah_mmack,       // Write is complete or Read is valid
  output  [0:63] ah_mmdata,      // Read data
  output         ah_mmdatapar,   // Read data parity
  // Control interface
  input          ha_jval,        // Job valid
  input  [0:7]   ha_jcom,        // Job command
  input          ha_jcompar,     // Job command parity
  input  [0:63]  ha_jea,         // Job address
  input          ha_jeapar,      // Job address parity
  output         ah_jrunning,    // Job running
  output         ah_jdone,       // Job done
  output         ah_jcack,       // Acknowledge completion of LLCMD
  output [0:63]  ah_jerror,      // Job error
  output         ah_jyield,      // Job yield
  output         ah_tbreq,       // Timebase command request
  output         ah_paren,       // Parity enable
  input          ha_pclock       // clock
);

  parity_afu svAFU(
    .clock(ha_pclock),
    .timebase_request(ah_tbreq),
    .parity_enabled(ah_paren),
    .job_in({ha_jval, ha_jcom, ha_jcompar, ha_jea, ha_jeapar}),
    .job_out({ah_jrunning, ah_jdone, ah_jcack, ah_jerror, ah_jyield}),
    .command_in({ha_croom}),
    .command_out({ah_cvalid, ah_ctag, ah_ctagpar, ah_com, ah_compar, ah_cabt,
                  ah_cea, ah_ceapar, ah_cch, ah_csize}),
    .buffer_in({ha_brvalid, ha_brtag, ha_brtagpar, ha_brad, ha_bwvalid,
                ha_bwtag, ha_bwtagpar, ha_bwad, ha_bwdata, ha_bwpar}),
    .buffer_out({ah_brlat, ah_brdata, ah_brpar}),
    .response({ha_rvalid, ha_rtag, ha_rtagpar, ha_response, ha_rcredits,
               ha_rcachestate, ha_rcachepos}),
    .mmio_in({ha_mmval, ha_mmcfg, ha_mmrnw, ha_mmdw, ha_mmad, ha_mmadpar,
              ha_mmdata, ha_mmdatapar}),
    .mmio_out({ah_mmack, ah_mmdata, ah_mmdatapar}));

endmodule
