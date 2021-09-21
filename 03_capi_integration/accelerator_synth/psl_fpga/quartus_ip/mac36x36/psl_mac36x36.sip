set_global_assignment -entity "psl_mac36x36" -library "lib_psl_mac36x36" -name IP_TOOL_NAME "altera_mult_add"
set_global_assignment -entity "psl_mac36x36" -library "lib_psl_mac36x36" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "psl_mac36x36" -library "lib_psl_mac36x36" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_psl_mac36x36" -name SPD_FILE [file join $::quartus(sip_path) "psl_mac36x36.spd"]

set_global_assignment -library "lib_psl_mac36x36" -name MISC_FILE [file join $::quartus(sip_path) "psl_mac36x36_sim/psl_mac36x36.vhd"]
