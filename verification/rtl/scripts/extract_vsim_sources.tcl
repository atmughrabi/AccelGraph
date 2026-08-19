if {$argc != 5} {
    puts stderr "Usage: tclsh extract_vsim_sources.tcl ALGORITHM DATA_STRUCTURE DIRECTION PRECISION CU_COUNT"
    exit 2
}

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ../../..]]
set sim_dir [file join $repo_root 03_capi_integration accelerator_sim sim]

set graph_algorithm [lindex $argv 0]
set data_structure [lindex $argv 1]
set direction [lindex $argv 2]
set cu_precision [lindex $argv 3]
set cu_count [lindex $argv 4]

proc echo {args} {}
proc vlog {args} {
    puts [lindex $args end]
}

set previous_directory [pwd]
cd $sim_dir
source [file join $sim_dir vsim.tcl]
r
cd $previous_directory
