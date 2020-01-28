# recompile
proc r  {} {

  # compile SystemVerilog files

  # compile libs
  echo "Compiling libs"
  
  # compile packages
  echo "Compiling Packages"
  vlog -quiet ../../accelerator_rtl/pkg/globals_pkg.sv
  vlog -quiet ../../accelerator_rtl/pkg/capi_pkg.sv
  vlog -quiet ../../accelerator_rtl/pkg/wed_pkg.sv
  vlog -quiet ../../accelerator_rtl/pkg/cu_pkg.sv
  vlog -quiet ../../accelerator_rtl/pkg/credit_pkg.sv
  vlog -quiet ../../accelerator_rtl/pkg/afu_pkg.sv

  # compile afu
  echo "Compiling RTL General"
  vlog -quiet ../../accelerator_rtl/afu/parity.sv
  vlog -quiet ../../accelerator_rtl/afu/reset_filter.sv
  vlog -quiet ../../accelerator_rtl/afu/reset_control.sv
  vlog -quiet ../../accelerator_rtl/afu/error_control.sv
  vlog -quiet ../../accelerator_rtl/afu/done_control.sv
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
  vlog -quiet ../../accelerator_rtl/cu/cu_prefetch_stream_engine_control.sv
  vlog -quiet ../../accelerator_rtl/cu/cu_data_read_engine_control.sv
  vlog -quiet ../../accelerator_rtl/cu/cu_data_write_engine_control.sv
  vlog -quiet ../../accelerator_rtl/cu/cu_control.sv

 
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
