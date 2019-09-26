package WED_PKG;

  import GLOBALS_PKG::*;
  import CAPI_PKG::*;

  typedef enum int unsigned {
    WED_RESET,
    WED_IDLE,
    WED_REQ,
    WED_WAITING_FOR_REQUEST,
    WED_DONE_REQ
  } wed_state;

  typedef struct packed{
    logic [0:31] num_edges                 ; // 4-Bytes
    logic [0:31] num_vertices              ; // 4-Bytes
    logic [0:31] max_weight                ; // 4-Bytes
    logic [0:63] vertex_out_degree         ; // 8-Bytes
    logic [0:63] vertex_in_degree          ; // 8-Bytes
    logic [0:63] vertex_edges_idx          ; // 8-Bytes
    logic [0:63] edges_array_weight        ; // 8-Bytes
    logic [0:63] edges_array_src           ; // 8-Bytes
    logic [0:63] edges_array_dest          ; // 8-Bytes
    logic [0:63] inverse_vertex_out_degree ; // 8-Bytes
    logic [0:63] inverse_vertex_in_degree  ; // 8-Bytes
    logic [0:63] inverse_vertex_edges_idx  ; // 8-Bytes
    logic [0:63] inverse_edges_array_weight; // 8-Bytes
    logic [0:63] inverse_edges_array_src   ; // 8-Bytes
    logic [0:63] inverse_edges_array_dest  ; // 8-Bytes
    logic [0:63] auxiliary1                ; // 8-Bytes
    logic [0:63] auxiliary2                ; // 8-Bytes
    logic [0:31] done                      ; // 4-Bytes
  } WED_request;// 108-bytes used from 128-Bytes WED

  typedef struct packed{
    logic        valid  ;
    logic [0:63] address;
    WED_request  wed    ;
  } WEDInterface;


  function WED_request map_GraphCSR_to_WED(logic [0:(CACHELINE_SIZE_BITS-1)] in);

    WED_request wed;

    wed.num_edges                  = swap_endianness_word(in[0:31]);               // 4-Bytes
    wed.num_vertices               = swap_endianness_word(in[32:63]);              // 4-Bytes
    wed.max_weight                 = swap_endianness_word(in[64:95]);              // 4-Bytes

    wed.vertex_out_degree          = swap_endianness_double_word(in[96:159]);      // 8-Bytes
    wed.vertex_in_degree           = swap_endianness_double_word(in[160:223]);     // 8-Bytes
    wed.vertex_edges_idx           = swap_endianness_double_word(in[224:287]);     // 8-Bytes
    wed.edges_array_weight         = swap_endianness_double_word(in[288:351]);     // 8-Bytes
    wed.edges_array_src            = swap_endianness_double_word(in[352:415]);     // 8-Bytes
    wed.edges_array_dest           = swap_endianness_double_word(in[416:479]);     // 8-Bytes
    wed.inverse_vertex_out_degree  = swap_endianness_double_word(in[480:543]);     // 8-Bytes
    wed.inverse_vertex_in_degree   = swap_endianness_double_word(in[544:607]);     // 8-Bytes
    wed.inverse_vertex_edges_idx   = swap_endianness_double_word(in[608:671]);     // 8-Bytes
    wed.inverse_edges_array_weight = swap_endianness_double_word(in[672:735]);     // 8-Bytes
    wed.inverse_edges_array_src    = swap_endianness_double_word(in[736:799]);     // 8-Bytes
    wed.inverse_edges_array_dest   = swap_endianness_double_word(in[800:863]);     // 8-Bytes
    wed.auxiliary1                 = swap_endianness_double_word(in[864:927]);     // 8-Bytes
    wed.auxiliary2                 = swap_endianness_double_word(in[928:991]);     // 8-Bytes
    wed.done                       = swap_endianness_word(in[992:1023]);           // 4-Bytes

    return wed;

  endfunction : map_GraphCSR_to_WED

endpackage