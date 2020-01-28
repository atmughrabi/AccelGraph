
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

# ACDS 15.1 185 linux 2015.11.06.12:49:39

# ----------------------------------------
# ncsim - auto-generated simulation script

# ----------------------------------------
# This script can be used to simulate the following IP:
#     sfpp_phy
# To create a top-level simulation script which compiles other
# IP, and manages other system issues, copy the following template
# and adapt it to your needs:
# 
# # Start of template
# # If the copied and modified template file is "ncsim.sh", run it as:
# #   ./ncsim.sh
# #
# # Do the file copy, dev_com and com steps
# source ncsim_setup.sh \
# SKIP_ELAB=1 \
# SKIP_SIM=1
# 
# # Compile the top level module
# ncvlog -sv "$QSYS_SIMDIR/../top.sv"
# 
# # Do the elaboration and sim steps
# # Override the top-level name
# # Override the user-defined sim options, so the simulation
# # runs forever (until $finish()).
# source ncsim_setup.sh \
# SKIP_FILE_COPY=1 \
# SKIP_DEV_COM=1 \
# SKIP_COM=1 \
# TOP_LEVEL_NAME=top \
# USER_DEFINED_SIM_OPTIONS=""
# # End of template
# ----------------------------------------
# If sfpp_phy is one of several IP cores in your
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
# ACDS 15.1 185 linux 2015.11.06.12:49:39
# ----------------------------------------
# initialize variables
TOP_LEVEL_NAME="sfpp_phy"
QSYS_SIMDIR="./../"
QUARTUS_INSTALL_DIR="/gsa/rchgsa-p3/00/quartus15.1/quartus/"
SKIP_FILE_COPY=0
SKIP_DEV_COM=0
SKIP_COM=0
SKIP_ELAB=0
SKIP_SIM=0
USER_DEFINED_ELAB_OPTIONS=""
USER_DEFINED_SIM_OPTIONS="-input \"@run 100; exit\""

# ----------------------------------------
# overwrite variables - DO NOT MODIFY!
# This block evaluates each command line argument, typically used for 
# overwriting variables. An example usage:
#   sh <simulator>_setup.sh SKIP_ELAB=1 SKIP_SIM=1
for expression in "$@"; do
  eval $expression
  if [ $? -ne 0 ]; then
    echo "Error: This command line argument, \"$expression\", is/has an invalid expression." >&2
    exit $?
  fi
done

# ----------------------------------------
# initialize simulation properties - DO NOT MODIFY!
ELAB_OPTIONS=""
SIM_OPTIONS=""
if [[ `ncsim -version` != *"ncsim(64)"* ]]; then
  :
else
  :
fi

# ----------------------------------------
# create compilation libraries
mkdir -p ./libraries/work/
mkdir -p ./libraries/sfpp_phy/
mkdir -p ./libraries/altera_ver/
mkdir -p ./libraries/lpm_ver/
mkdir -p ./libraries/sgate_ver/
mkdir -p ./libraries/altera_mf_ver/
mkdir -p ./libraries/altera_lnsim_ver/
mkdir -p ./libraries/stratixv_ver/
mkdir -p ./libraries/stratixv_hssi_ver/
mkdir -p ./libraries/stratixv_pcie_hip_ver/
mkdir -p ./libraries/altera/
mkdir -p ./libraries/lpm/
mkdir -p ./libraries/sgate/
mkdir -p ./libraries/altera_mf/
mkdir -p ./libraries/altera_lnsim/
mkdir -p ./libraries/stratixv/
mkdir -p ./libraries/stratixv_hssi/
mkdir -p ./libraries/stratixv_pcie_hip/

# ----------------------------------------
# copy RAM/ROM files to simulation directory

# ----------------------------------------
# compile device library files
if [ $SKIP_DEV_COM -eq 0 ]; then
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                      -work altera_ver           
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                               -work lpm_ver              
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                                  -work sgate_ver            
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                              -work altera_mf_ver        
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                          -work altera_lnsim_ver     
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/cadence/stratixv_atoms_ncrypt.v"          -work stratixv_ver         
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_atoms.v"                         -work stratixv_ver         
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/cadence/stratixv_hssi_atoms_ncrypt.v"     -work stratixv_hssi_ver    
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_atoms.v"                    -work stratixv_hssi_ver    
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/cadence/stratixv_pcie_hip_atoms_ncrypt.v" -work stratixv_pcie_hip_ver
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_atoms.v"                -work stratixv_pcie_hip_ver
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_syn_attributes.vhd"                -work altera               
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_standard_functions.vhd"            -work altera               
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/alt_dspbuilder_package.vhd"               -work altera               
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_europa_support_lib.vhd"            -work altera               
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives_components.vhd"         -work altera               
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.vhd"                    -work altera               
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/220pack.vhd"                              -work lpm                  
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.vhd"                             -work lpm                  
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate_pack.vhd"                           -work sgate                
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.vhd"                                -work sgate                
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf_components.vhd"                 -work altera_mf            
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.vhd"                            -work altera_mf            
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim_components.vhd"              -work altera_lnsim         
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_atoms.vhd"                       -work stratixv             
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_components.vhd"                  -work stratixv             
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_components.vhd"             -work stratixv_hssi        
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_atoms.vhd"                  -work stratixv_hssi        
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_components.vhd"         -work stratixv_pcie_hip    
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_atoms.vhd"              -work stratixv_pcie_hip    
fi

# ----------------------------------------
# compile design files in correct order
if [ $SKIP_COM -eq 0 ]; then
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_functions.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_custom.sv"                   -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_custom_nr.sv"                    -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_custom_native.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_resync.sv"                      -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_common_h.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_common.sv"                  -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_pcs8g_h.sv"                 -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_pcs8g.sv"                   -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_selector.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_mgmt2dec.sv"                    -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_wait_generate.v"                  -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_pcs.sv"                               -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_pcs_ch.sv"                            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_pma.sv"                               -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_to_xcvr.sv"           -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_to_ip.sv"             -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_merger.sv"            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_rx_pma.sv"                            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_tx_pma.sv"                            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_tx_pma_ch.sv"                         -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_h.sv"                            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_avmm_csr.sv"                     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_avmm_dcd.sv"                     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_avmm.sv"                         -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_data_adapter.sv"                 -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_native.sv"                       -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_xcvr_plls.sv"                         -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_10g_rx_pcs_rbc.sv"               -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_10g_tx_pcs_rbc.sv"               -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_8g_rx_pcs_rbc.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_8g_tx_pcs_rbc.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_8g_pcs_aggregate_rbc.sv"         -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_common_pcs_pma_interface_rbc.sv" -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_common_pld_pcs_interface_rbc.sv" -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_pipe_gen1_2_rbc.sv"              -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_pipe_gen3_rbc.sv"                -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_rx_pcs_pma_interface_rbc.sv"     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_rx_pld_pcs_interface_rbc.sv"     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_tx_pcs_pma_interface_rbc.sv"     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_hssi_tx_pld_pcs_interface_rbc.sv"     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_reset_control.sv"            -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_reset_counter.sv"               -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_arbiter.sv"                     -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvlog -sv $USER_DEFINED_COMPILE_OPTIONS  "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_m2s.sv"                         -work sfpp_phy -cdslib ./cds_libs/sfpp_phy.cds.lib
  ncvhdl -v93 $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/sfpp_phy.vhd"                                                                                                     
fi

# ----------------------------------------
# elaborate top level design
if [ $SKIP_ELAB -eq 0 ]; then
  ncelab -access +w+r+c -namemap_mixgen -relax $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS $TOP_LEVEL_NAME
fi

# ----------------------------------------
# simulate
if [ $SKIP_SIM -eq 0 ]; then
  eval ncsim -licqueue $SIM_OPTIONS $USER_DEFINED_SIM_OPTIONS $TOP_LEVEL_NAME
fi
