# -------------------------------------------------------------------------- #
# Design Files                                                               #
# -------------------------------------------------------------------------- #

set_global_assignment -name QIP_FILE  $PSL_FPGA/quartus_ip/sfpp_reconfig/synthesis/sfpp_reconfig.qip
set_global_assignment -name VHDL_FILE $PSL_FPGA/quartus_ip/crcblock/psl_svcrc.vhd
set_global_assignment -name QIP_FILE  $PSL_FPGA/quartus_ip/mac36x36/psl_mac36x36.qip
set_global_assignment -name QIP_FILE  $PSL_FPGA/quartus_ip/gpios/psl_gpo.qip
set_global_assignment -name QIP_FILE  $PSL_FPGA/quartus_ip/gpios/psl_gpi.qip
set_global_assignment -name QIP_FILE  $PSL_FPGA/quartus_ip/gpios/psl_gpio.qip
set_global_assignment -name QIP_FILE  $PSL_FPGA/quartus_ip/pcie_wrap0/synthesis/pcie_wrap0.qip
set_global_assignment -name QIP_FILE  $PSL_FPGA/quartus_ip/clkcntl/psl_clkcntl.qip
set_global_assignment -name QIP_FILE  $PSL_FPGA/quartus_ip/sfpp/sfpp_phy.qip

set_global_assignment -name SDC_FILE $PSL_FPGA/psl/psl.sdc
set_global_assignment -name QIP_FILE $PSL_FPGA/psl/psl.qip

#set_global_assignment -name QIP_FILE $PSL_FPGA/afu0/afu0.qip
set_global_assignment -name VHDL_FILE $PSL_FPGA/afu0/psl_accel.vhdl


