# (C) 2001-2015 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License Subscription 
# Agreement, Altera MegaCore Function License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


#####################################################################
#
# altera_pcie_sv_hip_ast SDC Contraint
#
######################################################################
#
# Constraints for asynchronous logic
#
set_false_path -from [ get_pins -compatibility {*stratixv_hssi_gen3_pcie_hip|testinhip[*]}]
set_false_path -from [ get_pins -compatibility {*stratixv_hssi_gen3_pcie_hip|testin1hip[*]}]

#####################################################################
#
# altera_pcie_sv_hip_ast SDC Contraint
#
######################################################################
#
# Skip if inspector is not enabled to suppress warnings
#

if {[get_collection_size [ get_registers {*lmi_dout_r*} ]] > 0} {
  create_clock -period "50 MHz"  -name {insp_clk} {*|altpcie_hip_256_pipen1b:altpcie_hip_256_pipen1b|insp_clk*}

  # For path crossing clock domains (pld_clk -> insp_clk)
  set_false_path -from [ get_registers {*lmi_dout_r[*]} ]  -to [ get_registers {*lmi_dout_rr[*]} ]
  set_false_path -from [ get_registers {*lmi_ack_sync} ] -to [ get_registers {*lmi_ack_sync_r} ]

  # For path crossing clock domains (insp_clk -> pld_clk)
  set_false_path -to [ get_registers {*lmi_addr_r[*]} ]
  set_false_path -to [ get_registers {*lmi_rden_r} ]

  # For DCFIFO rdclk recovery violation
  set_false_path -from [ get_registers {*altpcie_hip_256_pipen1b|arst_r[2]} ] -to [get_registers {*altpcie_inspector*ltssm_fifo*} ]
}
