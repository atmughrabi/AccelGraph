--IP Functional Simulation Model
--VERSION_BEGIN 15.1 cbx_mgl 2015:10:21:19:02:34:SJ cbx_simgen 2015:10:14:18:59:15:SJ  VERSION_END


-- Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, the Altera Quartus Prime License Agreement,
-- the Altera MegaCore Function License Agreement, or other 
-- applicable license agreement, including, without limitation, 
-- that your use is for the sole purpose of programming logic 
-- devices manufactured by Altera and sold by Altera or its 
-- authorized distributors.  Please refer to the applicable 
-- agreement for further details.

-- You may only use these simulation model output files for simulation
-- purposes and expressly not for synthesis or any other purposes (in which
-- event Altera disclaims all warranties of any kind).


--synopsys translate_off

--synthesis_resources = lut 24 mux21 91 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  sfpp_reconfig_master_0_p2b IS 
	 PORT 
	 ( 
		 clk	:	IN  STD_LOGIC;
		 in_channel	:	IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
		 in_data	:	IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
		 in_endofpacket	:	IN  STD_LOGIC;
		 in_ready	:	OUT  STD_LOGIC;
		 in_startofpacket	:	IN  STD_LOGIC;
		 in_valid	:	IN  STD_LOGIC;
		 out_data	:	OUT  STD_LOGIC_VECTOR (7 DOWNTO 0);
		 out_ready	:	IN  STD_LOGIC;
		 out_valid	:	OUT  STD_LOGIC;
		 reset_n	:	IN  STD_LOGIC
	 ); 
 END sfpp_reconfig_master_0_p2b;

 ARCHITECTURE RTL OF sfpp_reconfig_master_0_p2b IS

	 ATTRIBUTE synthesis_clearbox : natural;
	 ATTRIBUTE synthesis_clearbox OF RTL : ARCHITECTURE IS 1;
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_0_189q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_1_207q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_2_206q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_3_205q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_4_204q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_5_203q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_6_202q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_7_201q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_188q	:	STD_LOGIC := '0';
	 SIGNAL  wire_nl_w59w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_178q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_199q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_0_187q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_1_186q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_2_185q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_3_184q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_4_183q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_5_182q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_6_181q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_7_180q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_179q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_176q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_174q	:	STD_LOGIC := '0';
	 SIGNAL	sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_175q	:	STD_LOGIC := '0';
	 SIGNAL  wire_nO_w29w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_nO_w27w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_nO_w40w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_nO_w46w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_nO_w48w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_nO_w44w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_114m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_128m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_142m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_154m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_80m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_93m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_153m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_62m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_81m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_92m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_102m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_103m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_104m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_105m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_106m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_107m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_108m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_109m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_110m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_117m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_118m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_119m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_120m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_121m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_122m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_123m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_124m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_131m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_132m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_133m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_134m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_135m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_136m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_137m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_138m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_145m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_146m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_147m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_148m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_149m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_150m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_151m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_152m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_61m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_63m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_64m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_65m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_66m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_67m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_68m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_69m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_70m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_72m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_73m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_74m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_75m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_76m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_77m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_78m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_79m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_84m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_85m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_86m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_87m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_88m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_89m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_90m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_91m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_45m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_46m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_113m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_127m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_141m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_155m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_82m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_94m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_115m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_129m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_143m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_144m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_112m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_116m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_139m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_157m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_125m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_140m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_158m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_111m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_126m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_130m_dataout	:	STD_LOGIC;
	 SIGNAL	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_156m_dataout	:	STD_LOGIC;
	 SIGNAL  wire_w3w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_in_channel_range39w142w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_in_data_range58w87w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_in_endofpacket7w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_in_startofpacket4w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w25w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w10w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w1w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_in_channel_range38w134w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_in_data_range57w79w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_in_endofpacket7w8w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_in_startofpacket4w5w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w10w11w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w1w2w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_0_309_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_1_318_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_2_327_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_3_336_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_in_ready_210_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_channel_300_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_channel_43_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_0_263_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_1_272_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_290_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_2_281_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_40_dataout :	STD_LOGIC;
	 SIGNAL  s_wire_vcc :	STD_LOGIC;
	 SIGNAL  wire_w_in_channel_range39w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_in_channel_range38w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_in_data_range58w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_in_data_range57w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
 BEGIN

	wire_w3w(0) <= s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_in_ready_210_dataout AND wire_w_lg_w1w2w(0);
	wire_w_lg_w_in_channel_range39w142w(0) <= wire_w_in_channel_range39w(0) AND wire_w_lg_w_in_channel_range38w134w(0);
	wire_w_lg_w_in_data_range58w87w(0) <= wire_w_in_data_range58w(0) AND wire_w_lg_w_in_data_range57w79w(0);
	wire_w_lg_in_endofpacket7w(0) <= NOT in_endofpacket;
	wire_w_lg_in_startofpacket4w(0) <= NOT in_startofpacket;
	wire_w25w(0) <= NOT s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_channel_300_dataout;
	wire_w10w(0) <= NOT s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_channel_43_dataout;
	wire_w1w(0) <= NOT s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_40_dataout;
	wire_w_lg_w_in_channel_range38w134w(0) <= NOT wire_w_in_channel_range38w(0);
	wire_w_lg_w_in_data_range57w79w(0) <= NOT wire_w_in_data_range57w(0);
	wire_w_lg_w_lg_in_endofpacket7w8w(0) <= wire_w_lg_in_endofpacket7w(0) OR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_176q;
	wire_w_lg_w_lg_in_startofpacket4w5w(0) <= wire_w_lg_in_startofpacket4w(0) OR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_175q;
	wire_w_lg_w10w11w(0) <= wire_w10w(0) OR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q;
	wire_w_lg_w1w2w(0) <= wire_w1w(0) OR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_174q;
	in_ready <= (((wire_w3w(0) AND wire_w_lg_w_lg_in_startofpacket4w5w(0)) AND wire_w_lg_w_lg_in_endofpacket7w8w(0)) AND wire_w_lg_w10w11w(0));
	out_data <= ( sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_7_180q & sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_6_181q & sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_5_182q & sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_4_183q & sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_3_184q & sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_2_185q & sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_1_186q & sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_0_187q);
	out_valid <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_188q;
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout <= (s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_40_dataout AND wire_nO_w48w(0));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout <= (s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_channel_43_dataout AND wire_nO_w27w(0));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout <= (wire_nO_w29w(0) AND sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_199q);
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout <= (in_startofpacket AND wire_nO_w44w(0));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout <= (in_endofpacket AND wire_nO_w46w(0));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_0_309_dataout <= ((((((((NOT in_channel(0)) AND in_channel(1)) AND (NOT in_channel(2))) AND in_channel(3)) AND in_channel(4)) AND in_channel(5)) AND in_channel(6)) AND (NOT in_channel(7)));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_1_318_dataout <= (((((((in_channel(0) AND in_channel(1)) AND (NOT in_channel(2))) AND in_channel(3)) AND in_channel(4)) AND in_channel(5)) AND in_channel(6)) AND (NOT in_channel(7)));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_2_327_dataout <= ((((((((NOT in_channel(0)) AND wire_w_lg_w_in_channel_range38w134w(0)) AND in_channel(2)) AND in_channel(3)) AND in_channel(4)) AND in_channel(5)) AND in_channel(6)) AND (NOT in_channel(7)));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_3_336_dataout <= ((((((wire_w_lg_w_in_channel_range39w142w(0) AND in_channel(2)) AND in_channel(3)) AND in_channel(4)) AND in_channel(5)) AND in_channel(6)) AND (NOT in_channel(7)));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_in_ready_210_dataout <= (in_valid AND (out_ready OR wire_nl_w59w(0)));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_channel_300_dataout <= ((((((((NOT (in_channel(0) XOR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_0_189q)) AND (NOT (in_channel(1) XOR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_1_207q))) AND (NOT (in_channel(2) XOR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_2_206q))) AND (NOT (in_channel(3) XOR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_3_205q))) AND (NOT (in_channel(4) XOR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_4_204q))) AND (NOT (in_channel(5) XOR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_5_203q))) AND (NOT (in_channel(6) XOR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_6_202q))) AND (NOT (in_channel(7) XOR sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_7_201q)));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_channel_43_dataout <= (in_startofpacket OR wire_w25w(0));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_0_263_dataout <= ((((((((NOT in_data(0)) AND in_data(1)) AND (NOT in_data(2))) AND in_data(3)) AND in_data(4)) AND in_data(5)) AND in_data(6)) AND (NOT in_data(7)));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_1_272_dataout <= (((((((in_data(0) AND in_data(1)) AND (NOT in_data(2))) AND in_data(3)) AND in_data(4)) AND in_data(5)) AND in_data(6)) AND (NOT in_data(7)));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_290_dataout <= ((((((wire_w_lg_w_in_data_range58w87w(0) AND in_data(2)) AND in_data(3)) AND in_data(4)) AND in_data(5)) AND in_data(6)) AND (NOT in_data(7)));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_2_281_dataout <= ((((((((NOT in_data(0)) AND wire_w_lg_w_in_data_range57w79w(0)) AND in_data(2)) AND in_data(3)) AND in_data(4)) AND in_data(5)) AND in_data(6)) AND (NOT in_data(7)));
	s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_40_dataout <= (((s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_0_263_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_1_272_dataout) OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_2_281_dataout) OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_need_esc_290_dataout);
	s_wire_vcc <= '1';
	wire_w_in_channel_range39w(0) <= in_channel(0);
	wire_w_in_channel_range38w(0) <= in_channel(1);
	wire_w_in_data_range58w(0) <= in_data(0);
	wire_w_in_data_range57w(0) <= in_data(1);
	PROCESS (clk, reset_n)
	BEGIN
		IF (reset_n = '0') THEN
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_0_189q <= '1';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_1_207q <= '1';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_2_206q <= '1';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_3_205q <= '1';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_4_204q <= '1';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_5_203q <= '1';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_6_202q <= '1';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_7_201q <= '1';
		ELSIF (clk = '1' AND clk'event) THEN
			IF (sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q = '1') THEN
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_0_189q <= in_channel(0);
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_1_207q <= in_channel(1);
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_2_206q <= in_channel(2);
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_3_205q <= in_channel(3);
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_4_204q <= in_channel(4);
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_5_203q <= in_channel(5);
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_6_202q <= in_channel(6);
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_7_201q <= in_channel(7);
			END IF;
		END IF;
		if (now = 0 ns) then
			sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_0_189q <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_1_207q <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_2_206q <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_3_205q <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_4_204q <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_5_203q <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_6_202q <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_stored_channel_7_201q <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk, reset_n)
	BEGIN
		IF (reset_n = '0') THEN
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_188q <= '0';
		ELSIF (clk = '1' AND clk'event) THEN
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_188q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_46m_dataout;
		END IF;
	END PROCESS;
	wire_nl_w59w(0) <= NOT sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_188q;
	PROCESS (clk, reset_n)
	BEGIN
		IF (reset_n = '0') THEN
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_178q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_199q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_0_187q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_1_186q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_2_185q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_3_184q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_4_183q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_5_182q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_6_181q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_7_180q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_179q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_176q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_174q <= '0';
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_175q <= '0';
		ELSIF (clk = '1' AND clk'event) THEN
			IF (s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_in_ready_210_dataout = '1') THEN
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_178q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_154m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_199q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_153m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_0_187q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_152m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_1_186q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_151m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_2_185q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_150m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_3_184q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_149m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_4_183q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_148m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_5_182q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_147m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_6_181q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_146m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_7_180q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_145m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_155m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_179q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_144m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_176q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_157m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_174q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_158m_dataout;
				sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_175q <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_156m_dataout;
			END IF;
		END IF;
	END PROCESS;
	wire_nO_w29w(0) <= NOT sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_178q;
	wire_nO_w27w(0) <= NOT sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q;
	wire_nO_w40w(0) <= NOT sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_179q;
	wire_nO_w46w(0) <= NOT sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_176q;
	wire_nO_w48w(0) <= NOT sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_174q;
	wire_nO_w44w(0) <= NOT sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_175q;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_114m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_178q AND s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_128m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_178q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_114m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_142m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_178q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_128m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_154m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_93m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_142m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_80m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_178q OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_93m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_178q WHEN wire_nO_w40w(0) = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_escaped_80m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_153m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_92m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_199q;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_62m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_199q AND NOT(wire_nO_w27w(0));
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_81m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_199q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_62m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_92m_dataout <= (((s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_0_309_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_1_318_dataout) OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_2_327_dataout) OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_3_336_dataout) WHEN wire_nO_w40w(0) = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_81m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_102m_dataout <= (NOT in_data(5)) WHEN sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_174q = '1'  ELSE in_data(5);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_103m_dataout <= in_data(7) AND NOT(s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_104m_dataout <= in_data(6) OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_105m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_102m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_106m_dataout <= in_data(4) OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_107m_dataout <= in_data(3) OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_108m_dataout <= in_data(2) OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_109m_dataout <= in_data(1) AND NOT(s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_110m_dataout <= in_data(0) OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_117m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_103m_dataout AND NOT(s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_118m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_104m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_119m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_105m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_120m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_106m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_121m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_107m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_122m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_108m_dataout AND NOT(s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_123m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_109m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_124m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_110m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_131m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_117m_dataout AND NOT(s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_132m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_118m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_133m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_119m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_134m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_120m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_135m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_121m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_136m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_122m_dataout AND NOT(s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_137m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_123m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_138m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_124m_dataout AND NOT(s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_145m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_84m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_131m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_146m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_85m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_132m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_147m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_86m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_133m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_148m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_87m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_134m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_149m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_88m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_135m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_150m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_89m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_136m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_151m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_90m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_137m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_152m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_91m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_138m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_61m_dataout <= (NOT in_channel(5)) WHEN sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_channel_needs_esc_199q = '1'  ELSE in_channel(5);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_63m_dataout <= in_channel(7) WHEN wire_nO_w27w(0) = '1'  ELSE sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_7_180q;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_64m_dataout <= in_channel(6) WHEN wire_nO_w27w(0) = '1'  ELSE sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_6_181q;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_65m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_61m_dataout WHEN wire_nO_w27w(0) = '1'  ELSE sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_5_182q;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_66m_dataout <= in_channel(4) WHEN wire_nO_w27w(0) = '1'  ELSE sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_4_183q;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_67m_dataout <= in_channel(3) WHEN wire_nO_w27w(0) = '1'  ELSE sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_3_184q;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_68m_dataout <= in_channel(2) WHEN wire_nO_w27w(0) = '1'  ELSE sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_2_185q;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_69m_dataout <= in_channel(1) WHEN wire_nO_w27w(0) = '1'  ELSE sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_1_186q;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_70m_dataout <= in_channel(0) WHEN wire_nO_w27w(0) = '1'  ELSE sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_0_187q;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_72m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_63m_dataout AND NOT(s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_73m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_64m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_74m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_65m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_75m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_66m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_76m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_67m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_77m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_68m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_78m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_69m_dataout AND NOT(s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_79m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_70m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_84m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_72m_dataout AND NOT(wire_nO_w40w(0));
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_85m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_73m_dataout OR wire_nO_w40w(0);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_86m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_74m_dataout OR wire_nO_w40w(0);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_87m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_75m_dataout OR wire_nO_w40w(0);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_88m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_76m_dataout OR wire_nO_w40w(0);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_89m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_77m_dataout OR wire_nO_w40w(0);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_90m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_78m_dataout AND NOT(wire_nO_w40w(0));
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_91m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_data_79m_dataout AND NOT(wire_nO_w40w(0));
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_45m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_188q AND NOT(out_ready);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_46m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_out_valid_45m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_in_ready_210_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_113m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q AND s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_127m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_113m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_141m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_127m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_155m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_94m_dataout WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_141m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_82m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q OR NOT(s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_57_dataout);
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_94m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_177q WHEN wire_nO_w40w(0) = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_82m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_115m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_179q AND s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_129m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_179q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_115m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_143m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_179q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_129m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_144m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_channel_char_143m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_112m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_176q AND s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_116m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_112m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_139m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_176q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_116m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_157m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_176q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_eop_139m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_125m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_174q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout = '1'  ELSE s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_140m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_174q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_125m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_158m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_174q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_esc_140m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_111m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_175q AND s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_100_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_126m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_175q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_98_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_111m_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_130m_dataout <= wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_126m_dataout OR s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_96_dataout;
	wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_156m_dataout <= sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_175q WHEN s_wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_always0_47_dataout = '1'  ELSE wire_sfpp_reconfig_master_0_p2b_altera_avalon_st_packets_to_bytes_p2b_sent_sop_130m_dataout;

 END RTL; --sfpp_reconfig_master_0_p2b
--synopsys translate_on
--VALID FILE
