# recompile
proc r  {} {

  # compile SystemVerilog files

  # compile libs
  echo "Compiling libs"
  
  # compile packages
  echo "Compiling Packages"
  vlog -quiet ../../accelerator/pkg/capi_pkg.sv
  vlog -quiet ../../accelerator/pkg/wed_pkg.sv
  vlog -quiet ../../accelerator/pkg/credit_pkg.sv
  vlog -quiet ../../accelerator/pkg/command_pkg.sv

  # compile rtl
  echo "Compiling RTL General"
  vlog -quiet ../../accelerator/rtl/parity.sv
  vlog -quiet ../../accelerator/rtl/reset_filter.sv
  vlog -quiet ../../accelerator/rtl/reset_control.sv
  vlog -quiet ../../accelerator/rtl/error_control.sv
  vlog -quiet ../../accelerator/rtl/ram.sv
  vlog -quiet ../../accelerator/rtl/fifo.sv
  vlog -quiet ../../accelerator/rtl/priority_arbiter.sv

  echo "Compiling RTL Command"
  vlog -quiet ../../accelerator/rtl/credit_control.sv
  vlog -quiet ../../accelerator/rtl/response_control.sv
  vlog -quiet ../../accelerator/rtl/command_control.sv
  vlog -quiet ../../accelerator/rtl/command_buffer_arbiter.sv
  vlog -quiet ../../accelerator/rtl/tag_control.sv
  vlog -quiet ../../accelerator/rtl/command.sv

  echo "Compiling RTL Job"
  vlog -quiet ../../accelerator/rtl/job.sv

  echo "Compiling RTL MMIO"
  vlog -quiet ../../accelerator/rtl/mmio.sv
  
  echo "Compiling RTL WED_control"
  vlog -quiet ../../accelerator/rtl/wed_control.sv
 
  # echo "Compiling Compute Unit"
  # vlog -quiet ../../accelerator/cu/cu.sv

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
  recompile
  simulate
}

# init libs
vlib work
vmap work work

# automatically recompile on first call
r
