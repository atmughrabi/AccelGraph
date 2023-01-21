-- megafunction wizard: %ALTIOBUF%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altiobuf_out 

-- ============================================================
-- File Name: psl_gpo.vhd
-- Megafunction Name(s):
-- 			altiobuf_out
--
-- Simulation Library Files(s):
-- 			
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 18.1.0 Build 625 09/12/2018 SJ Standard Edition
-- ************************************************************


--Copyright (C) 2018  Intel Corporation. All rights reserved.
--Your use of Intel Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Intel Program License 
--Subscription Agreement, the Intel Quartus Prime License Agreement,
--the Intel FPGA IP License Agreement, or other applicable license
--agreement, including, without limitation, that your use is for
--the sole purpose of programming logic devices manufactured by
--Intel and sold by Intel or its authorized distributors.  Please
--refer to the applicable agreement for further details.


--altiobuf_out CBX_AUTO_BLACKBOX="ALL" DEVICE_FAMILY="Stratix V" ENABLE_BUS_HOLD="FALSE" LEFT_SHIFT_SERIES_TERMINATION_CONTROL="FALSE" NUMBER_OF_CHANNELS=1 OPEN_DRAIN_OUTPUT="FALSE" PSEUDO_DIFFERENTIAL_MODE="FALSE" USE_DIFFERENTIAL_MODE="FALSE" USE_OE="TRUE" USE_TERMINATION_CONTROL="FALSE" datain dataout oe
--VERSION_BEGIN 18.1 cbx_altiobuf_out 2018:09:12:13:04:09:SJ cbx_mgl 2018:09:12:14:15:07:SJ cbx_stratixiii 2018:09:12:13:04:09:SJ cbx_stratixv 2018:09:12:13:04:09:SJ  VERSION_END

 LIBRARY stratixv;
 USE stratixv.all;

--synthesis_resources = stratixv_io_obuf 1 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  psl_gpo_iobuf_out_1vs IS 
	 PORT 
	 ( 
		 datain	:	IN  STD_LOGIC_VECTOR (0 DOWNTO 0);
		 dataout	:	OUT  STD_LOGIC_VECTOR (0 DOWNTO 0);
		 oe	:	IN  STD_LOGIC_VECTOR (0 DOWNTO 0) := (OTHERS => '1')
	 ); 
 END psl_gpo_iobuf_out_1vs;

 ARCHITECTURE RTL OF psl_gpo_iobuf_out_1vs IS

	 SIGNAL  wire_obufa_o	:	STD_LOGIC;
	 SIGNAL  oe_w :	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 COMPONENT  stratixv_io_obuf
	 GENERIC 
	 (
		bus_hold	:	STRING := "false";
		open_drain_output	:	STRING := "false";
		shift_series_termination_control	:	STRING := "false";
		lpm_type	:	STRING := "stratixv_io_obuf"
	 );
	 PORT
	 ( 
		dynamicterminationcontrol	:	IN STD_LOGIC := '0';
		i	:	IN STD_LOGIC := '0';
		o	:	OUT STD_LOGIC;
		obar	:	OUT STD_LOGIC;
		oe	:	IN STD_LOGIC := '1';
		parallelterminationcontrol	:	IN STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
		seriesterminationcontrol	:	IN STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0')
	 ); 
	 END COMPONENT;
 BEGIN

	dataout(0) <= wire_obufa_o;
	oe_w <= oe;
	obufa :  stratixv_io_obuf
	  GENERIC MAP (
		bus_hold => "false",
		open_drain_output => "false"
	  )
	  PORT MAP ( 
		i => datain(0),
		o => wire_obufa_o,
		oe => oe_w(0)
	  );

 END RTL; --psl_gpo_iobuf_out_1vs
--VALID FILE


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY psl_gpo IS
	PORT
	(
		datain		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
		oe		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
		dataout		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
	);
END psl_gpo;


ARCHITECTURE RTL OF psl_gpo IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (0 DOWNTO 0);



	COMPONENT psl_gpo_iobuf_out_1vs
	PORT (
			datain	: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
			oe	: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
			dataout	: OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	dataout    <= sub_wire0(0 DOWNTO 0);

	psl_gpo_iobuf_out_1vs_component : psl_gpo_iobuf_out_1vs
	PORT MAP (
		datain => datain,
		oe => oe,
		dataout => sub_wire0
	);



END RTL;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix V"
-- Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix V"
-- Retrieval info: CONSTANT: enable_bus_hold STRING "FALSE"
-- Retrieval info: CONSTANT: left_shift_series_termination_control STRING "FALSE"
-- Retrieval info: CONSTANT: number_of_channels NUMERIC "1"
-- Retrieval info: CONSTANT: open_drain_output STRING "FALSE"
-- Retrieval info: CONSTANT: pseudo_differential_mode STRING "FALSE"
-- Retrieval info: CONSTANT: use_differential_mode STRING "FALSE"
-- Retrieval info: CONSTANT: use_oe STRING "TRUE"
-- Retrieval info: CONSTANT: use_termination_control STRING "FALSE"
-- Retrieval info: USED_PORT: datain 0 0 1 0 INPUT NODEFVAL "datain[0..0]"
-- Retrieval info: USED_PORT: dataout 0 0 1 0 OUTPUT NODEFVAL "dataout[0..0]"
-- Retrieval info: USED_PORT: oe 0 0 1 0 INPUT NODEFVAL "oe[0..0]"
-- Retrieval info: CONNECT: @datain 0 0 1 0 datain 0 0 1 0
-- Retrieval info: CONNECT: @oe 0 0 1 0 oe 0 0 1 0
-- Retrieval info: CONNECT: dataout 0 0 1 0 @dataout 0 0 1 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL psl_gpo.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL psl_gpo.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL psl_gpo.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL psl_gpo.bsf FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL psl_gpo_inst.vhd TRUE