if {$argc != 1} {
    puts stderr "Usage: tclsh test_graph_accelerator_sources.tcl REPO_ROOT"
    exit 2
}

set repo_root [file normalize [lindex $argv 0]]
set helper [file join $repo_root 03_capi_integration accelerator_synth capi fpga graph_accelerator_sources.tcl]
source $helper

proc set_global_assignment {args} {
    global collected_sources
    if {[llength $args] != 3 ||
        [lindex $args 0] ne "-name" ||
        [lindex $args 1] ne "SYSTEMVERILOG_FILE"} {
        error "Unexpected Quartus assignment: $args"
    }
    lappend collected_sources [file normalize [lindex $args 2]]
}

set layout_query [file join $repo_root verification rtl scripts layout_query.py]
set active_layouts [split [exec python3 $layout_query --active-layouts] "\n"]

foreach fields $active_layouts {
    lassign $fields algorithm data_structure direction precision
    set layout [graph_layout_id $algorithm $data_structure $direction $precision]
    set collected_sources {}
    add_graph_accelerator_manifest $repo_root $algorithm $data_structure $direction $precision

    set manifest [file join $repo_root verification rtl manifests "$layout.f"]
    set handle [open $manifest r]
    set contents [read $handle]
    close $handle
    set expected_sources {}
    foreach raw_line [split $contents "\n"] {
        set source [string trim $raw_line]
        if {$source eq "" || [string index $source 0] eq "#"} {
            continue
        }
        lappend expected_sources [file normalize [file join $repo_root $source]]
    }
    if {$collected_sources ne $expected_sources} {
        puts stderr "Quartus graph manifest order mismatch: $layout"
        exit 1
    }
    puts "PASS quartus_graph_manifest $layout files=[llength $collected_sources]"
}

foreach precision {FloatPoint FixedPoint Quantized} {
    if {![catch {
        add_graph_accelerator_manifest $repo_root cu_PageRank CSR PUSH $precision
    }]} {
        puts stderr "Quarantined PageRank PUSH unexpectedly has an active manifest: $precision"
        exit 1
    }
}
