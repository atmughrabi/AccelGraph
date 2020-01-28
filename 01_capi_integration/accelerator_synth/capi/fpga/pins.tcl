# -------------------------------------------------------------------------- #
# Pin Locations and Definitions                                              #
# -------------------------------------------------------------------------- #
#
#####################################
# General reference clocks          #
#####################################


set_instance_assignment -name IO_STANDARD "DIFFERENTIAL LVPECL" -to i_refclk_svc
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL LVPECL" -to i_refclk_app
#####################################
# Configuration Clock               #
#####################################
set_location_assignment PIN_B29 -to i_conf_clk

#####################################
# PCI-E x8 Interface                #
#####################################
set_location_assignment PIN_W29 -to pci_pi_refclk0
set_location_assignment PIN_W30 -to "pci_pi_refclk0(n)"
set_location_assignment PIN_W26 -to pci_pi_nperst0

set_location_assignment PIN_AL33 -to pci0_i_rx_in0
set_location_assignment PIN_AL34 -to "pci0_i_rx_in0(n)"
set_location_assignment PIN_AJ33 -to pci0_i_rx_in1
set_location_assignment PIN_AJ34 -to "pci0_i_rx_in1(n)"
set_location_assignment PIN_AG33 -to pci0_i_rx_in2
set_location_assignment PIN_AG34 -to "pci0_i_rx_in2(n)"
set_location_assignment PIN_AE33 -to pci0_i_rx_in3
set_location_assignment PIN_AE34 -to "pci0_i_rx_in3(n)"
set_location_assignment PIN_AA33 -to pci0_i_rx_in4
set_location_assignment PIN_AA34 -to "pci0_i_rx_in4(n)"
set_location_assignment PIN_W33 -to pci0_i_rx_in5
set_location_assignment PIN_W34 -to "pci0_i_rx_in5(n)"
set_location_assignment PIN_U33 -to pci0_i_rx_in6
set_location_assignment PIN_U34 -to "pci0_i_rx_in6(n)"
set_location_assignment PIN_R33 -to pci0_i_rx_in7
set_location_assignment PIN_R34 -to "pci0_i_rx_in7(n)"

set_location_assignment PIN_AK31 -to pci0_o_tx_out0
set_location_assignment PIN_AK32 -to "pci0_o_tx_out0(n)"
set_location_assignment PIN_AH31 -to pci0_o_tx_out1
set_location_assignment PIN_AH32 -to "pci0_o_tx_out1(n)"
set_location_assignment PIN_AF31 -to pci0_o_tx_out2
set_location_assignment PIN_AF32 -to "pci0_o_tx_out2(n)"
set_location_assignment PIN_AD31 -to pci0_o_tx_out3
set_location_assignment PIN_AD32 -to "pci0_o_tx_out3(n)"
set_location_assignment PIN_Y31 -to pci0_o_tx_out4
set_location_assignment PIN_Y32 -to "pci0_o_tx_out4(n)"
set_location_assignment PIN_V31 -to pci0_o_tx_out5
set_location_assignment PIN_V32 -to "pci0_o_tx_out5(n)"
set_location_assignment PIN_T31 -to pci0_o_tx_out6
set_location_assignment PIN_T32 -to "pci0_o_tx_out6(n)"
set_location_assignment PIN_P31 -to pci0_o_tx_out7
set_location_assignment PIN_P32 -to "pci0_o_tx_out7(n)"

set_instance_assignment -name IO_STANDARD HCSL -to pci_pi_refclk0
set_instance_assignment -name IO_STANDARD "2.5-V" -to pci_pi_nperst0


set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_i_rx_in0
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_i_rx_in1
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_i_rx_in2
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_i_rx_in3
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_i_rx_in4
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_i_rx_in5
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_i_rx_in6
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_i_rx_in7

set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_o_tx_out0
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_o_tx_out1
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_o_tx_out2
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_o_tx_out3
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_o_tx_out4
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_o_tx_out5
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_o_tx_out6
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to pci0_o_tx_out7

set_instance_assignment -name XCVR_RX_COMMON_MODE_VOLTAGE VTT_0P70V -to pci0_i_rx_in0
set_instance_assignment -name XCVR_VCCA_VOLTAGE 3_0V -to pci0_i_rx_in0
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 1_0V -to pci0_i_rx_in0
set_instance_assignment -name XCVR_RX_COMMON_MODE_VOLTAGE VTT_0P70V -to pci0_i_rx_in1
set_instance_assignment -name XCVR_VCCA_VOLTAGE 3_0V -to pci0_i_rx_in1
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 1_0V -to pci0_i_rx_in1
set_instance_assignment -name XCVR_RX_COMMON_MODE_VOLTAGE VTT_0P70V -to pci0_i_rx_in2
set_instance_assignment -name XCVR_VCCA_VOLTAGE 3_0V -to pci0_i_rx_in2
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 1_0V -to pci0_i_rx_in2
set_instance_assignment -name XCVR_RX_COMMON_MODE_VOLTAGE VTT_0P70V -to pci0_i_rx_in3
set_instance_assignment -name XCVR_VCCA_VOLTAGE 3_0V -to pci0_i_rx_in3
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 1_0V -to pci0_i_rx_in3
set_instance_assignment -name XCVR_RX_COMMON_MODE_VOLTAGE VTT_0P70V -to pci0_i_rx_in4
set_instance_assignment -name XCVR_VCCA_VOLTAGE 3_0V -to pci0_i_rx_in4
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 1_0V -to pci0_i_rx_in4
set_instance_assignment -name XCVR_RX_COMMON_MODE_VOLTAGE VTT_0P70V -to pci0_i_rx_in5
set_instance_assignment -name XCVR_VCCA_VOLTAGE 3_0V -to pci0_i_rx_in5
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 1_0V -to pci0_i_rx_in5
set_instance_assignment -name XCVR_RX_COMMON_MODE_VOLTAGE VTT_0P70V -to pci0_i_rx_in6
set_instance_assignment -name XCVR_VCCA_VOLTAGE 3_0V -to pci0_i_rx_in6
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 1_0V -to pci0_i_rx_in6
set_instance_assignment -name XCVR_RX_COMMON_MODE_VOLTAGE VTT_0P70V -to pci0_i_rx_in7
set_instance_assignment -name XCVR_VCCA_VOLTAGE 3_0V -to pci0_i_rx_in7
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 1_0V -to pci0_i_rx_in7

#####################################
# DDR3 Memory Bank 0 Pins           #
#####################################

set_location_assignment PIN_AF16 -to i_refclk_dram0
set_location_assignment PIN_AF17 -to "i_refclk_dram0(n)"
set_location_assignment PIN_AM6 -to i_dram0_rzq

set_location_assignment PIN_R10 -to b_dram0_mem_dqs[0]
set_location_assignment PIN_T10 -to b_dram0_mem_dqsn[0]
set_location_assignment PIN_AA8 -to o_dram0_mem_dm[0]
set_location_assignment PIN_W9 -to b_dram0_mem_dq[0]
set_location_assignment PIN_Y9 -to b_dram0_mem_dq[1]
set_location_assignment PIN_V10 -to b_dram0_mem_dq[2]
set_location_assignment PIN_AC9 -to b_dram0_mem_dq[3]
set_location_assignment PIN_W10 -to b_dram0_mem_dq[4]
set_location_assignment PIN_AB9 -to b_dram0_mem_dq[5]
set_location_assignment PIN_U9 -to b_dram0_mem_dq[6]
set_location_assignment PIN_AA9 -to b_dram0_mem_dq[7]

set_location_assignment PIN_V11 -to b_dram0_mem_dqs[1]
set_location_assignment PIN_W11 -to b_dram0_mem_dqsn[1]
set_location_assignment PIN_AB11 -to o_dram0_mem_dm[1]
set_location_assignment PIN_Y10 -to b_dram0_mem_dq[8]
set_location_assignment PIN_AB10 -to b_dram0_mem_dq[9]
set_location_assignment PIN_U11 -to b_dram0_mem_dq[10]
set_location_assignment PIN_AE11 -to b_dram0_mem_dq[11]
set_location_assignment PIN_Y11 -to b_dram0_mem_dq[12]
set_location_assignment PIN_AD11 -to b_dram0_mem_dq[13]
set_location_assignment PIN_U10 -to b_dram0_mem_dq[14]
set_location_assignment PIN_AC11 -to b_dram0_mem_dq[15]

set_location_assignment PIN_AE8 -to b_dram0_mem_dqs[2]
set_location_assignment PIN_AF8 -to b_dram0_mem_dqsn[2]
set_location_assignment PIN_AH11 -to o_dram0_mem_dm[2]
set_location_assignment PIN_AG9 -to b_dram0_mem_dq[16]
set_location_assignment PIN_AH8 -to b_dram0_mem_dq[17]
set_location_assignment PIN_AF10 -to b_dram0_mem_dq[18]
set_location_assignment PIN_AJ8 -to b_dram0_mem_dq[19]
set_location_assignment PIN_AH10 -to b_dram0_mem_dq[20]
set_location_assignment PIN_AJ11 -to b_dram0_mem_dq[21]
set_location_assignment PIN_AF9 -to b_dram0_mem_dq[22]
set_location_assignment PIN_AH9 -to b_dram0_mem_dq[23]

set_location_assignment PIN_AL10 -to b_dram0_mem_dqs[3]
set_location_assignment PIN_AM10 -to b_dram0_mem_dqsn[3]
set_location_assignment PIN_AP10 -to o_dram0_mem_dm[3]
set_location_assignment PIN_AN9 -to b_dram0_mem_dq[24]
set_location_assignment PIN_AM11 -to b_dram0_mem_dq[25]
set_location_assignment PIN_AK9 -to b_dram0_mem_dq[26]
set_location_assignment PIN_AK10 -to b_dram0_mem_dq[27]
set_location_assignment PIN_AN10 -to b_dram0_mem_dq[28]
set_location_assignment PIN_AL11 -to b_dram0_mem_dq[29]
set_location_assignment PIN_AJ9 -to b_dram0_mem_dq[30]
set_location_assignment PIN_AK11 -to b_dram0_mem_dq[31]

set_location_assignment PIN_AG12 -to b_dram0_mem_dqs[4]
set_location_assignment PIN_AF11 -to b_dram0_mem_dqsn[4]
set_location_assignment PIN_AJ12 -to o_dram0_mem_dm[4]
set_location_assignment PIN_AH14 -to b_dram0_mem_dq[32]
set_location_assignment PIN_AH13 -to b_dram0_mem_dq[33]
set_location_assignment PIN_AH15 -to b_dram0_mem_dq[34]
set_location_assignment PIN_AF14 -to b_dram0_mem_dq[35]
set_location_assignment PIN_AF12 -to b_dram0_mem_dq[36]
set_location_assignment PIN_AF13 -to b_dram0_mem_dq[37]
set_location_assignment PIN_AF15 -to b_dram0_mem_dq[38]
set_location_assignment PIN_AG13 -to b_dram0_mem_dq[39]

set_location_assignment PIN_AA13 -to b_dram0_mem_dqs[5]
set_location_assignment PIN_AB13 -to b_dram0_mem_dqsn[5]
set_location_assignment PIN_AB12 -to o_dram0_mem_dm[5]
set_location_assignment PIN_AC12 -to b_dram0_mem_dq[40]
set_location_assignment PIN_AA12 -to b_dram0_mem_dq[41]
set_location_assignment PIN_AE13 -to b_dram0_mem_dq[42]
set_location_assignment PIN_Y12 -to b_dram0_mem_dq[43]
set_location_assignment PIN_AD12 -to b_dram0_mem_dq[44]
set_location_assignment PIN_U13 -to b_dram0_mem_dq[45]
set_location_assignment PIN_AE14 -to b_dram0_mem_dq[46]
set_location_assignment PIN_W12 -to b_dram0_mem_dq[47]

set_location_assignment PIN_AL13 -to b_dram0_mem_dqs[6]
set_location_assignment PIN_AM13 -to b_dram0_mem_dqsn[6]
set_location_assignment PIN_AN12 -to o_dram0_mem_dm[6]
set_location_assignment PIN_AP13 -to b_dram0_mem_dq[48]
set_location_assignment PIN_AP12 -to b_dram0_mem_dq[49]
set_location_assignment PIN_AL14 -to b_dram0_mem_dq[50]
set_location_assignment PIN_AK12 -to b_dram0_mem_dq[51]
set_location_assignment PIN_AK14 -to b_dram0_mem_dq[52]
set_location_assignment PIN_AK13 -to b_dram0_mem_dq[53]
set_location_assignment PIN_AM14 -to b_dram0_mem_dq[54]
set_location_assignment PIN_AN13 -to b_dram0_mem_dq[55]

set_location_assignment PIN_AA14 -to b_dram0_mem_dqs[7]
set_location_assignment PIN_AB14 -to b_dram0_mem_dqsn[7]
set_location_assignment PIN_AC14 -to o_dram0_mem_dm[7]
set_location_assignment PIN_W14 -to b_dram0_mem_dq[56]
set_location_assignment PIN_AD15 -to b_dram0_mem_dq[57]
set_location_assignment PIN_Y14 -to b_dram0_mem_dq[58]
set_location_assignment PIN_W13 -to b_dram0_mem_dq[59]
set_location_assignment PIN_AB15 -to b_dram0_mem_dq[60]
set_location_assignment PIN_AD14 -to b_dram0_mem_dq[61]
set_location_assignment PIN_AA15 -to b_dram0_mem_dq[62]
set_location_assignment PIN_AC15 -to b_dram0_mem_dq[63]

set_location_assignment PIN_AM16 -to b_dram0_mem_dqs[8]
set_location_assignment PIN_AL16 -to b_dram0_mem_dqsn[8]
set_location_assignment PIN_AJ15 -to o_dram0_mem_dm[8]
set_location_assignment PIN_AK15 -to b_dram0_mem_dq[64]
set_location_assignment PIN_AK16 -to b_dram0_mem_dq[65]
set_location_assignment PIN_AN15 -to b_dram0_mem_dq[66]
set_location_assignment PIN_AJ17 -to b_dram0_mem_dq[67]
set_location_assignment PIN_AN16 -to b_dram0_mem_dq[68]
set_location_assignment PIN_AH17 -to b_dram0_mem_dq[69]
set_location_assignment PIN_AP15 -to b_dram0_mem_dq[70]
set_location_assignment PIN_AP16 -to b_dram0_mem_dq[71]

set_location_assignment PIN_AH20 -to o_dram0_mem_a[0]
set_location_assignment PIN_AL22 -to o_dram0_mem_a[1]
set_location_assignment PIN_AK20 -to o_dram0_mem_a[2]
set_location_assignment PIN_AF23 -to o_dram0_mem_a[3]
set_location_assignment PIN_AK22 -to o_dram0_mem_a[4]
set_location_assignment PIN_AG21 -to o_dram0_mem_a[5]
set_location_assignment PIN_AD23 -to o_dram0_mem_a[6]
set_location_assignment PIN_AC23 -to o_dram0_mem_a[7]
set_location_assignment PIN_AN22 -to o_dram0_mem_a[8]
set_location_assignment PIN_AJ20 -to o_dram0_mem_a[9]
set_location_assignment PIN_AM20 -to o_dram0_mem_a[10]
set_location_assignment PIN_AM22 -to o_dram0_mem_a[11]
set_location_assignment PIN_AK21 -to o_dram0_mem_a[12]
set_location_assignment PIN_AJ21 -to o_dram0_mem_a[13]
set_location_assignment PIN_AP22 -to o_dram0_mem_a[14]
set_location_assignment PIN_AH21 -to o_dram0_mem_a[15]

set_location_assignment PIN_AH23 -to o_dram0_mem_ba[0]
set_location_assignment PIN_AF21 -to o_dram0_mem_ba[1]
set_location_assignment PIN_AF20 -to o_dram0_mem_ba[2]

set_location_assignment PIN_AN21 -to o_dram0_mem_ck
set_location_assignment PIN_AP21 -to o_dram0_mem_ck_n

set_location_assignment PIN_AG22 -to o_dram0_mem_cs_n[0]
set_location_assignment PIN_AH22 -to o_dram0_mem_cs_n[1]
set_location_assignment PIN_AE22 -to o_dram0_mem_cke[0]
set_location_assignment PIN_AE20 -to o_dram0_mem_cke[1]
set_location_assignment PIN_AF22 -to o_dram0_mem_odt[0]
set_location_assignment PIN_AD20 -to o_dram0_mem_odt[1]
set_location_assignment PIN_AM19 -to o_dram0_mem_ras_n
set_location_assignment PIN_AN19 -to o_dram0_mem_cas_n
set_location_assignment PIN_AP19 -to o_dram0_mem_we_n
set_location_assignment PIN_AE23 -to o_dram0_mem_reset_n


set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[0]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[2]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[3]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[4]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[5]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[6]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[7]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[8]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[9]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[10]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[11]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[12]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[13]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[14]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[15]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[16]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[17]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[18]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[19]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[20]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[21]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[22]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[23]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[24]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[25]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[26]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[27]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[28]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[29]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[30]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[31]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[32]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[33]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[34]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[35]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[36]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[37]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[38]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[39]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[40]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[41]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[42]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[43]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[44]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[45]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[46]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[47]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[48]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[49]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[50]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[51]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[52]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[53]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[54]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[55]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[56]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[57]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[58]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[59]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[60]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[61]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[62]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[63]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[64]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[65]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[66]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[67]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[68]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[69]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[70]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dq[71]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqs[0]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqs[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqs[2]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqs[3]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqs[4]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqs[5]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqs[6]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqs[7]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqs[8]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqsn[0]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqsn[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqsn[2]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqsn[3]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqsn[4]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqsn[5]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqsn[6]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqsn[7]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_dram0_mem_dqsn[8]

#####################################
# DDR3 Memory Bank 0 Pins           #
#####################################

set_location_assignment PIN_H19 -to i_refclk_dram1
set_location_assignment PIN_G19 -to "i_refclk_dram1(n)"
set_location_assignment PIN_F3 -to i_dram1_rzq

set_location_assignment PIN_N12 -to b_dram1_mem_dqs[0]
set_location_assignment PIN_N13 -to b_dram1_mem_dqsn[0]
set_location_assignment PIN_K12 -to o_dram1_mem_dm[0]
set_location_assignment PIN_L11 -to b_dram1_mem_dq[0]
set_location_assignment PIN_L12 -to b_dram1_mem_dq[1]
set_location_assignment PIN_H11 -to b_dram1_mem_dq[2]
set_location_assignment PIN_P11 -to b_dram1_mem_dq[3]
set_location_assignment PIN_J12 -to b_dram1_mem_dq[4]
set_location_assignment PIN_M12 -to b_dram1_mem_dq[5]
set_location_assignment PIN_G12 -to b_dram1_mem_dq[6]
set_location_assignment PIN_N11 -to b_dram1_mem_dq[7]

set_location_assignment PIN_M8 -to b_dram1_mem_dqs[1]
set_location_assignment PIN_L8 -to b_dram1_mem_dqsn[1]
set_location_assignment PIN_L6 -to o_dram1_mem_dm[1]
set_location_assignment PIN_J7 -to b_dram1_mem_dq[8]
set_location_assignment PIN_L7 -to b_dram1_mem_dq[9]
set_location_assignment PIN_J8 -to b_dram1_mem_dq[10]
set_location_assignment PIN_M9 -to b_dram1_mem_dq[11]
set_location_assignment PIN_K7 -to b_dram1_mem_dq[12]
set_location_assignment PIN_N9 -to b_dram1_mem_dq[13]
set_location_assignment PIN_H8 -to b_dram1_mem_dq[14]
set_location_assignment PIN_K6 -to b_dram1_mem_dq[15]

set_location_assignment PIN_D9 -to b_dram1_mem_dqs[2]
set_location_assignment PIN_C9 -to b_dram1_mem_dqsn[2]
set_location_assignment PIN_E8 -to o_dram1_mem_dm[2]
set_location_assignment PIN_E10 -to b_dram1_mem_dq[16]
set_location_assignment PIN_F8 -to b_dram1_mem_dq[17]
set_location_assignment PIN_D10 -to b_dram1_mem_dq[18]
set_location_assignment PIN_F9 -to b_dram1_mem_dq[19]
set_location_assignment PIN_E9 -to b_dram1_mem_dq[20]
set_location_assignment PIN_G8 -to b_dram1_mem_dq[21]
set_location_assignment PIN_E11 -to b_dram1_mem_dq[22]
set_location_assignment PIN_E7 -to b_dram1_mem_dq[23]

set_location_assignment PIN_B8 -to b_dram1_mem_dqs[3]
set_location_assignment PIN_A8 -to b_dram1_mem_dqsn[3]
set_location_assignment PIN_A7 -to o_dram1_mem_dm[3]
set_location_assignment PIN_B10 -to b_dram1_mem_dq[24]
set_location_assignment PIN_C10 -to b_dram1_mem_dq[25]
set_location_assignment PIN_B11 -to b_dram1_mem_dq[26]
set_location_assignment PIN_C7 -to b_dram1_mem_dq[27]
set_location_assignment PIN_C11 -to b_dram1_mem_dq[28]
set_location_assignment PIN_B7 -to b_dram1_mem_dq[29]
set_location_assignment PIN_A11 -to b_dram1_mem_dq[30]
set_location_assignment PIN_A10 -to b_dram1_mem_dq[31]

set_location_assignment PIN_J14 -to b_dram1_mem_dqs[4]
set_location_assignment PIN_J13 -to b_dram1_mem_dqsn[4]
set_location_assignment PIN_G14 -to o_dram1_mem_dm[4]
set_location_assignment PIN_J15 -to b_dram1_mem_dq[32]
set_location_assignment PIN_H13 -to b_dram1_mem_dq[33]
set_location_assignment PIN_K13 -to b_dram1_mem_dq[34]
set_location_assignment PIN_G13 -to b_dram1_mem_dq[35]
set_location_assignment PIN_K15 -to b_dram1_mem_dq[36]
set_location_assignment PIN_G16 -to b_dram1_mem_dq[37]
set_location_assignment PIN_K14 -to b_dram1_mem_dq[38]
set_location_assignment PIN_H14 -to b_dram1_mem_dq[39]

set_location_assignment PIN_L10 -to b_dram1_mem_dqs[5]
set_location_assignment PIN_L9 -to b_dram1_mem_dqsn[5]
set_location_assignment PIN_J9 -to o_dram1_mem_dm[5]
set_location_assignment PIN_N10 -to b_dram1_mem_dq[40]
set_location_assignment PIN_J10 -to b_dram1_mem_dq[41]
set_location_assignment PIN_R9 -to b_dram1_mem_dq[42]
set_location_assignment PIN_G10 -to b_dram1_mem_dq[43]
set_location_assignment PIN_P10 -to b_dram1_mem_dq[44]
set_location_assignment PIN_G9 -to b_dram1_mem_dq[45]
set_location_assignment PIN_T9 -to b_dram1_mem_dq[46]
set_location_assignment PIN_K9 -to b_dram1_mem_dq[47]

set_location_assignment PIN_D6 -to b_dram1_mem_dqs[6]
set_location_assignment PIN_D7 -to b_dram1_mem_dqsn[6]
set_location_assignment PIN_B5 -to o_dram1_mem_dm[6]
set_location_assignment PIN_A4 -to b_dram1_mem_dq[48]
set_location_assignment PIN_A5 -to b_dram1_mem_dq[49]
set_location_assignment PIN_E4 -to b_dram1_mem_dq[50]
set_location_assignment PIN_E6 -to b_dram1_mem_dq[51]
set_location_assignment PIN_C4 -to b_dram1_mem_dq[52]
set_location_assignment PIN_E5 -to b_dram1_mem_dq[53]
set_location_assignment PIN_D4 -to b_dram1_mem_dq[54]
set_location_assignment PIN_F5 -to b_dram1_mem_dq[55]

set_location_assignment PIN_C16 -to b_dram1_mem_dqs[7]
set_location_assignment PIN_B16 -to b_dram1_mem_dqsn[7]
set_location_assignment PIN_E15 -to o_dram1_mem_dm[7]
set_location_assignment PIN_C13 -to b_dram1_mem_dq[56]
set_location_assignment PIN_D15 -to b_dram1_mem_dq[57]
set_location_assignment PIN_B13 -to b_dram1_mem_dq[58]
set_location_assignment PIN_E16 -to b_dram1_mem_dq[59]
set_location_assignment PIN_A14 -to b_dram1_mem_dq[60]
set_location_assignment PIN_D16 -to b_dram1_mem_dq[61]
set_location_assignment PIN_A13 -to b_dram1_mem_dq[62]
set_location_assignment PIN_B14 -to b_dram1_mem_dq[63]

set_location_assignment PIN_G11 -to b_dram1_mem_dqs[8]
set_location_assignment PIN_F11 -to b_dram1_mem_dqsn[8]
set_location_assignment PIN_E12 -to o_dram1_mem_dm[8]
set_location_assignment PIN_E14 -to b_dram1_mem_dq[64]
set_location_assignment PIN_F12 -to b_dram1_mem_dq[65]
set_location_assignment PIN_F15 -to b_dram1_mem_dq[66]
set_location_assignment PIN_C12 -to b_dram1_mem_dq[67]
set_location_assignment PIN_E13 -to b_dram1_mem_dq[68]
set_location_assignment PIN_D12 -to b_dram1_mem_dq[69]
set_location_assignment PIN_F14 -to b_dram1_mem_dq[70]
set_location_assignment PIN_D13 -to b_dram1_mem_dq[71]

set_location_assignment PIN_F20 -to o_dram1_mem_a[0]
set_location_assignment PIN_D21 -to o_dram1_mem_a[1]
set_location_assignment PIN_A19 -to o_dram1_mem_a[2]
set_location_assignment PIN_J21 -to o_dram1_mem_a[3]
set_location_assignment PIN_E21 -to o_dram1_mem_a[4]
set_location_assignment PIN_F21 -to o_dram1_mem_a[5]
set_location_assignment PIN_K21 -to o_dram1_mem_a[6]
set_location_assignment PIN_F18 -to o_dram1_mem_a[7]
set_location_assignment PIN_E18 -to o_dram1_mem_a[8]
set_location_assignment PIN_G21 -to o_dram1_mem_a[9]
set_location_assignment PIN_C17 -to o_dram1_mem_a[10]
set_location_assignment PIN_B19 -to o_dram1_mem_a[11]
set_location_assignment PIN_E19 -to o_dram1_mem_a[12]
set_location_assignment PIN_J22 -to o_dram1_mem_a[13]
set_location_assignment PIN_D18 -to o_dram1_mem_a[14]
set_location_assignment PIN_E17 -to o_dram1_mem_a[15]
set_location_assignment PIN_J19 -to o_dram1_mem_ba[0]
set_location_assignment PIN_F17 -to o_dram1_mem_ba[1]
set_location_assignment PIN_B20 -to o_dram1_mem_ba[2]
set_location_assignment PIN_A16 -to o_dram1_mem_ck
set_location_assignment PIN_A17 -to o_dram1_mem_ck_n
set_location_assignment PIN_E20 -to o_dram1_mem_cs_n[0]
set_location_assignment PIN_J18 -to o_dram1_mem_cs_n[1]
set_location_assignment PIN_J20 -to o_dram1_mem_cke[0]
set_location_assignment PIN_H17 -to o_dram1_mem_cke[1]
set_location_assignment PIN_G20 -to o_dram1_mem_odt[0]
set_location_assignment PIN_D19 -to o_dram1_mem_odt[1]
set_location_assignment PIN_H20 -to o_dram1_mem_ras_n
set_location_assignment PIN_B17 -to o_dram1_mem_cas_n
set_location_assignment PIN_A20 -to o_dram1_mem_we_n
set_location_assignment PIN_C19 -to o_dram1_mem_reset_n



set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to B_DRAM1_MEM_DQ

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to B_DRAM1_MEM_DQS

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to B_DRAM1_MEM_DQSN

#####################################
# SFP+ Reference Clock              #
#####################################
set_location_assignment PIN_N28 -to i_refclk_sfp
set_location_assignment PIN_N29 -to "i_refclk_sfp(n)"
set_location_assignment PIN_N24 -to o_refclk_sfp_fs

set_instance_assignment -name IO_STANDARD "DIFFERENTIAL LVPECL" -to i_refclk_sfp

#####################################
# SFP+ 0                            #
#####################################
set_location_assignment PIN_AC26 -to i_sfp0_tx_fault
set_location_assignment PIN_AD26 -to o_sfp0_tx_disable
set_location_assignment PIN_AE25 -to o_sfp0_rs0
set_location_assignment PIN_AE26 -to o_sfp0_rs1
set_location_assignment PIN_AF25 -to i_sfp0_mod_abs
set_location_assignment PIN_AF26 -to i_sfp0_rx_los
set_location_assignment PIN_AG25 -to o_sfp0_scl
set_location_assignment PIN_AH25 -to b_sfp0_sda
set_location_assignment PIN_J33 -to i_sfp0_rx_serial_data

set_location_assignment PIN_H31 -to o_sfp0_tx_serial_data


set_instance_assignment -name IO_STANDARD "2.5-V" -to i_sfp0_tx_fault
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_sfp0_tx_disable
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_sfp0_rs0
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_sfp0_rs1
set_instance_assignment -name IO_STANDARD "2.5-V" -to i_sfp0_mod_abs
set_instance_assignment -name IO_STANDARD "2.5-V" -to i_sfp0_rx_los
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_sfp0_scl
set_instance_assignment -name IO_STANDARD "2.5-V" -to b_sfp0_sda
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to i_sfp0_rx_serial_data
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to o_sfp0_tx_serial_data
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to o_sfp0_scl
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b_sfp0_sda
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to o_sfp0_scl
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_sfp0_sda
set_instance_assignment -name AUTO_OPEN_DRAIN_PINS ON -to o_sfp0_scl
set_instance_assignment -name AUTO_OPEN_DRAIN_PINS ON -to b_sfp0_sda

#####################################
# SFP+ 1                            #
#####################################
set_location_assignment PIN_V25 -to i_sfp1_tx_fault
set_location_assignment PIN_Y26 -to o_sfp1_tx_disable
set_location_assignment PIN_AA25 -to o_sfp1_rs0
set_location_assignment PIN_AJ24 -to o_sfp1_rs1
set_location_assignment PIN_Y25 -to i_sfp1_mod_abs
set_location_assignment PIN_AB24 -to i_sfp1_rx_los
set_location_assignment PIN_Y24 -to o_sfp1_scl
set_location_assignment PIN_W25 -to b_sfp1_sda
set_location_assignment PIN_L33 -to i_sfp1_rx_serial_data

set_location_assignment PIN_K31 -to o_sfp1_tx_serial_data


set_instance_assignment -name IO_STANDARD "2.5-V" -to i_sfp1_tx_fault
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_sfp1_tx_disable
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_sfp1_rs0
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_sfp1_rs1
set_instance_assignment -name IO_STANDARD "2.5-V" -to i_sfp1_mod_abs
set_instance_assignment -name IO_STANDARD "2.5-V" -to i_sfp1_rx_los
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_sfp1_scl
set_instance_assignment -name IO_STANDARD "2.5-V" -to b_sfp1_sda
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to i_sfp1_rx_serial_data
set_instance_assignment -name IO_STANDARD "1.5-V PCML" -to o_sfp1_tx_serial_data
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to o_sfp1_scl
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b_sfp1_sda
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to o_sfp1_scl
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_sfp1_sda
set_instance_assignment -name AUTO_OPEN_DRAIN_PINS ON -to o_sfp1_scl
set_instance_assignment -name AUTO_OPEN_DRAIN_PINS ON -to b_sfp1_sda

#####################################
# CONFIGURATION FLASH               #
#####################################
set_location_assignment PIN_D34 -to i_pfl_flash_grant
set_location_assignment PIN_C34 -to o_pfl_flash_reqn

set_location_assignment PIN_A26 -to o_flash_clk
set_location_assignment PIN_B26 -to o_flash_cen[0]
set_location_assignment PIN_J26 -to o_flash_cen[1]
set_location_assignment PIN_A29 -to o_flash_oen
set_location_assignment PIN_D31 -to o_flash_wen
set_location_assignment PIN_H29 -to i_flash_wait[0]
set_location_assignment PIN_M27 -to i_flash_wait[1]
set_location_assignment PIN_L26 -to o_flash_rstn
set_location_assignment PIN_J29 -to o_flash_advn
set_location_assignment PIN_H23 -to o_flash_wpn

set_location_assignment PIN_H25 -to o_flash_a[1]
set_location_assignment PIN_F26 -to o_flash_a[2]
set_location_assignment PIN_D27 -to o_flash_a[3]
set_location_assignment PIN_P26 -to o_flash_a[4]
set_location_assignment PIN_L25 -to o_flash_a[5]
set_location_assignment PIN_L24 -to o_flash_a[6]
set_location_assignment PIN_C27 -to o_flash_a[7]
set_location_assignment PIN_C25 -to o_flash_a[8]
set_location_assignment PIN_G26 -to o_flash_a[9]
set_location_assignment PIN_J25 -to o_flash_a[10]
set_location_assignment PIN_E26 -to o_flash_a[11]
set_location_assignment PIN_K25 -to o_flash_a[12]
set_location_assignment PIN_G25 -to o_flash_a[13]
set_location_assignment PIN_J24 -to o_flash_a[14]
set_location_assignment PIN_P25 -to o_flash_a[15]
set_location_assignment PIN_F27 -to o_flash_a[16]
set_location_assignment PIN_E27 -to o_flash_a[17]
set_location_assignment PIN_E25 -to o_flash_a[18]
set_location_assignment PIN_F24 -to o_flash_a[19]
set_location_assignment PIN_B25 -to o_flash_a[20]
set_location_assignment PIN_A25 -to o_flash_a[21]
set_location_assignment PIN_D25 -to o_flash_a[22]
set_location_assignment PIN_D33 -to o_flash_a[23]
set_location_assignment PIN_F32 -to o_flash_a[24]
set_location_assignment PIN_K24 -to o_flash_a[25]
set_location_assignment PIN_G24 -to o_flash_a[26]

set_location_assignment PIN_K27 -to b_flash_dq[0]
set_location_assignment PIN_C28 -to b_flash_dq[1]
set_location_assignment PIN_K28 -to b_flash_dq[2]
set_location_assignment PIN_B28 -to b_flash_dq[3]
set_location_assignment PIN_A28 -to b_flash_dq[4]
set_location_assignment PIN_B32 -to b_flash_dq[5]
set_location_assignment PIN_H28 -to b_flash_dq[6]
set_location_assignment PIN_A32 -to b_flash_dq[7]
set_location_assignment PIN_G27 -to b_flash_dq[8]
set_location_assignment PIN_D28 -to b_flash_dq[9]
set_location_assignment PIN_N26 -to b_flash_dq[10]
set_location_assignment PIN_E28 -to b_flash_dq[11]
set_location_assignment PIN_G28 -to b_flash_dq[12]
set_location_assignment PIN_B34 -to b_flash_dq[13]
set_location_assignment PIN_E31 -to b_flash_dq[14]
set_location_assignment PIN_M26 -to b_flash_dq[15]
set_location_assignment PIN_C31 -to b_flash_dq[16]
set_location_assignment PIN_L28 -to b_flash_dq[17]
set_location_assignment PIN_C32 -to b_flash_dq[18]
set_location_assignment PIN_J28 -to b_flash_dq[19]
set_location_assignment PIN_J27 -to b_flash_dq[20]
set_location_assignment PIN_E32 -to b_flash_dq[21]
set_location_assignment PIN_A31 -to b_flash_dq[22]
set_location_assignment PIN_C33 -to b_flash_dq[23]
set_location_assignment PIN_E30 -to b_flash_dq[24]
set_location_assignment PIN_L27 -to b_flash_dq[25]
set_location_assignment PIN_F30 -to b_flash_dq[26]
set_location_assignment PIN_D30 -to b_flash_dq[27]
set_location_assignment PIN_E29 -to b_flash_dq[28]
set_location_assignment PIN_A33 -to b_flash_dq[29]
set_location_assignment PIN_B31 -to b_flash_dq[30]
set_location_assignment PIN_L29 -to b_flash_dq[31]

#####################################
# LED outputs                       #
#####################################

set_location_assignment PIN_AK25 -to o_red_led[0]
set_location_assignment PIN_AK24 -to o_red_led[1]

set_location_assignment PIN_AH18 -to o_red_led[2]
set_location_assignment PIN_AL17 -to o_red_led[3]
set_location_assignment PIN_AF24 -to o_green_led[0]
set_location_assignment PIN_AD24 -to o_green_led[1]
set_location_assignment PIN_AM17 -to o_green_led[2]
set_location_assignment PIN_AK17 -to o_green_led[3]
set_location_assignment PIN_AB23 -to o_rgb_led[0]
set_location_assignment PIN_AG24 -to o_rgb_led[1]
set_location_assignment PIN_AH24 -to o_rgb_led[2]
set_location_assignment PIN_AC24 -to o_rgb_led[3]
set_location_assignment PIN_AA24 -to o_rgb_led[4]
set_location_assignment PIN_AB26 -to o_rgb_led[5]

set_instance_assignment -name IO_STANDARD "2.5-V" -to o_green_led[0]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_green_led[1]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_green_led[2]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_green_led[3]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_red_led[0]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_red_led[1]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_red_led[2]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_red_led[3]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_rgb_led[0]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_rgb_led[1]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_rgb_led[2]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_rgb_led[3]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_rgb_led[4]
set_instance_assignment -name IO_STANDARD "2.5-V" -to o_rgb_led[5]


# PMBUS (power supply controller & system monitor)
set_location_assignment PIN_R26 -to o_ucd_scl
set_location_assignment PIN_T25 -to b_ucd_sda
set_location_assignment PIN_R24 -to i_ucd_pmbus_alert

# Temperature Sensor
set_location_assignment PIN_C21 -to o_therm_scl
set_location_assignment PIN_C22 -to b_therm_sda
set_location_assignment PIN_B22 -to i_therm2n

#####################################
# CPLD                              #
#####################################
set_location_assignment PIN_L22 -to o_cpld_scl
set_location_assignment PIN_M22 -to b_cpld_sda

set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to o_cpld_scl
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b_cpld_sda
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to o_cpld_scl
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to b_cpld_sda
set_instance_assignment -name AUTO_OPEN_DRAIN_PINS ON -to o_cpld_scl
set_instance_assignment -name AUTO_OPEN_DRAIN_PINS ON -to b_cpld_sda

#####################################
# FPGA Driven Reconfiguration       #
#####################################
set_location_assignment PIN_AP30 -to o_cpld_softreconfigreq
set_location_assignment PIN_E34 -to b_cpld_usergolden

#####################################
# Debug I/O                         #
#####################################
set_location_assignment PIN_AL19 -to o_debug[0]
set_location_assignment PIN_AM18 -to o_debug[1]
set_location_assignment PIN_AN18 -to o_debug[2]
set_location_assignment PIN_AP18 -to o_debug[3]

