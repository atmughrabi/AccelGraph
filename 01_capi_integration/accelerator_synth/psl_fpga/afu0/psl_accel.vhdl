
-- *!****************************************************************
-- *! (C) Copyright International Business Machines 2014



library ieee, work;
use ieee.std_logic_1164.all;
use work.std_ulogic_function_support.all;
use work.std_ulogic_support.all;
use work.std_ulogic_unsigned.all;

ENTITY psl_accel IS
  PORT(
    -- Accelerator Command Interface
    ah_cvalid : out std_ulogic;  -- A valid command is present
    ah_ctag   : out std_ulogic_vector(0 to 7);  -- request id
    ah_com    : out std_ulogic_vector(0 to 12);  -- command PSL will execute
    ah_cpad   : out std_ulogic_vector(0 to 2);  -- prefetch attributes
    ah_cabt   : out std_ulogic_vector(0 to 2);  -- abort if translation intr is generated
    ah_cea    : out std_ulogic_vector(0 to 63);  -- Effective byte address for command
    ah_cch    : out std_ulogic_vector(0 to 15);  -- Context Handle
    ah_csize  : out std_ulogic_vector(0 to 11);  -- Number of bytes
    ha_croom  : in  std_ulogic_vector(0 to 7);  -- Commands PSL is prepared to accept

    -- command parity
    ah_ctagpar : out std_ulogic;
    ah_compar  : out std_ulogic;
    ah_ceapar  : out std_ulogic;

    -- Accelerator Buffer Interfaces
    ha_brvalid : in  std_ulogic;  -- A read transfer is present
    ha_brtag   : in  std_ulogic_vector(0 to 7);  -- Accelerator generated ID for read
    ha_brad    : in  std_ulogic_vector(0 to 5);  -- half line index of read data
    ah_brlat   : out std_ulogic_vector(0 to 3);  -- Read data ready latency
    ah_brdata  : out std_ulogic_vector(0 to 511);  -- Read data
    ah_brpar   : out std_ulogic_vector(0 to 7);  -- Read data parity
    ha_bwvalid : in  std_ulogic;  -- A write data transfer is present
    ha_bwtag   : in  std_ulogic_vector(0 to 7);  -- Accelerator ID of the write
    ha_bwad    : in  std_ulogic_vector(0 to 5);  -- half line index of write data
    ha_bwdata  : in  std_ulogic_vector(0 to 511);  -- Write data
    ha_bwpar   : in  std_ulogic_vector(0 to 7);  -- Write data parity

    -- buffer tag parity
    ha_brtagpar : in std_ulogic;
    ha_bwtagpar : in std_ulogic;

    -- PSL Response Interface
    ha_rvalid      : in std_ulogic;  --A response is present
    ha_rtag        : in std_ulogic_vector(0 to 7);  --Accelerator generated request ID
    ha_response    : in std_ulogic_vector(0 to 7);  --response code
    ha_rcredits    : in std_ulogic_vector(0 to 8);  --twos compliment number of credits
    ha_rcachestate : in std_ulogic_vector(0 to 1);  --Resultant Cache State
    ha_rcachepos   : in std_ulogic_vector(0 to 12);  --Cache location id
    ha_rtagpar     : in std_ulogic;

    -- MMIO Interface
    ha_mmval  : in  std_ulogic;  -- A valid MMIO is present
    ha_mmrnw  : in  std_ulogic;  -- 1 = read, 0 = write
    ha_mmdw   : in  std_ulogic;  -- 1 = doubleword, 0 = word
    ha_mmad   : in  std_ulogic_vector(0 to 23);  -- mmio address
    ha_mmdata : in  std_ulogic_vector(0 to 63);  -- Write data
    ha_mmcfg  : in  std_ulogic;  -- mmio is to afu descriptor space
    ah_mmack  : out std_ulogic;  -- Write is complete or Read is valid pulse
    ah_mmdata : out std_ulogic_vector(0 to 63);  -- Read data

    -- mmio parity
    ha_mmadpar   : in  std_ulogic;
    ha_mmdatapar : in  std_ulogic;
    ah_mmdatapar : out std_ulogic;

    -- Accelerator Control Interface
    ha_jval     : in  std_ulogic;  -- A valid job control command is present
    ha_jcom     : in  std_ulogic_vector(0 to 7);  -- Job control command opcode
    ha_jea      : in  std_ulogic_vector(0 to 63);  -- Save/Restore address
    ah_jrunning : out std_ulogic;  -- Accelerator is running level
    ah_jdone    : out std_ulogic;  -- Accelerator is finished pulse
    ah_jcack    : out std_ulogic;  -- Accelerator is with context llcmd pulse
    ah_jerror   : out std_ulogic_vector(0 to 63);  -- Accelerator error code. 0 = success
    ah_tbreq    : out std_ulogic;  -- Timebase request pulse
    ah_jyield   : out std_ulogic;  -- Accelerator wants to stop
    ha_jeapar   : in  std_ulogic;
    ha_jcompar  : in  std_ulogic;
    ah_paren    : out std_ulogic;
    ha_pclock   : in  std_ulogic;

       -- SFP+ Phy 0 Interface
       as_sfp0_phy_mgmt_clk_reset   : out std_ulogic;
       as_sfp0_phy_mgmt_address     : out std_ulogic_vector(0 to 8);
       as_sfp0_phy_mgmt_read        : out std_ulogic;
       sa_sfp0_phy_mgmt_readdata    : in  std_ulogic_vector(0 to 31);
       sa_sfp0_phy_mgmt_waitrequest : in  std_ulogic;
       as_sfp0_phy_mgmt_write       : out std_ulogic;
       as_sfp0_phy_mgmt_writedata   : out std_ulogic_vector(0 to 31);
       sa_sfp0_tx_ready             : in  std_ulogic;
       sa_sfp0_rx_ready             : in  std_ulogic;
       as_sfp0_tx_forceelecidle     : out std_ulogic;
       sa_sfp0_pll_locked           : in  std_ulogic;
       sa_sfp0_rx_is_lockedtoref    : in  std_ulogic;
       sa_sfp0_rx_is_lockedtodata   : in  std_ulogic;
       sa_sfp0_rx_signaldetect      : in  std_ulogic;
       as_sfp0_tx_coreclk           : out std_ulogic;
       sa_sfp0_tx_clk               : in  std_ulogic;
       sa_sfp0_rx_clk               : in  std_ulogic;
       as_sfp0_tx_parallel_data     : out std_ulogic_vector(39 downto 0);
       sa_sfp0_rx_parallel_data     : in  std_ulogic_vector(39 downto 0);

       -- SFP+ 0 Sideband Signals
       sa_sfp0_tx_fault   : in  std_ulogic;
       sa_sfp0_mod_abs    : in  std_ulogic;
       sa_sfp0_rx_los     : in  std_ulogic;
       as_sfp0_tx_disable : out std_ulogic;
       as_sfp0_rs0        : out std_ulogic;
       as_sfp0_rs1        : out std_ulogic;
       as_sfp0_scl        : out std_ulogic;
       as_sfp0_en         : out std_ulogic;
       sa_sfp0_sda        : in  std_ulogic;
       as_sfp0_sda        : out std_ulogic;
       as_sfp0_sda_oe     : out std_ulogic;

       -- SFP+ Phy 1 Interface
       as_sfp1_phy_mgmt_clk_reset   : out std_ulogic;
       as_sfp1_phy_mgmt_address     : out std_ulogic_vector(0 to 8);
       as_sfp1_phy_mgmt_read        : out std_ulogic;
       sa_sfp1_phy_mgmt_readdata    : in  std_ulogic_vector(0 to 31);
       sa_sfp1_phy_mgmt_waitrequest : in  std_ulogic;
       as_sfp1_phy_mgmt_write       : out std_ulogic;
       as_sfp1_phy_mgmt_writedata   : out std_ulogic_vector(0 to 31);
       sa_sfp1_tx_ready             : in  std_ulogic;
       sa_sfp1_rx_ready             : in  std_ulogic;
       as_sfp1_tx_forceelecidle     : out std_ulogic;
       sa_sfp1_pll_locked           : in  std_ulogic;
       sa_sfp1_rx_is_lockedtoref    : in  std_ulogic;
       sa_sfp1_rx_is_lockedtodata   : in  std_ulogic;
       sa_sfp1_rx_signaldetect      : in  std_ulogic;
       as_sfp1_tx_coreclk           : out std_ulogic;
       sa_sfp1_tx_clk               : in  std_ulogic;
       sa_sfp1_rx_clk               : in  std_ulogic;
       as_sfp1_tx_parallel_data     : out std_ulogic_vector(39 downto 0);
       sa_sfp1_rx_parallel_data     : in  std_ulogic_vector(39 downto 0);

       -- SFP+ 1 Sideband Signals
       sa_sfp1_tx_fault   : in  std_ulogic;
       sa_sfp1_mod_abs    : in  std_ulogic;
       sa_sfp1_rx_los     : in  std_ulogic;
       as_sfp1_tx_disable : out std_ulogic;
       as_sfp1_rs0        : out std_ulogic;
       as_sfp1_rs1        : out std_ulogic;
       as_sfp1_scl        : out std_ulogic;
       as_sfp1_en         : out std_ulogic;
       sa_sfp1_sda        : in  std_ulogic;
       as_sfp1_sda        : out std_ulogic;
       as_sfp1_sda_oe     : out std_ulogic;

       as_refclk_sfp_fs    : out std_ulogic;
       as_refclk_sfp_fs_en : out std_ulogic;

       as_red_led   : out std_ulogic_vector(0 to 3);
       as_green_led : out std_ulogic_vector(0 to 3));
  
END psl_accel;



ARCHITECTURE psl_accel OF psl_accel IS

  component afu
    port (
      ah_cvalid      : out std_ulogic;
      ah_ctag        : out std_ulogic_vector(0 to 7);
      ah_com         : out std_ulogic_vector(0 to 12);
      ah_cabt        : out std_ulogic_vector(0 to 2);
      ah_cea         : out std_ulogic_vector(0 to 63);
      ah_cch         : out std_ulogic_vector(0 to 15);
      ah_csize       : out std_ulogic_vector(0 to 11);
      ha_croom       : in  std_ulogic_vector(0 to 7);
      ah_ctagpar     : out std_ulogic;
      ah_compar      : out std_ulogic;
      ah_ceapar      : out std_ulogic;
      ha_brvalid     : in  std_ulogic;
      ha_brtag       : in  std_ulogic_vector(0 to 7);
      ha_brad        : in  std_ulogic_vector(0 to 5);
      ah_brlat       : out std_ulogic_vector(0 to 3);
      ah_brdata      : out std_ulogic_vector(0 to 511);
      ah_brpar       : out std_ulogic_vector(0 to 7);
      ha_bwvalid     : in  std_ulogic;
      ha_bwtag       : in  std_ulogic_vector(0 to 7);
      ha_bwad        : in  std_ulogic_vector(0 to 5);
      ha_bwdata      : in  std_ulogic_vector(0 to 511);
      ha_bwpar       : in  std_ulogic_vector(0 to 7);
      ha_brtagpar    : in  std_ulogic;
      ha_bwtagpar    : in  std_ulogic;
      ha_rvalid      : in  std_ulogic;
      ha_rtag        : in  std_ulogic_vector(0 to 7);
      ha_response    : in  std_ulogic_vector(0 to 7);
      ha_rcredits    : in  std_ulogic_vector(0 to 8);
      ha_rcachestate : in  std_ulogic_vector(0 to 1);
      ha_rcachepos   : in  std_ulogic_vector(0 to 12);
      ha_rtagpar     : in  std_ulogic;
      ha_mmval       : in  std_ulogic;
      ha_mmrnw       : in  std_ulogic;
      ha_mmdw        : in  std_ulogic;
      ha_mmad        : in  std_ulogic_vector(0 to 23);
      ha_mmdata      : in  std_ulogic_vector(0 to 63);
      ha_mmcfg       : in  std_ulogic;
      ah_mmack       : out std_ulogic;
      ah_mmdata      : out std_ulogic_vector(0 to 63);
      ha_mmadpar     : in  std_ulogic;
      ha_mmdatapar   : in  std_ulogic;
      ah_mmdatapar   : out std_ulogic;
      ha_jval        : in  std_ulogic;
      ha_jcom        : in  std_ulogic_vector(0 to 7);
      ha_jea         : in  std_ulogic_vector(0 to 63);
      ah_jrunning    : out std_ulogic;
      ah_jdone       : out std_ulogic;
      ah_jcack       : out std_ulogic;
      ah_jerror      : out std_ulogic_vector(0 to 63);
      ah_tbreq       : out std_ulogic;
      ah_jyield      : out std_ulogic;
      ha_jeapar      : in  std_ulogic;
      ha_jcompar     : in  std_ulogic;
      ah_paren       : out std_ulogic;
      ha_pclock      : in  std_ulogic);
  end component;

begin



     afu0: afu
       port map (
         ah_cvalid      => ah_cvalid,
         ah_ctag        => ah_ctag,
         ah_com         => ah_com,
         ah_cabt        => ah_cabt,
         ah_cea         => ah_cea,
         ah_cch         => ah_cch,
         ah_csize       => ah_csize,
         ha_croom       => ha_croom,
         ah_ctagpar     => ah_ctagpar,
         ah_compar      => ah_compar,
         ah_ceapar      => ah_ceapar,
         ha_brvalid     => ha_brvalid,
         ha_brtag       => ha_brtag,
         ha_brad        => ha_brad,
         ah_brlat       => ah_brlat,
         ah_brdata      => ah_brdata,
         ah_brpar       => ah_brpar,
         ha_bwvalid     => ha_bwvalid,
         ha_bwtag       => ha_bwtag,
         ha_bwad        => ha_bwad,
         ha_bwdata      => ha_bwdata,
         ha_bwpar       => ha_bwpar,
         ha_brtagpar    => ha_brtagpar,
         ha_bwtagpar    => ha_bwtagpar,
         ha_rvalid      => ha_rvalid,
         ha_rtag        => ha_rtag,
         ha_response    => ha_response,
         ha_rcredits    => ha_rcredits,
         ha_rcachestate => ha_rcachestate,
         ha_rcachepos   => ha_rcachepos,
         ha_rtagpar     => ha_rtagpar,
         ha_mmval       => ha_mmval,
         ha_mmrnw       => ha_mmrnw,
         ha_mmdw        => ha_mmdw,
         ha_mmad        => ha_mmad,
         ha_mmdata      => ha_mmdata,
         ha_mmcfg       => ha_mmcfg,
         ah_mmack       => ah_mmack,
         ah_mmdata      => ah_mmdata,
         ha_mmadpar     => ha_mmadpar,
         ha_mmdatapar   => ha_mmdatapar,
         ah_mmdatapar   => ah_mmdatapar,
         ha_jval        => ha_jval,
         ha_jcom        => ha_jcom,
         ha_jea         => ha_jea,
         ah_jrunning    => ah_jrunning,
         ah_jdone       => ah_jdone,
         ah_jcack       => ah_jcack,
         ah_jerror      => ah_jerror,
         ah_tbreq       => ah_tbreq,
         ah_jyield      => ah_jyield,
         ha_jeapar      => ha_jeapar,
         ha_jcompar     => ha_jcompar,
         ah_paren       => ah_paren,
         ha_pclock      => ha_pclock);

     -- Input into PSL is not used
    ah_cpad <= (others => '0');

     -- SFP+ Phy 0 Interface
    as_sfp0_phy_mgmt_clk_reset <= '0' ;

    as_sfp0_phy_mgmt_address <= (others => '0') ;

    as_sfp0_phy_mgmt_read <= '0' ;

    as_sfp0_phy_mgmt_write <= '0' ;

    as_sfp0_phy_mgmt_writedata <= (others => '0') ;

    as_sfp0_tx_forceelecidle <= '0' ;

    as_sfp0_tx_coreclk <= '0' ;

    as_sfp0_tx_parallel_data <= (others => '0') ;

    -- SFP+ 0 Sideband Signals
    as_sfp0_tx_disable <= '0' ;

    as_sfp0_rs0 <= '0' ;

    as_sfp0_rs1 <= '0' ;

    as_sfp0_scl <= '0' ;

    as_sfp0_en <= '0' ;

--    bool     sa_sfp0_sda,
    as_sfp0_sda <= '0' ;

    as_sfp0_sda_oe <= '0' ;

    -- SFP+ Phy 1 Interface
    as_sfp1_phy_mgmt_clk_reset <= '0' ;

    as_sfp1_phy_mgmt_address <= (others => '0') ;

    as_sfp1_phy_mgmt_read <= '0' ;

    as_sfp1_phy_mgmt_write <= '0' ;

    as_sfp1_phy_mgmt_writedata <= (others => '0') ;

    as_sfp1_tx_forceelecidle <= '0' ;

    as_sfp1_tx_coreclk <= '0' ;

    as_sfp1_tx_parallel_data <= (others => '0') ;

    -- SFP+ 1 Sideband Signals
    as_sfp1_tx_disable <= '0' ;

    as_sfp1_rs0 <= '0' ;

    as_sfp1_rs1 <= '0' ;

    as_sfp1_scl <= '0' ;

    as_sfp1_en <= '0' ;

    as_sfp1_sda <= '0' ;

    as_sfp1_sda_oe <= '0' ;

    as_refclk_sfp_fs <= '0' ;

    as_refclk_sfp_fs_en <= '0' ;

    as_red_led <= (others => '0') ;

    as_green_led <= (others => '0') ;


END psl_accel;
