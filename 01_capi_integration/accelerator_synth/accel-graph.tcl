  #!/usr/bin/tclsh
set project_name accel-graph
set PSL_FPGA ./psl_fpga
set LIBCAPI  ./capi
set VERSION   [binary format A24 [exec $LIBCAPI/scripts/version.py]]
set project_revision accel-graph


if { $argc != 5 } {
	puts "SET Project to DEFAULT"
	set graph_algorithm "cu_PageRank"
	set data_structure 	"CSR"
	set direction 		"PULL"
	set cu_precision 	"FloatPoint"
	set cu_count  	 	"20"
} else {
	puts "SET Project to ARGV"
	set graph_algorithm "[lindex $argv 0]"
	set data_structure 	"[lindex $argv 1]"
	set direction 		"[lindex $argv 2]"
	set cu_precision 	"[lindex $argv 3]"
	set cu_count 		"[lindex $argv 4]"
}

puts "Algorithm $graph_algorithm"
puts "Datastructure $data_structure"
puts "Direction $direction"
puts "Precision $cu_precision"
puts "CU Count  $cu_count"

project_new $project_name -overwrite -revision $project_revision

set_global_assignment -name TOP_LEVEL_ENTITY psl_fpga


# source $LIBCAPI/fpga/common_${graph_algorithm}_${data_structure}_${direction}_${cu_precision}.tcl
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

foreach filename [glob ../accelerator_rtl/cu/$graph_algorithm/$data_structure/$direction/global_cu/*.sv] {
	set_global_assignment -name SYSTEMVERILOG_FILE $filename
}

foreach filename [glob ../accelerator_rtl/cu/$graph_algorithm/$data_structure/$direction/global_pkg/*.sv] {
	set_global_assignment -name SYSTEMVERILOG_FILE $filename
}

foreach filename [glob ../accelerator_rtl/cu/$graph_algorithm/$data_structure/$direction/$cu_precision/cu/*.sv] {
	set_global_assignment -name SYSTEMVERILOG_FILE $filename
}

foreach filename [glob ../accelerator_rtl/cu/$graph_algorithm/$data_structure/$direction/$cu_precision/pkg/*.sv] {
	set_global_assignment -name SYSTEMVERILOG_FILE $filename
}