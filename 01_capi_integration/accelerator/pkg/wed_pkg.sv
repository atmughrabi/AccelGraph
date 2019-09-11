package WED_PKG;

  import CAPI_PKG::*;

// since Wed control interact with PSL it is considered a simple CU with an ID
  parameter WED_ID = 8'h01;

  typedef enum int unsigned {
    WED_RESET,
    WED_IDLE,
    WED_REQ,
    WED_WAITING_FOR_REQUEST,
    WED_DONE_REQ
  } wed_state;

  typedef struct packed{
    logic [0:31] num_edges;                   // 4-Bytes
    logic [0:31] num_vertices;                // 4-Bytes
    logic [0:31] max_weight;                  // 4-Bytes
    logic [0:63] vertex_out_degree;           // 8-Bytes
    logic [0:63] vertex_in_degree;            // 8-Bytes
    logic [0:63] vertex_edges_idx;            // 8-Bytes
    logic [0:63] edges_array_weight;          // 8-Bytes
    logic [0:63] edges_array_src;             // 8-Bytes
    logic [0:63] edges_array_dest;            // 8-Bytes
    logic [0:63] inverse_vertex_out_degree;   // 8-Bytes
    logic [0:63] inverse_vertex_in_degree;    // 8-Bytes
    logic [0:63] inverse_vertex_edges_idx;    // 8-Bytes
    logic [0:63] inverse_edges_array_weight;  // 8-Bytes
    logic [0:63] inverse_edges_array_src;     // 8-Bytes
    logic [0:63] inverse_edges_array_dest;    // 8-Bytes
    logic [0:31] reserved1;                   // 4-Bytes
    logic [0:63] reserved2;                   // 8-Bytes
    logic [0:63] reserved3;                   // 8-Bytes
  } WED_request;// 108-bytes used from 128-Bytes WED

  typedef struct packed{
    logic valid;
    logic [0:63] address;
    WED_request wed;
  } WEDInterface;


  function WED_request map_GraphCSR_to_WED(logic [0:1023] in);

    WED_request wed;

    wed.num_edges          = swap_endianness_word(in[0:31]);                   // 4-Bytes
    wed.num_vertices       = swap_endianness_word(in[32:63]);                  // 4-Bytes
    wed.max_weight         = swap_endianness_word(in[64:95]);                  // 4-Bytes
    wed.vertex_out_degree  = swap_endianness_double_word(in[96:159]);          // 8-Bytes
    wed.vertex_in_degree   = swap_endianness_double_word(in[160:223]);         // 8-Bytes
    wed.vertex_edges_idx   = swap_endianness_double_word(in[224:287]);         // 8-Bytes
    wed.edges_array_weight = swap_endianness_double_word(in[288:351]);         // 8-Bytes
    wed.edges_array_src    = swap_endianness_double_word(in[352:415]);         // 8-Bytes
    wed.edges_array_dest   = swap_endianness_double_word(in[416:479]);         // 8-Bytes
    wed.inverse_vertex_out_degree   = swap_endianness_double_word(in[480:543]);     // 8-Bytes
    wed.inverse_vertex_in_degree    = swap_endianness_double_word(in[544:607]);     // 8-Bytes
    wed.inverse_vertex_edges_idx    = swap_endianness_double_word(in[608:671]);     // 8-Bytes
    wed.inverse_edges_array_weight  = swap_endianness_double_word(in[672:735]);     // 8-Bytes
    wed.inverse_edges_array_src     = swap_endianness_double_word(in[736:799]);     // 8-Bytes
    wed.inverse_edges_array_dest    = swap_endianness_double_word(in[800:863]);     // 8-Bytes
    wed.reserved1 = 32'h0000_0000;                                                  // 4-Bytes
    wed.reserved2 = 64'h0000_0000_0000_0000;                   // 8-Bytes
    wed.reserved3 = 64'h0000_0000_0000_0000;                  // 8-Bytes

    return wed;

  endfunction : map_GraphCSR_to_WED

endpackage