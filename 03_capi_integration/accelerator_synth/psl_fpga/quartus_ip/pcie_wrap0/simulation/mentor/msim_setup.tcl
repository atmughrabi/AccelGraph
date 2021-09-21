
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

# ----------------------------------------
# Auto-generated simulation script msim_setup.tcl
# ----------------------------------------
# This script can be used to simulate the following IP:
#     pcie_wrap0
# To create a top-level simulation script which compiles other
# IP, and manages other system issues, copy the following template
# and adapt it to your needs:
# 
# # Start of template
# # If the copied and modified template file is "mentor.do", run it as:
# #   vsim -c -do mentor.do
# #
# # Source the generated sim script
# source msim_setup.tcl
# # Compile eda/sim_lib contents first
# dev_com
# # Override the top-level name (so that elab is useful)
# set TOP_LEVEL_NAME top
# # Compile the standalone IP.
# com
# # Compile the user top-level
# vlog -sv ../../top.sv
# # Elaborate the design.
# elab
# # Run the simulation
# run -a
# # Report success to the shell
# exit -code 0
# # End of template
# ----------------------------------------
# If pcie_wrap0 is one of several IP cores in your
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
# ACDS 15.1 185 linux 2015.11.06.12:44:30

# ----------------------------------------
# Initialize variables
if ![info exists SYSTEM_INSTANCE_NAME] { 
  set SYSTEM_INSTANCE_NAME ""
} elseif { ![ string match "" $SYSTEM_INSTANCE_NAME ] } { 
  set SYSTEM_INSTANCE_NAME "/$SYSTEM_INSTANCE_NAME"
}

if ![info exists TOP_LEVEL_NAME] { 
  set TOP_LEVEL_NAME "pcie_wrap0"
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

# ----------------------------------------
# Copy ROM/RAM files to simulation directory
alias file_copy {
  echo "\[exec\] file_copy"
}

# ----------------------------------------
# Create compilation libraries
proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib          ./libraries/     
ensure_lib          ./libraries/work/
vmap       work     ./libraries/work/
vmap       work_lib ./libraries/work/
if ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] {
  ensure_lib                       ./libraries/altera_ver/           
  vmap       altera_ver            ./libraries/altera_ver/           
  ensure_lib                       ./libraries/lpm_ver/              
  vmap       lpm_ver               ./libraries/lpm_ver/              
  ensure_lib                       ./libraries/sgate_ver/            
  vmap       sgate_ver             ./libraries/sgate_ver/            
  ensure_lib                       ./libraries/altera_mf_ver/        
  vmap       altera_mf_ver         ./libraries/altera_mf_ver/        
  ensure_lib                       ./libraries/altera_lnsim_ver/     
  vmap       altera_lnsim_ver      ./libraries/altera_lnsim_ver/     
  ensure_lib                       ./libraries/stratixv_ver/         
  vmap       stratixv_ver          ./libraries/stratixv_ver/         
  ensure_lib                       ./libraries/stratixv_hssi_ver/    
  vmap       stratixv_hssi_ver     ./libraries/stratixv_hssi_ver/    
  ensure_lib                       ./libraries/stratixv_pcie_hip_ver/
  vmap       stratixv_pcie_hip_ver ./libraries/stratixv_pcie_hip_ver/
  ensure_lib                       ./libraries/altera/               
  vmap       altera                ./libraries/altera/               
  ensure_lib                       ./libraries/lpm/                  
  vmap       lpm                   ./libraries/lpm/                  
  ensure_lib                       ./libraries/sgate/                
  vmap       sgate                 ./libraries/sgate/                
  ensure_lib                       ./libraries/altera_mf/            
  vmap       altera_mf             ./libraries/altera_mf/            
  ensure_lib                       ./libraries/altera_lnsim/         
  vmap       altera_lnsim          ./libraries/altera_lnsim/         
  ensure_lib                       ./libraries/stratixv/             
  vmap       stratixv              ./libraries/stratixv/             
  ensure_lib                       ./libraries/stratixv_hssi/        
  vmap       stratixv_hssi         ./libraries/stratixv_hssi/        
  ensure_lib                       ./libraries/stratixv_pcie_hip/    
  vmap       stratixv_pcie_hip     ./libraries/stratixv_pcie_hip/    
}
ensure_lib                        ./libraries/rst_controller/        
vmap       rst_controller         ./libraries/rst_controller/        
ensure_lib                        ./libraries/pcie_reconfig_driver_0/
vmap       pcie_reconfig_driver_0 ./libraries/pcie_reconfig_driver_0/
ensure_lib                        ./libraries/hip/                   
vmap       hip                    ./libraries/hip/                   
ensure_lib                        ./libraries/alt_xcvr_reconfig_0/   
vmap       alt_xcvr_reconfig_0    ./libraries/alt_xcvr_reconfig_0/   

# ----------------------------------------
# Compile device library files
alias dev_com {
  echo "\[exec\] dev_com"
  if ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] {
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                       -work altera_ver           
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                                -work lpm_ver              
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                                   -work sgate_ver            
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                               -work altera_mf_ver        
    eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/altera_lnsim_for_vhdl.sv"           -work altera_lnsim_ver     
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_atoms_ncrypt.v"            -work stratixv_ver         
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_atoms_for_vhdl.v"          -work stratixv_ver         
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_hssi_atoms_ncrypt.v"       -work stratixv_hssi_ver    
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_hssi_atoms_for_vhdl.v"     -work stratixv_hssi_ver    
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_pcie_hip_atoms_ncrypt.v"   -work stratixv_pcie_hip_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_pcie_hip_atoms_for_vhdl.v" -work stratixv_pcie_hip_ver
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_syn_attributes.vhd"                 -work altera               
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_standard_functions.vhd"             -work altera               
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/alt_dspbuilder_package.vhd"                -work altera               
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_europa_support_lib.vhd"             -work altera               
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives_components.vhd"          -work altera               
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.vhd"                     -work altera               
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220pack.vhd"                               -work lpm                  
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.vhd"                              -work lpm                  
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate_pack.vhd"                            -work sgate                
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.vhd"                                 -work sgate                
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf_components.vhd"                  -work altera_mf            
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.vhd"                             -work altera_mf            
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim_components.vhd"               -work altera_lnsim         
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_atoms.vhd"                        -work stratixv             
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_components.vhd"                   -work stratixv             
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_components.vhd"              -work stratixv_hssi        
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_atoms.vhd"                   -work stratixv_hssi        
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_components.vhd"          -work stratixv_pcie_hip    
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_atoms.vhd"               -work stratixv_pcie_hip    
  }
}

# ----------------------------------------
# Compile the design files in correct order
alias com {
  echo "\[exec\] com"
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altera_reset_controller.v"                      -work rst_controller        
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altera_reset_synchronizer.v"                    -work rst_controller        
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_h.sv"                                -work pcie_reconfig_driver_0
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altpcie_reconfig_driver.sv"                            -work pcie_reconfig_driver_0
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_sv_hip_ast_hwtcl.v"                     -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_hip_256_pipen1b.v"                      -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_rs_serdes.v"                            -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_rs_hip.v"                               -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_scfifo.v"                               -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_sv_scfifo_ext.v"                        -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_scfifo_sv.v"                            -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_sv_gbfifo.v"                            -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_tlp_inspector.v"                        -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_tlp_inspector_trigger.v"                -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_hip_eq_dprio.v"                         -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcie_hip_eq_bypass_ph3.v"                    -work hip                   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altpcietb_bfm_pipe_8to32.v"                     -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/altpcie_inspector.sv"                           -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/altpcie_monitor_sv_dlhip_sim.sv"                -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/altpcie_tlp_inspector_monitor.sv"               -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/altpcie_tlp_inspector_cseb.sv"                  -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_xcvr_functions.sv"                              -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/altera_xcvr_functions.sv"                       -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_pcs.sv"                                             -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_pcs_ch.sv"                                          -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_pma.sv"                                             -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_reconfig_bundle_to_xcvr.sv"                         -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_reconfig_bundle_to_ip.sv"                           -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_reconfig_bundle_merger.sv"                          -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_rx_pma.sv"                                          -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_tx_pma.sv"                                          -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_tx_pma_ch.sv"                                       -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_h.sv"                                          -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_avmm_csr.sv"                                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_avmm_dcd.sv"                                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_avmm.sv"                                       -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_data_adapter.sv"                               -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_native.sv"                                     -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_plls.sv"                                       -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_pcs.sv"                                      -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_pcs_ch.sv"                                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_pma.sv"                                      -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_reconfig_bundle_to_xcvr.sv"                  -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_reconfig_bundle_to_ip.sv"                    -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_reconfig_bundle_merger.sv"                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_rx_pma.sv"                                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_tx_pma.sv"                                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_tx_pma_ch.sv"                                -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_h.sv"                                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_avmm_csr.sv"                            -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_avmm_dcd.sv"                            -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_avmm.sv"                                -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_data_adapter.sv"                        -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_native.sv"                              -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_plls.sv"                                -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_resync.sv"                                    -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_resync.sv"                             -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_10g_rx_pcs_rbc.sv"                             -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_10g_tx_pcs_rbc.sv"                             -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_8g_rx_pcs_rbc.sv"                              -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_8g_tx_pcs_rbc.sv"                              -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_8g_pcs_aggregate_rbc.sv"                       -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_common_pcs_pma_interface_rbc.sv"               -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_common_pld_pcs_interface_rbc.sv"               -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_pipe_gen1_2_rbc.sv"                            -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_pipe_gen3_rbc.sv"                              -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_rx_pcs_pma_interface_rbc.sv"                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_rx_pld_pcs_interface_rbc.sv"                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_tx_pcs_pma_interface_rbc.sv"                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_hssi_tx_pld_pcs_interface_rbc.sv"                   -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_10g_rx_pcs_rbc.sv"                      -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_10g_tx_pcs_rbc.sv"                      -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_8g_rx_pcs_rbc.sv"                       -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_8g_tx_pcs_rbc.sv"                       -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_8g_pcs_aggregate_rbc.sv"                -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_common_pcs_pma_interface_rbc.sv"        -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_common_pld_pcs_interface_rbc.sv"        -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_pipe_gen1_2_rbc.sv"                     -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_pipe_gen3_rbc.sv"                       -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_rx_pcs_pma_interface_rbc.sv"            -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_rx_pld_pcs_interface_rbc.sv"            -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_tx_pcs_pma_interface_rbc.sv"            -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_hssi_tx_pld_pcs_interface_rbc.sv"            -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_emsip_adapter.sv"                              -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_pipe_native.sv"                                -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_emsip_adapter.sv"                       -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_pipe_native.sv"                         -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_h.sv"                         -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/altpcie_reconfig_driver.sv"                     -work hip                   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/altera_xcvr_functions.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/altera_xcvr_functions.sv"                       -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_h.sv"                                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_h.sv"                                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_resync.sv"                                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_resync.sv"                             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_h.sv"                                -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_h.sv"                         -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_dfe_cal_sweep_h.sv"                            -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_dfe_cal_sweep_h.sv"                     -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig.sv"                                  -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig.sv"                           -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_sv.sv"                               -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_sv.sv"                        -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_cal_seq.sv"                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_cal_seq.sv"                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xreconf_cif.sv"                                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xreconf_cif.sv"                             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xreconf_uif.sv"                                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xreconf_uif.sv"                             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xreconf_basic_acq.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xreconf_basic_acq.sv"                       -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_analog.sv"                           -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_analog.sv"                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_analog_sv.sv"                        -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_analog_sv.sv"                 -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xreconf_analog_datactrl.sv"                        -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xreconf_analog_datactrl.sv"                 -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xreconf_analog_rmw.sv"                             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xreconf_analog_rmw.sv"                      -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xreconf_analog_ctrlsm.sv"                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xreconf_analog_ctrlsm.sv"                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_offset_cancellation.sv"              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_offset_cancellation.sv"       -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_offset_cancellation_sv.sv"           -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_offset_cancellation_sv.sv"    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_eyemon.sv"                           -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_eyemon.sv"                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_eyemon_sv.sv"                        -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_eyemon_ctrl_sv.sv"                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_eyemon_ber_sv.sv"                    -work alt_xcvr_reconfig_0   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/ber_reader_dcfifo.v"                                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/step_to_mon_sv.sv"                                     -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mon_to_step_sv.sv"                                     -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_eyemon_sv.sv"                 -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_eyemon_ctrl_sv.sv"            -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_eyemon_ber_sv.sv"             -work alt_xcvr_reconfig_0   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/ber_reader_dcfifo.v"                            -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/step_to_mon_sv.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/mon_to_step_sv.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe.sv"                       -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_sv.sv"                           -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_reg_sv.sv"                       -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_cal_sv.sv"                       -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_cal_sweep_sv.sv"                 -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_cal_sweep_datapath_sv.sv"        -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_oc_cal_sv.sv"                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_pi_phase_sv.sv"                  -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_step_to_mon_en_sv.sv"            -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_adapt_tap_sv.sv"                 -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_ctrl_mux_sv.sv"                  -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_local_reset_sv.sv"               -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_cal_sim_sv.sv"                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dfe_adapt_tap_sim_sv.sv"             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_sv.sv"                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_reg_sv.sv"                -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sv.sv"                -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sweep_sv.sv"          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sweep_datapath_sv.sv" -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_oc_cal_sv.sv"             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_pi_phase_sv.sv"           -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_step_to_mon_en_sv.sv"     -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_adapt_tap_sv.sv"          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_ctrl_mux_sv.sv"           -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_local_reset_sv.sv"        -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sim_sv.sv"            -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dfe_adapt_tap_sim_sv.sv"      -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_adce.sv"                             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_adce.sv"                      -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_adce_sv.sv"                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_adce_datactrl_sv.sv"                 -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_adce_sv.sv"                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_adce_datactrl_sv.sv"          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dcd.sv"                       -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_sv.sv"                           -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_cal.sv"                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_control.sv"                      -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_datapath.sv"                     -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_pll_reset.sv"                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_eye_width.sv"                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_align_clk.sv"                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_get_sum.sv"                      -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_dcd_cal_sim_model.sv"                -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dcd_sv.sv"                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dcd_cal.sv"                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dcd_control.sv"               -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dcd_datapath.sv"              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dcd_pll_reset.sv"             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dcd_eye_width.sv"             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dcd_align_clk.sv"             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dcd_get_sum.sv"               -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_dcd_cal_sim_model.sv"         -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_mif.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_mif.sv"                       -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_mif.sv"                               -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_mif_ctrl.sv"                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_mif_avmm.sv"                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_reconfig_mif.sv"                        -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_reconfig_mif_ctrl.sv"                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_reconfig_mif_avmm.sv"                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_pll.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_pll.sv"                       -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_pll.sv"                               -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_pll_ctrl.sv"                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_reconfig_pll.sv"                        -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_reconfig_pll_ctrl.sv"                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_soc.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_cpu_ram.sv"                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_direct.sv"                           -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xrbasic_l2p_addr.sv"                                -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xrbasic_l2p_ch.sv"                                  -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xrbasic_l2p_rom.sv"                                 -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xrbasic_lif_csr.sv"                                 -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xrbasic_lif.sv"                                     -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_xcvr_reconfig_basic.sv"                             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_arbiter_acq.sv"                                    -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_reconfig_basic.sv"                            -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xrbasic_l2p_addr.sv"                         -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xrbasic_l2p_ch.sv"                           -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xrbasic_l2p_rom.sv"                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xrbasic_lif_csr.sv"                          -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xrbasic_lif.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_xcvr_reconfig_basic.sv"                      -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_arbiter_acq.sv"                             -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_reconfig_basic.sv"                     -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_arbiter.sv"                                   -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_m2s.sv"                                       -work alt_xcvr_reconfig_0   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/altera_wait_generate.v"                                -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/alt_xcvr_csr_selector.sv"                              -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_arbiter.sv"                            -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_m2s.sv"                                -work alt_xcvr_reconfig_0   
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/submodules/mentor/altera_wait_generate.v"                         -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/alt_xcvr_csr_selector.sv"                       -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/sv_reconfig_bundle_to_basic.sv"                        -work alt_xcvr_reconfig_0   
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/submodules/mentor/sv_reconfig_bundle_to_basic.sv"                 -work alt_xcvr_reconfig_0   
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/pcie_wrap0.vhd"                                                                               
}

# ----------------------------------------
# Elaborate top level design
alias elab {
  echo "\[exec\] elab"
  eval vsim -t ps $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS -L work -L work_lib -L rst_controller -L pcie_reconfig_driver_0 -L hip -L alt_xcvr_reconfig_0 -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L stratixv -L stratixv_hssi -L stratixv_pcie_hip $TOP_LEVEL_NAME
}

# ----------------------------------------
# Elaborate the top level design with novopt option
alias elab_debug {
  echo "\[exec\] elab_debug"
  eval vsim -novopt -t ps $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS -L work -L work_lib -L rst_controller -L pcie_reconfig_driver_0 -L hip -L alt_xcvr_reconfig_0 -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L stratixv -L stratixv_hssi -L stratixv_pcie_hip $TOP_LEVEL_NAME
}

# ----------------------------------------
# Compile all the design files and elaborate the top level design
alias ld "
  dev_com
  com
  elab
"

# ----------------------------------------
# Compile all the design files and elaborate the top level design with -novopt
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
  echo "elab_debug                    -- Elaborate the top level design with novopt option"
  echo
  echo "ld                            -- Compile all the design files and elaborate the top level design"
  echo
  echo "ld_debug                      -- Compile all the design files and elaborate the top level design with -novopt"
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
