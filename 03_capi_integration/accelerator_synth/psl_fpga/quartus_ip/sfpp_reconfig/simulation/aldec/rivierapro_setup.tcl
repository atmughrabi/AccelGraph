
# (C) 2001-2015 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and 
# other software and tools, and its AMPP partner logic functions, and 
# any output files any of the foregoing (including device programming 
# or simulation files), and any associated documentation or information 
# are expressly subject to the terms and conditions of the Altera 
# Program License Subscription Agreement, Altera MegaCore Function 
# License Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by Altera 
# or its authorized distributors. Please refer to the applicable 
# agreement for further details.

# ACDS 15.1 185 linux 2015.11.06.12:42:06
# ----------------------------------------
# Auto-generated simulation script rivierapro_setup.tcl
# ----------------------------------------
# This script can be used to simulate the following IP:
#     sfpp_reconfig
# To create a top-level simulation script which compiles other
# IP, and manages other system issues, copy the following template
# and adapt it to your needs:
# 
# # Start of template
# # If the copied and modified template file is "aldec.do", run it as:
# #   vsim -c -do aldec.do
# #
# # Source the generated sim script
# source rivierapro_setup.tcl
# # Compile eda/sim_lib contents first
# dev_com
# # Override the top-level name (so that elab is useful)
# set TOP_LEVEL_NAME top
# # Compile the standalone IP.
# com
# # Compile the user top-level
# vlog -sv2k5 ../../top.sv
# # Elaborate the design.
# elab
# # Run the simulation
# run
# # Report success to the shell
# exit -code 0
# # End of template
# ----------------------------------------
# If sfpp_reconfig is one of several IP cores in your
# Quartus project, you can generate a simulation script
# suitable for inclusion in your top-level simulation
# script by running the following command line:
# 
# ip-setup-simulation --quartus-project=<quartus project>
# 
# ip-setup-simulation will discover the Altera IP
# within the Quartus project, and generate a unified
# script which supports all the Altera IP within the design.
# ----------------------------------------

# ----------------------------------------
# Initialize variables
if ![info exists SYSTEM_INSTANCE_NAME] { 
  set SYSTEM_INSTANCE_NAME ""
} elseif { ![ string match "" $SYSTEM_INSTANCE_NAME ] } { 
  set SYSTEM_INSTANCE_NAME "/$SYSTEM_INSTANCE_NAME"
}

if ![info exists TOP_LEVEL_NAME] { 
  set TOP_LEVEL_NAME "sfpp_reconfig"
}

if ![info exists QSYS_SIMDIR] { 
  set QSYS_SIMDIR "./../"
}

if ![info exists QUARTUS_INSTALL_DIR] { 
  set QUARTUS_INSTALL_DIR "/gsa/rchgsa-p3/00/quartus15.1/quartus/"
}

if ![info exists USER_DEFINED_COMPILE_OPTIONS] { 
  set USER_DEFINED_COMPILE_OPTIONS ""
}
if ![info exists USER_DEFINED_ELAB_OPTIONS] { 
  set USER_DEFINED_ELAB_OPTIONS ""
}

# ----------------------------------------
# Initialize simulation properties - DO NOT MODIFY!
set ELAB_OPTIONS ""
set SIM_OPTIONS ""
if ![ string match "*-64 vsim*" [ vsim -version ] ] {
} else {
}

set Aldec "Riviera"
if { [ string match "*Active-HDL*" [ vsim -version ] ] } {
  set Aldec "Active"
}

if { [ string match "Active" $Aldec ] } {
  scripterconf -tcl
  createdesign "$TOP_LEVEL_NAME"  "."
  opendesign "$TOP_LEVEL_NAME"
}

# ----------------------------------------
# Copy ROM/RAM files to simulation directory
alias file_copy {
  echo "\[exec\] file_copy"
}

# ----------------------------------------
# Create compilation libraries
proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib      ./libraries     
ensure_lib      ./libraries/work
vmap       work ./libraries/work
ensure_lib                       ./libraries/altera_ver           
vmap       altera_ver            ./libraries/altera_ver           
ensure_lib                       ./libraries/lpm_ver              
vmap       lpm_ver               ./libraries/lpm_ver              
ensure_lib                       ./libraries/sgate_ver            
vmap       sgate_ver             ./libraries/sgate_ver            
ensure_lib                       ./libraries/altera_mf_ver        
vmap       altera_mf_ver         ./libraries/altera_mf_ver        
ensure_lib                       ./libraries/altera_lnsim_ver     
vmap       altera_lnsim_ver      ./libraries/altera_lnsim_ver     
ensure_lib                       ./libraries/stratixv_ver         
vmap       stratixv_ver          ./libraries/stratixv_ver         
ensure_lib                       ./libraries/stratixv_hssi_ver    
vmap       stratixv_hssi_ver     ./libraries/stratixv_hssi_ver    
ensure_lib                       ./libraries/stratixv_pcie_hip_ver
vmap       stratixv_pcie_hip_ver ./libraries/stratixv_pcie_hip_ver
ensure_lib                       ./libraries/altera               
vmap       altera                ./libraries/altera               
ensure_lib                       ./libraries/lpm                  
vmap       lpm                   ./libraries/lpm                  
ensure_lib                       ./libraries/sgate                
vmap       sgate                 ./libraries/sgate                
ensure_lib                       ./libraries/altera_mf            
vmap       altera_mf             ./libraries/altera_mf            
ensure_lib                       ./libraries/altera_lnsim         
vmap       altera_lnsim          ./libraries/altera_lnsim         
ensure_lib                       ./libraries/stratixv             
vmap       stratixv              ./libraries/stratixv             
ensure_lib                       ./libraries/stratixv_hssi        
vmap       stratixv_hssi         ./libraries/stratixv_hssi        
ensure_lib                       ./libraries/stratixv_pcie_hip    
vmap       stratixv_pcie_hip     ./libraries/stratixv_pcie_hip    
ensure_lib                                              ./libraries/alt_xcvr_reconfig_0_reconfig_mgmt_translator
vmap       alt_xcvr_reconfig_0_reconfig_mgmt_translator ./libraries/alt_xcvr_reconfig_0_reconfig_mgmt_translator
ensure_lib                                              ./libraries/master_0_master_translator                  
vmap       master_0_master_translator                   ./libraries/master_0_master_translator                  
ensure_lib                                              ./libraries/p2b_adapter                                 
vmap       p2b_adapter                                  ./libraries/p2b_adapter                                 
ensure_lib                                              ./libraries/b2p_adapter                                 
vmap       b2p_adapter                                  ./libraries/b2p_adapter                                 
ensure_lib                                              ./libraries/transacto                                   
vmap       transacto                                    ./libraries/transacto                                   
ensure_lib                                              ./libraries/p2b                                         
vmap       p2b                                          ./libraries/p2b                                         
ensure_lib                                              ./libraries/b2p                                         
vmap       b2p                                          ./libraries/b2p                                         
ensure_lib                                              ./libraries/fifo                                        
vmap       fifo                                         ./libraries/fifo                                        
ensure_lib                                              ./libraries/timing_adt                                  
vmap       timing_adt                                   ./libraries/timing_adt                                  
ensure_lib                                              ./libraries/jtag_phy_embedded_in_jtag_master            
vmap       jtag_phy_embedded_in_jtag_master             ./libraries/jtag_phy_embedded_in_jtag_master            
ensure_lib                                              ./libraries/rst_controller                              
vmap       rst_controller                               ./libraries/rst_controller                              
ensure_lib                                              ./libraries/mm_interconnect_0                           
vmap       mm_interconnect_0                            ./libraries/mm_interconnect_0                           
ensure_lib                                              ./libraries/master_0                                    
vmap       master_0                                     ./libraries/master_0                                    
ensure_lib                                              ./libraries/alt_xcvr_reconfig_0                         
vmap       alt_xcvr_reconfig_0                          ./libraries/alt_xcvr_reconfig_0                         

# ----------------------------------------
# Compile device library files
alias dev_com {
  echo "\[exec\] dev_com"
  eval vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                    -work altera_ver           
  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                             -work lpm_ver              
  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                                -work sgate_ver            
  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                            -work altera_mf_ver        
  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                        -work altera_lnsim_ver     
  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/aldec/stratixv_atoms_ncrypt.v"          -work stratixv_ver         
  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_atoms.v"                       -work stratixv_ver         
  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/aldec/stratixv_hssi_atoms_ncrypt.v"     -work stratixv_hssi_ver    
  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_atoms.v"                  -work stratixv_hssi_ver    
  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/aldec/stratixv_pcie_hip_atoms_ncrypt.v" -work stratixv_pcie_hip_ver
  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_atoms.v"              -work stratixv_pcie_hip_ver
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_syn_attributes.vhd"              -work altera               
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_standard_functions.vhd"          -work altera               
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/alt_dspbuilder_package.vhd"             -work altera               
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_europa_support_lib.vhd"          -work altera               
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives_components.vhd"       -work altera               
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.vhd"                  -work altera               
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/220pack.vhd"                            -work lpm                  
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.vhd"                           -work lpm                  
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate_pack.vhd"                         -work sgate                
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.vhd"                              -work sgate                
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf_components.vhd"               -work altera_mf            
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.vhd"                          -work altera_mf            
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim_components.vhd"            -work altera_lnsim         
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_atoms.vhd"                     -work stratixv             
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_components.vhd"                -work stratixv             
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_components.vhd"           -work stratixv_hssi        
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_atoms.vhd"                -work stratixv_hssi        
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_components.vhd"       -work stratixv_pcie_hip    
  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_atoms.vhd"            -work stratixv_pcie_hip    
}

# ----------------------------------------
# Compile the design files in correct order
alias com {
  echo "\[exec\] com"
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/aldec/altera_merlin_slave_translator.sv"        -work alt_xcvr_reconfig_0_reconfig_mgmt_translator
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/altera_merlin_master_translator.sv"             -work master_0_master_translator                  
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/submodules/sfpp_reconfig_master_0_p2b_adapter.vho"         -work p2b_adapter                                 
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/submodules/sfpp_reconfig_master_0_b2p_adapter.vho"         -work b2p_adapter                                 
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/submodules/sfpp_reconfig_master_0_transacto.vho"           -work transacto                                   
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/submodules/sfpp_reconfig_master_0_p2b.vho"                 -work p2b                                         
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/submodules/sfpp_reconfig_master_0_b2p.vho"                 -work b2p                                         
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/submodules/sfpp_reconfig_master_0_fifo.vho"                -work fifo                                        
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/submodules/sfpp_reconfig_master_0_timing_adt.vho"          -work timing_adt                                  
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_avalon_st_jtag_interface.v"              -work jtag_phy_embedded_in_jtag_master            
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_jtag_dc_streaming.v"                     -work jtag_phy_embedded_in_jtag_master            
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_jtag_sld_node.v"                         -work jtag_phy_embedded_in_jtag_master            
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_jtag_streaming.v"                        -work jtag_phy_embedded_in_jtag_master            
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_avalon_st_clock_crosser.v"               -work jtag_phy_embedded_in_jtag_master            
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_std_synchronizer_nocut.v"                -work jtag_phy_embedded_in_jtag_master            
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_avalon_st_pipeline_base.v"               -work jtag_phy_embedded_in_jtag_master            
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_avalon_st_idle_remover.v"                -work jtag_phy_embedded_in_jtag_master            
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_avalon_st_idle_inserter.v"               -work jtag_phy_embedded_in_jtag_master            
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/altera_avalon_st_pipeline_stage.sv"             -work jtag_phy_embedded_in_jtag_master            
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/aldec/altera_reset_controller.v"                -work rst_controller                              
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/aldec/altera_reset_synchronizer.v"              -work rst_controller                              
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/submodules/sfpp_reconfig_mm_interconnect_0.vhd"            -work mm_interconnect_0                           
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/submodules/sfpp_reconfig_master_0.vhd"                     -work master_0                                    
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/altera_xcvr_functions.sv"                       -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xcvr_h.sv"                                   -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_resync.sv"                             -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_h.sv"                         -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xcvr_dfe_cal_sweep_h.sv"                     -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig.sv"                           -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_sv.sv"                        -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_cal_seq.sv"                   -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xreconf_cif.sv"                             -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xreconf_uif.sv"                             -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xreconf_basic_acq.sv"                       -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_analog.sv"                    -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_analog_sv.sv"                 -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xreconf_analog_datactrl.sv"                 -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xreconf_analog_rmw.sv"                      -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xreconf_analog_ctrlsm.sv"                   -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_offset_cancellation.sv"       -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_offset_cancellation_sv.sv"    -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_eyemon.sv"                    -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_eyemon_sv.sv"                 -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_eyemon_ctrl_sv.sv"            -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_eyemon_ber_sv.sv"             -work alt_xcvr_reconfig_0                         
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/ber_reader_dcfifo.v"                            -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/step_to_mon_sv.sv"                              -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/mon_to_step_sv.sv"                              -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe.sv"                       -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_sv.sv"                    -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_reg_sv.sv"                -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_cal_sv.sv"                -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_cal_sweep_sv.sv"          -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_cal_sweep_datapath_sv.sv" -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_oc_cal_sv.sv"             -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_pi_phase_sv.sv"           -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_step_to_mon_en_sv.sv"     -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_adapt_tap_sv.sv"          -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_ctrl_mux_sv.sv"           -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_local_reset_sv.sv"        -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_cal_sim_sv.sv"            -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_adapt_tap_sim_sv.sv"      -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_adce.sv"                      -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_adce_sv.sv"                   -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_adce_datactrl_sv.sv"          -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd.sv"                       -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_sv.sv"                    -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_cal.sv"                   -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_control.sv"               -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_datapath.sv"              -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_pll_reset.sv"             -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_eye_width.sv"             -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_align_clk.sv"             -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_get_sum.sv"               -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_cal_sim_model.sv"         -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_mif.sv"                       -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_mif.sv"                        -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_mif_ctrl.sv"                   -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_mif_avmm.sv"                   -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_pll.sv"                       -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_pll.sv"                        -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_pll_ctrl.sv"                   -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_soc.sv"                       -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_cpu_ram.sv"                   -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_direct.sv"                    -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xrbasic_l2p_addr.sv"                         -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xrbasic_l2p_ch.sv"                           -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xrbasic_l2p_rom.sv"                          -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xrbasic_lif_csr.sv"                          -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xrbasic_lif.sv"                              -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_basic.sv"                      -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_arbiter_acq.sv"                             -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_basic.sv"                     -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_arbiter.sv"                            -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_m2s.sv"                                -work alt_xcvr_reconfig_0                         
  eval  vlog -v2k5 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_wait_generate.v"                         -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/alt_xcvr_csr_selector.sv"                       -work alt_xcvr_reconfig_0                         
  eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/submodules/sv_reconfig_bundle_to_basic.sv"                 -work alt_xcvr_reconfig_0                         
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/sfpp_reconfig.vhd"                                                                                           
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/sfpp_reconfig_rst_controller.vhd"                                                                            
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS       "$QSYS_SIMDIR/sfpp_reconfig_rst_controller_001.vhd"                                                                        
}

# ----------------------------------------
# Elaborate top level design
alias elab {
  echo "\[exec\] elab"
  eval vsim +access +r -t ps $ELAB_OPTIONS -L work -L alt_xcvr_reconfig_0_reconfig_mgmt_translator -L master_0_master_translator -L p2b_adapter -L b2p_adapter -L transacto -L p2b -L b2p -L fifo -L timing_adt -L jtag_phy_embedded_in_jtag_master -L rst_controller -L mm_interconnect_0 -L master_0 -L alt_xcvr_reconfig_0 -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L stratixv -L stratixv_hssi -L stratixv_pcie_hip $TOP_LEVEL_NAME
}

# ----------------------------------------
# Elaborate the top level design with -dbg -O2 option
alias elab_debug {
  echo "\[exec\] elab_debug"
  eval vsim -dbg -O2 +access +r -t ps $ELAB_OPTIONS -L work -L alt_xcvr_reconfig_0_reconfig_mgmt_translator -L master_0_master_translator -L p2b_adapter -L b2p_adapter -L transacto -L p2b -L b2p -L fifo -L timing_adt -L jtag_phy_embedded_in_jtag_master -L rst_controller -L mm_interconnect_0 -L master_0 -L alt_xcvr_reconfig_0 -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L stratixv -L stratixv_hssi -L stratixv_pcie_hip $TOP_LEVEL_NAME
}

# ----------------------------------------
# Compile all the design files and elaborate the top level design
alias ld "
  dev_com
  com
  elab
"

# ----------------------------------------
# Compile all the design files and elaborate the top level design with -dbg -O2
alias ld_debug "
  dev_com
  com
  elab_debug
"

# ----------------------------------------
# Print out user commmand line aliases
alias h {
  echo "List Of Command Line Aliases"
  echo
  echo "file_copy                     -- Copy ROM/RAM files to simulation directory"
  echo
  echo "dev_com                       -- Compile device library files"
  echo
  echo "com                           -- Compile the design files in correct order"
  echo
  echo "elab                          -- Elaborate top level design"
  echo
  echo "elab_debug                    -- Elaborate the top level design with -dbg -O2 option"
  echo
  echo "ld                            -- Compile all the design files and elaborate the top level design"
  echo
  echo "ld_debug                      -- Compile all the design files and elaborate the top level design with -dbg -O2"
  echo
  echo 
  echo
  echo "List Of Variables"
  echo
  echo "TOP_LEVEL_NAME                -- Top level module name."
  echo "                                 For most designs, this should be overridden"
  echo "                                 to enable the elab/elab_debug aliases."
  echo
  echo "SYSTEM_INSTANCE_NAME          -- Instantiated system module name inside top level module."
  echo
  echo "QSYS_SIMDIR                   -- Qsys base simulation directory."
  echo
  echo "QUARTUS_INSTALL_DIR           -- Quartus installation directory."
  echo
  echo "USER_DEFINED_COMPILE_OPTIONS  -- User-defined compile options, added to com/dev_com aliases."
  echo
  echo "USER_DEFINED_ELAB_OPTIONS     -- User-defined elaboration options, added to elab/elab_debug aliases."
}
file_copy
h
