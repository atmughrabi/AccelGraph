# recompile
proc r  {} {

  # compile SystemVerilog files

  # compile libs
  echo "Compiling libs"
  
  # compile packages
 
  echo "Compiling Packages"

  vlog -quiet ../../accelerator/pkg/globals_pkg.sv
  vlog -quiet ../../accelerator/pkg/capi_pkg.sv
  vlog -quiet ../../accelerator/pkg/wed_pkg.sv
  vlog -quiet ../../accelerator/pkg/cu_pkg.sv
  vlog -quiet ../../accelerator/pkg/credit_pkg.sv
  vlog -quiet ../../accelerator/pkg/afu_pkg.sv

  # compile rtl
  echo "Compiling RTL General"
  vlog -quiet ../../accelerator/rtl/parity.sv
  vlog -quiet ../../accelerator/rtl/reset_filter.sv
  vlog -quiet ../../accelerator/rtl/reset_control.sv
  vlog -quiet ../../accelerator/rtl/error_control.sv
  vlog -quiet ../../accelerator/rtl/done_control.sv
  vlog -quiet ../../accelerator/rtl/ram.sv
  vlog -quiet ../../accelerator/rtl/fifo.sv
  vlog -quiet ../../accelerator/rtl/priority_arbiters.sv
  vlog -quiet ../../accelerator/rtl/round_robin_priority_arbiter.sv
  vlog -quiet ../../accelerator/rtl/fixed_priority_arbiter.sv

  echo "Compiling RTL AFU Control"
  vlog -quiet ../../accelerator/rtl/credit_control.sv
  vlog -quiet ../../accelerator/rtl/response_control.sv
  vlog -quiet ../../accelerator/rtl/restart_control.sv
  vlog -quiet ../../accelerator/rtl/command_control.sv
  vlog -quiet ../../accelerator/rtl/command_buffer_arbiter.sv
  vlog -quiet ../../accelerator/rtl/tag_control.sv
  vlog -quiet ../../accelerator/rtl/read_data_control.sv
  vlog -quiet ../../accelerator/rtl/write_data_control.sv
  vlog -quiet ../../accelerator/rtl/afu_control.sv

  echo "Compiling RTL JOB"
  vlog -quiet ../../accelerator/rtl/job.sv

  echo "Compiling RTL MMIO"
  vlog -quiet ../../accelerator/rtl/mmio.sv
  
  echo "Compiling RTL WED_control"
  vlog -quiet ../../accelerator/rtl/wed_control.sv

  echo "Compiling RTL CU control PAGERANK"
  vlog -quiet ../../accelerator/cu/cu_cacheline_stream.sv
  vlog -quiet ../../accelerator/cu/cu_sum_kernel_control.sv
  vlog -quiet ../../accelerator/cu/cu_edge_data_write_control.sv
  vlog -quiet ../../accelerator/cu/cu_edge_data_read_control.sv
  vlog -quiet ../../accelerator/cu/cu_edge_data_control.sv
  vlog -quiet ../../accelerator/cu/cu_edge_job_control.sv
  vlog -quiet ../../accelerator/cu/cu_vertex_job_control.sv
  vlog -quiet ../../accelerator/cu/cu_vertex_pagerank.sv
  vlog -quiet ../../accelerator/cu/cu_graph_algorithm_control.sv
  vlog -quiet ../../accelerator/cu/cu_control.sv

 
  echo "Compiling RTL AFU"
  vlog -quiet ../../accelerator/rtl/afu.sv
  vlog -quiet ../../accelerator/rtl/cached_afu.sv
  
  
  # compile top level
  echo "Compiling top level"
  # vlog -quiet       pslse/afu_driver/verilog/top.v
  vlog -quiet -sv +define+PSL8=PSL8 ../../pslse/afu_driver/verilog/top.v

}

# simulate
proc c {} {
  # vsim -t ns -novopt -c -pli pslse/afu_driver/src/veriuser.sl +nowarnTSCALE work.top
  # vsim -t ns -L work -L work_lib -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -novopt  -voptargs=+acc=npr -c -sv_lib ../../pslse/afu_driver/src/libdpi +nowarnTSCALE work.top
  vsim -t ns -novopt  -voptargs=+acc=npr -c -sv_lib ../../pslse/afu_driver/src/libdpi +nowarnTSCALE work.top
  view wave
  radix h
  log * -r
  # do wave.do
  do watch_job_interface.do
  do watch_mmio_interface.do
  do watch_command_interface.do
  do watch_buffer_interface.do
  do watch_response_interface.do
  
  view structure
  view signals
  view wave
  run -all
  # run 40
}

# shortcut for recompilation + simulation
proc rc {} {
  r
  c
}

# init libs
vlib work
vmap work work

# automatically recompile on first call
r
