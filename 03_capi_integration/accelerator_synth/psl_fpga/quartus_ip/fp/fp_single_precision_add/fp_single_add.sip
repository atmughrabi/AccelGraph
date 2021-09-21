set_global_assignment -entity "fp_single_add" -library "lib_fp_single_add" -name IP_TOOL_NAME "altera_fp_functions"
set_global_assignment -entity "fp_single_add" -library "lib_fp_single_add" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "fp_single_add" -library "lib_fp_single_add" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_fp_single_add" -name SPD_FILE [file join $::quartus(sip_path) "fp_single_add.spd"]

set_global_assignment -library "lib_fp_single_add" -name MISC_FILE [file join $::quartus(sip_path) "fp_single_add_sim/fp_single_add.vo"]
