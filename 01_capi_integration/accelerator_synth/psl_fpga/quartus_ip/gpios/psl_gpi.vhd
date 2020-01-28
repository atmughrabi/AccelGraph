-- megafunction wizard: %ALTIOBUF%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altiobuf_in 

-- ============================================================
-- File Name: psl_gpi.vhd
-- Megafunction Name(s):
-- 			altiobuf_in
--
-- Simulation Library Files(s):
-- 			
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 15.1.0 Build 185 10/21/2015 SJ Standard Edition
-- ************************************************************


--Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, the Altera Quartus Prime License Agreement,
--the Altera MegaCore Function License Agreement, or other 
--applicable license agreement, including, without limitation, 
--that your use is for the sole purpose of programming logic 
--devices manufactured by Altera and sold by Altera or its 
--authorized distributors.  Please refer to the applicable 
--agreement for further details.


--altiobuf_in CBX_AUTO_BLACKBOX="ALL" DEVICE_FAMILY="Stratix V" ENABLE_BUS_HOLD="FALSE" NUMBER_OF_CHANNELS=1 USE_DIFFERENTIAL_MODE="FALSE" USE_DYNAMIC_TERMINATION_CONTROL="FALSE" datain dataout
--VERSION_BEGIN 15.1 cbx_altiobuf_in 2015:10:14:18:59:15:SJ cbx_mgl 2015:10:21:19:02:34:SJ cbx_stratixiii 2015:10:14:18:59:15:SJ cbx_stratixv 2015:10:14:18:59:15:SJ  VERSION_END

 LIBRARY stratixv;
 USE stratixv.all;

--synthesis_resources = stratixv_io_ibuf 1 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  psl_gpi_iobuf_in_12i IS 
	 PORT 
	 ( 
		 datain	:	IN  STD_LOGIC_VECTOR (0 DOWNTO 0);
		 dataout	:	OUT  STD_LOGIC_VECTOR (0 DOWNTO 0)
	 ); 
 END psl_gpi_iobuf_in_12i;

 ARCHITECTURE RTL OF psl_gpi_iobuf_in_12i IS

	 SIGNAL  wire_ibufa_o	:	STD_LOGIC;
	 COMPONENT  stratixv_io_ibuf
	 GENERIC 
	 (
		bus_hold	:	STRING := "false";
		differential_mode	:	STRING := "false";
		simulate_z_as	:	STRING := "z";
		lpm_type	:	STRING := "stratixv_io_ibuf"
	 );
	 PORT
	 ( 
		dynamicterminationcontrol	:	IN STD_LOGIC := '0';
		i	:	IN STD_LOGIC := '0';
		ibar	:	IN STD_LOGIC := '0';
		o	:	OUT STD_LOGIC
	 ); 
	 END COMPONENT;
 BEGIN

	dataout(0) <= wire_ibufa_o;
	ibufa :  stratixv_io_ibuf
	  GENERIC MAP (
		bus_hold => "false",
		differential_mode => "false"
	  )
	  PORT MAP ( 
		i => datain(0),
		o => wire_ibufa_o
	  );

 END RTL; --psl_gpi_iobuf_in_12i
--VALID FILE


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY psl_gpi IS
	PORT
	(
		datain		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
		dataout		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
	);
END psl_gpi;


ARCHITECTURE RTL OF psl_gpi IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (0 DOWNTO 0);



	COMPONENT psl_gpi_iobuf_in_12i
	PORT (
			datain	: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
			dataout	: OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	dataout    <= sub_wire0(0 DOWNTO 0);

	psl_gpi_iobuf_in_12i_component : psl_gpi_iobuf_in_12i
	PORT MAP (
		datain => datain,
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
-- Retrieval info: CONSTANT: number_of_channels NUMERIC "1"
-- Retrieval info: CONSTANT: use_differential_mode STRING "FALSE"
-- Retrieval info: CONSTANT: use_dynamic_termination_control STRING "FALSE"
-- Retrieval info: USED_PORT: datain 0 0 1 0 INPUT NODEFVAL "datain[0..0]"
-- Retrieval info: USED_PORT: dataout 0 0 1 0 OUTPUT NODEFVAL "dataout[0..0]"
-- Retrieval info: CONNECT: @datain 0 0 1 0 datain 0 0 1 0
-- Retrieval info: CONNECT: dataout 0 0 1 0 @dataout 0 0 1 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL psl_gpi.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL psl_gpi.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL psl_gpi.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL psl_gpi.bsf FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL psl_gpi_inst.vhd TRUE