  #!/usr/bin/tclsh

# if { $argc != 1 } {
#   puts "Default Project cu_PageRank_pull"
#   set project_algorithm "cu_PageRank_pull"
# } else {
#   puts "SET Project to [lindex $argv 0]"
#   set project_algorithm "[lindex $argv 0]"
# }

# recompile
proc r  {} {
  global project_algorithm
  # compile SystemVerilog files

  # compile libs
  echo "Compiling libs"
  
  # compile packages
  echo "Compiling Packages AFU-1"
  vlog -quiet ../../accelerator_rtl/pkg/globals_afu_pkg.sv
  vlog -quiet ../../accelerator_rtl/pkg/capi_pkg.sv
  vlog -quiet ../../accelerator_rtl/pkg/wed_pkg.sv
  vlog -quiet ../../accelerator_rtl/pkg/credit_pkg.sv



  if {$project_algorithm eq "cu_PageRank_pull"} {
   echo "Compiling Packages CU PAGERANK PULL"
   vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/pkg/globals_cu_pkg.sv
   vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/pkg/cu_pkg.sv
   } elseif {$project_algorithm eq "cu_PageRank_push"} {
   echo "Compiling Packages CU PAGERANK PUSH"
   vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/pkg/globals_cu_pkg.sv
   vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/pkg/cu_pkg.sv
   } else {
    echo "UNKNOWN Packages CU"
  }

  echo "Compiling Packages AFU-2"
  vlog -quiet ../../accelerator_rtl/pkg/afu_pkg.sv

  # compile afu
  echo "Compiling RTL General"
  vlog -quiet ../../accelerator_rtl/afu/parity.sv
  vlog -quiet ../../accelerator_rtl/afu/reset_filter.sv
  vlog -quiet ../../accelerator_rtl/afu/reset_control.sv
  vlog -quiet ../../accelerator_rtl/afu/error_control.sv
  vlog -quiet ../../accelerator_rtl/afu/done_control.sv
  vlog -quiet ../../accelerator_rtl/afu/sum_reduce.sv
  vlog -quiet ../../accelerator_rtl/afu/demux_bus.sv
  vlog -quiet ../../accelerator_rtl/afu/ram.sv
  vlog -quiet ../../accelerator_rtl/afu/fifo.sv
  vlog -quiet ../../accelerator_rtl/afu/priority_arbiters.sv
  vlog -quiet ../../accelerator_rtl/afu/round_robin_priority_arbiter.sv
  vlog -quiet ../../accelerator_rtl/afu/fixed_priority_arbiter.sv

  echo "Compiling RTL AFU Control"
  vlog -quiet ../../accelerator_rtl/afu/credit_control.sv
  vlog -quiet ../../accelerator_rtl/afu/response_statistics_control.sv
  vlog -quiet ../../accelerator_rtl/afu/response_control.sv
  vlog -quiet ../../accelerator_rtl/afu/restart_control.sv
  vlog -quiet ../../accelerator_rtl/afu/command_control.sv
  vlog -quiet ../../accelerator_rtl/afu/command_buffer_arbiter.sv
  vlog -quiet ../../accelerator_rtl/afu/tag_control.sv
  vlog -quiet ../../accelerator_rtl/afu/read_data_control.sv
  vlog -quiet ../../accelerator_rtl/afu/write_data_control.sv
  vlog -quiet ../../accelerator_rtl/afu/afu_control.sv

  echo "Compiling RTL JOB"
  vlog -quiet ../../accelerator_rtl/afu/job.sv

  echo "Compiling RTL MMIO"
  vlog -quiet ../../accelerator_rtl/afu/mmio.sv
  
  echo "Compiling RTL WED_control"
  vlog -quiet ../../accelerator_rtl/afu/wed_control.sv

  echo "Compiling RTL CU control "

  if {$project_algorithm eq "cu_PageRank_pull"} {
    echo "Compiling RTL CU control PAGERANK PULL"
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_cacheline_stream.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/array_struct_type_demux_bus.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_sum_kernel_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_sum_kernel_fp_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_edge_data_write_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_edge_data_read_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_edge_data_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_edge_job_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_vertex_job_filter.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_vertex_job_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_vertex_pagerank_arbiter_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_vertex_pagerank.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_graph_algorithm_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_control.sv
  } elseif {$project_algorithm eq "cu_PageRank_push"} {
    echo "Compiling RTL CU control PAGERANK PUSH"
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_cacheline_stream.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/array_struct_type_demux_bus.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_sum_kernel_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_sum_kernel_fp_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_edge_data_write_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_edge_data_read_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_edge_data_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_edge_job_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_vertex_job_filter.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_vertex_job_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_vertex_pagerank_arbiter_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_vertex_pagerank.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_graph_algorithm_control.sv
    vlog -quiet ../../accelerator_rtl/cu/$project_algorithm/cu/cu_control.sv
  } else {
    echo "UNKNOWN RTL CU"
  }

    echo "Compiling RTL AFU"
    vlog -quiet ../../accelerator_rtl/afu/afu.sv
    vlog -quiet ../../accelerator_rtl/afu/cached_afu.sv


  # compile top level
  echo "Compiling top level"
  # vlog -quiet       pslse/afu_driver/verilog/top.v
  vlog -quiet -sv +define+PSL8=PSL8 ../../pslse/afu_driver/verilog/top.v

}

# simulate
proc c {} {
  # vsim -t ns -novopt -c -pli pslse/afu_driver/src/veriuser.sl +nowarnTSCALE work.top
  # vsim -t ns -L work -L work_lib -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -novopt  -voptargs=+acc=npr -c -sv_lib ../../pslse/afu_driver/src/libdpi +nowarnTSCALE work.top
  vsim -t ns -novopt -voptargs=+acc=npr -c -sv_lib ../../pslse/afu_driver/src/libdpi +nowarnTSCALE work.top
  view wave
  radix h
  log * -r
  # do wave.do
  # do watch_job_interface.do
  # do watch_mmio_interface.do
  # do watch_command_interface.do
  # do watch_buffer_interface.do
  # do watch_response_interface.do
  
  # view structure
  # view signals
  # view wave
  run -all
  # run 40
}

proc c_fp {} {
  # vsim -t ns -novopt -c -pli pslse/afu_driver/src/veriuser.sl +nowarnTSCALE work.top
  vsim -novopt -t ns -L work -L work_lib -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver   -voptargs=+acc=npr -c -sv_lib ../../pslse/afu_driver/src/libdpi +nowarnTSCALE work.top
  view wave
  radix h
  log * -r
  # do wave.do
  # do watch_job_interface.do
  # do watch_mmio_interface.do
  # do watch_command_interface.do
  # do watch_buffer_interface.do
  # do watch_response_interface.do
  
  # view structure
  # view signals
  # view wave
  run -all
  # run 40
}

# shortcut for recompilation + simulation
proc rc {} {

  # init libs
  vlib work
  vmap work work

  r
  c
}

proc rcf {} {
  global project_algorithm

  if {$project_algorithm eq "cu_PageRank_pull"} {
  set QSYS_SIMDIR "../../accelerator_synth/psl_fpga/quartus_ip/fp/fp_single_precision_acc/fp_single_add_acc_sim"
  } elseif {$project_algorithm eq "cu_PageRank_push"} {
  set QSYS_SIMDIR "../../accelerator_synth/psl_fpga/quartus_ip/fp/fp_single_precision_add/fp_single_add_sim"
  } else {
  echo "UNKNOWN Packages CU"
  }

  set USER_DEFINED_COMPILE_OPTIONS ""
  set USER_DEFINED_VHDL_COMPILE_OPTIONS ""
  set USER_DEFINED_VERILOG_COMPILE_OPTIONS ""

  source $QSYS_SIMDIR/mentor/msim_setup.tcl

  dev_com
  com

  r
  c_fp
}

proc rcd {} {
  global project_algorithm
  
  if {$project_algorithm eq "cu_PageRank_pull"} {
  set QSYS_SIMDIR "../../accelerator_synth/psl_fpga/quartus_ip/fp/fp_double_precision_acc/fp_double_add_acc_sim"
  } elseif {$project_algorithm eq "cu_PageRank_push"} {
  set QSYS_SIMDIR "../../accelerator_synth/psl_fpga/quartus_ip/fp/fp_double_precision_add/fp_double_add_sim"
  } else {
  echo "UNKNOWN Packages CU"
  }

  set USER_DEFINED_COMPILE_OPTIONS ""
  set USER_DEFINED_VHDL_COMPILE_OPTIONS ""
  set USER_DEFINED_VERILOG_COMPILE_OPTIONS ""

  source $QSYS_SIMDIR/mentor/msim_setup.tcl

  dev_com
  com

  r
  c_fp
}

