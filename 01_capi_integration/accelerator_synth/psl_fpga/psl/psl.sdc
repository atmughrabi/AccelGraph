unset -nocomplain ram_list ram_addr_list ram_addr_list_we ram_datain_list_we ram_we_reg ram_mlab half_rate_all half_regs ram_mlab_addr_regs half_ins half_outs
unset -nocomplain allflashio pflio flashio flashdatout flashoutputs 


set dssspins [get_pins -compatibility_mode *p|ct|ds|dff_ss*|dout*|q*]
set dsssspins [get_pins -compatibility_mode *p|ct|ds|*|dff_ss|dout*|q*]

set sspins [add_to_collection $dssspins $dsssspins]

#foreach sspin [query_collection -all -report_format $sspins] {
#  puts "sspin $sspin"
#}

set half_rate_regs [get_fanouts $sspins  -through [get_pins -hierarchical *|*ena*] ]

# multicycle paths M20K
#set half_rate_rams [get_fanouts $sspins -through [get_pins -hierarchical *|*portbre*] ]
#set half_rate_rams_we [get_fanouts $sspins -through [get_pins -hierarchical *|*portawe*] ]

set ss_rd_mlab [get_keepers *:ss_rd_ram|*]
set ss_rw_mlab [get_keepers *:ss_rw_ram|*]
set ss_wr_mlab [get_keepers *:ss_wr_ram|*]


#foreach it [query_collection -all -report_format $half_rate_regs] {
#	puts "regs $it to halfs"
#	lappend halfs  $it
#}
# There is no need to do this first add_to_collection, since half_rate_regs is already a collection

# ss_rd
#foreach it [query_collection -all -report_format $ss_rd_mlab] {
#	puts "ss_rd_mlab $it to halfs"
#	lappend halfs $it
#}
set halfs [add_to_collection $half_rate_regs $ss_rd_mlab]

# ss_rw
#foreach it [query_collection -all -report_format $ss_rw_mlab] {
#	puts "ss_rw_mlab_rdo $it to halfs"
#	lappend halfs $it
#}
set halfs [add_to_collection $halfs $ss_rw_mlab]

# ss_wr
#foreach it [query_collection -all -report_format $ss_wr_mlab] {
#	puts "ss_wr_mlab_wen $it to half"
#	lappend halfs $it
#}
#rts set halfs [add_to_collection $halfs $ss_wr_mlab]


# set multicycle path from any of these registers/ram to each other
set_multicycle_path -setup 2 -from $halfs -to $halfs
set_multicycle_path -hold  1 -from $halfs -to $halfs

set_false_path -from {psl_clkcontrol:cc|psl_rise_vdff:ccnt|dout[0]} -to {psl_clkcontrol:cc|psl_clkcntl:cctrl|psl_clkcntl_altclkctrl_fph:psl_clkcntl_altclkctrl_fph_component|sd1~FF_0}

######################################################################
# HIP Soft reset controller SDC constraints
set_false_path -to   [get_registers *altpcie_rs_serdes|fifo_err_sync_r[0]]

# HIP testin pins SDC constraints
set_false_path -from [get_pins -compatibility_mode *hip_ctrl*]

######################################################################
# Configuraiton Clock
#create_clock -period "100 MHz" -name {conf_clk} {*i_conf_clk*}
#create_clock -period "100 MHz" -name {virt_conf_clk}
 
# Constraints required for the Hard IP for PCI Express
# derive_pll_clock is used to calculate all clock derived from PCIe refclk
# the derive_pll_clocks and derive clock_uncertainty should only be applied
# once across all of the SDC files used in a project
derive_pll_clocks -create_base_clocks
derive_clock_uncertainty
##############################################################################
# PHY IP reconfig controller constraints
# Set reconfig_xcvr clock
# this line will likely need to be modified to match the actual clock pin name
# used for this clock, and also changed to have the correct period set for the actually
# used clock
create_clock -period "100 MHz" -name {pci_pi_refclk0} {*pci_pi_refclk0*}

set_clock_groups -exclusive -group [get_clocks {pci_pi_refclk0}] -group [get_clocks {pcihip0|p|hip|altpcie_hip_256_pipen1b|stratixv_hssi_gen3_pcie_hip|coreclkout}]
#set_clock_groups -asynchronous -group [get_clocks {pcihip0|p|hip|altpcie_hip_256_pipen1b|stratixv_hssi_gen3_pcie_hip|coreclkout}] -group [get_clocks {conf_clk}]

######################################################################
# HIP Soft reset controller SDC constraints
set_false_path -to    [get_registers *altpcie_rs_serdes|fifo_err_sync_r[0]]
set_false_path -from [get_registers *sv_xcvr_pipe_native*] -to [get_registers *altpcie_rs_serdes|*]
######################################################################
# Flash I/O Ports

set allflashio [get_ports *flash*]
set pflio [get_ports *pfl_flash*]
set flashio [remove_from_collection $allflashio $pflio]
set flashdatout [get_pins -compatibility_mode *fdq*\|psl_gpio*\|obuf*\|o*]
set flashoutputs [get_pins -compatibility_mode *f*\|psl_gpo*\|obuf*\|o*]

set_max_skew -to $flashio 3
set_max_skew -from $flashio 3
set_max_skew -to $flashdatout 3
set_max_skew -to $flashoutputs 3

set_max_delay -from $flashio -to [get_registers *] 12
set_max_delay -from [get_registers *] -to $flashio 12
set_max_delay -from [get_registers *] -to $flashoutputs 12

######################################################################
# Soft Reconfiguraiton Signals

#set_output_delay -clock { virt_conf_clk } -max 2 [get_ports {o_cpld_softreconfigreq b_cpld_usergolden}]
#set_output_delay -clock { conf_clk } -min 0 [get_ports {o_cpld_softreconfigreq b_cpld_usergolden}]
set_max_skew -to [get_ports {o_cpld_softreconfigreq b_cpld_usergolden}] 3
