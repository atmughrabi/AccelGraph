// -----------------------------------------------------------------------------
//
//      "CAPIPrecis Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : wed_pkg.sv
// Create : 2019-09-26 15:20:20
// Revise : 2019-09-26 15:20:20
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

package WED_PKG;

    import GLOBALS_AFU_PKG::*;
    import CAPI_PKG::*;

    typedef enum int unsigned {
        WED_RESET,
        WED_IDLE,
        WED_REQ,
        WED_WAITING_FOR_REQUEST,
        WED_READ_DATA,
        WED_DONE_REQ
    } wed_state;

    typedef struct packed{
        logic [0:63] size_send    ; // 4-Bytes
        logic [0:63] size_recive  ; // 4-Bytes
        logic [0:63] array_send   ; // 8-Bytes
        logic [0:63] array_receive; // 8-Bytes
        logic [0:63] pointer1     ; // 8-Bytes
        logic [0:63] pointer2     ; // 8-Bytes
        logic [0:63] pointer3     ; // 8-Bytes
        logic [0:63] pointer4     ; // 8-Bytes
        logic [0:63] pointer5     ; // 8-Bytes
        logic [0:63] pointer6     ; // 8-Bytes
        logic [0:63] pointer7     ; // 8-Bytes
        logic [0:63] pointer8     ; // 8-Bytes
        logic [0:63] pointer9     ; // 8-Bytes
        logic [0:63] pointer10    ; // 8-Bytes
        logic [0:63] pointer11    ; // 8-Bytes
        logic [0:63] pointer12    ; // 8-Bytes
    } WED_request;// 108-bytes used from 128-Bytes WED

    typedef struct packed{
        logic        valid  ;
        logic [0:63] address;
        WED_request  wed    ;
    } WEDInterface;

    function WED_request map_DataArrays_to_WED(logic [0:(CACHELINE_SIZE_BITS-1)] in);

        WED_request wed;

        wed.num_edges                  = swap_endianness_word(in[0:31]);               // 4-Bytes
        wed.num_vertices               = swap_endianness_word(in[32:63]);              // 4-Bytes
        wed.max_weight                 = swap_endianness_word(in[64:95]);              // 4-Bytes
        wed.auxiliary0                 = swap_endianness_word(in[96:127]);              // 4-Bytes
        wed.vertex_out_degree          = swap_endianness_double_word(in[128:191]);     // 8-Bytes
        wed.vertex_in_degree           = swap_endianness_double_word(in[192:255]);     // 8-Bytes
        wed.vertex_edges_idx           = swap_endianness_double_word(in[256:319]);     // 8-Bytes
        wed.edges_array_weight         = swap_endianness_double_word(in[320:383]);     // 8-Bytes
        wed.edges_array_src            = swap_endianness_double_word(in[384:447]);     // 8-Bytes
        wed.edges_array_dest           = swap_endianness_double_word(in[448:511]);     // 8-Bytes
        wed.inverse_vertex_out_degree  = swap_endianness_double_word(in[512:575]);     // 8-Bytes
        wed.inverse_vertex_in_degree   = swap_endianness_double_word(in[576:639]);     // 8-Bytes
        wed.inverse_vertex_edges_idx   = swap_endianness_double_word(in[640:703]);     // 8-Bytes
        wed.inverse_edges_array_weight = swap_endianness_double_word(in[704:767]);     // 8-Bytes
        wed.inverse_edges_array_src    = swap_endianness_double_word(in[768:831]);     // 8-Bytes
        wed.inverse_edges_array_dest   = swap_endianness_double_word(in[832:895]);     // 8-Bytes
        wed.auxiliary1                 = swap_endianness_double_word(in[896:959]);     // 8-Bytes
        wed.auxiliary2                 = swap_endianness_double_word(in[960:1023]);    // 8-Bytes

        return wed;

    endfunction : map_DataArrays_to_WED

    function trans_order_behavior_t map_CABT (logic [0:2] cabt_in);

        trans_order_behavior_t cabt;

        case(cabt_in)
            3'b000 : begin
                cabt = STRICT;
            end
            3'b100 : begin
                cabt = ABORT;
            end
            3'b010 : begin
                cabt = PAGE;
            end
            3'b110 : begin
                cabt = PREF;
            end
            3'b111 : begin
                cabt = SPEC;
            end
            default : begin
                cabt = STRICT;
            end
        endcase

        return cabt;

    endfunction : map_CABT

endpackage