# recompile
proc r  {} {

  # compile vhdl files

  # compile libs
  echo "Compiling libs"
  

  # compile packages
  echo "Compiling packages"
  vlog -quiet ../accelerator/rtl/capi_pkg.sv
  vlog -quiet ../accelerator/rtl/cu_pkg.sv

  # compile rtl
  echo "Compiling rtl"

  
  vlog -quiet ../accelerator/rtl/shift_register.sv
  vlog -quiet ../accelerator/rtl/cu.sv
  vlog -quiet ../accelerator/rtl/job.sv
  vlog -quiet ../accelerator/rtl/control.sv
  vlog -quiet ../accelerator/rtl/mmio.sv
  vlog -quiet ../accelerator/rtl/afu.sv
  vlog -quiet ../accelerator/rtl/parity_afu.sv

  # compile verilog files

  # compile top level
  echo "Compiling top level"
  # vlog -quiet       pslse/afu_driver/verilog/top.v
  vlog -quiet -sv +define+PSL8=PSL8 pslse/afu_driver/verilog/top.v

}

# simulate
proc s  {} {
  # vsim -t ns -novopt -c -pli pslse/afu_driver/src/veriuser.sl +nowarnTSCALE work.top
  vsim -t ns -novopt -c -sv_lib ./pslse/afu_driver/src/libdpi +nowarnTSCALE work.top
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
}

# shortcut for recompilation + simulation
proc rs {} {
  r
  s
}

# init libs
vlib work
vmap work work

# automatically recompile on first call
r
