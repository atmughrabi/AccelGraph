

-- *!***************************************************************************
-- *! Copyright 2014 International Business Machines
-- *! 
-- *! Licensed under the Apache License, Version 2.0 (the "License");
-- *! you may not use this file except in compliance with the License.
-- *! You may obtain a copy of the License at
-- *! 
-- *!     http://www.apache.org/licenses/LICENSE-2.0
-- *! 
-- *! Unless required by applicable law or agreed to in writing, software
-- *! distributed under the License is distributed on an "AS IS" BASIS,
-- *! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- *! See the License for the specific language governing permissions and
-- *! limitations under the License.
-- *!
-- *!***************************************************************************
-- *! FILENAME    : psl_fpga.vhdl
-- *!***************************************************************************



library ieee, work;
use ieee.std_logic_1164.all;
use work.std_ulogic_function_support.all;
use work.std_ulogic_support.all;
use work.std_ulogic_unsigned.all;

ENTITY psl_fpga IS
  PORT(crc_error: out std_logic;
       


       i_refclk_dram0: in std_logic;
       b_dram0_mem_dq: inout std_logic_vector(0 to 71);
       b_dram0_mem_dqs: inout std_logic_vector(0 to 8);
       b_dram0_mem_dqsn: inout std_logic_vector(0 to 8);
       o_dram0_mem_dm: out std_logic_vector(0 to 8);
       o_dram0_mem_a: out std_logic_vector(0 to 15);
       o_dram0_mem_ba: out std_logic_vector(0 to 2);
       o_dram0_mem_ck: out std_logic;
       o_dram0_mem_ck_n: out std_logic;
       o_dram0_mem_cs_n: out std_logic_vector(0 to 1);
       o_dram0_mem_cke: out std_logic_vector(0 to 1);
       o_dram0_mem_odt: out std_logic_vector(0 to 1);
       o_dram0_mem_ras_n: out std_logic;
       o_dram0_mem_cas_n: out std_logic;
       o_dram0_mem_we_n: out std_logic;
       o_dram0_mem_reset_n: out std_logic;
       i_dram0_rzq: in std_logic;
       i_refclk_dram1: in std_logic;
       b_dram1_mem_dq: inout std_logic_vector(0 to 71);
       b_dram1_mem_dqs: inout std_logic_vector(0 to 8);
       b_dram1_mem_dqsn: inout std_logic_vector(0 to 8);
       o_dram1_mem_dm: out std_logic_vector(0 to 8);
       o_dram1_mem_a: out std_logic_vector(0 to 15);
       o_dram1_mem_ba: out std_logic_vector(0 to 2);
       o_dram1_mem_ck: out std_logic;
       o_dram1_mem_ck_n: out std_logic;
       o_dram1_mem_cs_n: out std_logic_vector(0 to 1);
       o_dram1_mem_cke: out std_logic_vector(0 to 1);
       o_dram1_mem_odt: out std_logic_vector(0 to 1);
       o_dram1_mem_ras_n: out std_logic;
       o_dram1_mem_cas_n: out std_logic;
       o_dram1_mem_we_n: out std_logic;
       o_dram1_mem_reset_n: out std_logic;
       i_dram1_rzq: in std_logic;
       
       -- sfp ports
       o_refclk_sfp_fs: out std_logic;
       i_refclk_sfp: in std_logic;
       i_sfp0_rx_serial_data: in std_logic;
       o_sfp0_tx_serial_data: out std_logic;
       
       -- sfp+ sideband i/o
       i_sfp0_tx_fault: in std_logic;                                        -- module transmitter has detected a fault
       o_sfp0_tx_disable: out std_logic;                                     -- drive high to turn off transmitter output
       o_sfp0_rs0: out std_logic;                                            -- optical receive signaling rate
       o_sfp0_rs1: out std_logic;                                            -- optical transmit signaling rate
       i_sfp0_mod_abs: in std_logic;                                         -- asserted high when sfp+ is physically absent
       i_sfp0_rx_los: in std_logic;                                          -- loss of signal - non-installed cable, faulty cable, no transmitter at far end of cable
       o_sfp0_scl: out std_logic;                                            -- i2c clock
       b_sfp0_sda: inout std_logic;                                          -- i2c data
       i_sfp1_rx_serial_data: in std_logic;
       o_sfp1_tx_serial_data: out std_logic;
       
       -- sfp+ sideband i/o
       i_sfp1_tx_fault: in std_logic;                                        -- module transmitter has detected a fault
       o_sfp1_tx_disable: out std_logic;                                     -- drive high to turn off transmitter output
       o_sfp1_rs0: out std_logic;                                            -- optical receive signaling rate
       o_sfp1_rs1: out std_logic;                                            -- optical transmit signaling rate
       i_sfp1_mod_abs: in std_logic;                                         -- asserted high when sfp+ is physically absent
       i_sfp1_rx_los: in std_logic;                                          -- loss of signal - non-installed cable, faulty cable, no transmitter at far end of cable
       o_sfp1_scl: out std_logic;                                            -- i2c clock
       b_sfp1_sda: inout std_logic;                                          -- i2c data
       
       -- flash bus
       o_flash_clk: out std_logic;
       o_flash_oen: out std_logic;
       o_flash_wen: out std_logic;
       o_flash_rstn: out std_logic;
       o_flash_a: out std_logic_vector(1 to 26);
       o_flash_advn: out std_logic;
       b_flash_dq: inout std_logic_vector(0 to 31);
       o_flash_cen: out std_logic_vector(0 to 1);
       i_flash_wait: in std_logic_vector(0 to 1);
       o_flash_wpn: out std_logic;
       o_pfl_flash_reqn: out std_logic;
       i_pfl_flash_grant: in std_logic;
       
       -- LED outputs
       o_red_led: out std_logic_vector(0 to 3);
       o_green_led: out std_logic_vector(0 to 3);
       o_rgb_led: out std_logic_vector(0 to 5);
       
       -- PMBUS (power supply controller & system monitor)
       b_ucd_scl: inout std_logic;                                           -- I2C clock
       b_ucd_sda: inout std_logic;                                           -- I2C data
       i_ucd_pmbus_alert: in std_logic;
       
       -- Temperature Sensor
       b_therm_scl: inout std_logic;                                         -- I2C clock
       b_therm_sda: inout std_logic;                                         -- I2C data
       i_therm2n: in std_logic;
       
       -- CPLD I2C and Reconfig
       o_cpld_scl: out std_logic;                                            -- I2C clock
       b_cpld_sda: inout std_logic;                                          -- I2C data
       o_cpld_softreconfigreq: out std_logic;                                -- initiate a reconfig req
       b_cpld_usergolden: inout std_logic;                                   -- this pin is used to tell the CPLD which bitstream to load, or for us to see which was loaded
       i_conf_clk: in std_logic;
       
       -- pci interface
       pci_pi_nperst0: in std_logic;                                         -- Active low reset from the PCIe reset pin of the device
       pci_pi_refclk0: in std_logic;                                         -- 100MHz Refclk
       pci0_i_rx_in0: in std_logic;
       pci0_i_rx_in1: in std_logic;
       pci0_i_rx_in2: in std_logic;
       pci0_i_rx_in3: in std_logic;
       pci0_i_rx_in4: in std_logic;
       pci0_i_rx_in5: in std_logic;
       pci0_i_rx_in6: in std_logic;
       pci0_i_rx_in7: in std_logic;
       pci0_o_tx_out0: out std_logic;
       pci0_o_tx_out1: out std_logic;
       pci0_o_tx_out2: out std_logic;
       pci0_o_tx_out3: out std_logic;
       pci0_o_tx_out4: out std_logic;
       pci0_o_tx_out5: out std_logic;
       pci0_o_tx_out6: out std_logic;
       pci0_o_tx_out7: out std_logic;
       o_debug: out std_logic_vector(0 to 3));

END psl_fpga;



ARCHITECTURE psl_fpga OF psl_fpga IS

Component psl_svcrc
  PORT(crcerror: out std_logic;
       crc_clk: in std_ulogic);
End Component psl_svcrc;

Component psl_clkcontrol
  PORT(clkout: out std_ulogic;
       clkin: in std_ulogic);
End Component psl_clkcontrol;

Component psl_accel
  PORT(
       -- Accelerator Command Interface
       ah_cvalid: out std_ulogic;                                            -- A valid command is present
       ah_ctag: out std_ulogic_vector(0 to 7);                               -- request id
       ah_com: out std_ulogic_vector(0 to 12);                               -- command PSL will execute
       ah_cpad: out std_ulogic_vector(0 to 2);                               -- prefetch attributes
       ah_cabt: out std_ulogic_vector(0 to 2);                               -- abort if translation intr is generated
       ah_cea: out std_ulogic_vector(0 to 63);                               -- Effective byte address for command
       ah_cch: out std_ulogic_vector(0 to 15);                               -- Context Handle
       ah_csize: out std_ulogic_vector(0 to 11);                             -- Number of bytes
       ha_croom: in std_ulogic_vector(0 to 7);                               -- Commands PSL is prepared to accept
       
       -- command parity
       ah_ctagpar: out std_ulogic;
       ah_compar: out std_ulogic;
       ah_ceapar: out std_ulogic;
       
       -- Accelerator Buffer Interfaces
       ha_brvalid: in std_ulogic;                                            -- A read transfer is present
       ha_brtag: in std_ulogic_vector(0 to 7);                               -- Accelerator generated ID for read
       ha_brad: in std_ulogic_vector(0 to 5);                                -- half line index of read data
       ah_brlat: out std_ulogic_vector(0 to 3);                              -- Read data ready latency
       ah_brdata: out std_ulogic_vector(0 to 511);                           -- Read data
       ah_brpar: out std_ulogic_vector(0 to 7);                              -- Read data parity
       ha_bwvalid: in std_ulogic;                                            -- A write data transfer is present
       ha_bwtag: in std_ulogic_vector(0 to 7);                               -- Accelerator ID of the write
       ha_bwad: in std_ulogic_vector(0 to 5);                                -- half line index of write data
       ha_bwdata: in std_ulogic_vector(0 to 511);                            -- Write data
       ha_bwpar: in std_ulogic_vector(0 to 7);                               -- Write data parity
       
       -- buffer tag parity
       ha_brtagpar: in std_ulogic;
       ha_bwtagpar: in std_ulogic;
       
       -- PSL Response Interface
       ha_rvalid: in std_ulogic;                                             --A response is present
       ha_rtag: in std_ulogic_vector(0 to 7);                                --Accelerator generated request ID
       ha_response: in std_ulogic_vector(0 to 7);                            --response code
       ha_rcredits: in std_ulogic_vector(0 to 8);                            --twos compliment number of credits
       ha_rcachestate: in std_ulogic_vector(0 to 1);                         --Resultant Cache State
       ha_rcachepos: in std_ulogic_vector(0 to 12);                          --Cache location id
       ha_rtagpar: in std_ulogic;
       
       -- MMIO Interface
       ha_mmval: in std_ulogic;                                              -- A valid MMIO is present
       ha_mmrnw: in std_ulogic;                                              -- 1 = read, 0 = write
       ha_mmdw: in std_ulogic;                                               -- 1 = doubleword, 0 = word
       ha_mmad: in std_ulogic_vector(0 to 23);                               -- mmio address
       ha_mmdata: in std_ulogic_vector(0 to 63);                             -- Write data
       ha_mmcfg: in std_ulogic;                                              -- mmio is to afu descriptor space
       ah_mmack: out std_ulogic;                                             -- Write is complete or Read is valid pulse
       ah_mmdata: out std_ulogic_vector(0 to 63);                            -- Read data
       
       -- mmio parity
       ha_mmadpar: in std_ulogic;
       ha_mmdatapar: in std_ulogic;
       ah_mmdatapar: out std_ulogic;
       
       -- Accelerator Control Interface
       ha_jval: in std_ulogic;                                               -- A valid job control command is present
       ha_jcom: in std_ulogic_vector(0 to 7);                                -- Job control command opcode
       ha_jea: in std_ulogic_vector(0 to 63);                                -- Save/Restore address
       ah_jrunning: out std_ulogic;                                          -- Accelerator is running level
       ah_jdone: out std_ulogic;                                             -- Accelerator is finished pulse
       ah_jcack: out std_ulogic;                                             -- Accelerator is with context llcmd pulse
       ah_jerror: out std_ulogic_vector(0 to 63);                            -- Accelerator error code. 0 = success
       ah_tbreq: out std_ulogic;                                             -- Timebase request pulse
       ah_jyield: out std_ulogic;                                            -- Accelerator wants to stop
       ha_jeapar: in std_ulogic;
       ha_jcompar: in std_ulogic;
       ah_paren: out std_ulogic;
       
       -- SFP+ Phy 0 Interface
       as_sfp0_phy_mgmt_clk_reset: out std_ulogic;
       as_sfp0_phy_mgmt_address: out std_ulogic_vector(0 to 8);
       as_sfp0_phy_mgmt_read: out std_ulogic;
       sa_sfp0_phy_mgmt_readdata: in std_ulogic_vector(0 to 31);
       sa_sfp0_phy_mgmt_waitrequest: in std_ulogic;
       as_sfp0_phy_mgmt_write: out std_ulogic;
       as_sfp0_phy_mgmt_writedata: out std_ulogic_vector(0 to 31);
       sa_sfp0_tx_ready: in std_ulogic;
       sa_sfp0_rx_ready: in std_ulogic;
       as_sfp0_tx_forceelecidle: out std_ulogic;
       sa_sfp0_pll_locked: in std_ulogic;
       sa_sfp0_rx_is_lockedtoref: in std_ulogic;
       sa_sfp0_rx_is_lockedtodata: in std_ulogic;
       sa_sfp0_rx_signaldetect: in std_ulogic;
       as_sfp0_tx_coreclk: out std_ulogic;
       sa_sfp0_tx_clk: in std_ulogic;
       sa_sfp0_rx_clk: in std_ulogic;
       as_sfp0_tx_parallel_data: out std_ulogic_vector(0 to 39);
       sa_sfp0_rx_parallel_data: in std_ulogic_vector(0 to 39);
       
       -- SFP+ 0 Sideband Signals
       sa_sfp0_tx_fault: in std_ulogic;
       sa_sfp0_mod_abs: in std_ulogic;
       sa_sfp0_rx_los: in std_ulogic;
       as_sfp0_tx_disable: out std_ulogic;
       as_sfp0_rs0: out std_ulogic;
       as_sfp0_rs1: out std_ulogic;
       as_sfp0_scl: out std_ulogic;
       as_sfp0_en: out std_ulogic;
       sa_sfp0_sda: in std_ulogic;
       as_sfp0_sda: out std_ulogic;
       as_sfp0_sda_oe: out std_ulogic;
       
       -- SFP+ Phy 1 Interface
       as_sfp1_phy_mgmt_clk_reset: out std_ulogic;
       as_sfp1_phy_mgmt_address: out std_ulogic_vector(0 to 8);
       as_sfp1_phy_mgmt_read: out std_ulogic;
       sa_sfp1_phy_mgmt_readdata: in std_ulogic_vector(0 to 31);
       sa_sfp1_phy_mgmt_waitrequest: in std_ulogic;
       as_sfp1_phy_mgmt_write: out std_ulogic;
       as_sfp1_phy_mgmt_writedata: out std_ulogic_vector(0 to 31);
       sa_sfp1_tx_ready: in std_ulogic;
       sa_sfp1_rx_ready: in std_ulogic;
       as_sfp1_tx_forceelecidle: out std_ulogic;
       sa_sfp1_pll_locked: in std_ulogic;
       sa_sfp1_rx_is_lockedtoref: in std_ulogic;
       sa_sfp1_rx_is_lockedtodata: in std_ulogic;
       sa_sfp1_rx_signaldetect: in std_ulogic;
       as_sfp1_tx_coreclk: out std_ulogic;
       sa_sfp1_tx_clk: in std_ulogic;
       sa_sfp1_rx_clk: in std_ulogic;
       as_sfp1_tx_parallel_data: out std_ulogic_vector(0 to 39);
       sa_sfp1_rx_parallel_data: in std_ulogic_vector(0 to 39);
       
       -- SFP+ 1 Sideband Signals
       sa_sfp1_tx_fault: in std_ulogic;
       sa_sfp1_mod_abs: in std_ulogic;
       sa_sfp1_rx_los: in std_ulogic;
       as_sfp1_tx_disable: out std_ulogic;
       as_sfp1_rs0: out std_ulogic;
       as_sfp1_rs1: out std_ulogic;
       as_sfp1_scl: out std_ulogic;
       as_sfp1_en: out std_ulogic;
       sa_sfp1_sda: in std_ulogic;
       as_sfp1_sda: out std_ulogic;
       as_sfp1_sda_oe: out std_ulogic;
       
       -- SFP+ Reference Clock Select
       as_refclk_sfp_fs: out std_ulogic;
       as_refclk_sfp_fs_en: out std_ulogic;
       
       -- SFP+ LED
       as_red_led: out std_ulogic_vector(0 to 3);
       as_green_led: out std_ulogic_vector(0 to 3);
       ha_pclock: in std_ulogic);
End Component psl_accel;

Component sfpp_phy
  PORT(phy_mgmt_clk: in std_logic;
       phy_mgmt_clk_reset: in std_logic;
       phy_mgmt_address: in std_logic_vector(0 to 8);
       phy_mgmt_read: in std_logic;
       phy_mgmt_readdata: out std_logic_vector(0 to 31);
       phy_mgmt_waitrequest: out std_logic;
       phy_mgmt_write: in std_logic;
       phy_mgmt_writedata: in std_logic_vector(0 to 31);
       tx_ready: out std_logic;
       rx_ready: out std_logic;
       pll_ref_clk: in std_logic;
       tx_serial_data: out std_logic;
       tx_forceelecidle: in std_logic;
       pll_locked: out std_logic;
       rx_serial_data: in std_logic;
       rx_is_lockedtoref: out std_logic;
       rx_is_lockedtodata: out std_logic;
       rx_signaldetect: out std_logic;
       tx_coreclkin: in std_logic;
       tx_clkout: out std_logic;
       rx_clkout: out std_logic;
       tx_parallel_data: in std_logic_vector(0 to 39);
       rx_parallel_data: out std_logic_vector(0 to 39);
       reconfig_from_xcvr: out std_logic_vector(0 to 91);
       reconfig_to_xcvr: in std_logic_vector(0 to 139));
End Component sfpp_phy;

Component psl_gpi1
  PORT(pin: in std_logic;
       id: out std_ulogic);
End Component psl_gpi1;

Component psl_gpo1
  PORT(pin: out std_logic;
       od: in std_ulogic;
       oe: in std_ulogic);
End Component psl_gpo1;

Component psl_gpio1
  PORT(pin: inout std_logic;
       id: out std_ulogic;
       od: in std_ulogic;
       oe: in std_ulogic);
End Component psl_gpio1;

Component sfpp_reconfig
  PORT(clk_clk: in std_logic;
       reset_reset_n: in std_logic;
       alt_xcvr_reconfig_0_ch0_1_to_xcvr_reconfig_to_xcvr: out std_logic_vector(0 to 139);
       alt_xcvr_reconfig_0_ch0_1_from_xcvr_reconfig_from_xcvr: in std_logic_vector(0 to 91);
       alt_xcvr_reconfig_0_ch2_3_to_xcvr_reconfig_to_xcvr: out std_logic_vector(0 to 139);
       alt_xcvr_reconfig_0_ch2_3_from_xcvr_reconfig_from_xcvr: in std_logic_vector(0 to 91);
       alt_xcvr_reconfig_0_reconfig_busy_reconfig_busy: out std_logic);
End Component sfpp_reconfig;

Component psl_gpo4
  PORT(pin: out std_logic_vector(0 to 3);
       od: in std_ulogic_vector(0 to 3);
       oe: in std_ulogic);
End Component psl_gpo4;

Component psl_gpo6
  PORT(pin: out std_logic_vector(0 to 5);
       od: in std_ulogic_vector(0 to 5);
       oe: in std_ulogic);
End Component psl_gpo6;

Component psl_ptmon
  PORT(psl_clk: in std_ulogic;
       
       -- -------------- --
       mi2c_cmdval: out std_ulogic;
       mi2c_dataval: out std_ulogic;
       mi2c_addr: out std_ulogic_vector(0 to 6);
       mi2c_rd: out std_ulogic;
       mi2c_cmdin: out std_ulogic_vector(0 to 7);
       mi2c_datain: out std_ulogic_vector(0 to 7);
       mi2c_blk: out std_ulogic;
       mi2c_bytecnt: out std_ulogic_vector(0 to 7);
       mi2c_cntlrsel: out std_ulogic_vector(0 to 2);
       i2cm_wrdatack: in std_ulogic;
       i2cm_dataval: in std_ulogic;
       i2cm_error: in std_ulogic;
       i2cm_dataout: in std_ulogic_vector(0 to 7);
       i2cm_ready: in std_ulogic;
       
       -- -------------- --
       hi2c_cmdval: in std_ulogic;
       hi2c_dataval: in std_ulogic;
       hi2c_addr: in std_ulogic_vector(0 to 6);
       hi2c_rd: in std_ulogic;
       hi2c_cmdin: in std_ulogic_vector(0 to 7);
       hi2c_datain: in std_ulogic_vector(0 to 7);
       hi2c_blk: in std_ulogic;
       hi2c_bytecnt: in std_ulogic_vector(0 to 7);
       hi2c_cntlrsel: in std_ulogic_vector(0 to 2);
       i2ch_wrdatack: out std_ulogic;
       i2ch_dataval: out std_ulogic;
       i2ch_error: out std_ulogic;
       i2ch_dataout: out std_ulogic_vector(0 to 7);
       i2ch_ready: out std_ulogic;
       
       -- -------------- --
       mon_power: out std_ulogic_vector(0 to 15);
       mon_temperature: out std_ulogic_vector(0 to 15);
       mon_enable: in std_ulogic;
       aptm_req: in std_ulogic;
       ptma_grant: out std_ulogic);
End Component psl_ptmon;

Component psl_i2c
  PORT(psl_clk: in std_ulogic;
       
       -- --------------- --
       i2c0_scl_out: out std_ulogic;
       i2c0_scl_in: in std_ulogic;
       i2c0_sda_out: out std_ulogic;
       i2c0_sda_in: in std_ulogic;
       i2c1_scl_out: out std_ulogic;
       i2c1_scl_in: in std_ulogic;
       i2c1_sda_out: out std_ulogic;
       i2c1_sda_in: in std_ulogic;
       
       -- -------------- --
       mi2c_cmdval: in std_ulogic;
       mi2c_dataval: in std_ulogic;
       mi2c_addr: in std_ulogic_vector(0 to 6);
       mi2c_rd: in std_ulogic;
       mi2c_cmdin: in std_ulogic_vector(0 to 7);
       mi2c_datain: in std_ulogic_vector(0 to 7);
       mi2c_blk: in std_ulogic;
       mi2c_bytecnt: in std_ulogic_vector(0 to 7);
       mi2c_cntlrsel: in std_ulogic_vector(0 to 2);
       i2cm_wrdatack: out std_ulogic;
       i2cm_dataval: out std_ulogic;
       i2cm_error: out std_ulogic;
       i2cm_dataout: out std_ulogic_vector(0 to 7);
       i2cm_ready: out std_ulogic);
End Component psl_i2c;

Component psl_gpo2
  PORT(pin: out std_logic_vector(0 to 1);
       od: in std_ulogic_vector(0 to 1);
       oe: in std_ulogic);
End Component psl_gpo2;

Component psl_gpi2
  PORT(pin: in std_logic_vector(0 to 1);
       id: out std_ulogic_vector(0 to 1));
End Component psl_gpi2;

Component psl_gpo26
  PORT(pin: out std_logic_vector(0 to 25);
       od: in std_ulogic_vector(0 to 25);
       oe: in std_ulogic);
End Component psl_gpo26;

Component psl_gpio32
  PORT(pin: inout std_logic_vector(0 to 31);
       id: out std_ulogic_vector(0 to 31);
       od: in std_ulogic_vector(0 to 31);
       oe: in std_ulogic);
End Component psl_gpio32;

Component psl_vsec
  PORT(psl_clk: in std_ulogic;
       
       -- -------------- --
       cseb_rddata: out std_ulogic_vector(0 to 31);
       cseb_rdresponse: out std_ulogic_vector(0 to 4);
       cseb_waitrequest: out std_ulogic;
       cseb_wrresponse: out std_ulogic_vector(0 to 4);
       cseb_wrresp_valid: out std_ulogic;
       cseb_addr: in std_ulogic_vector(0 to 32);
       cseb_be: in std_ulogic_vector(0 to 3);
       cseb_rden: in std_ulogic;
       cseb_wrdata: in std_ulogic_vector(0 to 31);
       cseb_wren: in std_ulogic;
       cseb_wrresp_req: in std_ulogic;
       cseb_rddata_parity: out std_ulogic_vector(0 to 3);
       cseb_addr_parity: in std_ulogic_vector(0 to 4);
       cseb_wrdata_parity: in std_ulogic_vector(0 to 3);
       
       -- -------------- --
       pci_pi_nperst0: in std_ulogic;
       cpld_usergolden: in std_ulogic;
       cpld_softreconfigreq: out std_ulogic;
       cpld_user_bs_req: out std_ulogic;
       cpld_oe: out std_ulogic;
       
       -- --------------- --
       f_program_req: out std_ulogic;                                        -- Level --
       f_num_blocks: out std_ulogic_vector(0 to 9);                          -- 128KB Block Size --
       f_start_blk: out std_ulogic_vector(0 to 9);
       f_program_data: out std_ulogic_vector(0 to 31);
       f_program_data_val: out std_ulogic;
       f_program_data_ack: in std_ulogic;
       f_ready: in std_ulogic;
       f_done: in std_ulogic;
       f_stat_erase: in std_ulogic;
       f_stat_program: in std_ulogic;
       f_stat_read: in std_ulogic;
       f_remainder: in std_ulogic_vector(0 to 9);
       
       -- -------------- --
       f_read_req: out std_ulogic;
       f_num_words_m1: out std_ulogic_vector(0 to 9);                        -- N-1 words --
       f_read_start_addr: out std_ulogic_vector(0 to 25);
       f_read_data: in std_ulogic_vector(0 to 31);
       f_read_data_val: in std_ulogic;
       f_read_data_ack: out std_ulogic);
End Component psl_vsec;

Component psl_flash
  PORT(psl_clk: in std_ulogic;
       
       -- --------------- --
       flash_clk: out std_ulogic;
       flash_rstn: out std_ulogic;
       flash_addr: out std_ulogic_vector(0 to 25);
       flash_dataout: out std_ulogic_vector(0 to 31);
       flash_dat_oe: out std_ulogic;
       flash_datain: in std_ulogic_vector(0 to 31);
       flash_cen: out std_ulogic_vector(0 to 1);
       flash_oen: out std_ulogic;
       flash_wen: out std_ulogic;
       flash_wait: in std_ulogic_vector(0 to 1);
       flash_wpn: out std_ulogic;
       flash_advn: out std_ulogic;
       pfl_flash_reqn: out std_ulogic;
       pfl_flash_grant: in std_ulogic;
       flash_intf_oe: out std_ulogic;
       
       -- -------------- --
       f_program_req: in std_ulogic;                                         -- Level --
       f_num_blocks: in std_ulogic_vector(0 to 9);                           -- 128KB Block Size --
       f_start_blk: in std_ulogic_vector(0 to 9);
       f_program_data: in std_ulogic_vector(0 to 31);
       f_program_data_val: in std_ulogic;
       f_program_data_ack: out std_ulogic;
       f_ready: out std_ulogic;
       f_done: out std_ulogic;
       f_stat_erase: out std_ulogic;
       f_stat_program: out std_ulogic;
       f_stat_read: out std_ulogic;
       f_remainder: out std_ulogic_vector(0 to 9);
       
       -- Read Interface --
       f_read_req: in std_ulogic;
       f_num_words_m1: in std_ulogic_vector(0 to 9);                         -- N-1 words --
       f_read_start_addr: in std_ulogic_vector(0 to 25);
       f_read_data: out std_ulogic_vector(0 to 31);
       f_read_data_val: out std_ulogic;
       f_read_data_ack: in std_ulogic);
End Component psl_flash;

Component psl
  PORT(psl_clk: in std_ulogic;
       crc_error: in std_ulogic;
       a0h_cvalid: in std_ulogic;
       a0h_ctag: in std_ulogic_vector(0 to 7);
       a0h_com: in std_ulogic_vector(0 to 12);
       a0h_cpad: in std_ulogic_vector(0 to 2);
       a0h_cabt: in std_ulogic_vector(0 to 2);
       a0h_cea: in std_ulogic_vector(0 to 63);
       a0h_cch: in std_ulogic_vector(0 to 15);
       a0h_csize: in std_ulogic_vector(0 to 11);
       ha0_croom: out std_ulogic_vector(0 to 7);
       a0h_ctagpar: in std_ulogic;
       a0h_compar: in std_ulogic;
       a0h_ceapar: in std_ulogic;
       ha0_brvalid: out std_ulogic;
       ha0_brtag: out std_ulogic_vector(0 to 7);
       ha0_brad: out std_ulogic_vector(0 to 5);
       a0h_brlat: in std_ulogic_vector(0 to 3);
       a0h_brdata: in std_ulogic_vector(0 to 511);
       a0h_brpar: in std_ulogic_vector(0 to 7);
       ha0_bwvalid: out std_ulogic;
       ha0_bwtag: out std_ulogic_vector(0 to 7);
       ha0_bwad: out std_ulogic_vector(0 to 5);
       ha0_bwdata: out std_ulogic_vector(0 to 511);
       ha0_bwpar: out std_ulogic_vector(0 to 7);
       ha0_brtagpar: out std_ulogic;
       ha0_bwtagpar: out std_ulogic;
       ha0_rvalid: out std_ulogic;
       ha0_rtag: out std_ulogic_vector(0 to 7);
       ha0_response: out std_ulogic_vector(0 to 7);
       ha0_rcredits: out std_ulogic_vector(0 to 8);
       ha0_rcachestate: out std_ulogic_vector(0 to 1);
       ha0_rcachepos: out std_ulogic_vector(0 to 12);
       ha0_rtagpar: out std_ulogic;
       ha0_mmval: out std_ulogic;
       ha0_mmrnw: out std_ulogic;
       ha0_mmdw: out std_ulogic;
       ha0_mmad: out std_ulogic_vector(0 to 23);
       ha0_mmdata: out std_ulogic_vector(0 to 63);
       ha0_mmcfg: out std_ulogic;
       a0h_mmack: in std_ulogic;
       a0h_mmdata: in std_ulogic_vector(0 to 63);
       ha0_mmadpar: out std_ulogic;
       ha0_mmdatapar: out std_ulogic;
       a0h_mmdatapar: in std_ulogic;
       ha0_jval: out std_ulogic;
       ha0_jcom: out std_ulogic_vector(0 to 7);
       ha0_jea: out std_ulogic_vector(0 to 63);
       a0h_jrunning: in std_ulogic;
       a0h_jdone: in std_ulogic;
       a0h_jcack: in std_ulogic;
       a0h_jerror: in std_ulogic_vector(0 to 63);
       a0h_tbreq: in std_ulogic;
       a0h_jyield: in std_ulogic;
       ha0_jeapar: out std_ulogic;
       ha0_jcompar: out std_ulogic;
       a0h_paren: in std_ulogic;
       ha0_pclock: out std_ulogic;
       psl_pcihip_freeze: out std_ulogic;                                    
       hi2c_cmdval: out std_ulogic;
       hi2c_dataval: out std_ulogic;
       hi2c_addr: out std_ulogic_vector(0 to 6);
       hi2c_rd: out std_ulogic;
       hi2c_cmdin: out std_ulogic_vector(0 to 7);
       hi2c_datain: out std_ulogic_vector(0 to 7);
       hi2c_blk: out std_ulogic;
       hi2c_bytecnt: out std_ulogic_vector(0 to 7);
       hi2c_cntlrsel: out std_ulogic_vector(0 to 2);
       i2ch_wrdatack: in std_ulogic;
       i2ch_dataval: in std_ulogic;
       i2ch_error: in std_ulogic;
       i2ch_dataout: in std_ulogic_vector(0 to 7);
       i2ch_ready: in std_ulogic;
       mon_power: in std_ulogic_vector(0 to 15);
       mon_temperature: in std_ulogic_vector(0 to 15);
       mon_enable: out std_ulogic;
       

       psl_pcihip0_rx_st_ready: out std_ulogic;
       pcihip0_psl_rx_st_valid: in std_ulogic;
       pcihip0_psl_rx_st_data: in std_ulogic_vector(0 to 255);
       pcihip0_psl_rx_st_parity: in std_ulogic_vector(0 to 31);
       pcihip0_psl_rx_st_sop: in std_ulogic;
       pcihip0_psl_rx_st_eop: in std_ulogic;
       pcihip0_psl_rx_st_empty: in std_ulogic_vector(0 to 1);
       pcihip0_psl_rx_st_err: in std_ulogic;
       psl_pcihip0_rx_st_mask: out std_ulogic;
       pcihip0_psl_rx_st_bar: in std_ulogic_vector(0 to 7);
       pcihip0_psl_tx_st_ready: in std_ulogic;
       psl_pcihip0_tx_st_valid: out std_ulogic;
       psl_pcihip0_tx_st_data: out std_ulogic_vector(0 to 255);
       psl_pcihip0_tx_st_parity: out std_ulogic_vector(0 to 31);
       psl_pcihip0_tx_st_sop: out std_ulogic;
       psl_pcihip0_tx_st_eop: out std_ulogic;
       psl_pcihip0_tx_st_empty: out std_ulogic_vector(0 to 1);
       psl_pcihip0_tx_st_err: out std_ulogic;
       pcihip0_psl_tx_cred_datafccp: in std_ulogic_vector(0 to 11);
       pcihip0_psl_tx_cred_datafcnp: in std_ulogic_vector(0 to 11);
       pcihip0_psl_tx_cred_datafcp: in std_ulogic_vector(0 to 11);
       pcihip0_psl_tx_cred_fchipcons: in std_ulogic_vector(0 to 5);
       pcihip0_psl_tx_cred_fcinfinite: in std_ulogic_vector(0 to 5);
       pcihip0_psl_tx_cred_hdrfccp: in std_ulogic_vector(0 to 7);
       pcihip0_psl_tx_cred_hdrfcnp: in std_ulogic_vector(0 to 7);
       pcihip0_psl_tx_cred_hdrfcp: in std_ulogic_vector(0 to 7);
       pcihip0_psl_ko_cpl_spc_header: in std_ulogic_vector(0 to 7);
       pcihip0_psl_ko_cpl_spc_data: in std_ulogic_vector(0 to 11);
       psl_pcihip0_freeze: out std_ulogic;
       pcihip0_psl_reset_status: in std_ulogic;
       psl_pcihip0_app_msi_req: out std_ulogic;
       pcihip0_psl_app_msi_ack: in std_ulogic;
       psl_pcihip0_app_msi_tc: out std_ulogic_vector(0 to 2);
       psl_pcihip0_app_msi_num: out std_ulogic_vector(0 to 4);
       pcihip0_psl_app_int_ack: in std_ulogic;
       psl_pcihip0_lmi_rden: out std_ulogic;
       psl_pcihip0_lmi_wren: out std_ulogic;
       psl_pcihip0_lmi_addr: out std_ulogic_vector(0 to 11);
       psl_pcihip0_lmi_din: out std_ulogic_vector(0 to 31);
       pcihip0_psl_lmi_ack: in std_ulogic;
       pcihip0_psl_lmi_dout: in std_ulogic_vector(0 to 31);
       pcihip0_psl_tl_cfg_add: in std_ulogic_vector(0 to 3);
       pcihip0_psl_tl_cfg_ctl: in std_ulogic_vector(0 to 31);
       pcihip0_psl_tl_cfg_sts: in std_ulogic_vector(0 to 52);
       pcihip0_psl_hip_reconfig_readdata: in std_ulogic_vector(0 to 15);
       psl_pcihip0_hip_reconfig_rst_n: out std_ulogic;
       psl_pcihip0_hip_reconfig_address: out std_ulogic_vector(0 to 9);
       psl_pcihip0_hip_reconfig_byte_en: out std_ulogic_vector(0 to 1);
       psl_pcihip0_hip_reconfig_read: out std_ulogic;
       psl_pcihip0_hip_reconfig_clk: out std_ulogic;
       psl_pcihip0_hip_reconfig_write: out std_ulogic;
       psl_pcihip0_hip_reconfig_writedata: out std_ulogic_vector(0 to 15);
       psl_pcihip0_interface_sel: out std_ulogic;
       psl_pcihip0_ser_shift_load: out std_ulogic;
       psl_pcihip0_cpl_err: out std_ulogic_vector(0 to 6);
       psl_pcihip0_cpl_pending: out std_ulogic;
       pcihip0_psl_tx_par_err: in std_ulogic_vector(0 to 1);
       pcihip0_psl_cfg_par_err: in std_ulogic;
       pcihip0_psl_rx_par_err: in std_ulogic;
       psl_pcihip0_pme_to_cr: out std_ulogic;
       pcihip0_psl_pme_to_sr: in std_ulogic;
       psl_pcihip0_pm_event: out std_ulogic;
       psl_pcihip0_pm_data: out std_ulogic_vector(0 to 9);
       psl_pcihip0_pm_auxpwr: out std_ulogic;
       pcihip0_psl_derr_cor_ext_rcv: in std_ulogic;
       pcihip0_psl_derr_cor_ext_rpl: in std_ulogic;
       pcihip0_psl_derr_rpl: in std_ulogic;
       psl_pcihip0_test_in: out std_ulogic_vector(0 to 31);
       pcihip0_psl_testin_zero: in std_ulogic;
       psl_pcihip0_simu_mode_pipe: out std_ulogic);
End Component psl;

Component psl_pcihip0
  PORT(
       ----------------------------------------------------
       pld_clk: in std_ulogic;
       coreclkout_hip: out std_ulogic;
       refclk: in std_logic;
       
       -- avalon st rx
       rx_st_ready: in std_ulogic;
       rx_st_valid: out std_ulogic;
       rx_st_data: out std_ulogic_vector(0 to 255);
       rx_st_parity: out std_ulogic_vector(0 to 31);
       rx_st_sop: out std_ulogic;
       rx_st_eop: out std_ulogic;
       rx_st_empty: out std_ulogic_vector(0 to 1);
       rx_st_err: out std_ulogic;
       rx_st_mask: in std_ulogic;
       rx_st_bar: out std_ulogic_vector(0 to 7);
       
       -- avalon st tx
       tx_st_ready: out std_ulogic;
       tx_st_valid: in std_ulogic;
       tx_st_data: in std_ulogic_vector(0 to 255);
       tx_st_parity: in std_ulogic_vector(0 to 31);
       tx_st_sop: in std_ulogic;
       tx_st_eop: in std_ulogic;
       tx_st_empty: in std_ulogic_vector(0 to 1);
       tx_st_err: in std_ulogic;
       tx_cred_datafccp: out std_ulogic_vector(0 to 11);
       tx_cred_datafcnp: out std_ulogic_vector(0 to 11);
       tx_cred_datafcp: out std_ulogic_vector(0 to 11);
       tx_cred_fchipcons: out std_ulogic_vector(0 to 5);
       tx_cred_fcinfinite: out std_ulogic_vector(0 to 5);
       tx_cred_hdrfccp: out std_ulogic_vector(0 to 7);
       tx_cred_hdrfcnp: out std_ulogic_vector(0 to 7);
       tx_cred_hdrfcp: out std_ulogic_vector(0 to 7);
       
       -- reset and link training
       npor: in std_logic;                                                   --sync reset the link
       pin_perst: in std_logic;                                              -- async reset the link
       reset_status: out std_ulogic;
       pld_clk_inuse: out std_ulogic;
       
       -- end point interrupt
       app_msi_req: in std_ulogic;
       app_msi_ack: out std_ulogic;
       app_msi_tc: in std_ulogic_vector(0 to 2);
       app_msi_num: in std_ulogic_vector(0 to 4);
       app_int_ack: out std_ulogic;
       
       -- LMI
       lmi_rden: in std_ulogic;
       lmi_wren: in std_ulogic;
       lmi_addr: in std_ulogic_vector(0 to 11);
       lmi_din: in std_ulogic_vector(0 to 31);
       lmi_ack: out std_ulogic;
       lmi_dout: out std_ulogic_vector(0 to 31);
       
       -- Transaction Layer Configuration
       tl_cfg_add: out std_ulogic_vector(0 to 3);
       tl_cfg_ctl: out std_ulogic_vector(0 to 31);
       tl_cfg_sts: out std_ulogic_vector(0 to 52);
       
       -- vsec
       cseb_rddata: in std_ulogic_vector(0 to 31);
       cseb_rdresponse: in std_ulogic_vector(0 to 4);
       cseb_waitrequest: in std_ulogic;
       cseb_wrresponse: in std_ulogic_vector(0 to 4);
       cseb_wrresp_valid: in std_ulogic;
       cseb_addr: out std_ulogic_vector(0 to 32);
       cseb_be: out std_ulogic_vector(0 to 3);
       cseb_rden: out std_ulogic;
       cseb_wrdata: out std_ulogic_vector(0 to 31);
       cseb_wren: out std_ulogic;
       cseb_wrresp_req: out std_ulogic;
       cseb_rddata_parity: in std_ulogic_vector(0 to 3);
       cseb_addr_parity: out std_ulogic_vector(0 to 4);
       cseb_wrdata_parity: out std_ulogic_vector(0 to 3);
       
       -- Completion Interface
       cpl_err: in std_ulogic_vector(0 to 6);
       cpl_pending: in std_ulogic;
       
       -- Parity Error Detection
       tx_par_err: out std_ulogic_vector(0 to 1);
       cfg_par_err: out std_ulogic;
       rx_par_err: out std_ulogic;
       
       -- Power Management
       pme_to_cr: in std_ulogic;
       pme_to_sr: out std_ulogic;
       pm_event: in std_ulogic;
       pm_data: in std_ulogic_vector(0 to 9);
       pm_auxpwr: in std_ulogic;
       
       -- ECC Error
       derr_cor_ext_rcv: out std_ulogic;
       derr_cor_ext_rpl: out std_ulogic;
       derr_rpl: out std_ulogic;
       
       -- serial in
       rx_in0: in std_logic;
       rx_in1: in std_logic;
       rx_in2: in std_logic;
       rx_in3: in std_logic;
       rx_in4: in std_logic;
       rx_in5: in std_logic;
       rx_in6: in std_logic;
       rx_in7: in std_logic;
       
       -- serial out
       tx_out0: out std_logic;
       tx_out1: out std_logic;
       tx_out2: out std_logic;
       tx_out3: out std_logic;
       tx_out4: out std_logic;
       tx_out5: out std_logic;
       tx_out6: out std_logic;
       tx_out7: out std_logic;
       
       --test interface
       test_in: in std_ulogic_vector(0 to 31);
       
       testin_zero: out std_ulogic;
       ko_cpl_spc_header: out std_ulogic_vector(0 to 7);
       ko_cpl_spc_data: out std_ulogic_vector(0 to 11);
       simu_mode_pipe: in std_ulogic);
End Component psl_pcihip0;


Signal a0h_brdata: std_ulogic_vector(0 to 511);  -- hline
Signal a0h_brlat: std_ulogic_vector(0 to 3);  -- v4bit
Signal a0h_brpar: std_ulogic_vector(0 to 7);  -- v8bit
Signal a0h_cabt: std_ulogic_vector(0 to 2);  -- cabt
Signal a0h_cch: std_ulogic_vector(0 to 15);  -- ctxhndl
Signal a0h_cea: std_ulogic_vector(0 to 63);  -- ead
Signal a0h_ceapar: std_ulogic;  -- bool
Signal a0h_com: std_ulogic_vector(0 to 12);  -- apcmd
Signal a0h_compar: std_ulogic;  -- bool
Signal a0h_cpad: std_ulogic_vector(0 to 2);  -- pade
Signal a0h_csize: std_ulogic_vector(0 to 11);  -- v12bit
Signal a0h_ctag: std_ulogic_vector(0 to 7);  -- acctag
Signal a0h_ctagpar: std_ulogic;  -- bool
Signal a0h_cvalid: std_ulogic;  -- bool
Signal a0h_jcack: std_ulogic;  -- bool
Signal a0h_jdone: std_ulogic;  -- bool
Signal a0h_jerror: std_ulogic_vector(0 to 63);  -- v64bit
Signal a0h_jrunning: std_ulogic;  -- bool
Signal a0h_jyield: std_ulogic;  -- bool
Signal a0h_mmack: std_ulogic;  -- bool
Signal a0h_mmdata: std_ulogic_vector(0 to 63);  -- v64bit
Signal a0h_mmdatapar: std_ulogic;  -- bool
Signal a0h_paren: std_ulogic;  -- bool
Signal a0h_tbreq: std_ulogic;  -- bool
Signal a0s_green_led: std_ulogic_vector(0 to 3);  -- v4bit
Signal a0s_red_led: std_ulogic_vector(0 to 3);  -- v4bit
Signal a0s_refclk_sfp_fs: std_ulogic;  -- bool
Signal a0s_refclk_sfp_fs_en: std_ulogic;  -- bool
Signal a0s_sfp0_en: std_ulogic;  -- bool
Signal a0s_sfp0_phy_mgmt_address: std_ulogic_vector(0 to 8);  -- v9bit
Signal a0s_sfp0_phy_mgmt_clk_reset: std_ulogic;  -- bool
Signal a0s_sfp0_phy_mgmt_read: std_ulogic;  -- bool
Signal a0s_sfp0_phy_mgmt_write: std_ulogic;  -- bool
Signal a0s_sfp0_phy_mgmt_writedata: std_ulogic_vector(0 to 31);  -- v32bit
Signal a0s_sfp0_rs0: std_ulogic;  -- bool
Signal a0s_sfp0_rs1: std_ulogic;  -- bool
Signal a0s_sfp0_scl: std_ulogic;  -- bool
Signal a0s_sfp0_sda: std_ulogic;  -- bool
Signal a0s_sfp0_sda_oe: std_ulogic;  -- bool
Signal a0s_sfp0_tx_coreclk: std_ulogic;  -- bool
Signal a0s_sfp0_tx_disable: std_ulogic;  -- bool
Signal a0s_sfp0_tx_forceelecidle: std_ulogic;  -- bool
Signal a0s_sfp0_tx_parallel_data: std_ulogic_vector(0 to 39);  -- v40bit
Signal a0s_sfp1_en: std_ulogic;  -- bool
Signal a0s_sfp1_phy_mgmt_address: std_ulogic_vector(0 to 8);  -- v9bit
Signal a0s_sfp1_phy_mgmt_clk_reset: std_ulogic;  -- bool
Signal a0s_sfp1_phy_mgmt_read: std_ulogic;  -- bool
Signal a0s_sfp1_phy_mgmt_write: std_ulogic;  -- bool
Signal a0s_sfp1_phy_mgmt_writedata: std_ulogic_vector(0 to 31);  -- v32bit
Signal a0s_sfp1_rs0: std_ulogic;  -- bool
Signal a0s_sfp1_rs1: std_ulogic;  -- bool
Signal a0s_sfp1_scl: std_ulogic;  -- bool
Signal a0s_sfp1_sda: std_ulogic;  -- bool
Signal a0s_sfp1_sda_oe: std_ulogic;  -- bool
Signal a0s_sfp1_tx_coreclk: std_ulogic;  -- bool
Signal a0s_sfp1_tx_disable: std_ulogic;  -- bool
Signal a0s_sfp1_tx_forceelecidle: std_ulogic;  -- bool
Signal a0s_sfp1_tx_parallel_data: std_ulogic_vector(0 to 39);  -- v40bit
Signal alt_xcvr_reconfig_0_reconfig_busy_reconfig_busy: std_ulogic;  -- bool
Signal aptm_req: std_ulogic;  -- bool
Signal cpld_oe: std_ulogic;  -- bool
Signal cpld_softreconfigreq: std_ulogic;  -- bool
Signal cpld_user_bs_req: std_ulogic;  -- bool
Signal cpld_usergolden: std_ulogic;  -- bool
Signal f_done: std_ulogic;  -- bool
Signal f_num_blocks: std_ulogic_vector(0 to 9);  -- v10bit
Signal f_num_words_m1: std_ulogic_vector(0 to 9);  -- v10bit
Signal f_program_data: std_ulogic_vector(0 to 31);  -- v32bit
Signal f_program_data_ack: std_ulogic;  -- bool
Signal f_program_data_val: std_ulogic;  -- bool
Signal f_program_req: std_ulogic;  -- bool
Signal f_read_data: std_ulogic_vector(0 to 31);  -- v32bit
Signal f_read_data_ack: std_ulogic;  -- bool
Signal f_read_data_val: std_ulogic;  -- bool
Signal f_read_req: std_ulogic;  -- bool
Signal f_read_start_addr: std_ulogic_vector(0 to 25);  -- v26bit
Signal f_ready: std_ulogic;  -- bool
Signal f_remainder: std_ulogic_vector(0 to 9);  -- v10bit
Signal f_start_blk: std_ulogic_vector(0 to 9);  -- v10bit
Signal f_stat_erase: std_ulogic;  -- bool
Signal f_stat_program: std_ulogic;  -- bool
Signal f_stat_read: std_ulogic;  -- bool
Signal flash_addr: std_ulogic_vector(0 to 25);  -- v26bit
Signal flash_advn: std_ulogic;  -- bool
Signal flash_cen: std_ulogic_vector(0 to 1);  -- v2bit
Signal flash_clk: std_ulogic;  -- bool
Signal flash_dat_oe: std_ulogic;  -- bool
Signal flash_datain: std_ulogic_vector(0 to 31);  -- v32bit
Signal flash_dataout: std_ulogic_vector(0 to 31);  -- v32bit
Signal flash_intf_oe: std_ulogic;  -- bool
Signal flash_oen: std_ulogic;  -- bool
Signal flash_rstn: std_ulogic;  -- bool
Signal flash_wait: std_ulogic_vector(0 to 1);  -- v2bit
Signal flash_wen: std_ulogic;  -- bool
Signal flash_wpn: std_ulogic;  -- bool
Signal ha0_brad: std_ulogic_vector(0 to 5);  -- v6bit
Signal ha0_brtag: std_ulogic_vector(0 to 7);  -- acctag
Signal ha0_brtagpar: std_ulogic;  -- bool
Signal ha0_brvalid: std_ulogic;  -- bool
Signal ha0_bwad: std_ulogic_vector(0 to 5);  -- v6bit
Signal ha0_bwdata: std_ulogic_vector(0 to 511);  -- hline
Signal ha0_bwpar: std_ulogic_vector(0 to 7);  -- v8bit
Signal ha0_bwtag: std_ulogic_vector(0 to 7);  -- acctag
Signal ha0_bwtagpar: std_ulogic;  -- bool
Signal ha0_bwvalid: std_ulogic;  -- bool
Signal ha0_croom: std_ulogic_vector(0 to 7);  -- v8bit
Signal ha0_jcom: std_ulogic_vector(0 to 7);  -- jbcom
Signal ha0_jcompar: std_ulogic;  -- bool
Signal ha0_jea: std_ulogic_vector(0 to 63);  -- v64bit
Signal ha0_jeapar: std_ulogic;  -- bool
Signal ha0_jval: std_ulogic;  -- bool
Signal ha0_mmad: std_ulogic_vector(0 to 23);  -- v24bit
Signal ha0_mmadpar: std_ulogic;  -- bool
Signal ha0_mmcfg: std_ulogic;  -- bool
Signal ha0_mmdata: std_ulogic_vector(0 to 63);  -- v64bit
Signal ha0_mmdatapar: std_ulogic;  -- bool
Signal ha0_mmdw: std_ulogic;  -- bool
Signal ha0_mmrnw: std_ulogic;  -- bool
Signal ha0_mmval: std_ulogic;  -- bool
Signal ha0_pclock: std_ulogic;  -- bool
Signal ha0_rcachepos: std_ulogic_vector(0 to 12);  -- v13bit
Signal ha0_rcachestate: std_ulogic_vector(0 to 1);  -- statespec
Signal ha0_rcredits: std_ulogic_vector(0 to 8);  -- v9bit
Signal ha0_response: std_ulogic_vector(0 to 7);  -- apresp
Signal ha0_rtag: std_ulogic_vector(0 to 7);  -- acctag
Signal ha0_rtagpar: std_ulogic;  -- bool
Signal ha0_rvalid: std_ulogic;  -- bool
Signal hi2c_addr: std_ulogic_vector(0 to 6);  -- v7bit
Signal hi2c_blk: std_ulogic;  -- bool
Signal hi2c_bytecnt: std_ulogic_vector(0 to 7);  -- v8bit
Signal hi2c_cmdin: std_ulogic_vector(0 to 7);  -- v8bit
Signal hi2c_cmdval: std_ulogic;  -- bool
Signal hi2c_cntlrsel: std_ulogic_vector(0 to 2);  -- v3bit
Signal hi2c_datain: std_ulogic_vector(0 to 7);  -- v8bit
Signal hi2c_dataval: std_ulogic;  -- bool
Signal hi2c_rd: std_ulogic;  -- bool
Signal hip_npor0: std_ulogic;  -- bool
Signal i2c0_scl_en: std_ulogic;  -- bool
Signal i2c0_scl_in: std_ulogic;  -- bool
Signal i2c0_scl_out: std_ulogic;  -- bool
Signal i2c0_sda_en: std_ulogic;  -- bool
Signal i2c0_sda_in: std_ulogic;  -- bool
Signal i2c0_sda_out: std_ulogic;  -- bool
Signal i2c1_scl_en: std_ulogic;  -- bool
Signal i2c1_scl_in: std_ulogic;  -- bool
Signal i2c1_scl_out: std_ulogic;  -- bool
Signal i2c1_sda_en: std_ulogic;  -- bool
Signal i2c1_sda_in: std_ulogic;  -- bool
Signal i2c1_sda_out: std_ulogic;  -- bool
Signal i2ch_dataout: std_ulogic_vector(0 to 7);  -- v8bit
Signal i2ch_dataval: std_ulogic;  -- bool
Signal i2ch_error: std_ulogic;  -- bool
Signal i2ch_ready: std_ulogic;  -- bool
Signal i2ch_wrdatack: std_ulogic;  -- bool
Signal i2cm_dataout: std_ulogic_vector(0 to 7);  -- v8bit
Signal i2cm_dataval: std_ulogic;  -- bool
Signal i2cm_error: std_ulogic;  -- bool
Signal i2cm_ready: std_ulogic;  -- bool
Signal i2cm_wrdatack: std_ulogic;  -- bool
Signal i_cpld_sda: std_ulogic;  -- bool
Signal i_cpld_usergolden: std_ulogic;  -- bool
Signal mi2c_addr: std_ulogic_vector(0 to 6);  -- v7bit
Signal mi2c_blk: std_ulogic;  -- bool
Signal mi2c_bytecnt: std_ulogic_vector(0 to 7);  -- v8bit
Signal mi2c_cmdin: std_ulogic_vector(0 to 7);  -- v8bit
Signal mi2c_cmdval: std_ulogic;  -- bool
Signal mi2c_cntlrsel: std_ulogic_vector(0 to 2);  -- v3bit
Signal mi2c_datain: std_ulogic_vector(0 to 7);  -- v8bit
Signal mi2c_dataval: std_ulogic;  -- bool
Signal mi2c_rd: std_ulogic;  -- bool
Signal mon_enable: std_ulogic;  -- bool
Signal mon_power: std_ulogic_vector(0 to 15);  -- v16bit
Signal mon_temperature: std_ulogic_vector(0 to 15);  -- v16bit
Signal pcihip0_psl_app_int_ack: std_ulogic;  -- bool
Signal pcihip0_psl_app_msi_ack: std_ulogic;  -- bool
Signal pcihip0_psl_cfg_par_err: std_ulogic;  -- bool
Signal pcihip0_psl_coreclkout_hip: std_ulogic;  -- bool
Signal pcihip0_psl_cseb_addr: std_ulogic_vector(0 to 32);  -- v33bit
Signal pcihip0_psl_cseb_addr_parity: std_ulogic_vector(0 to 4);  -- v5bit
Signal pcihip0_psl_cseb_be: std_ulogic_vector(0 to 3);  -- v4bit
Signal pcihip0_psl_cseb_rden: std_ulogic;  -- bool
Signal pcihip0_psl_cseb_wrdata: std_ulogic_vector(0 to 31);  -- v32bit
Signal pcihip0_psl_cseb_wrdata_parity: std_ulogic_vector(0 to 3);  -- v4bit
Signal pcihip0_psl_cseb_wren: std_ulogic;  -- bool
Signal pcihip0_psl_cseb_wrresp_req: std_ulogic;  -- bool
Signal pcihip0_psl_derr_cor_ext_rcv: std_ulogic;  -- bool
Signal pcihip0_psl_derr_cor_ext_rpl: std_ulogic;  -- bool
Signal pcihip0_psl_derr_rpl: std_ulogic;  -- bool
Signal pcihip0_psl_hip_reconfig_readdata: std_ulogic_vector(0 to 15);  -- v16bit
Signal pcihip0_psl_ko_cpl_spc_data: std_ulogic_vector(0 to 11);  -- v12bit
Signal pcihip0_psl_ko_cpl_spc_header: std_ulogic_vector(0 to 7);  -- v8bit
Signal pcihip0_psl_lmi_ack: std_ulogic;  -- bool
Signal pcihip0_psl_lmi_dout: std_ulogic_vector(0 to 31);  -- v32bit
Signal pcihip0_psl_pld_clk_inuse: std_ulogic;  -- bool
Signal pcihip0_psl_pme_to_sr: std_ulogic;  -- bool
Signal pcihip0_psl_reset_status: std_ulogic;  -- bool
Signal pcihip0_psl_rx_par_err: std_ulogic;  -- bool
Signal pcihip0_psl_rx_st_bar: std_ulogic_vector(0 to 7);  -- v8bit
Signal pcihip0_psl_rx_st_data: std_ulogic_vector(0 to 255);  -- v256bit
Signal pcihip0_psl_rx_st_empty: std_ulogic_vector(0 to 1);  -- v2bit
Signal pcihip0_psl_rx_st_eop: std_ulogic;  -- bool
Signal pcihip0_psl_rx_st_err: std_ulogic;  -- bool
Signal pcihip0_psl_rx_st_parity: std_ulogic_vector(0 to 31);  -- v32bit
Signal pcihip0_psl_rx_st_sop: std_ulogic;  -- bool
Signal pcihip0_psl_rx_st_valid: std_ulogic;  -- bool
Signal pcihip0_psl_testin_zero: std_ulogic;  -- bool
Signal pcihip0_psl_tl_cfg_add: std_ulogic_vector(0 to 3);  -- v4bit
Signal pcihip0_psl_tl_cfg_ctl: std_ulogic_vector(0 to 31);  -- v32bit
Signal pcihip0_psl_tl_cfg_sts: std_ulogic_vector(0 to 52);  -- v53bit
Signal pcihip0_psl_tx_cred_datafccp: std_ulogic_vector(0 to 11);  -- v12bit
Signal pcihip0_psl_tx_cred_datafcnp: std_ulogic_vector(0 to 11);  -- v12bit
Signal pcihip0_psl_tx_cred_datafcp: std_ulogic_vector(0 to 11);  -- v12bit
Signal pcihip0_psl_tx_cred_fchipcons: std_ulogic_vector(0 to 5);  -- v6bit
Signal pcihip0_psl_tx_cred_fcinfinite: std_ulogic_vector(0 to 5);  -- v6bit
Signal pcihip0_psl_tx_cred_hdrfccp: std_ulogic_vector(0 to 7);  -- v8bit
Signal pcihip0_psl_tx_cred_hdrfcnp: std_ulogic_vector(0 to 7);  -- v8bit
Signal pcihip0_psl_tx_cred_hdrfcp: std_ulogic_vector(0 to 7);  -- v8bit
Signal pcihip0_psl_tx_par_err: std_ulogic_vector(0 to 1);  -- v2bit
Signal pcihip0_psl_tx_st_ready: std_ulogic;  -- bool
Signal pfl_flash_grant: std_ulogic;  -- bool
Signal pfl_flash_reqn: std_ulogic;  -- bool
Signal psl_clk: std_ulogic;  -- bool
Signal psl_pcihip0_app_msi_num: std_ulogic_vector(0 to 4);  -- v5bit
Signal psl_pcihip0_app_msi_req: std_ulogic;  -- bool
Signal psl_pcihip0_app_msi_tc: std_ulogic_vector(0 to 2);  -- v3bit
Signal psl_pcihip0_cpl_err: std_ulogic_vector(0 to 6);  -- v7bit
Signal psl_pcihip0_cpl_pending: std_ulogic;  -- bool
Signal psl_pcihip0_cseb_rddata: std_ulogic_vector(0 to 31);  -- v32bit
Signal psl_pcihip0_cseb_rddata_parity: std_ulogic_vector(0 to 3);  -- v4bit
Signal psl_pcihip0_cseb_rdresponse: std_ulogic_vector(0 to 4);  -- v5bit
Signal psl_pcihip0_cseb_waitrequest: std_ulogic;  -- bool
Signal psl_pcihip0_cseb_wrresp_valid: std_ulogic;  -- bool
Signal psl_pcihip0_cseb_wrresponse: std_ulogic_vector(0 to 4);  -- v5bit
Signal psl_pcihip0_freeze: std_ulogic;  -- bool
Signal psl_pcihip0_hip_reconfig_address: std_ulogic_vector(0 to 9);  -- v10bit
Signal psl_pcihip0_hip_reconfig_byte_en: std_ulogic_vector(0 to 1);  -- v2bit
Signal psl_pcihip0_hip_reconfig_clk: std_ulogic;  -- bool
Signal psl_pcihip0_hip_reconfig_read: std_ulogic;  -- bool
Signal psl_pcihip0_hip_reconfig_rst_n: std_ulogic;  -- bool
Signal psl_pcihip0_hip_reconfig_write: std_ulogic;  -- bool
Signal psl_pcihip0_hip_reconfig_writedata: std_ulogic_vector(0 to 15);  -- v16bit
Signal psl_pcihip0_interface_sel: std_ulogic;  -- bool
Signal psl_pcihip0_lmi_addr: std_ulogic_vector(0 to 11);  -- v12bit
Signal psl_pcihip0_lmi_din: std_ulogic_vector(0 to 31);  -- v32bit
Signal psl_pcihip0_lmi_rden: std_ulogic;  -- bool
Signal psl_pcihip0_lmi_wren: std_ulogic;  -- bool
Signal psl_pcihip0_nfreeze: std_ulogic;  -- bool
Signal psl_pcihip0_pm_auxpwr: std_ulogic;  -- bool
Signal psl_pcihip0_pm_data: std_ulogic_vector(0 to 9);  -- v10bit
Signal psl_pcihip0_pm_event: std_ulogic;  -- bool
Signal psl_pcihip0_pme_to_cr: std_ulogic;  -- bool
Signal psl_pcihip0_rx_st_mask: std_ulogic;  -- bool
Signal psl_pcihip0_rx_st_ready: std_ulogic;  -- bool
Signal psl_pcihip0_ser_shift_load: std_ulogic;  -- bool
Signal psl_pcihip0_simu_mode_pipe: std_ulogic;  -- bool
Signal psl_pcihip0_test_in: std_ulogic_vector(0 to 31);  -- v32bit
Signal psl_pcihip0_tx_st_data: std_ulogic_vector(0 to 255);  -- v256bit
Signal psl_pcihip0_tx_st_empty: std_ulogic_vector(0 to 1);  -- v2bit
Signal psl_pcihip0_tx_st_eop: std_ulogic;  -- bool
Signal psl_pcihip0_tx_st_err: std_ulogic;  -- bool
Signal psl_pcihip0_tx_st_parity: std_ulogic_vector(0 to 31);  -- v32bit
Signal psl_pcihip0_tx_st_sop: std_ulogic;  -- bool
Signal psl_pcihip0_tx_st_valid: std_ulogic;  -- bool
Signal psl_pcihip_freeze: std_ulogic;  -- bool
Signal ptma_grant: std_ulogic;  -- bool
Signal rgb_led_pat: std_ulogic_vector(0 to 5);  -- v6bit
Signal sa0_sfp0_mod_abs: std_ulogic;  -- bool
Signal sa0_sfp0_phy_mgmt_readdata: std_ulogic_vector(0 to 31);  -- v32bit
Signal sa0_sfp0_phy_mgmt_waitrequest: std_ulogic;  -- bool
Signal sa0_sfp0_pll_locked: std_ulogic;  -- bool
Signal sa0_sfp0_rx_clk: std_ulogic;  -- bool
Signal sa0_sfp0_rx_is_lockedtodata: std_ulogic;  -- bool
Signal sa0_sfp0_rx_is_lockedtoref: std_ulogic;  -- bool
Signal sa0_sfp0_rx_los: std_ulogic;  -- bool
Signal sa0_sfp0_rx_parallel_data: std_ulogic_vector(0 to 39);  -- v40bit
Signal sa0_sfp0_rx_ready: std_ulogic;  -- bool
Signal sa0_sfp0_rx_signaldetect: std_ulogic;  -- bool
Signal sa0_sfp0_sda: std_ulogic;  -- bool
Signal sa0_sfp0_tx_clk: std_ulogic;  -- bool
Signal sa0_sfp0_tx_fault: std_ulogic;  -- bool
Signal sa0_sfp0_tx_ready: std_ulogic;  -- bool
Signal sa0_sfp1_mod_abs: std_ulogic;  -- bool
Signal sa0_sfp1_phy_mgmt_readdata: std_ulogic_vector(0 to 31);  -- v32bit
Signal sa0_sfp1_phy_mgmt_waitrequest: std_ulogic;  -- bool
Signal sa0_sfp1_pll_locked: std_ulogic;  -- bool
Signal sa0_sfp1_rx_clk: std_ulogic;  -- bool
Signal sa0_sfp1_rx_is_lockedtodata: std_ulogic;  -- bool
Signal sa0_sfp1_rx_is_lockedtoref: std_ulogic;  -- bool
Signal sa0_sfp1_rx_los: std_ulogic;  -- bool
Signal sa0_sfp1_rx_parallel_data: std_ulogic_vector(0 to 39);  -- v40bit
Signal sa0_sfp1_rx_ready: std_ulogic;  -- bool
Signal sa0_sfp1_rx_signaldetect: std_ulogic;  -- bool
Signal sa0_sfp1_sda: std_ulogic;  -- bool
Signal sa0_sfp1_tx_clk: std_ulogic;  -- bool
Signal sa0_sfp1_tx_fault: std_ulogic;  -- bool
Signal sa0_sfp1_tx_ready: std_ulogic;  -- bool
Signal sfp0_reconfig_from_xcvr: std_ulogic_vector(0 to 91);  -- v92bit
Signal sfp0_reconfig_to_xcvr: std_ulogic_vector(0 to 139);  -- v140bit
Signal sfp1_reconfig_from_xcvr: std_ulogic_vector(0 to 91);  -- v92bit
Signal sfp1_reconfig_to_xcvr: std_ulogic_vector(0 to 139);  -- v140bit
Signal crc_errorinternal: std_ulogic;  -- bool

begin




    -- -----------------------------------------
    -- CRC Detection
    -- -----------------------------------------
    crc: psl_svcrc
      PORT MAP (
         crcerror => crc_errorinternal,
         crc_clk => psl_clk
    );


    -- drive logic clock from here
    cc: psl_clkcontrol
      PORT MAP (
         clkout => psl_clk,
         clkin => pcihip0_psl_coreclkout_hip
    );



                    -- Drive DDR3 External Signals to inacive --
    b_dram0_mem_dq <= (others => '0') ;
    b_dram0_mem_dqs <= (others => '0') ;
    b_dram0_mem_dqsn <= (others => '0') ;
    o_dram0_mem_dm <= (others => '0') ;
    o_dram0_mem_a <= (others => '0') ;
    o_dram0_mem_ba <= (others => '0') ;
    o_dram0_mem_ck <= '1' ;
    o_dram0_mem_ck_n <= '0' ;
    o_dram0_mem_cs_n <= (others => '1') ;
    o_dram0_mem_cke <= (others => '0') ;
    o_dram0_mem_odt <= (others => '0') ;
    o_dram0_mem_ras_n <= '1' ;
    o_dram0_mem_cas_n <= '1' ;
    o_dram0_mem_we_n <= '1' ;
    o_dram0_mem_reset_n <= '0' ;
                    -- Drive DDR3 External Signals to inacive --
    b_dram1_mem_dq <= (others => '0') ;
    b_dram1_mem_dqs <= (others => '0') ;
    b_dram1_mem_dqsn <= (others => '0') ;
    o_dram1_mem_dm <= (others => '0') ;
    o_dram1_mem_a <= (others => '0') ;
    o_dram1_mem_ba <= (others => '0') ;
    o_dram1_mem_ck <= '1' ;
    o_dram1_mem_ck_n <= '0' ;
    o_dram1_mem_cs_n <= (others => '1') ;
    o_dram1_mem_cke <= (others => '0') ;
    o_dram1_mem_odt <= (others => '0') ;
    o_dram1_mem_ras_n <= '1' ;
    o_dram1_mem_cas_n <= '1' ;
    o_dram1_mem_we_n <= '1' ;
    o_dram1_mem_reset_n <= '0' ;


    a0: psl_accel
      PORT MAP (
         ah_cvalid => a0h_cvalid,
         ah_ctag => a0h_ctag,
         ah_com => a0h_com,
         ah_cpad => a0h_cpad,
         ah_cabt => a0h_cabt,
         ah_cea => a0h_cea,
         ah_cch => a0h_cch,
         ah_csize => a0h_csize,
         ha_croom => ha0_croom,
         ah_ctagpar => a0h_ctagpar,
         ah_compar => a0h_compar,
         ah_ceapar => a0h_ceapar,
         ha_brvalid => ha0_brvalid,
         ha_brtag => ha0_brtag,
         ha_brad => ha0_brad,
         ah_brlat => a0h_brlat,
         ah_brdata => a0h_brdata,
         ah_brpar => a0h_brpar,
         ha_bwvalid => ha0_bwvalid,
         ha_bwtag => ha0_bwtag,
         ha_bwad => ha0_bwad,
         ha_bwdata => ha0_bwdata,
         ha_bwpar => ha0_bwpar,
         ha_brtagpar => ha0_brtagpar,
         ha_bwtagpar => ha0_bwtagpar,
         ha_rvalid => ha0_rvalid,
         ha_rtag => ha0_rtag,
         ha_response => ha0_response,
         ha_rcredits => ha0_rcredits,
         ha_rcachestate => ha0_rcachestate,
         ha_rcachepos => ha0_rcachepos,
         ha_rtagpar => ha0_rtagpar,
         ha_mmval => ha0_mmval,
         ha_mmrnw => ha0_mmrnw,
         ha_mmdw => ha0_mmdw,
         ha_mmad => ha0_mmad,
         ha_mmdata => ha0_mmdata,
         ha_mmcfg => ha0_mmcfg,
         ah_mmack => a0h_mmack,
         ah_mmdata => a0h_mmdata,
         ha_mmadpar => ha0_mmadpar,
         ha_mmdatapar => ha0_mmdatapar,
         ah_mmdatapar => a0h_mmdatapar,
         ha_jval => ha0_jval,
         ha_jcom => ha0_jcom,
         ha_jea => ha0_jea,
         ah_jrunning => a0h_jrunning,
         ah_jdone => a0h_jdone,
         ah_jcack => a0h_jcack,
         ah_jerror => a0h_jerror,
         ah_tbreq => a0h_tbreq,
         ah_jyield => a0h_jyield,
         ha_jeapar => ha0_jeapar,
         ha_jcompar => ha0_jcompar,
         ah_paren => a0h_paren,
         as_sfp0_phy_mgmt_clk_reset => a0s_sfp0_phy_mgmt_clk_reset,
         as_sfp0_phy_mgmt_address => a0s_sfp0_phy_mgmt_address,
         as_sfp0_phy_mgmt_read => a0s_sfp0_phy_mgmt_read,
         sa_sfp0_phy_mgmt_readdata => sa0_sfp0_phy_mgmt_readdata,
         sa_sfp0_phy_mgmt_waitrequest => sa0_sfp0_phy_mgmt_waitrequest,
         as_sfp0_phy_mgmt_write => a0s_sfp0_phy_mgmt_write,
         as_sfp0_phy_mgmt_writedata => a0s_sfp0_phy_mgmt_writedata,
         sa_sfp0_tx_ready => sa0_sfp0_tx_ready,
         sa_sfp0_rx_ready => sa0_sfp0_rx_ready,
         as_sfp0_tx_forceelecidle => a0s_sfp0_tx_forceelecidle,
         sa_sfp0_pll_locked => sa0_sfp0_pll_locked,
         sa_sfp0_rx_is_lockedtoref => sa0_sfp0_rx_is_lockedtoref,
         sa_sfp0_rx_is_lockedtodata => sa0_sfp0_rx_is_lockedtodata,
         sa_sfp0_rx_signaldetect => sa0_sfp0_rx_signaldetect,
         as_sfp0_tx_coreclk => a0s_sfp0_tx_coreclk,
         sa_sfp0_tx_clk => sa0_sfp0_tx_clk,
         sa_sfp0_rx_clk => sa0_sfp0_rx_clk,
         as_sfp0_tx_parallel_data => a0s_sfp0_tx_parallel_data,
         sa_sfp0_rx_parallel_data => sa0_sfp0_rx_parallel_data,
         sa_sfp0_tx_fault => sa0_sfp0_tx_fault,
         sa_sfp0_mod_abs => sa0_sfp0_mod_abs,
         sa_sfp0_rx_los => sa0_sfp0_rx_los,
         as_sfp0_tx_disable => a0s_sfp0_tx_disable,
         as_sfp0_rs0 => a0s_sfp0_rs0,
         as_sfp0_rs1 => a0s_sfp0_rs1,
         as_sfp0_scl => a0s_sfp0_scl,
         as_sfp0_en => a0s_sfp0_en,
         sa_sfp0_sda => sa0_sfp0_sda,
         as_sfp0_sda => a0s_sfp0_sda,
         as_sfp0_sda_oe => a0s_sfp0_sda_oe,
         as_sfp1_phy_mgmt_clk_reset => a0s_sfp1_phy_mgmt_clk_reset,
         as_sfp1_phy_mgmt_address => a0s_sfp1_phy_mgmt_address,
         as_sfp1_phy_mgmt_read => a0s_sfp1_phy_mgmt_read,
         sa_sfp1_phy_mgmt_readdata => sa0_sfp1_phy_mgmt_readdata,
         sa_sfp1_phy_mgmt_waitrequest => sa0_sfp1_phy_mgmt_waitrequest,
         as_sfp1_phy_mgmt_write => a0s_sfp1_phy_mgmt_write,
         as_sfp1_phy_mgmt_writedata => a0s_sfp1_phy_mgmt_writedata,
         sa_sfp1_tx_ready => sa0_sfp1_tx_ready,
         sa_sfp1_rx_ready => sa0_sfp1_rx_ready,
         as_sfp1_tx_forceelecidle => a0s_sfp1_tx_forceelecidle,
         sa_sfp1_pll_locked => sa0_sfp1_pll_locked,
         sa_sfp1_rx_is_lockedtoref => sa0_sfp1_rx_is_lockedtoref,
         sa_sfp1_rx_is_lockedtodata => sa0_sfp1_rx_is_lockedtodata,
         sa_sfp1_rx_signaldetect => sa0_sfp1_rx_signaldetect,
         as_sfp1_tx_coreclk => a0s_sfp1_tx_coreclk,
         sa_sfp1_tx_clk => sa0_sfp1_tx_clk,
         sa_sfp1_rx_clk => sa0_sfp1_rx_clk,
         as_sfp1_tx_parallel_data => a0s_sfp1_tx_parallel_data,
         sa_sfp1_rx_parallel_data => sa0_sfp1_rx_parallel_data,
         sa_sfp1_tx_fault => sa0_sfp1_tx_fault,
         sa_sfp1_mod_abs => sa0_sfp1_mod_abs,
         sa_sfp1_rx_los => sa0_sfp1_rx_los,
         as_sfp1_tx_disable => a0s_sfp1_tx_disable,
         as_sfp1_rs0 => a0s_sfp1_rs0,
         as_sfp1_rs1 => a0s_sfp1_rs1,
         as_sfp1_scl => a0s_sfp1_scl,
         as_sfp1_en => a0s_sfp1_en,
         sa_sfp1_sda => sa0_sfp1_sda,
         as_sfp1_sda => a0s_sfp1_sda,
         as_sfp1_sda_oe => a0s_sfp1_sda_oe,
         as_refclk_sfp_fs => a0s_refclk_sfp_fs,
         as_refclk_sfp_fs_en => a0s_refclk_sfp_fs_en,
         as_red_led => a0s_red_led,
         as_green_led => a0s_green_led,
         ha_pclock => ha0_pclock
    );


    sfp0: sfpp_phy
      PORT MAP (
         phy_mgmt_clk => TCONV(psl_clk),
         phy_mgmt_clk_reset => TCONV(a0s_sfp0_phy_mgmt_clk_reset),
         phy_mgmt_address => TCONV(a0s_sfp0_phy_mgmt_address),
         phy_mgmt_read => TCONV(a0s_sfp0_phy_mgmt_read),
         TCONV(phy_mgmt_readdata) => sa0_sfp0_phy_mgmt_readdata,
         TCONV(phy_mgmt_waitrequest) => sa0_sfp0_phy_mgmt_waitrequest,
         phy_mgmt_write => TCONV(a0s_sfp0_phy_mgmt_write),
         phy_mgmt_writedata => TCONV(a0s_sfp0_phy_mgmt_writedata),
         TCONV(tx_ready) => sa0_sfp0_tx_ready,
         TCONV(rx_ready) => sa0_sfp0_rx_ready,
         pll_ref_clk => i_refclk_sfp,
         tx_serial_data => o_sfp0_tx_serial_data,
         tx_forceelecidle => TCONV(a0s_sfp0_tx_forceelecidle),
         TCONV(pll_locked) => sa0_sfp0_pll_locked,
         rx_serial_data => i_sfp0_rx_serial_data,
         TCONV(rx_is_lockedtoref) => sa0_sfp0_rx_is_lockedtoref,
         TCONV(rx_is_lockedtodata) => sa0_sfp0_rx_is_lockedtodata,
         TCONV(rx_signaldetect) => sa0_sfp0_rx_signaldetect,
         tx_coreclkin => TCONV(a0s_sfp0_tx_coreclk),
         TCONV(tx_clkout) => sa0_sfp0_tx_clk,
         TCONV(rx_clkout) => sa0_sfp0_rx_clk,
         tx_parallel_data => TCONV(a0s_sfp0_tx_parallel_data),
         TCONV(rx_parallel_data) => sa0_sfp0_rx_parallel_data,
         TCONV(reconfig_from_xcvr) => sfp0_reconfig_from_xcvr,
         reconfig_to_xcvr => TCONV(sfp0_reconfig_to_xcvr)
    );


    gpi_sa0_sfp0_tx_fault: psl_gpi1
      PORT MAP (
         pin => i_sfp0_tx_fault,
         id => sa0_sfp0_tx_fault
    );

    gpi_sa0_sfp0_mod_abs: psl_gpi1
      PORT MAP (
         pin => i_sfp0_mod_abs,
         id => sa0_sfp0_mod_abs
    );

    gpi_sa0_sfp0_rx_los: psl_gpi1
      PORT MAP (
         pin => i_sfp0_rx_los,
         id => sa0_sfp0_rx_los
    );


    gpo_o_sfp0_tx_disable: psl_gpo1
      PORT MAP (
         pin => o_sfp0_tx_disable,
         od => a0s_sfp0_tx_disable,
         oe => a0s_sfp0_en
    );

    gpo_o_sfp0_rs0: psl_gpo1
      PORT MAP (
         pin => o_sfp0_rs0,
         od => a0s_sfp0_rs0,
         oe => a0s_sfp0_en
    );

    gpo_o_sfp0_rs1: psl_gpo1
      PORT MAP (
         pin => o_sfp0_rs1,
         od => a0s_sfp0_rs1,
         oe => a0s_sfp0_en
    );

    gpo_o_sfp0_scl: psl_gpo1
      PORT MAP (
         pin => o_sfp0_scl,
         od => a0s_sfp0_scl,
         oe => a0s_sfp0_en
    );


    gpio_b_sfp0_sda: psl_gpio1
      PORT MAP (
         pin => b_sfp0_sda,
         id => sa0_sfp0_sda,
         od => a0s_sfp0_sda,
         oe => a0s_sfp0_sda_oe
    );


    sfp1: sfpp_phy
      PORT MAP (
         phy_mgmt_clk => TCONV(psl_clk),
         phy_mgmt_clk_reset => TCONV(a0s_sfp1_phy_mgmt_clk_reset),
         phy_mgmt_address => TCONV(a0s_sfp1_phy_mgmt_address),
         phy_mgmt_read => TCONV(a0s_sfp1_phy_mgmt_read),
         TCONV(phy_mgmt_readdata) => sa0_sfp1_phy_mgmt_readdata,
         TCONV(phy_mgmt_waitrequest) => sa0_sfp1_phy_mgmt_waitrequest,
         phy_mgmt_write => TCONV(a0s_sfp1_phy_mgmt_write),
         phy_mgmt_writedata => TCONV(a0s_sfp1_phy_mgmt_writedata),
         TCONV(tx_ready) => sa0_sfp1_tx_ready,
         TCONV(rx_ready) => sa0_sfp1_rx_ready,
         pll_ref_clk => i_refclk_sfp,
         tx_serial_data => o_sfp1_tx_serial_data,
         tx_forceelecidle => TCONV(a0s_sfp1_tx_forceelecidle),
         TCONV(pll_locked) => sa0_sfp1_pll_locked,
         rx_serial_data => i_sfp1_rx_serial_data,
         TCONV(rx_is_lockedtoref) => sa0_sfp1_rx_is_lockedtoref,
         TCONV(rx_is_lockedtodata) => sa0_sfp1_rx_is_lockedtodata,
         TCONV(rx_signaldetect) => sa0_sfp1_rx_signaldetect,
         tx_coreclkin => TCONV(a0s_sfp1_tx_coreclk),
         TCONV(tx_clkout) => sa0_sfp1_tx_clk,
         TCONV(rx_clkout) => sa0_sfp1_rx_clk,
         tx_parallel_data => TCONV(a0s_sfp1_tx_parallel_data),
         TCONV(rx_parallel_data) => sa0_sfp1_rx_parallel_data,
         TCONV(reconfig_from_xcvr) => sfp1_reconfig_from_xcvr,
         reconfig_to_xcvr => TCONV(sfp1_reconfig_to_xcvr)
    );


    gpi_sa0_sfp1_tx_fault: psl_gpi1
      PORT MAP (
         pin => i_sfp1_tx_fault,
         id => sa0_sfp1_tx_fault
    );

    gpi_sa0_sfp1_mod_abs: psl_gpi1
      PORT MAP (
         pin => i_sfp1_mod_abs,
         id => sa0_sfp1_mod_abs
    );

    gpi_sa0_sfp1_rx_los: psl_gpi1
      PORT MAP (
         pin => i_sfp1_rx_los,
         id => sa0_sfp1_rx_los
    );


    gpo_o_sfp1_tx_disable: psl_gpo1
      PORT MAP (
         pin => o_sfp1_tx_disable,
         od => a0s_sfp1_tx_disable,
         oe => a0s_sfp1_en
    );

    gpo_o_sfp1_rs0: psl_gpo1
      PORT MAP (
         pin => o_sfp1_rs0,
         od => a0s_sfp1_rs0,
         oe => a0s_sfp1_en
    );

    gpo_o_sfp1_rs1: psl_gpo1
      PORT MAP (
         pin => o_sfp1_rs1,
         od => a0s_sfp1_rs1,
         oe => a0s_sfp1_en
    );

    gpo_o_sfp1_scl: psl_gpo1
      PORT MAP (
         pin => o_sfp1_scl,
         od => a0s_sfp1_scl,
         oe => a0s_sfp1_en
    );


    gpio_b_sfp1_sda: psl_gpio1
      PORT MAP (
         pin => b_sfp1_sda,
         id => sa0_sfp1_sda,
         od => a0s_sfp1_sda,
         oe => a0s_sfp1_sda_oe
    );




    sfp_reconfig: sfpp_reconfig
      PORT MAP (
         clk_clk => pci_pi_refclk0,
         reset_reset_n => pci_pi_nperst0,
         TCONV(alt_xcvr_reconfig_0_ch0_1_to_xcvr_reconfig_to_xcvr) => sfp0_reconfig_to_xcvr,
         alt_xcvr_reconfig_0_ch0_1_from_xcvr_reconfig_from_xcvr => TCONV(sfp0_reconfig_from_xcvr),
         TCONV(alt_xcvr_reconfig_0_ch2_3_to_xcvr_reconfig_to_xcvr) => sfp1_reconfig_to_xcvr,
         alt_xcvr_reconfig_0_ch2_3_from_xcvr_reconfig_from_xcvr => TCONV(sfp1_reconfig_from_xcvr),
         TCONV(alt_xcvr_reconfig_0_reconfig_busy_reconfig_busy) => alt_xcvr_reconfig_0_reconfig_busy_reconfig_busy
    );


    gpo_o_refclk_sfp_fs: psl_gpo1
      PORT MAP (
         pin => o_refclk_sfp_fs,
         od => a0s_refclk_sfp_fs,
         oe => a0s_refclk_sfp_fs_en
    );

    gpo_o_red_led: psl_gpo4
      PORT MAP (
         pin => o_red_led,
         od => a0s_red_led,
         oe => '1'
    );

    gpo_o_green_led: psl_gpo4
      PORT MAP (
         pin => o_green_led,
         od => a0s_green_led,
         oe => '1'
    );



    rgb_led_pat <= ( cpld_usergolden & "01111" );

    
    rgbleds: psl_gpo6
      PORT MAP (
         pin => o_rgb_led,
         od => rgb_led_pat,
         oe => '1'
    );


    -- Power Temperature Monitoring
    ptmon: psl_ptmon
      PORT MAP (
         mi2c_cmdval => mi2c_cmdval,
         mi2c_dataval => mi2c_dataval,
         mi2c_addr => mi2c_addr,
         mi2c_rd => mi2c_rd,
         mi2c_cmdin => mi2c_cmdin,
         mi2c_datain => mi2c_datain,
         mi2c_blk => mi2c_blk,
         mi2c_bytecnt => mi2c_bytecnt,
         mi2c_cntlrsel => mi2c_cntlrsel,
         i2cm_wrdatack => i2cm_wrdatack,
         i2cm_dataval => i2cm_dataval,
         i2cm_error => i2cm_error,
         i2cm_dataout => i2cm_dataout,
         i2cm_ready => i2cm_ready,
         hi2c_cmdval => hi2c_cmdval,
         hi2c_dataval => hi2c_dataval,
         hi2c_addr => hi2c_addr,
         hi2c_rd => hi2c_rd,
         hi2c_cmdin => hi2c_cmdin,
         hi2c_datain => hi2c_datain,
         hi2c_blk => hi2c_blk,
         hi2c_bytecnt => hi2c_bytecnt,
         hi2c_cntlrsel => hi2c_cntlrsel,
         i2ch_wrdatack => i2ch_wrdatack,
         i2ch_dataval => i2ch_dataval,
         i2ch_error => i2ch_error,
         i2ch_dataout => i2ch_dataout,
         i2ch_ready => i2ch_ready,
         mon_power => mon_power,
         mon_temperature => mon_temperature,
         mon_enable => mon_enable,
         aptm_req => aptm_req,
         ptma_grant => ptma_grant,
         psl_clk => psl_clk
    );

    aptm_req <= '0' ;


    -- PMBUS (power supply controller & system monitor)
    -- I2C logic
    i2c: psl_i2c
      PORT MAP (
         i2c0_scl_out => i2c0_scl_out,
         i2c0_scl_in => i2c0_scl_in,
         i2c0_sda_out => i2c0_sda_out,
         i2c0_sda_in => i2c0_sda_in,
         i2c1_scl_out => i2c1_scl_out,
         i2c1_scl_in => i2c1_scl_in,
         i2c1_sda_out => i2c1_sda_out,
         i2c1_sda_in => i2c1_sda_in,
         mi2c_cmdval => mi2c_cmdval,
         mi2c_dataval => mi2c_dataval,
         mi2c_addr => mi2c_addr,
         mi2c_rd => mi2c_rd,
         mi2c_cmdin => mi2c_cmdin,
         mi2c_datain => mi2c_datain,
         mi2c_blk => mi2c_blk,
         mi2c_bytecnt => mi2c_bytecnt,
         mi2c_cntlrsel => mi2c_cntlrsel,
         i2cm_wrdatack => i2cm_wrdatack,
         i2cm_dataval => i2cm_dataval,
         i2cm_error => i2cm_error,
         i2cm_dataout => i2cm_dataout,
         i2cm_ready => i2cm_ready,
         psl_clk => psl_clk
    );

    i2c0_scl_en <=  not i2c0_scl_out ;
    i2c0_sda_en <=  not i2c0_sda_out ;
    gpio_b_ucd_scl: psl_gpio1
      PORT MAP (
         pin => b_ucd_scl,
         id => i2c0_scl_in,
         od => '0',
         oe => i2c0_scl_en
    );

    gpio_b_ucd_sda: psl_gpio1
      PORT MAP (
         pin => b_ucd_sda,
         id => i2c0_sda_in,
         od => '0',
         oe => i2c0_sda_en
    );


    -- Temperature Sensor
    i2c1_scl_en <=  not i2c1_scl_out ;
    i2c1_sda_en <=  not i2c1_sda_out ;
    gpio_b_therm_scl: psl_gpio1
      PORT MAP (
         pin => b_therm_scl,
         id => i2c1_scl_in,
         od => '0',
         oe => i2c1_scl_en
    );

    gpio_b_therm_sda: psl_gpio1
      PORT MAP (
         pin => b_therm_sda,
         id => i2c1_sda_in,
         od => '0',
         oe => i2c1_sda_en
    );


    -- CPLD I2C and Reconfig
    o_cpld_scl <= '0' ;
    gpio_b_cpld_sda: psl_gpio1
      PORT MAP (
         pin => b_cpld_sda,
         id => i_cpld_sda,
         od => '0',
         oe => '0'
    );


   
    cfg_req: psl_gpo1
      PORT MAP (
         pin => o_cpld_softreconfigreq,
         od => cpld_softreconfigreq,
         oe => '1'
    );


    usr_bs: psl_gpio1
      PORT MAP (
         pin => b_cpld_usergolden,
         id => i_cpld_usergolden,
         od => cpld_user_bs_req,
         oe => cpld_oe
    );


    
    o_debug <= (others => '0') ;

    cpld_usergolden <= '1' ;

    -- Flash pins
    frstn: psl_gpo1
      PORT MAP (
         pin => o_flash_rstn,
         od => flash_rstn,
         oe => flash_intf_oe
    );

    foen: psl_gpo1
      PORT MAP (
         pin => o_flash_oen,
         od => flash_oen,
         oe => flash_intf_oe
    );

    fwen: psl_gpo1
      PORT MAP (
         pin => o_flash_wen,
         od => flash_wen,
         oe => flash_intf_oe
    );

    fadvn: psl_gpo1
      PORT MAP (
         pin => o_flash_advn,
         od => flash_advn,
         oe => flash_intf_oe
    );


    fclk: psl_gpo1
      PORT MAP (
         pin => o_flash_clk,
         od => flash_clk,
         oe => flash_intf_oe
    );

    fwpn: psl_gpo1
      PORT MAP (
         pin => o_flash_wpn,
         od => flash_wpn,
         oe => flash_intf_oe
    );

    fcen: psl_gpo2
      PORT MAP (
         pin => o_flash_cen,
         od => flash_cen,
         oe => flash_intf_oe
    );

    fwait: psl_gpi2
      PORT MAP (
         pin => i_flash_wait,
         id => flash_wait
    );

    pflr: psl_gpo1
      PORT MAP (
         pin => o_pfl_flash_reqn,
         od => pfl_flash_reqn,
         oe => '1'
    );

    fgrant: psl_gpi1
      PORT MAP (
         pin => i_pfl_flash_grant,
         id => pfl_flash_grant
    );


    fadr: psl_gpo26
      PORT MAP (
         pin => o_flash_a,
         od => flash_addr,
         oe => flash_intf_oe
    );


    fdq: psl_gpio32
      PORT MAP (
         pin => b_flash_dq,
         id => flash_datain,
         od => flash_dataout,
         oe => flash_dat_oe
    );



    -- vsec logic
    v: psl_vsec
      PORT MAP (
         cseb_rddata => psl_pcihip0_cseb_rddata,
         cseb_rdresponse => psl_pcihip0_cseb_rdresponse,
         cseb_waitrequest => psl_pcihip0_cseb_waitrequest,
         cseb_wrresponse => psl_pcihip0_cseb_wrresponse,
         cseb_wrresp_valid => psl_pcihip0_cseb_wrresp_valid,
         cseb_addr => pcihip0_psl_cseb_addr,
         cseb_be => pcihip0_psl_cseb_be,
         cseb_rden => pcihip0_psl_cseb_rden,
         cseb_wrdata => pcihip0_psl_cseb_wrdata,
         cseb_wren => pcihip0_psl_cseb_wren,
         cseb_wrresp_req => pcihip0_psl_cseb_wrresp_req,
         cseb_rddata_parity => psl_pcihip0_cseb_rddata_parity,
         cseb_addr_parity => pcihip0_psl_cseb_addr_parity,
         cseb_wrdata_parity => pcihip0_psl_cseb_wrdata_parity,
         pci_pi_nperst0 => TCONV(pci_pi_nperst0),
         cpld_usergolden => cpld_usergolden,
         cpld_softreconfigreq => cpld_softreconfigreq,
         cpld_user_bs_req => cpld_user_bs_req,
         cpld_oe => cpld_oe,
         f_program_req => f_program_req,
         f_num_blocks => f_num_blocks,
         f_start_blk => f_start_blk,
         f_program_data => f_program_data,
         f_program_data_val => f_program_data_val,
         f_program_data_ack => f_program_data_ack,
         f_ready => f_ready,
         f_done => f_done,
         f_stat_erase => f_stat_erase,
         f_stat_program => f_stat_program,
         f_stat_read => f_stat_read,
         f_remainder => f_remainder,
         f_read_req => f_read_req,
         f_num_words_m1 => f_num_words_m1,
         f_read_start_addr => f_read_start_addr,
         f_read_data => f_read_data,
         f_read_data_val => f_read_data_val,
         f_read_data_ack => f_read_data_ack,
         psl_clk => psl_clk
    );


    -- Flash logic
    f: psl_flash
      PORT MAP (
         flash_clk => flash_clk,
         flash_rstn => flash_rstn,
         flash_addr => flash_addr,
         flash_dataout => flash_dataout,
         flash_dat_oe => flash_dat_oe,
         flash_datain => flash_datain,
         flash_cen => flash_cen,
         flash_oen => flash_oen,
         flash_wen => flash_wen,
         flash_wait => flash_wait,
         flash_wpn => flash_wpn,
         flash_advn => flash_advn,
         pfl_flash_reqn => pfl_flash_reqn,
         pfl_flash_grant => pfl_flash_grant,
         flash_intf_oe => flash_intf_oe,
         f_program_req => f_program_req,
         f_num_blocks => f_num_blocks,
         f_start_blk => f_start_blk,
         f_program_data => f_program_data,
         f_program_data_val => f_program_data_val,
         f_program_data_ack => f_program_data_ack,
         f_ready => f_ready,
         f_done => f_done,
         f_stat_erase => f_stat_erase,
         f_stat_program => f_stat_program,
         f_stat_read => f_stat_read,
         f_remainder => f_remainder,
         f_read_req => f_read_req,
         f_num_words_m1 => f_num_words_m1,
         f_read_start_addr => f_read_start_addr,
         f_read_data => f_read_data,
         f_read_data_val => f_read_data_val,
         f_read_data_ack => f_read_data_ack,
         psl_clk => psl_clk
    );



    -- PSL logic
    p: psl
      PORT MAP (
         crc_error => TCONV(crc_errorinternal),
         a0h_cvalid => a0h_cvalid,
         a0h_ctag => a0h_ctag,
         a0h_com => a0h_com,
         a0h_cpad => a0h_cpad,
         a0h_cabt => a0h_cabt,
         a0h_cea => a0h_cea,
         a0h_cch => a0h_cch,
         a0h_csize => a0h_csize,
         ha0_croom => ha0_croom,
         a0h_ctagpar => a0h_ctagpar,
         a0h_compar => a0h_compar,
         a0h_ceapar => a0h_ceapar,
         ha0_brvalid => ha0_brvalid,
         ha0_brtag => ha0_brtag,
         ha0_brad => ha0_brad,
         a0h_brlat => a0h_brlat,
         a0h_brdata => a0h_brdata,
         a0h_brpar => a0h_brpar,
         ha0_bwvalid => ha0_bwvalid,
         ha0_bwtag => ha0_bwtag,
         ha0_bwad => ha0_bwad,
         ha0_bwdata => ha0_bwdata,
         ha0_bwpar => ha0_bwpar,
         ha0_brtagpar => ha0_brtagpar,
         ha0_bwtagpar => ha0_bwtagpar,
         ha0_rvalid => ha0_rvalid,
         ha0_rtag => ha0_rtag,
         ha0_response => ha0_response,
         ha0_rcredits => ha0_rcredits,
         ha0_rcachestate => ha0_rcachestate,
         ha0_rcachepos => ha0_rcachepos,
         ha0_rtagpar => ha0_rtagpar,
         ha0_mmval => ha0_mmval,
         ha0_mmrnw => ha0_mmrnw,
         ha0_mmdw => ha0_mmdw,
         ha0_mmad => ha0_mmad,
         ha0_mmdata => ha0_mmdata,
         ha0_mmcfg => ha0_mmcfg,
         a0h_mmack => a0h_mmack,
         a0h_mmdata => a0h_mmdata,
         ha0_mmadpar => ha0_mmadpar,
         ha0_mmdatapar => ha0_mmdatapar,
         a0h_mmdatapar => a0h_mmdatapar,
         ha0_jval => ha0_jval,
         ha0_jcom => ha0_jcom,
         ha0_jea => ha0_jea,
         a0h_jrunning => a0h_jrunning,
         a0h_jdone => a0h_jdone,
         a0h_jcack => a0h_jcack,
         a0h_jerror => a0h_jerror,
         a0h_tbreq => a0h_tbreq,
         a0h_jyield => a0h_jyield,
         ha0_jeapar => ha0_jeapar,
         ha0_jcompar => ha0_jcompar,
         a0h_paren => a0h_paren,
         ha0_pclock => ha0_pclock,
         psl_pcihip_freeze => psl_pcihip_freeze,
         hi2c_cmdval => hi2c_cmdval,
         hi2c_dataval => hi2c_dataval,
         hi2c_addr => hi2c_addr,
         hi2c_rd => hi2c_rd,
         hi2c_cmdin => hi2c_cmdin,
         hi2c_datain => hi2c_datain,
         hi2c_blk => hi2c_blk,
         hi2c_bytecnt => hi2c_bytecnt,
         hi2c_cntlrsel => hi2c_cntlrsel,
         i2ch_wrdatack => i2ch_wrdatack,
         i2ch_dataval => i2ch_dataval,
         i2ch_error => i2ch_error,
         i2ch_dataout => i2ch_dataout,
         i2ch_ready => i2ch_ready,
         mon_power => mon_power,
         mon_temperature => mon_temperature,
         mon_enable => mon_enable,
         psl_pcihip0_rx_st_ready => psl_pcihip0_rx_st_ready,
         pcihip0_psl_rx_st_valid => pcihip0_psl_rx_st_valid,
         pcihip0_psl_rx_st_data => pcihip0_psl_rx_st_data,
         pcihip0_psl_rx_st_parity => pcihip0_psl_rx_st_parity,
         pcihip0_psl_rx_st_sop => pcihip0_psl_rx_st_sop,
         pcihip0_psl_rx_st_eop => pcihip0_psl_rx_st_eop,
         pcihip0_psl_rx_st_empty => pcihip0_psl_rx_st_empty,
         pcihip0_psl_rx_st_err => pcihip0_psl_rx_st_err,
         psl_pcihip0_rx_st_mask => psl_pcihip0_rx_st_mask,
         pcihip0_psl_rx_st_bar => pcihip0_psl_rx_st_bar,
         pcihip0_psl_tx_st_ready => pcihip0_psl_tx_st_ready,
         psl_pcihip0_tx_st_valid => psl_pcihip0_tx_st_valid,
         psl_pcihip0_tx_st_data => psl_pcihip0_tx_st_data,
         psl_pcihip0_tx_st_parity => psl_pcihip0_tx_st_parity,
         psl_pcihip0_tx_st_sop => psl_pcihip0_tx_st_sop,
         psl_pcihip0_tx_st_eop => psl_pcihip0_tx_st_eop,
         psl_pcihip0_tx_st_empty => psl_pcihip0_tx_st_empty,
         psl_pcihip0_tx_st_err => psl_pcihip0_tx_st_err,
         pcihip0_psl_tx_cred_datafccp => pcihip0_psl_tx_cred_datafccp,
         pcihip0_psl_tx_cred_datafcnp => pcihip0_psl_tx_cred_datafcnp,
         pcihip0_psl_tx_cred_datafcp => pcihip0_psl_tx_cred_datafcp,
         pcihip0_psl_tx_cred_fchipcons => pcihip0_psl_tx_cred_fchipcons,
         pcihip0_psl_tx_cred_fcinfinite => pcihip0_psl_tx_cred_fcinfinite,
         pcihip0_psl_tx_cred_hdrfccp => pcihip0_psl_tx_cred_hdrfccp,
         pcihip0_psl_tx_cred_hdrfcnp => pcihip0_psl_tx_cred_hdrfcnp,
         pcihip0_psl_tx_cred_hdrfcp => pcihip0_psl_tx_cred_hdrfcp,
         pcihip0_psl_ko_cpl_spc_header => pcihip0_psl_ko_cpl_spc_header,
         pcihip0_psl_ko_cpl_spc_data => pcihip0_psl_ko_cpl_spc_data,
         psl_pcihip0_freeze => psl_pcihip0_freeze,
         pcihip0_psl_reset_status => pcihip0_psl_reset_status,
         psl_pcihip0_app_msi_req => psl_pcihip0_app_msi_req,
         pcihip0_psl_app_msi_ack => pcihip0_psl_app_msi_ack,
         psl_pcihip0_app_msi_tc => psl_pcihip0_app_msi_tc,
         psl_pcihip0_app_msi_num => psl_pcihip0_app_msi_num,
         pcihip0_psl_app_int_ack => pcihip0_psl_app_int_ack,
         psl_pcihip0_lmi_rden => psl_pcihip0_lmi_rden,
         psl_pcihip0_lmi_wren => psl_pcihip0_lmi_wren,
         psl_pcihip0_lmi_addr => psl_pcihip0_lmi_addr,
         psl_pcihip0_lmi_din => psl_pcihip0_lmi_din,
         pcihip0_psl_lmi_ack => pcihip0_psl_lmi_ack,
         pcihip0_psl_lmi_dout => pcihip0_psl_lmi_dout,
         pcihip0_psl_tl_cfg_add => pcihip0_psl_tl_cfg_add,
         pcihip0_psl_tl_cfg_ctl => pcihip0_psl_tl_cfg_ctl,
         pcihip0_psl_tl_cfg_sts => pcihip0_psl_tl_cfg_sts,
         pcihip0_psl_hip_reconfig_readdata => pcihip0_psl_hip_reconfig_readdata,
         psl_pcihip0_hip_reconfig_rst_n => psl_pcihip0_hip_reconfig_rst_n,
         psl_pcihip0_hip_reconfig_address => psl_pcihip0_hip_reconfig_address,
         psl_pcihip0_hip_reconfig_byte_en => psl_pcihip0_hip_reconfig_byte_en,
         psl_pcihip0_hip_reconfig_read => psl_pcihip0_hip_reconfig_read,
         psl_pcihip0_hip_reconfig_clk => psl_pcihip0_hip_reconfig_clk,
         psl_pcihip0_hip_reconfig_write => psl_pcihip0_hip_reconfig_write,
         psl_pcihip0_hip_reconfig_writedata => psl_pcihip0_hip_reconfig_writedata,
         psl_pcihip0_interface_sel => psl_pcihip0_interface_sel,
         psl_pcihip0_ser_shift_load => psl_pcihip0_ser_shift_load,
         psl_pcihip0_cpl_err => psl_pcihip0_cpl_err,
         psl_pcihip0_cpl_pending => psl_pcihip0_cpl_pending,
         pcihip0_psl_tx_par_err => pcihip0_psl_tx_par_err,
         pcihip0_psl_cfg_par_err => pcihip0_psl_cfg_par_err,
         pcihip0_psl_rx_par_err => pcihip0_psl_rx_par_err,
         psl_pcihip0_pme_to_cr => psl_pcihip0_pme_to_cr,
         pcihip0_psl_pme_to_sr => pcihip0_psl_pme_to_sr,
         psl_pcihip0_pm_event => psl_pcihip0_pm_event,
         psl_pcihip0_pm_data => psl_pcihip0_pm_data,
         psl_pcihip0_pm_auxpwr => psl_pcihip0_pm_auxpwr,
         pcihip0_psl_derr_cor_ext_rcv => pcihip0_psl_derr_cor_ext_rcv,
         pcihip0_psl_derr_cor_ext_rpl => pcihip0_psl_derr_cor_ext_rpl,
         pcihip0_psl_derr_rpl => pcihip0_psl_derr_rpl,
         psl_pcihip0_test_in => psl_pcihip0_test_in,
         pcihip0_psl_testin_zero => pcihip0_psl_testin_zero,
         psl_pcihip0_simu_mode_pipe => psl_pcihip0_simu_mode_pipe,
         psl_clk => psl_clk
    );



    pcihip0: psl_pcihip0
      PORT MAP (
         pld_clk => psl_clk,
         coreclkout_hip => pcihip0_psl_coreclkout_hip,
         refclk => pci_pi_refclk0,
         rx_st_ready => psl_pcihip0_rx_st_ready,
         rx_st_valid => pcihip0_psl_rx_st_valid,
         rx_st_data => pcihip0_psl_rx_st_data,
         rx_st_parity => pcihip0_psl_rx_st_parity,
         rx_st_sop => pcihip0_psl_rx_st_sop,
         rx_st_eop => pcihip0_psl_rx_st_eop,
         rx_st_empty => pcihip0_psl_rx_st_empty,
         rx_st_err => pcihip0_psl_rx_st_err,
         rx_st_mask => psl_pcihip0_rx_st_mask,
         rx_st_bar => pcihip0_psl_rx_st_bar,
         tx_st_ready => pcihip0_psl_tx_st_ready,
         tx_st_valid => psl_pcihip0_tx_st_valid,
         tx_st_data => psl_pcihip0_tx_st_data,
         tx_st_parity => psl_pcihip0_tx_st_parity,
         tx_st_sop => psl_pcihip0_tx_st_sop,
         tx_st_eop => psl_pcihip0_tx_st_eop,
         tx_st_empty => psl_pcihip0_tx_st_empty,
         tx_st_err => psl_pcihip0_tx_st_err,
         tx_cred_datafccp => pcihip0_psl_tx_cred_datafccp,
         tx_cred_datafcnp => pcihip0_psl_tx_cred_datafcnp,
         tx_cred_datafcp => pcihip0_psl_tx_cred_datafcp,
         tx_cred_fchipcons => pcihip0_psl_tx_cred_fchipcons,
         tx_cred_fcinfinite => pcihip0_psl_tx_cred_fcinfinite,
         tx_cred_hdrfccp => pcihip0_psl_tx_cred_hdrfccp,
         tx_cred_hdrfcnp => pcihip0_psl_tx_cred_hdrfcnp,
         tx_cred_hdrfcp => pcihip0_psl_tx_cred_hdrfcp,
         npor => TCONV(hip_npor0),
         pin_perst => pci_pi_nperst0,
         reset_status => pcihip0_psl_reset_status,
         pld_clk_inuse => pcihip0_psl_pld_clk_inuse,
         app_msi_req => psl_pcihip0_app_msi_req,
         app_msi_ack => pcihip0_psl_app_msi_ack,
         app_msi_tc => psl_pcihip0_app_msi_tc,
         app_msi_num => psl_pcihip0_app_msi_num,
         app_int_ack => pcihip0_psl_app_int_ack,
         lmi_rden => psl_pcihip0_lmi_rden,
         lmi_wren => psl_pcihip0_lmi_wren,
         lmi_addr => psl_pcihip0_lmi_addr,
         lmi_din => psl_pcihip0_lmi_din,
         lmi_ack => pcihip0_psl_lmi_ack,
         lmi_dout => pcihip0_psl_lmi_dout,
         tl_cfg_add => pcihip0_psl_tl_cfg_add,
         tl_cfg_ctl => pcihip0_psl_tl_cfg_ctl,
         tl_cfg_sts => pcihip0_psl_tl_cfg_sts,
         cseb_rddata => psl_pcihip0_cseb_rddata,
         cseb_rdresponse => psl_pcihip0_cseb_rdresponse,
         cseb_waitrequest => psl_pcihip0_cseb_waitrequest,
         cseb_wrresponse => psl_pcihip0_cseb_wrresponse,
         cseb_wrresp_valid => psl_pcihip0_cseb_wrresp_valid,
         cseb_addr => pcihip0_psl_cseb_addr,
         cseb_be => pcihip0_psl_cseb_be,
         cseb_rden => pcihip0_psl_cseb_rden,
         cseb_wrdata => pcihip0_psl_cseb_wrdata,
         cseb_wren => pcihip0_psl_cseb_wren,
         cseb_wrresp_req => pcihip0_psl_cseb_wrresp_req,
         cseb_rddata_parity => psl_pcihip0_cseb_rddata_parity,
         cseb_addr_parity => pcihip0_psl_cseb_addr_parity,
         cseb_wrdata_parity => pcihip0_psl_cseb_wrdata_parity,
         cpl_err => psl_pcihip0_cpl_err,
         cpl_pending => psl_pcihip0_cpl_pending,
         tx_par_err => pcihip0_psl_tx_par_err,
         cfg_par_err => pcihip0_psl_cfg_par_err,
         rx_par_err => pcihip0_psl_rx_par_err,
         pme_to_cr => psl_pcihip0_pme_to_cr,
         pme_to_sr => pcihip0_psl_pme_to_sr,
         pm_event => psl_pcihip0_pm_event,
         pm_data => psl_pcihip0_pm_data,
         pm_auxpwr => psl_pcihip0_pm_auxpwr,
         derr_cor_ext_rcv => pcihip0_psl_derr_cor_ext_rcv,
         derr_cor_ext_rpl => pcihip0_psl_derr_cor_ext_rpl,
         derr_rpl => pcihip0_psl_derr_rpl,
         rx_in0 => pci0_i_rx_in0,
         rx_in1 => pci0_i_rx_in1,
         rx_in2 => pci0_i_rx_in2,
         rx_in3 => pci0_i_rx_in3,
         rx_in4 => pci0_i_rx_in4,
         rx_in5 => pci0_i_rx_in5,
         rx_in6 => pci0_i_rx_in6,
         rx_in7 => pci0_i_rx_in7,
         tx_out0 => pci0_o_tx_out0,
         tx_out1 => pci0_o_tx_out1,
         tx_out2 => pci0_o_tx_out2,
         tx_out3 => pci0_o_tx_out3,
         tx_out4 => pci0_o_tx_out4,
         tx_out5 => pci0_o_tx_out5,
         tx_out6 => pci0_o_tx_out6,
         tx_out7 => pci0_o_tx_out7,
         test_in => psl_pcihip0_test_in,
         testin_zero => pcihip0_psl_testin_zero,
         ko_cpl_spc_header => pcihip0_psl_ko_cpl_spc_header,
         ko_cpl_spc_data => pcihip0_psl_ko_cpl_spc_data,
         simu_mode_pipe => psl_pcihip0_simu_mode_pipe
    );



       
    psl_pcihip0_nfreeze <=  not psl_pcihip0_freeze ;
    hip_npor0 <= psl_pcihip0_nfreeze ; --pci_pi_nperst0

  crc_error <= crc_errorinternal; 
END psl_fpga;
