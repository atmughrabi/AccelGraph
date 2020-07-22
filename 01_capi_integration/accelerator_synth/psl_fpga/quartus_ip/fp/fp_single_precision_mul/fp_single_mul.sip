set_global_assignment -entity "fp_single_mul" -library "lib_fp_single_mul" -name IP_TOOL_NAME "altera_fp_functions"
set_global_assignment -entity "fp_single_mul" -library "lib_fp_single_mul" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "fp_single_mul" -library "lib_fp_single_mul" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_fp_single_mul" -name SPD_FILE [file join $::quartus(sip_path) "fp_single_mul.spd"]

set_global_assignment -library "lib_fp_single_mul" -name MISC_FILE [file join $::quartus(sip_path) "fp_single_mul_sim/fp_single_mul.vo"]
