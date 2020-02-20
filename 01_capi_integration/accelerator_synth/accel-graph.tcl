set project_name accel-graph
set PSL_FPGA ./psl_fpga
set LIBCAPI  ./capi
set VERSION   [binary format A24 [exec $LIBCAPI/scripts/version.py]]
set project_revision accel-graph
set project_algorithm cu_PageRank_pull

if { $argc != 1 } {
	puts "Default Project cu_PageRank_pull"
	set project_algorithm cu_PageRank_pull
	} else {
		puts "SET Project to [lindex $argv 0]"
		set project_algorithm [lindex $argv 0]
	}

	set project_algorithm cu_PageRank_pull

	project_new $project_name -overwrite -revision $project_revision

	set_global_assignment -name TOP_LEVEL_ENTITY psl_fpga


	source $LIBCAPI/fpga/common.tcl
	source $LIBCAPI/fpga/ibm_sources.tcl
	source $LIBCAPI/fpga/pins.tcl
	source $LIBCAPI/fpga/build_version.tcl


# foreach filename [glob ../accelerator/rtl/*.vhd] {
#     set_global_assignment -name VHDL_FILE $filename
# }

# foreach filename [glob ../accelerator/rtl/*.v] {
#     set_global_assignment -name SYSTEMVERILOG_FILE $filename
# }

foreach filename [glob ../accelerator_rtl/afu/*.sv] {
	set_global_assignment -name SYSTEMVERILOG_FILE $filename
}

# foreach filename [glob ../accelerator/pkg/*.vhd] {
#     set_global_assignment -name VHDL_FILE $filename
# }

# foreach filename [glob ../accelerator/pkg/*.v] {
#     set_global_assignment -name SYSTEMVERILOG_FILE $filename
# }

foreach filename [glob ../accelerator_rtl/pkg/*.sv] {
	set_global_assignment -name SYSTEMVERILOG_FILE $filename
}

# foreach filename [glob ../accelerator/cu/*.vhd] {
#     set_global_assignment -name VHDL_FILE $filename
# }

# foreach filename [glob ../accelerator/cu/*.v] {
#     set_global_assignment -name SYSTEMVERILOG_FILE $filename
# }

foreach filename [glob ../accelerator_rtl/cu/$project_algorithm/cu/*.sv] {
	set_global_assignment -name SYSTEMVERILOG_FILE $filename
}

foreach filename [glob ../accelerator_rtl/cu/$project_algorithm/pkg/*.sv] {
	set_global_assignment -name SYSTEMVERILOG_FILE $filename
}