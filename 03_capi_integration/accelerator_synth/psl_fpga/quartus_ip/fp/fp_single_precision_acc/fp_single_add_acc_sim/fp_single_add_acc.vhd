-- ------------------------------------------------------------------------- 
-- High Level Design Compiler for Intel(R) FPGAs Version 18.1 (Release Build #625)
-- Quartus Prime development tool and MATLAB/Simulink Interface
-- 
-- Legal Notice: Copyright 2018 Intel Corporation.  All rights reserved.
-- Your use of  Intel Corporation's design tools,  logic functions and other
-- software and  tools, and its AMPP partner logic functions, and any output
-- files any  of the foregoing (including  device programming  or simulation
-- files), and  any associated  documentation  or information  are expressly
-- subject  to the terms and  conditions of the  Intel FPGA Software License
-- Agreement, Intel MegaCore Function License Agreement, or other applicable
-- license agreement,  including,  without limitation,  that your use is for
-- the  sole  purpose of  programming  logic devices  manufactured by  Intel
-- and  sold by Intel  or its authorized  distributors. Please refer  to the
-- applicable agreement for further details.
-- ---------------------------------------------------------------------------

-- VHDL created from fp_single_add_acc
-- VHDL created on Wed Feb 19 18:20:36 2020


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;
use std.TextIO.all;
use work.dspba_library_package.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
LIBRARY altera_lnsim;
USE altera_lnsim.altera_lnsim_components.altera_syncram;
LIBRARY lpm;
USE lpm.lpm_components.all;

entity fp_single_add_acc is
    port (
        x : in std_logic_vector(31 downto 0);  -- float32_m23
        n : in std_logic_vector(0 downto 0);  -- ufix1
        en : in std_logic_vector(0 downto 0);  -- ufix1
        r : out std_logic_vector(31 downto 0);  -- float32_m23
        xo : out std_logic_vector(0 downto 0);  -- ufix1
        xu : out std_logic_vector(0 downto 0);  -- ufix1
        ao : out std_logic_vector(0 downto 0);  -- ufix1
        clk : in std_logic;
        areset : in std_logic
    );
end fp_single_add_acc;

architecture normal of fp_single_add_acc is

    attribute altera_attribute : string;
    attribute altera_attribute of normal : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF; -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 10037; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 15400; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 12020; -name MESSAGE_DISABLE 12030; -name MESSAGE_DISABLE 12010; -name MESSAGE_DISABLE 12110; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 13410; -name MESSAGE_DISABLE 113007";
    
    signal GND_q : STD_LOGIC_VECTOR (0 downto 0);
    signal VCC_q : STD_LOGIC_VECTOR (0 downto 0);
    signal expX_uid6_fpAccTest_b : STD_LOGIC_VECTOR (7 downto 0);
    signal fracX_uid7_fpAccTest_b : STD_LOGIC_VECTOR (22 downto 0);
    signal signX_uid8_fpAccTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal oFracX_uid10_fpAccTest_q : STD_LOGIC_VECTOR (23 downto 0);
    signal expLTLSBA_uid11_fpAccTest_q : STD_LOGIC_VECTOR (7 downto 0);
    signal cmpLT_expX_expLTLSBA_uid12_fpAccTest_a : STD_LOGIC_VECTOR (9 downto 0);
    signal cmpLT_expX_expLTLSBA_uid12_fpAccTest_b : STD_LOGIC_VECTOR (9 downto 0);
    signal cmpLT_expX_expLTLSBA_uid12_fpAccTest_o : STD_LOGIC_VECTOR (9 downto 0);
    signal cmpLT_expX_expLTLSBA_uid12_fpAccTest_c : STD_LOGIC_VECTOR (0 downto 0);
    signal expGTMaxMSBX_uid13_fpAccTest_q : STD_LOGIC_VECTOR (7 downto 0);
    signal cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_a : STD_LOGIC_VECTOR (9 downto 0);
    signal cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_b : STD_LOGIC_VECTOR (9 downto 0);
    signal cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_o : STD_LOGIC_VECTOR (9 downto 0);
    signal cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_c : STD_LOGIC_VECTOR (0 downto 0);
    signal rShiftConstant_uid15_fpAccTest_q : STD_LOGIC_VECTOR (8 downto 0);
    signal rightShiftValue_uid16_fpAccTest_a : STD_LOGIC_VECTOR (9 downto 0);
    signal rightShiftValue_uid16_fpAccTest_b : STD_LOGIC_VECTOR (9 downto 0);
    signal rightShiftValue_uid16_fpAccTest_o : STD_LOGIC_VECTOR (9 downto 0);
    signal rightShiftValue_uid16_fpAccTest_q : STD_LOGIC_VECTOR (9 downto 0);
    signal padConst_uid17_fpAccTest_q : STD_LOGIC_VECTOR (93 downto 0);
    signal rightPaddedIn_uid18_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal shiftedFracUpper_uid20_fpAccTest_b : STD_LOGIC_VECTOR (93 downto 0);
    signal extendedAlignedShiftedFrac_uid21_fpAccTest_q : STD_LOGIC_VECTOR (94 downto 0);
    signal onesComplementExtendedFrac_uid22_fpAccTest_b : STD_LOGIC_VECTOR (94 downto 0);
    signal onesComplementExtendedFrac_uid22_fpAccTest_q : STD_LOGIC_VECTOR (94 downto 0);
    signal accumulator_uid24_fpAccTest_a : STD_LOGIC_VECTOR (98 downto 0);
    signal accumulator_uid24_fpAccTest_b : STD_LOGIC_VECTOR (98 downto 0);
    signal accumulator_uid24_fpAccTest_i : STD_LOGIC_VECTOR (98 downto 0);
    signal accumulator_uid24_fpAccTest_o : STD_LOGIC_VECTOR (98 downto 0);
    signal accumulator_uid24_fpAccTest_cin : STD_LOGIC_VECTOR (0 downto 0);
    signal accumulator_uid24_fpAccTest_c : STD_LOGIC_VECTOR (0 downto 0);
    signal accumulator_uid24_fpAccTest_q : STD_LOGIC_VECTOR (96 downto 0);
    signal os_uid25_fpAccTest_q : STD_LOGIC_VECTOR (97 downto 0);
    signal osr_uid26_fpAccTest_in : STD_LOGIC_VECTOR (96 downto 0);
    signal osr_uid26_fpAccTest_b : STD_LOGIC_VECTOR (96 downto 0);
    signal sum_uid27_fpAccTest_in : STD_LOGIC_VECTOR (95 downto 0);
    signal sum_uid27_fpAccTest_b : STD_LOGIC_VECTOR (95 downto 0);
    signal accumulatorSign_uid29_fpAccTest_in : STD_LOGIC_VECTOR (94 downto 0);
    signal accumulatorSign_uid29_fpAccTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal accOverflowBitMSB_uid30_fpAccTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal accOverflow_uid32_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal accValidRange_uid33_fpAccTest_in : STD_LOGIC_VECTOR (94 downto 0);
    signal accValidRange_uid33_fpAccTest_b : STD_LOGIC_VECTOR (94 downto 0);
    signal accOnesComplement_uid34_fpAccTest_b : STD_LOGIC_VECTOR (94 downto 0);
    signal accOnesComplement_uid34_fpAccTest_q : STD_LOGIC_VECTOR (94 downto 0);
    signal accValuePositive_uid35_fpAccTest_a : STD_LOGIC_VECTOR (95 downto 0);
    signal accValuePositive_uid35_fpAccTest_b : STD_LOGIC_VECTOR (95 downto 0);
    signal accValuePositive_uid35_fpAccTest_o : STD_LOGIC_VECTOR (95 downto 0);
    signal accValuePositive_uid35_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal posAccWoLeadingZeroBit_uid36_fpAccTest_in : STD_LOGIC_VECTOR (93 downto 0);
    signal posAccWoLeadingZeroBit_uid36_fpAccTest_b : STD_LOGIC_VECTOR (93 downto 0);
    signal ShiftedOutComparator_uid38_fpAccTest_q : STD_LOGIC_VECTOR (6 downto 0);
    signal accResOutOfExpRange_uid39_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal zeroExponent_uid42_fpAccTest_q : STD_LOGIC_VECTOR (7 downto 0);
    signal resExpSub_uid43_fpAccTest_a : STD_LOGIC_VECTOR (9 downto 0);
    signal resExpSub_uid43_fpAccTest_b : STD_LOGIC_VECTOR (9 downto 0);
    signal resExpSub_uid43_fpAccTest_o : STD_LOGIC_VECTOR (9 downto 0);
    signal resExpSub_uid43_fpAccTest_q : STD_LOGIC_VECTOR (9 downto 0);
    signal finalExponent_uid44_fpAccTest_in : STD_LOGIC_VECTOR (7 downto 0);
    signal finalExponent_uid44_fpAccTest_b : STD_LOGIC_VECTOR (7 downto 0);
    signal finalExpUpdated_uid45_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal finalExpUpdated_uid45_fpAccTest_q : STD_LOGIC_VECTOR (7 downto 0);
    signal fracR_uid46_fpAccTest_in : STD_LOGIC_VECTOR (92 downto 0);
    signal fracR_uid46_fpAccTest_b : STD_LOGIC_VECTOR (22 downto 0);
    signal R_uid47_fpAccTest_q : STD_LOGIC_VECTOR (31 downto 0);
    signal muxXOverflowFeedbackSignal_uid51_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal muxXOverflowFeedbackSignal_uid51_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal oRXOverflowFlagFeedback_uid52_fpAccTest_qi : STD_LOGIC_VECTOR (0 downto 0);
    signal oRXOverflowFlagFeedback_uid52_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal muxXUnderflowFeedbackSignal_uid55_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal muxXUnderflowFeedbackSignal_uid55_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal expNotZero_uid56_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal underflowCond_uid57_fpAccTest_qi : STD_LOGIC_VECTOR (0 downto 0);
    signal underflowCond_uid57_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal oRXUnderflowFlagFeedback_uid58_fpAccTest_qi : STD_LOGIC_VECTOR (0 downto 0);
    signal oRXUnderflowFlagFeedback_uid58_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal muxAccOverflowFeedbackSignal_uid61_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal muxAccOverflowFeedbackSignal_uid61_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal oRAccOverflowFlagFeedback_uid62_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal zs_uid66_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (63 downto 0);
    signal vCount_uid68_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal mO_uid69_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (33 downto 0);
    signal cStage_uid71_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (63 downto 0);
    signal vStagei_uid73_zeroCounter_uid37_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid73_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (63 downto 0);
    signal zs_uid74_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (31 downto 0);
    signal vCount_uid76_zeroCounter_uid37_fpAccTest_qi : STD_LOGIC_VECTOR (0 downto 0);
    signal vCount_uid76_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid79_zeroCounter_uid37_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid79_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (31 downto 0);
    signal zs_uid80_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (15 downto 0);
    signal vCount_uid82_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid85_zeroCounter_uid37_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid85_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (15 downto 0);
    signal vCount_uid88_zeroCounter_uid37_fpAccTest_qi : STD_LOGIC_VECTOR (0 downto 0);
    signal vCount_uid88_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid91_zeroCounter_uid37_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid91_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (7 downto 0);
    signal zs_uid92_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (3 downto 0);
    signal vCount_uid94_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid97_zeroCounter_uid37_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid97_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (3 downto 0);
    signal zs_uid98_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (1 downto 0);
    signal vCount_uid100_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid103_zeroCounter_uid37_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid103_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (1 downto 0);
    signal rVStage_uid105_zeroCounter_uid37_fpAccTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal vCount_uid106_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal r_uid107_zeroCounter_uid37_fpAccTest_q : STD_LOGIC_VECTOR (6 downto 0);
    signal wIntCst_uid111_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (6 downto 0);
    signal shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_a : STD_LOGIC_VECTOR (11 downto 0);
    signal shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (11 downto 0);
    signal shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_o : STD_LOGIC_VECTOR (11 downto 0);
    signal shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_n : STD_LOGIC_VECTOR (0 downto 0);
    signal rightShiftStage0Idx1Rng32_uid113_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (85 downto 0);
    signal rightShiftStage0Idx1_uid115_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage0Idx2Rng64_uid116_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (53 downto 0);
    signal rightShiftStage0Idx2_uid118_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage0Idx3Rng96_uid119_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (21 downto 0);
    signal rightShiftStage0Idx3Pad96_uid120_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal rightShiftStage0Idx3_uid121_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage1Idx1Rng8_uid124_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (109 downto 0);
    signal rightShiftStage1Idx1_uid126_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage1Idx2Rng16_uid127_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (101 downto 0);
    signal rightShiftStage1Idx2_uid129_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage1Idx3Rng24_uid130_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (93 downto 0);
    signal rightShiftStage1Idx3Pad24_uid131_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (23 downto 0);
    signal rightShiftStage1Idx3_uid132_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage2Idx1Rng2_uid135_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (115 downto 0);
    signal rightShiftStage2Idx1_uid137_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage2Idx2Rng4_uid138_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (113 downto 0);
    signal rightShiftStage2Idx2_uid140_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage2Idx3Rng6_uid141_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (111 downto 0);
    signal rightShiftStage2Idx3Pad6_uid142_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (5 downto 0);
    signal rightShiftStage2Idx3_uid143_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage3Idx1Rng1_uid146_alignmentShifter_uid17_fpAccTest_b : STD_LOGIC_VECTOR (116 downto 0);
    signal rightShiftStage3Idx1_uid148_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal zeroOutCst_uid151_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal r_uid152_alignmentShifter_uid17_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal r_uid152_alignmentShifter_uid17_fpAccTest_q : STD_LOGIC_VECTOR (117 downto 0);
    signal leftShiftStage0Idx1Rng32_uid157_normalizationShifter_uid40_fpAccTest_in : STD_LOGIC_VECTOR (63 downto 0);
    signal leftShiftStage0Idx1Rng32_uid157_normalizationShifter_uid40_fpAccTest_b : STD_LOGIC_VECTOR (63 downto 0);
    signal leftShiftStage0Idx1_uid158_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage0Idx2Rng64_uid160_normalizationShifter_uid40_fpAccTest_in : STD_LOGIC_VECTOR (31 downto 0);
    signal leftShiftStage0Idx2Rng64_uid160_normalizationShifter_uid40_fpAccTest_b : STD_LOGIC_VECTOR (31 downto 0);
    signal leftShiftStage0Idx2_uid161_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage1Idx1Rng8_uid166_normalizationShifter_uid40_fpAccTest_in : STD_LOGIC_VECTOR (87 downto 0);
    signal leftShiftStage1Idx1Rng8_uid166_normalizationShifter_uid40_fpAccTest_b : STD_LOGIC_VECTOR (87 downto 0);
    signal leftShiftStage1Idx1_uid167_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage1Idx2Rng16_uid169_normalizationShifter_uid40_fpAccTest_in : STD_LOGIC_VECTOR (79 downto 0);
    signal leftShiftStage1Idx2Rng16_uid169_normalizationShifter_uid40_fpAccTest_b : STD_LOGIC_VECTOR (79 downto 0);
    signal leftShiftStage1Idx2_uid170_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage1Idx3Rng24_uid172_normalizationShifter_uid40_fpAccTest_in : STD_LOGIC_VECTOR (71 downto 0);
    signal leftShiftStage1Idx3Rng24_uid172_normalizationShifter_uid40_fpAccTest_b : STD_LOGIC_VECTOR (71 downto 0);
    signal leftShiftStage1Idx3_uid173_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage2Idx1Rng2_uid177_normalizationShifter_uid40_fpAccTest_in : STD_LOGIC_VECTOR (93 downto 0);
    signal leftShiftStage2Idx1Rng2_uid177_normalizationShifter_uid40_fpAccTest_b : STD_LOGIC_VECTOR (93 downto 0);
    signal leftShiftStage2Idx1_uid178_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage2Idx2Rng4_uid180_normalizationShifter_uid40_fpAccTest_in : STD_LOGIC_VECTOR (91 downto 0);
    signal leftShiftStage2Idx2Rng4_uid180_normalizationShifter_uid40_fpAccTest_b : STD_LOGIC_VECTOR (91 downto 0);
    signal leftShiftStage2Idx2_uid181_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage2Idx3Rng6_uid183_normalizationShifter_uid40_fpAccTest_in : STD_LOGIC_VECTOR (89 downto 0);
    signal leftShiftStage2Idx3Rng6_uid183_normalizationShifter_uid40_fpAccTest_b : STD_LOGIC_VECTOR (89 downto 0);
    signal leftShiftStage2Idx3_uid184_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage3Idx1Rng1_uid188_normalizationShifter_uid40_fpAccTest_in : STD_LOGIC_VECTOR (94 downto 0);
    signal leftShiftStage3Idx1Rng1_uid188_normalizationShifter_uid40_fpAccTest_b : STD_LOGIC_VECTOR (94 downto 0);
    signal leftShiftStage3Idx1_uid189_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest_q : STD_LOGIC_VECTOR (95 downto 0);
    signal rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_in : STD_LOGIC_VECTOR (6 downto 0);
    signal rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_b : STD_LOGIC_VECTOR (1 downto 0);
    signal rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_c : STD_LOGIC_VECTOR (1 downto 0);
    signal rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_d : STD_LOGIC_VECTOR (1 downto 0);
    signal rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_e : STD_LOGIC_VECTOR (0 downto 0);
    signal rVStage_uid67_zeroCounter_uid37_fpAccTest_merged_bit_select_b : STD_LOGIC_VECTOR (63 downto 0);
    signal rVStage_uid67_zeroCounter_uid37_fpAccTest_merged_bit_select_c : STD_LOGIC_VECTOR (29 downto 0);
    signal rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_b : STD_LOGIC_VECTOR (31 downto 0);
    signal rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_c : STD_LOGIC_VECTOR (31 downto 0);
    signal rVStage_uid81_zeroCounter_uid37_fpAccTest_merged_bit_select_b : STD_LOGIC_VECTOR (15 downto 0);
    signal rVStage_uid81_zeroCounter_uid37_fpAccTest_merged_bit_select_c : STD_LOGIC_VECTOR (15 downto 0);
    signal rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_b : STD_LOGIC_VECTOR (7 downto 0);
    signal rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_c : STD_LOGIC_VECTOR (7 downto 0);
    signal rVStage_uid93_zeroCounter_uid37_fpAccTest_merged_bit_select_b : STD_LOGIC_VECTOR (3 downto 0);
    signal rVStage_uid93_zeroCounter_uid37_fpAccTest_merged_bit_select_c : STD_LOGIC_VECTOR (3 downto 0);
    signal rVStage_uid99_zeroCounter_uid37_fpAccTest_merged_bit_select_b : STD_LOGIC_VECTOR (1 downto 0);
    signal rVStage_uid99_zeroCounter_uid37_fpAccTest_merged_bit_select_c : STD_LOGIC_VECTOR (1 downto 0);
    signal leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_b : STD_LOGIC_VECTOR (1 downto 0);
    signal leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_c : STD_LOGIC_VECTOR (1 downto 0);
    signal leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_d : STD_LOGIC_VECTOR (1 downto 0);
    signal leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_e : STD_LOGIC_VECTOR (0 downto 0);
    signal redist0_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1_q : STD_LOGIC_VECTOR (7 downto 0);
    signal redist1_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1_q : STD_LOGIC_VECTOR (7 downto 0);
    signal redist2_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1_q : STD_LOGIC_VECTOR (31 downto 0);
    signal redist3_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1_q : STD_LOGIC_VECTOR (31 downto 0);
    signal redist4_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_b_1_q : STD_LOGIC_VECTOR (1 downto 0);
    signal redist5_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_c_1_q : STD_LOGIC_VECTOR (1 downto 0);
    signal redist6_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_d_1_q : STD_LOGIC_VECTOR (1 downto 0);
    signal redist7_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_e_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist8_shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_n_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist9_rVStage_uid105_zeroCounter_uid37_fpAccTest_b_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist10_vCount_uid100_zeroCounter_uid37_fpAccTest_q_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist11_vCount_uid94_zeroCounter_uid37_fpAccTest_q_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist12_vCount_uid88_zeroCounter_uid37_fpAccTest_q_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist13_vCount_uid82_zeroCounter_uid37_fpAccTest_q_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist14_vCount_uid76_zeroCounter_uid37_fpAccTest_q_3_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist15_vCount_uid68_zeroCounter_uid37_fpAccTest_q_3_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist16_oRAccOverflowFlagFeedback_uid62_fpAccTest_q_4_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist17_oRXUnderflowFlagFeedback_uid58_fpAccTest_q_5_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist18_underflowCond_uid57_fpAccTest_q_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist19_oRXOverflowFlagFeedback_uid52_fpAccTest_q_5_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist20_accValuePositive_uid35_fpAccTest_q_4_q : STD_LOGIC_VECTOR (95 downto 0);
    signal redist21_accumulatorSign_uid29_fpAccTest_b_4_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist22_cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_c_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist23_signX_uid8_fpAccTest_b_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist24_fracX_uid7_fpAccTest_b_1_q : STD_LOGIC_VECTOR (22 downto 0);
    signal redist25_xIn_n_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist20_accValuePositive_uid35_fpAccTest_q_4_outputreg_q : STD_LOGIC_VECTOR (95 downto 0);

begin


    -- signX_uid8_fpAccTest(BITSELECT,7)@0
    signX_uid8_fpAccTest_b <= STD_LOGIC_VECTOR(x(31 downto 31));

    -- redist23_signX_uid8_fpAccTest_b_2(DELAY,223)
    redist23_signX_uid8_fpAccTest_b_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => signX_uid8_fpAccTest_b, xout => redist23_signX_uid8_fpAccTest_b_2_q, ena => en(0), clk => clk, aclr => areset );

    -- redist25_xIn_n_2(DELAY,225)
    redist25_xIn_n_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => n, xout => redist25_xIn_n_2_q, ena => en(0), clk => clk, aclr => areset );

    -- GND(CONSTANT,0)
    GND_q <= "0";

    -- zeroOutCst_uid151_alignmentShifter_uid17_fpAccTest(CONSTANT,150)
    zeroOutCst_uid151_alignmentShifter_uid17_fpAccTest_q <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    -- rightShiftStage3Idx1Rng1_uid146_alignmentShifter_uid17_fpAccTest(BITSELECT,145)@1
    rightShiftStage3Idx1Rng1_uid146_alignmentShifter_uid17_fpAccTest_b <= rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_q(117 downto 1);

    -- rightShiftStage3Idx1_uid148_alignmentShifter_uid17_fpAccTest(BITJOIN,147)@1
    rightShiftStage3Idx1_uid148_alignmentShifter_uid17_fpAccTest_q <= GND_q & rightShiftStage3Idx1Rng1_uid146_alignmentShifter_uid17_fpAccTest_b;

    -- rightShiftStage2Idx3Pad6_uid142_alignmentShifter_uid17_fpAccTest(CONSTANT,141)
    rightShiftStage2Idx3Pad6_uid142_alignmentShifter_uid17_fpAccTest_q <= "000000";

    -- rightShiftStage2Idx3Rng6_uid141_alignmentShifter_uid17_fpAccTest(BITSELECT,140)@1
    rightShiftStage2Idx3Rng6_uid141_alignmentShifter_uid17_fpAccTest_b <= rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q(117 downto 6);

    -- rightShiftStage2Idx3_uid143_alignmentShifter_uid17_fpAccTest(BITJOIN,142)@1
    rightShiftStage2Idx3_uid143_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage2Idx3Pad6_uid142_alignmentShifter_uid17_fpAccTest_q & rightShiftStage2Idx3Rng6_uid141_alignmentShifter_uid17_fpAccTest_b;

    -- zs_uid92_zeroCounter_uid37_fpAccTest(CONSTANT,91)
    zs_uid92_zeroCounter_uid37_fpAccTest_q <= "0000";

    -- rightShiftStage2Idx2Rng4_uid138_alignmentShifter_uid17_fpAccTest(BITSELECT,137)@1
    rightShiftStage2Idx2Rng4_uid138_alignmentShifter_uid17_fpAccTest_b <= rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q(117 downto 4);

    -- rightShiftStage2Idx2_uid140_alignmentShifter_uid17_fpAccTest(BITJOIN,139)@1
    rightShiftStage2Idx2_uid140_alignmentShifter_uid17_fpAccTest_q <= zs_uid92_zeroCounter_uid37_fpAccTest_q & rightShiftStage2Idx2Rng4_uid138_alignmentShifter_uid17_fpAccTest_b;

    -- zs_uid98_zeroCounter_uid37_fpAccTest(CONSTANT,97)
    zs_uid98_zeroCounter_uid37_fpAccTest_q <= "00";

    -- rightShiftStage2Idx1Rng2_uid135_alignmentShifter_uid17_fpAccTest(BITSELECT,134)@1
    rightShiftStage2Idx1Rng2_uid135_alignmentShifter_uid17_fpAccTest_b <= rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q(117 downto 2);

    -- rightShiftStage2Idx1_uid137_alignmentShifter_uid17_fpAccTest(BITJOIN,136)@1
    rightShiftStage2Idx1_uid137_alignmentShifter_uid17_fpAccTest_q <= zs_uid98_zeroCounter_uid37_fpAccTest_q & rightShiftStage2Idx1Rng2_uid135_alignmentShifter_uid17_fpAccTest_b;

    -- rightShiftStage1Idx3Pad24_uid131_alignmentShifter_uid17_fpAccTest(CONSTANT,130)
    rightShiftStage1Idx3Pad24_uid131_alignmentShifter_uid17_fpAccTest_q <= "000000000000000000000000";

    -- rightShiftStage1Idx3Rng24_uid130_alignmentShifter_uid17_fpAccTest(BITSELECT,129)@1
    rightShiftStage1Idx3Rng24_uid130_alignmentShifter_uid17_fpAccTest_b <= rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q(117 downto 24);

    -- rightShiftStage1Idx3_uid132_alignmentShifter_uid17_fpAccTest(BITJOIN,131)@1
    rightShiftStage1Idx3_uid132_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage1Idx3Pad24_uid131_alignmentShifter_uid17_fpAccTest_q & rightShiftStage1Idx3Rng24_uid130_alignmentShifter_uid17_fpAccTest_b;

    -- zs_uid80_zeroCounter_uid37_fpAccTest(CONSTANT,79)
    zs_uid80_zeroCounter_uid37_fpAccTest_q <= "0000000000000000";

    -- rightShiftStage1Idx2Rng16_uid127_alignmentShifter_uid17_fpAccTest(BITSELECT,126)@1
    rightShiftStage1Idx2Rng16_uid127_alignmentShifter_uid17_fpAccTest_b <= rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q(117 downto 16);

    -- rightShiftStage1Idx2_uid129_alignmentShifter_uid17_fpAccTest(BITJOIN,128)@1
    rightShiftStage1Idx2_uid129_alignmentShifter_uid17_fpAccTest_q <= zs_uid80_zeroCounter_uid37_fpAccTest_q & rightShiftStage1Idx2Rng16_uid127_alignmentShifter_uid17_fpAccTest_b;

    -- zeroExponent_uid42_fpAccTest(CONSTANT,41)
    zeroExponent_uid42_fpAccTest_q <= "00000000";

    -- rightShiftStage1Idx1Rng8_uid124_alignmentShifter_uid17_fpAccTest(BITSELECT,123)@1
    rightShiftStage1Idx1Rng8_uid124_alignmentShifter_uid17_fpAccTest_b <= rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q(117 downto 8);

    -- rightShiftStage1Idx1_uid126_alignmentShifter_uid17_fpAccTest(BITJOIN,125)@1
    rightShiftStage1Idx1_uid126_alignmentShifter_uid17_fpAccTest_q <= zeroExponent_uid42_fpAccTest_q & rightShiftStage1Idx1Rng8_uid124_alignmentShifter_uid17_fpAccTest_b;

    -- rightShiftStage0Idx3Pad96_uid120_alignmentShifter_uid17_fpAccTest(CONSTANT,119)
    rightShiftStage0Idx3Pad96_uid120_alignmentShifter_uid17_fpAccTest_q <= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    -- rightShiftStage0Idx3Rng96_uid119_alignmentShifter_uid17_fpAccTest(BITSELECT,118)@1
    rightShiftStage0Idx3Rng96_uid119_alignmentShifter_uid17_fpAccTest_b <= rightPaddedIn_uid18_fpAccTest_q(117 downto 96);

    -- rightShiftStage0Idx3_uid121_alignmentShifter_uid17_fpAccTest(BITJOIN,120)@1
    rightShiftStage0Idx3_uid121_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage0Idx3Pad96_uid120_alignmentShifter_uid17_fpAccTest_q & rightShiftStage0Idx3Rng96_uid119_alignmentShifter_uid17_fpAccTest_b;

    -- zs_uid66_zeroCounter_uid37_fpAccTest(CONSTANT,65)
    zs_uid66_zeroCounter_uid37_fpAccTest_q <= "0000000000000000000000000000000000000000000000000000000000000000";

    -- rightShiftStage0Idx2Rng64_uid116_alignmentShifter_uid17_fpAccTest(BITSELECT,115)@1
    rightShiftStage0Idx2Rng64_uid116_alignmentShifter_uid17_fpAccTest_b <= rightPaddedIn_uid18_fpAccTest_q(117 downto 64);

    -- rightShiftStage0Idx2_uid118_alignmentShifter_uid17_fpAccTest(BITJOIN,117)@1
    rightShiftStage0Idx2_uid118_alignmentShifter_uid17_fpAccTest_q <= zs_uid66_zeroCounter_uid37_fpAccTest_q & rightShiftStage0Idx2Rng64_uid116_alignmentShifter_uid17_fpAccTest_b;

    -- zs_uid74_zeroCounter_uid37_fpAccTest(CONSTANT,73)
    zs_uid74_zeroCounter_uid37_fpAccTest_q <= "00000000000000000000000000000000";

    -- rightShiftStage0Idx1Rng32_uid113_alignmentShifter_uid17_fpAccTest(BITSELECT,112)@1
    rightShiftStage0Idx1Rng32_uid113_alignmentShifter_uid17_fpAccTest_b <= rightPaddedIn_uid18_fpAccTest_q(117 downto 32);

    -- rightShiftStage0Idx1_uid115_alignmentShifter_uid17_fpAccTest(BITJOIN,114)@1
    rightShiftStage0Idx1_uid115_alignmentShifter_uid17_fpAccTest_q <= zs_uid74_zeroCounter_uid37_fpAccTest_q & rightShiftStage0Idx1Rng32_uid113_alignmentShifter_uid17_fpAccTest_b;

    -- VCC(CONSTANT,1)
    VCC_q <= "1";

    -- fracX_uid7_fpAccTest(BITSELECT,6)@0
    fracX_uid7_fpAccTest_b <= x(22 downto 0);

    -- redist24_fracX_uid7_fpAccTest_b_1(DELAY,224)
    redist24_fracX_uid7_fpAccTest_b_1 : dspba_delay
    GENERIC MAP ( width => 23, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => fracX_uid7_fpAccTest_b, xout => redist24_fracX_uid7_fpAccTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- oFracX_uid10_fpAccTest(BITJOIN,9)@1
    oFracX_uid10_fpAccTest_q <= VCC_q & redist24_fracX_uid7_fpAccTest_b_1_q;

    -- padConst_uid17_fpAccTest(CONSTANT,16)
    padConst_uid17_fpAccTest_q <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    -- rightPaddedIn_uid18_fpAccTest(BITJOIN,17)@1
    rightPaddedIn_uid18_fpAccTest_q <= oFracX_uid10_fpAccTest_q & padConst_uid17_fpAccTest_q;

    -- expX_uid6_fpAccTest(BITSELECT,5)@0
    expX_uid6_fpAccTest_b <= x(30 downto 23);

    -- rShiftConstant_uid15_fpAccTest(CONSTANT,14)
    rShiftConstant_uid15_fpAccTest_q <= "010011111";

    -- rightShiftValue_uid16_fpAccTest(SUB,15)@0
    rightShiftValue_uid16_fpAccTest_a <= STD_LOGIC_VECTOR("0" & rShiftConstant_uid15_fpAccTest_q);
    rightShiftValue_uid16_fpAccTest_b <= STD_LOGIC_VECTOR("00" & expX_uid6_fpAccTest_b);
    rightShiftValue_uid16_fpAccTest_o <= STD_LOGIC_VECTOR(UNSIGNED(rightShiftValue_uid16_fpAccTest_a) - UNSIGNED(rightShiftValue_uid16_fpAccTest_b));
    rightShiftValue_uid16_fpAccTest_q <= rightShiftValue_uid16_fpAccTest_o(9 downto 0);

    -- rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select(BITSELECT,192)@0
    rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_in <= rightShiftValue_uid16_fpAccTest_q(6 downto 0);
    rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_b <= rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_in(6 downto 5);
    rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_c <= rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_in(4 downto 3);
    rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_d <= rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_in(2 downto 1);
    rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_e <= rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_in(0 downto 0);

    -- redist4_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_b_1(DELAY,204)
    redist4_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_b_1 : dspba_delay
    GENERIC MAP ( width => 2, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_b, xout => redist4_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest(MUX,122)@1
    rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_s <= redist4_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_b_1_q;
    rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_combproc: PROCESS (rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_s, en, rightPaddedIn_uid18_fpAccTest_q, rightShiftStage0Idx1_uid115_alignmentShifter_uid17_fpAccTest_q, rightShiftStage0Idx2_uid118_alignmentShifter_uid17_fpAccTest_q, rightShiftStage0Idx3_uid121_alignmentShifter_uid17_fpAccTest_q)
    BEGIN
        CASE (rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_s) IS
            WHEN "00" => rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q <= rightPaddedIn_uid18_fpAccTest_q;
            WHEN "01" => rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage0Idx1_uid115_alignmentShifter_uid17_fpAccTest_q;
            WHEN "10" => rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage0Idx2_uid118_alignmentShifter_uid17_fpAccTest_q;
            WHEN "11" => rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage0Idx3_uid121_alignmentShifter_uid17_fpAccTest_q;
            WHEN OTHERS => rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- redist5_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_c_1(DELAY,205)
    redist5_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_c_1 : dspba_delay
    GENERIC MAP ( width => 2, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_c, xout => redist5_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_c_1_q, ena => en(0), clk => clk, aclr => areset );

    -- rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest(MUX,133)@1
    rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_s <= redist5_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_c_1_q;
    rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_combproc: PROCESS (rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_s, en, rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q, rightShiftStage1Idx1_uid126_alignmentShifter_uid17_fpAccTest_q, rightShiftStage1Idx2_uid129_alignmentShifter_uid17_fpAccTest_q, rightShiftStage1Idx3_uid132_alignmentShifter_uid17_fpAccTest_q)
    BEGIN
        CASE (rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_s) IS
            WHEN "00" => rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage0_uid123_alignmentShifter_uid17_fpAccTest_q;
            WHEN "01" => rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage1Idx1_uid126_alignmentShifter_uid17_fpAccTest_q;
            WHEN "10" => rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage1Idx2_uid129_alignmentShifter_uid17_fpAccTest_q;
            WHEN "11" => rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage1Idx3_uid132_alignmentShifter_uid17_fpAccTest_q;
            WHEN OTHERS => rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- redist6_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_d_1(DELAY,206)
    redist6_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_d_1 : dspba_delay
    GENERIC MAP ( width => 2, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_d, xout => redist6_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_d_1_q, ena => en(0), clk => clk, aclr => areset );

    -- rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest(MUX,144)@1
    rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_s <= redist6_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_d_1_q;
    rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_combproc: PROCESS (rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_s, en, rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q, rightShiftStage2Idx1_uid137_alignmentShifter_uid17_fpAccTest_q, rightShiftStage2Idx2_uid140_alignmentShifter_uid17_fpAccTest_q, rightShiftStage2Idx3_uid143_alignmentShifter_uid17_fpAccTest_q)
    BEGIN
        CASE (rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_s) IS
            WHEN "00" => rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage1_uid134_alignmentShifter_uid17_fpAccTest_q;
            WHEN "01" => rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage2Idx1_uid137_alignmentShifter_uid17_fpAccTest_q;
            WHEN "10" => rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage2Idx2_uid140_alignmentShifter_uid17_fpAccTest_q;
            WHEN "11" => rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage2Idx3_uid143_alignmentShifter_uid17_fpAccTest_q;
            WHEN OTHERS => rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- redist7_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_e_1(DELAY,207)
    redist7_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_e_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_e, xout => redist7_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_e_1_q, ena => en(0), clk => clk, aclr => areset );

    -- rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest(MUX,149)@1 + 1
    rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_s <= redist7_rightShiftStageSel6Dto5_uid122_alignmentShifter_uid17_fpAccTest_merged_bit_select_e_1_q;
    rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_q <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (en = "1") THEN
                CASE (rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_s) IS
                    WHEN "0" => rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage2_uid145_alignmentShifter_uid17_fpAccTest_q;
                    WHEN "1" => rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage3Idx1_uid148_alignmentShifter_uid17_fpAccTest_q;
                    WHEN OTHERS => rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_q <= (others => '0');
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- wIntCst_uid111_alignmentShifter_uid17_fpAccTest(CONSTANT,110)
    wIntCst_uid111_alignmentShifter_uid17_fpAccTest_q <= "1110110";

    -- shiftedOut_uid112_alignmentShifter_uid17_fpAccTest(COMPARE,111)@0 + 1
    shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_a <= STD_LOGIC_VECTOR("00" & rightShiftValue_uid16_fpAccTest_q);
    shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_b <= STD_LOGIC_VECTOR("00000" & wIntCst_uid111_alignmentShifter_uid17_fpAccTest_q);
    shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (en = "1") THEN
                shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_o <= STD_LOGIC_VECTOR(UNSIGNED(shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_a) - UNSIGNED(shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_b));
            END IF;
        END IF;
    END PROCESS;
    shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_n(0) <= not (shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_o(11));

    -- redist8_shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_n_2(DELAY,208)
    redist8_shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_n_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_n, xout => redist8_shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_n_2_q, ena => en(0), clk => clk, aclr => areset );

    -- r_uid152_alignmentShifter_uid17_fpAccTest(MUX,151)@2
    r_uid152_alignmentShifter_uid17_fpAccTest_s <= redist8_shiftedOut_uid112_alignmentShifter_uid17_fpAccTest_n_2_q;
    r_uid152_alignmentShifter_uid17_fpAccTest_combproc: PROCESS (r_uid152_alignmentShifter_uid17_fpAccTest_s, en, rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_q, zeroOutCst_uid151_alignmentShifter_uid17_fpAccTest_q)
    BEGIN
        CASE (r_uid152_alignmentShifter_uid17_fpAccTest_s) IS
            WHEN "0" => r_uid152_alignmentShifter_uid17_fpAccTest_q <= rightShiftStage3_uid150_alignmentShifter_uid17_fpAccTest_q;
            WHEN "1" => r_uid152_alignmentShifter_uid17_fpAccTest_q <= zeroOutCst_uid151_alignmentShifter_uid17_fpAccTest_q;
            WHEN OTHERS => r_uid152_alignmentShifter_uid17_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- shiftedFracUpper_uid20_fpAccTest(BITSELECT,19)@2
    shiftedFracUpper_uid20_fpAccTest_b <= r_uid152_alignmentShifter_uid17_fpAccTest_q(117 downto 24);

    -- extendedAlignedShiftedFrac_uid21_fpAccTest(BITJOIN,20)@2
    extendedAlignedShiftedFrac_uid21_fpAccTest_q <= GND_q & shiftedFracUpper_uid20_fpAccTest_b;

    -- onesComplementExtendedFrac_uid22_fpAccTest(LOGICAL,21)@2
    onesComplementExtendedFrac_uid22_fpAccTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((94 downto 1 => redist23_signX_uid8_fpAccTest_b_2_q(0)) & redist23_signX_uid8_fpAccTest_b_2_q));
    onesComplementExtendedFrac_uid22_fpAccTest_q <= extendedAlignedShiftedFrac_uid21_fpAccTest_q xor onesComplementExtendedFrac_uid22_fpAccTest_b;

    -- accumulator_uid24_fpAccTest(ADD,23)@2 + 1
    accumulator_uid24_fpAccTest_cin <= redist23_signX_uid8_fpAccTest_b_2_q;
    accumulator_uid24_fpAccTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((97 downto 96 => sum_uid27_fpAccTest_b(95)) & sum_uid27_fpAccTest_b) & '1');
    accumulator_uid24_fpAccTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((97 downto 95 => onesComplementExtendedFrac_uid22_fpAccTest_q(94)) & onesComplementExtendedFrac_uid22_fpAccTest_q) & accumulator_uid24_fpAccTest_cin(0));
    accumulator_uid24_fpAccTest_i <= accumulator_uid24_fpAccTest_b;
    accumulator_uid24_fpAccTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            accumulator_uid24_fpAccTest_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (en = "1") THEN
                IF (redist25_xIn_n_2_q = "1") THEN
                    accumulator_uid24_fpAccTest_o <= accumulator_uid24_fpAccTest_i;
                ELSE
                    accumulator_uid24_fpAccTest_o <= STD_LOGIC_VECTOR(SIGNED(accumulator_uid24_fpAccTest_a) + SIGNED(accumulator_uid24_fpAccTest_b));
                END IF;
            END IF;
        END IF;
    END PROCESS;
    accumulator_uid24_fpAccTest_c(0) <= accumulator_uid24_fpAccTest_o(98);
    accumulator_uid24_fpAccTest_q <= accumulator_uid24_fpAccTest_o(97 downto 1);

    -- os_uid25_fpAccTest(BITJOIN,24)@3
    os_uid25_fpAccTest_q <= accumulator_uid24_fpAccTest_c & accumulator_uid24_fpAccTest_q;

    -- osr_uid26_fpAccTest(BITSELECT,25)@3
    osr_uid26_fpAccTest_in <= STD_LOGIC_VECTOR(os_uid25_fpAccTest_q(96 downto 0));
    osr_uid26_fpAccTest_b <= STD_LOGIC_VECTOR(osr_uid26_fpAccTest_in(96 downto 0));

    -- sum_uid27_fpAccTest(BITSELECT,26)@3
    sum_uid27_fpAccTest_in <= STD_LOGIC_VECTOR(osr_uid26_fpAccTest_b(95 downto 0));
    sum_uid27_fpAccTest_b <= STD_LOGIC_VECTOR(sum_uid27_fpAccTest_in(95 downto 0));

    -- accumulatorSign_uid29_fpAccTest(BITSELECT,28)@3
    accumulatorSign_uid29_fpAccTest_in <= sum_uid27_fpAccTest_b(94 downto 0);
    accumulatorSign_uid29_fpAccTest_b <= accumulatorSign_uid29_fpAccTest_in(94 downto 94);

    -- accOverflowBitMSB_uid30_fpAccTest(BITSELECT,29)@3
    accOverflowBitMSB_uid30_fpAccTest_b <= sum_uid27_fpAccTest_b(95 downto 95);

    -- accOverflow_uid32_fpAccTest(LOGICAL,31)@3
    accOverflow_uid32_fpAccTest_q <= accOverflowBitMSB_uid30_fpAccTest_b xor accumulatorSign_uid29_fpAccTest_b;

    -- muxAccOverflowFeedbackSignal_uid61_fpAccTest(MUX,60)@2 + 1
    muxAccOverflowFeedbackSignal_uid61_fpAccTest_s <= redist25_xIn_n_2_q;
    muxAccOverflowFeedbackSignal_uid61_fpAccTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            muxAccOverflowFeedbackSignal_uid61_fpAccTest_q <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (en = "1") THEN
                CASE (muxAccOverflowFeedbackSignal_uid61_fpAccTest_s) IS
                    WHEN "0" => muxAccOverflowFeedbackSignal_uid61_fpAccTest_q <= oRAccOverflowFlagFeedback_uid62_fpAccTest_q;
                    WHEN "1" => muxAccOverflowFeedbackSignal_uid61_fpAccTest_q <= GND_q;
                    WHEN OTHERS => muxAccOverflowFeedbackSignal_uid61_fpAccTest_q <= (others => '0');
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- oRAccOverflowFlagFeedback_uid62_fpAccTest(LOGICAL,61)@3
    oRAccOverflowFlagFeedback_uid62_fpAccTest_q <= muxAccOverflowFeedbackSignal_uid61_fpAccTest_q or accOverflow_uid32_fpAccTest_q;

    -- redist16_oRAccOverflowFlagFeedback_uid62_fpAccTest_q_4(DELAY,216)
    redist16_oRAccOverflowFlagFeedback_uid62_fpAccTest_q_4 : dspba_delay
    GENERIC MAP ( width => 1, depth => 4, reset_kind => "ASYNC" )
    PORT MAP ( xin => oRAccOverflowFlagFeedback_uid62_fpAccTest_q, xout => redist16_oRAccOverflowFlagFeedback_uid62_fpAccTest_q_4_q, ena => en(0), clk => clk, aclr => areset );

    -- expNotZero_uid56_fpAccTest(LOGICAL,55)@0
    expNotZero_uid56_fpAccTest_q <= "1" WHEN expX_uid6_fpAccTest_b /= "00000000" ELSE "0";

    -- expLTLSBA_uid11_fpAccTest(CONSTANT,10)
    expLTLSBA_uid11_fpAccTest_q <= "01000001";

    -- cmpLT_expX_expLTLSBA_uid12_fpAccTest(COMPARE,11)@0
    cmpLT_expX_expLTLSBA_uid12_fpAccTest_a <= STD_LOGIC_VECTOR("00" & expX_uid6_fpAccTest_b);
    cmpLT_expX_expLTLSBA_uid12_fpAccTest_b <= STD_LOGIC_VECTOR("00" & expLTLSBA_uid11_fpAccTest_q);
    cmpLT_expX_expLTLSBA_uid12_fpAccTest_o <= STD_LOGIC_VECTOR(UNSIGNED(cmpLT_expX_expLTLSBA_uid12_fpAccTest_a) - UNSIGNED(cmpLT_expX_expLTLSBA_uid12_fpAccTest_b));
    cmpLT_expX_expLTLSBA_uid12_fpAccTest_c(0) <= cmpLT_expX_expLTLSBA_uid12_fpAccTest_o(9);

    -- underflowCond_uid57_fpAccTest(LOGICAL,56)@0 + 1
    underflowCond_uid57_fpAccTest_qi <= cmpLT_expX_expLTLSBA_uid12_fpAccTest_c and expNotZero_uid56_fpAccTest_q;
    underflowCond_uid57_fpAccTest_delay : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => underflowCond_uid57_fpAccTest_qi, xout => underflowCond_uid57_fpAccTest_q, ena => en(0), clk => clk, aclr => areset );

    -- redist18_underflowCond_uid57_fpAccTest_q_2(DELAY,218)
    redist18_underflowCond_uid57_fpAccTest_q_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => underflowCond_uid57_fpAccTest_q, xout => redist18_underflowCond_uid57_fpAccTest_q_2_q, ena => en(0), clk => clk, aclr => areset );

    -- muxXUnderflowFeedbackSignal_uid55_fpAccTest(MUX,54)@2
    muxXUnderflowFeedbackSignal_uid55_fpAccTest_s <= redist25_xIn_n_2_q;
    muxXUnderflowFeedbackSignal_uid55_fpAccTest_combproc: PROCESS (muxXUnderflowFeedbackSignal_uid55_fpAccTest_s, en, oRXUnderflowFlagFeedback_uid58_fpAccTest_q, GND_q)
    BEGIN
        CASE (muxXUnderflowFeedbackSignal_uid55_fpAccTest_s) IS
            WHEN "0" => muxXUnderflowFeedbackSignal_uid55_fpAccTest_q <= oRXUnderflowFlagFeedback_uid58_fpAccTest_q;
            WHEN "1" => muxXUnderflowFeedbackSignal_uid55_fpAccTest_q <= GND_q;
            WHEN OTHERS => muxXUnderflowFeedbackSignal_uid55_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- oRXUnderflowFlagFeedback_uid58_fpAccTest(LOGICAL,57)@2 + 1
    oRXUnderflowFlagFeedback_uid58_fpAccTest_qi <= muxXUnderflowFeedbackSignal_uid55_fpAccTest_q or redist18_underflowCond_uid57_fpAccTest_q_2_q;
    oRXUnderflowFlagFeedback_uid58_fpAccTest_delay : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => oRXUnderflowFlagFeedback_uid58_fpAccTest_qi, xout => oRXUnderflowFlagFeedback_uid58_fpAccTest_q, ena => en(0), clk => clk, aclr => areset );

    -- redist17_oRXUnderflowFlagFeedback_uid58_fpAccTest_q_5(DELAY,217)
    redist17_oRXUnderflowFlagFeedback_uid58_fpAccTest_q_5 : dspba_delay
    GENERIC MAP ( width => 1, depth => 4, reset_kind => "ASYNC" )
    PORT MAP ( xin => oRXUnderflowFlagFeedback_uid58_fpAccTest_q, xout => redist17_oRXUnderflowFlagFeedback_uid58_fpAccTest_q_5_q, ena => en(0), clk => clk, aclr => areset );

    -- expGTMaxMSBX_uid13_fpAccTest(CONSTANT,12)
    expGTMaxMSBX_uid13_fpAccTest_q <= "10011111";

    -- cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest(COMPARE,13)@0 + 1
    cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_a <= STD_LOGIC_VECTOR("00" & expGTMaxMSBX_uid13_fpAccTest_q);
    cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_b <= STD_LOGIC_VECTOR("00" & expX_uid6_fpAccTest_b);
    cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (en = "1") THEN
                cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_o <= STD_LOGIC_VECTOR(UNSIGNED(cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_a) - UNSIGNED(cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_b));
            END IF;
        END IF;
    END PROCESS;
    cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_c(0) <= cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_o(9);

    -- redist22_cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_c_2(DELAY,222)
    redist22_cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_c_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_c, xout => redist22_cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_c_2_q, ena => en(0), clk => clk, aclr => areset );

    -- muxXOverflowFeedbackSignal_uid51_fpAccTest(MUX,50)@2
    muxXOverflowFeedbackSignal_uid51_fpAccTest_s <= redist25_xIn_n_2_q;
    muxXOverflowFeedbackSignal_uid51_fpAccTest_combproc: PROCESS (muxXOverflowFeedbackSignal_uid51_fpAccTest_s, en, oRXOverflowFlagFeedback_uid52_fpAccTest_q, GND_q)
    BEGIN
        CASE (muxXOverflowFeedbackSignal_uid51_fpAccTest_s) IS
            WHEN "0" => muxXOverflowFeedbackSignal_uid51_fpAccTest_q <= oRXOverflowFlagFeedback_uid52_fpAccTest_q;
            WHEN "1" => muxXOverflowFeedbackSignal_uid51_fpAccTest_q <= GND_q;
            WHEN OTHERS => muxXOverflowFeedbackSignal_uid51_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- oRXOverflowFlagFeedback_uid52_fpAccTest(LOGICAL,51)@2 + 1
    oRXOverflowFlagFeedback_uid52_fpAccTest_qi <= muxXOverflowFeedbackSignal_uid51_fpAccTest_q or redist22_cmpGT_expX_expGTMaxMSBX_uid14_fpAccTest_c_2_q;
    oRXOverflowFlagFeedback_uid52_fpAccTest_delay : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => oRXOverflowFlagFeedback_uid52_fpAccTest_qi, xout => oRXOverflowFlagFeedback_uid52_fpAccTest_q, ena => en(0), clk => clk, aclr => areset );

    -- redist19_oRXOverflowFlagFeedback_uid52_fpAccTest_q_5(DELAY,219)
    redist19_oRXOverflowFlagFeedback_uid52_fpAccTest_q_5 : dspba_delay
    GENERIC MAP ( width => 1, depth => 4, reset_kind => "ASYNC" )
    PORT MAP ( xin => oRXOverflowFlagFeedback_uid52_fpAccTest_q, xout => redist19_oRXOverflowFlagFeedback_uid52_fpAccTest_q_5_q, ena => en(0), clk => clk, aclr => areset );

    -- redist21_accumulatorSign_uid29_fpAccTest_b_4(DELAY,221)
    redist21_accumulatorSign_uid29_fpAccTest_b_4 : dspba_delay
    GENERIC MAP ( width => 1, depth => 4, reset_kind => "ASYNC" )
    PORT MAP ( xin => accumulatorSign_uid29_fpAccTest_b, xout => redist21_accumulatorSign_uid29_fpAccTest_b_4_q, ena => en(0), clk => clk, aclr => areset );

    -- accValidRange_uid33_fpAccTest(BITSELECT,32)@3
    accValidRange_uid33_fpAccTest_in <= sum_uid27_fpAccTest_b(94 downto 0);
    accValidRange_uid33_fpAccTest_b <= accValidRange_uid33_fpAccTest_in(94 downto 0);

    -- accOnesComplement_uid34_fpAccTest(LOGICAL,33)@3
    accOnesComplement_uid34_fpAccTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((94 downto 1 => accumulatorSign_uid29_fpAccTest_b(0)) & accumulatorSign_uid29_fpAccTest_b));
    accOnesComplement_uid34_fpAccTest_q <= accValidRange_uid33_fpAccTest_b xor accOnesComplement_uid34_fpAccTest_b;

    -- accValuePositive_uid35_fpAccTest(ADD,34)@3 + 1
    accValuePositive_uid35_fpAccTest_a <= STD_LOGIC_VECTOR("0" & accOnesComplement_uid34_fpAccTest_q);
    accValuePositive_uid35_fpAccTest_b <= STD_LOGIC_VECTOR("00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & accumulatorSign_uid29_fpAccTest_b);
    accValuePositive_uid35_fpAccTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            accValuePositive_uid35_fpAccTest_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (en = "1") THEN
                accValuePositive_uid35_fpAccTest_o <= STD_LOGIC_VECTOR(UNSIGNED(accValuePositive_uid35_fpAccTest_a) + UNSIGNED(accValuePositive_uid35_fpAccTest_b));
            END IF;
        END IF;
    END PROCESS;
    accValuePositive_uid35_fpAccTest_q <= accValuePositive_uid35_fpAccTest_o(95 downto 0);

    -- posAccWoLeadingZeroBit_uid36_fpAccTest(BITSELECT,35)@4
    posAccWoLeadingZeroBit_uid36_fpAccTest_in <= accValuePositive_uid35_fpAccTest_q(93 downto 0);
    posAccWoLeadingZeroBit_uid36_fpAccTest_b <= posAccWoLeadingZeroBit_uid36_fpAccTest_in(93 downto 0);

    -- rVStage_uid67_zeroCounter_uid37_fpAccTest_merged_bit_select(BITSELECT,193)@4
    rVStage_uid67_zeroCounter_uid37_fpAccTest_merged_bit_select_b <= posAccWoLeadingZeroBit_uid36_fpAccTest_b(93 downto 30);
    rVStage_uid67_zeroCounter_uid37_fpAccTest_merged_bit_select_c <= posAccWoLeadingZeroBit_uid36_fpAccTest_b(29 downto 0);

    -- vCount_uid68_zeroCounter_uid37_fpAccTest(LOGICAL,67)@4
    vCount_uid68_zeroCounter_uid37_fpAccTest_q <= "1" WHEN rVStage_uid67_zeroCounter_uid37_fpAccTest_merged_bit_select_b = zs_uid66_zeroCounter_uid37_fpAccTest_q ELSE "0";

    -- redist15_vCount_uid68_zeroCounter_uid37_fpAccTest_q_3(DELAY,215)
    redist15_vCount_uid68_zeroCounter_uid37_fpAccTest_q_3 : dspba_delay
    GENERIC MAP ( width => 1, depth => 3, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid68_zeroCounter_uid37_fpAccTest_q, xout => redist15_vCount_uid68_zeroCounter_uid37_fpAccTest_q_3_q, ena => en(0), clk => clk, aclr => areset );

    -- mO_uid69_zeroCounter_uid37_fpAccTest(CONSTANT,68)
    mO_uid69_zeroCounter_uid37_fpAccTest_q <= "1111111111111111111111111111111111";

    -- cStage_uid71_zeroCounter_uid37_fpAccTest(BITJOIN,70)@4
    cStage_uid71_zeroCounter_uid37_fpAccTest_q <= rVStage_uid67_zeroCounter_uid37_fpAccTest_merged_bit_select_c & mO_uid69_zeroCounter_uid37_fpAccTest_q;

    -- vStagei_uid73_zeroCounter_uid37_fpAccTest(MUX,72)@4
    vStagei_uid73_zeroCounter_uid37_fpAccTest_s <= vCount_uid68_zeroCounter_uid37_fpAccTest_q;
    vStagei_uid73_zeroCounter_uid37_fpAccTest_combproc: PROCESS (vStagei_uid73_zeroCounter_uid37_fpAccTest_s, en, rVStage_uid67_zeroCounter_uid37_fpAccTest_merged_bit_select_b, cStage_uid71_zeroCounter_uid37_fpAccTest_q)
    BEGIN
        CASE (vStagei_uid73_zeroCounter_uid37_fpAccTest_s) IS
            WHEN "0" => vStagei_uid73_zeroCounter_uid37_fpAccTest_q <= rVStage_uid67_zeroCounter_uid37_fpAccTest_merged_bit_select_b;
            WHEN "1" => vStagei_uid73_zeroCounter_uid37_fpAccTest_q <= cStage_uid71_zeroCounter_uid37_fpAccTest_q;
            WHEN OTHERS => vStagei_uid73_zeroCounter_uid37_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select(BITSELECT,194)@4
    rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_b <= vStagei_uid73_zeroCounter_uid37_fpAccTest_q(63 downto 32);
    rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_c <= vStagei_uid73_zeroCounter_uid37_fpAccTest_q(31 downto 0);

    -- vCount_uid76_zeroCounter_uid37_fpAccTest(LOGICAL,75)@4 + 1
    vCount_uid76_zeroCounter_uid37_fpAccTest_qi <= "1" WHEN rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_b = zs_uid74_zeroCounter_uid37_fpAccTest_q ELSE "0";
    vCount_uid76_zeroCounter_uid37_fpAccTest_delay : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid76_zeroCounter_uid37_fpAccTest_qi, xout => vCount_uid76_zeroCounter_uid37_fpAccTest_q, ena => en(0), clk => clk, aclr => areset );

    -- redist14_vCount_uid76_zeroCounter_uid37_fpAccTest_q_3(DELAY,214)
    redist14_vCount_uid76_zeroCounter_uid37_fpAccTest_q_3 : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid76_zeroCounter_uid37_fpAccTest_q, xout => redist14_vCount_uid76_zeroCounter_uid37_fpAccTest_q_3_q, ena => en(0), clk => clk, aclr => areset );

    -- redist3_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1(DELAY,203)
    redist3_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1 : dspba_delay
    GENERIC MAP ( width => 32, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_c, xout => redist3_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1_q, ena => en(0), clk => clk, aclr => areset );

    -- redist2_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1(DELAY,202)
    redist2_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1 : dspba_delay
    GENERIC MAP ( width => 32, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_b, xout => redist2_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- vStagei_uid79_zeroCounter_uid37_fpAccTest(MUX,78)@5
    vStagei_uid79_zeroCounter_uid37_fpAccTest_s <= vCount_uid76_zeroCounter_uid37_fpAccTest_q;
    vStagei_uid79_zeroCounter_uid37_fpAccTest_combproc: PROCESS (vStagei_uid79_zeroCounter_uid37_fpAccTest_s, en, redist2_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1_q, redist3_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1_q)
    BEGIN
        CASE (vStagei_uid79_zeroCounter_uid37_fpAccTest_s) IS
            WHEN "0" => vStagei_uid79_zeroCounter_uid37_fpAccTest_q <= redist2_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1_q;
            WHEN "1" => vStagei_uid79_zeroCounter_uid37_fpAccTest_q <= redist3_rVStage_uid75_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1_q;
            WHEN OTHERS => vStagei_uid79_zeroCounter_uid37_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- rVStage_uid81_zeroCounter_uid37_fpAccTest_merged_bit_select(BITSELECT,195)@5
    rVStage_uid81_zeroCounter_uid37_fpAccTest_merged_bit_select_b <= vStagei_uid79_zeroCounter_uid37_fpAccTest_q(31 downto 16);
    rVStage_uid81_zeroCounter_uid37_fpAccTest_merged_bit_select_c <= vStagei_uid79_zeroCounter_uid37_fpAccTest_q(15 downto 0);

    -- vCount_uid82_zeroCounter_uid37_fpAccTest(LOGICAL,81)@5
    vCount_uid82_zeroCounter_uid37_fpAccTest_q <= "1" WHEN rVStage_uid81_zeroCounter_uid37_fpAccTest_merged_bit_select_b = zs_uid80_zeroCounter_uid37_fpAccTest_q ELSE "0";

    -- redist13_vCount_uid82_zeroCounter_uid37_fpAccTest_q_2(DELAY,213)
    redist13_vCount_uid82_zeroCounter_uid37_fpAccTest_q_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid82_zeroCounter_uid37_fpAccTest_q, xout => redist13_vCount_uid82_zeroCounter_uid37_fpAccTest_q_2_q, ena => en(0), clk => clk, aclr => areset );

    -- vStagei_uid85_zeroCounter_uid37_fpAccTest(MUX,84)@5
    vStagei_uid85_zeroCounter_uid37_fpAccTest_s <= vCount_uid82_zeroCounter_uid37_fpAccTest_q;
    vStagei_uid85_zeroCounter_uid37_fpAccTest_combproc: PROCESS (vStagei_uid85_zeroCounter_uid37_fpAccTest_s, en, rVStage_uid81_zeroCounter_uid37_fpAccTest_merged_bit_select_b, rVStage_uid81_zeroCounter_uid37_fpAccTest_merged_bit_select_c)
    BEGIN
        CASE (vStagei_uid85_zeroCounter_uid37_fpAccTest_s) IS
            WHEN "0" => vStagei_uid85_zeroCounter_uid37_fpAccTest_q <= rVStage_uid81_zeroCounter_uid37_fpAccTest_merged_bit_select_b;
            WHEN "1" => vStagei_uid85_zeroCounter_uid37_fpAccTest_q <= rVStage_uid81_zeroCounter_uid37_fpAccTest_merged_bit_select_c;
            WHEN OTHERS => vStagei_uid85_zeroCounter_uid37_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select(BITSELECT,196)@5
    rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_b <= vStagei_uid85_zeroCounter_uid37_fpAccTest_q(15 downto 8);
    rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_c <= vStagei_uid85_zeroCounter_uid37_fpAccTest_q(7 downto 0);

    -- vCount_uid88_zeroCounter_uid37_fpAccTest(LOGICAL,87)@5 + 1
    vCount_uid88_zeroCounter_uid37_fpAccTest_qi <= "1" WHEN rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_b = zeroExponent_uid42_fpAccTest_q ELSE "0";
    vCount_uid88_zeroCounter_uid37_fpAccTest_delay : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid88_zeroCounter_uid37_fpAccTest_qi, xout => vCount_uid88_zeroCounter_uid37_fpAccTest_q, ena => en(0), clk => clk, aclr => areset );

    -- redist12_vCount_uid88_zeroCounter_uid37_fpAccTest_q_2(DELAY,212)
    redist12_vCount_uid88_zeroCounter_uid37_fpAccTest_q_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid88_zeroCounter_uid37_fpAccTest_q, xout => redist12_vCount_uid88_zeroCounter_uid37_fpAccTest_q_2_q, ena => en(0), clk => clk, aclr => areset );

    -- redist1_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1(DELAY,201)
    redist1_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1 : dspba_delay
    GENERIC MAP ( width => 8, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_c, xout => redist1_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1_q, ena => en(0), clk => clk, aclr => areset );

    -- redist0_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1(DELAY,200)
    redist0_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1 : dspba_delay
    GENERIC MAP ( width => 8, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_b, xout => redist0_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- vStagei_uid91_zeroCounter_uid37_fpAccTest(MUX,90)@6
    vStagei_uid91_zeroCounter_uid37_fpAccTest_s <= vCount_uid88_zeroCounter_uid37_fpAccTest_q;
    vStagei_uid91_zeroCounter_uid37_fpAccTest_combproc: PROCESS (vStagei_uid91_zeroCounter_uid37_fpAccTest_s, en, redist0_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1_q, redist1_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1_q)
    BEGIN
        CASE (vStagei_uid91_zeroCounter_uid37_fpAccTest_s) IS
            WHEN "0" => vStagei_uid91_zeroCounter_uid37_fpAccTest_q <= redist0_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_b_1_q;
            WHEN "1" => vStagei_uid91_zeroCounter_uid37_fpAccTest_q <= redist1_rVStage_uid87_zeroCounter_uid37_fpAccTest_merged_bit_select_c_1_q;
            WHEN OTHERS => vStagei_uid91_zeroCounter_uid37_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- rVStage_uid93_zeroCounter_uid37_fpAccTest_merged_bit_select(BITSELECT,197)@6
    rVStage_uid93_zeroCounter_uid37_fpAccTest_merged_bit_select_b <= vStagei_uid91_zeroCounter_uid37_fpAccTest_q(7 downto 4);
    rVStage_uid93_zeroCounter_uid37_fpAccTest_merged_bit_select_c <= vStagei_uid91_zeroCounter_uid37_fpAccTest_q(3 downto 0);

    -- vCount_uid94_zeroCounter_uid37_fpAccTest(LOGICAL,93)@6
    vCount_uid94_zeroCounter_uid37_fpAccTest_q <= "1" WHEN rVStage_uid93_zeroCounter_uid37_fpAccTest_merged_bit_select_b = zs_uid92_zeroCounter_uid37_fpAccTest_q ELSE "0";

    -- redist11_vCount_uid94_zeroCounter_uid37_fpAccTest_q_1(DELAY,211)
    redist11_vCount_uid94_zeroCounter_uid37_fpAccTest_q_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid94_zeroCounter_uid37_fpAccTest_q, xout => redist11_vCount_uid94_zeroCounter_uid37_fpAccTest_q_1_q, ena => en(0), clk => clk, aclr => areset );

    -- vStagei_uid97_zeroCounter_uid37_fpAccTest(MUX,96)@6
    vStagei_uid97_zeroCounter_uid37_fpAccTest_s <= vCount_uid94_zeroCounter_uid37_fpAccTest_q;
    vStagei_uid97_zeroCounter_uid37_fpAccTest_combproc: PROCESS (vStagei_uid97_zeroCounter_uid37_fpAccTest_s, en, rVStage_uid93_zeroCounter_uid37_fpAccTest_merged_bit_select_b, rVStage_uid93_zeroCounter_uid37_fpAccTest_merged_bit_select_c)
    BEGIN
        CASE (vStagei_uid97_zeroCounter_uid37_fpAccTest_s) IS
            WHEN "0" => vStagei_uid97_zeroCounter_uid37_fpAccTest_q <= rVStage_uid93_zeroCounter_uid37_fpAccTest_merged_bit_select_b;
            WHEN "1" => vStagei_uid97_zeroCounter_uid37_fpAccTest_q <= rVStage_uid93_zeroCounter_uid37_fpAccTest_merged_bit_select_c;
            WHEN OTHERS => vStagei_uid97_zeroCounter_uid37_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- rVStage_uid99_zeroCounter_uid37_fpAccTest_merged_bit_select(BITSELECT,198)@6
    rVStage_uid99_zeroCounter_uid37_fpAccTest_merged_bit_select_b <= vStagei_uid97_zeroCounter_uid37_fpAccTest_q(3 downto 2);
    rVStage_uid99_zeroCounter_uid37_fpAccTest_merged_bit_select_c <= vStagei_uid97_zeroCounter_uid37_fpAccTest_q(1 downto 0);

    -- vCount_uid100_zeroCounter_uid37_fpAccTest(LOGICAL,99)@6
    vCount_uid100_zeroCounter_uid37_fpAccTest_q <= "1" WHEN rVStage_uid99_zeroCounter_uid37_fpAccTest_merged_bit_select_b = zs_uid98_zeroCounter_uid37_fpAccTest_q ELSE "0";

    -- redist10_vCount_uid100_zeroCounter_uid37_fpAccTest_q_1(DELAY,210)
    redist10_vCount_uid100_zeroCounter_uid37_fpAccTest_q_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid100_zeroCounter_uid37_fpAccTest_q, xout => redist10_vCount_uid100_zeroCounter_uid37_fpAccTest_q_1_q, ena => en(0), clk => clk, aclr => areset );

    -- vStagei_uid103_zeroCounter_uid37_fpAccTest(MUX,102)@6
    vStagei_uid103_zeroCounter_uid37_fpAccTest_s <= vCount_uid100_zeroCounter_uid37_fpAccTest_q;
    vStagei_uid103_zeroCounter_uid37_fpAccTest_combproc: PROCESS (vStagei_uid103_zeroCounter_uid37_fpAccTest_s, en, rVStage_uid99_zeroCounter_uid37_fpAccTest_merged_bit_select_b, rVStage_uid99_zeroCounter_uid37_fpAccTest_merged_bit_select_c)
    BEGIN
        CASE (vStagei_uid103_zeroCounter_uid37_fpAccTest_s) IS
            WHEN "0" => vStagei_uid103_zeroCounter_uid37_fpAccTest_q <= rVStage_uid99_zeroCounter_uid37_fpAccTest_merged_bit_select_b;
            WHEN "1" => vStagei_uid103_zeroCounter_uid37_fpAccTest_q <= rVStage_uid99_zeroCounter_uid37_fpAccTest_merged_bit_select_c;
            WHEN OTHERS => vStagei_uid103_zeroCounter_uid37_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- rVStage_uid105_zeroCounter_uid37_fpAccTest(BITSELECT,104)@6
    rVStage_uid105_zeroCounter_uid37_fpAccTest_b <= vStagei_uid103_zeroCounter_uid37_fpAccTest_q(1 downto 1);

    -- redist9_rVStage_uid105_zeroCounter_uid37_fpAccTest_b_1(DELAY,209)
    redist9_rVStage_uid105_zeroCounter_uid37_fpAccTest_b_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => rVStage_uid105_zeroCounter_uid37_fpAccTest_b, xout => redist9_rVStage_uid105_zeroCounter_uid37_fpAccTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- vCount_uid106_zeroCounter_uid37_fpAccTest(LOGICAL,105)@7
    vCount_uid106_zeroCounter_uid37_fpAccTest_q <= "1" WHEN redist9_rVStage_uid105_zeroCounter_uid37_fpAccTest_b_1_q = GND_q ELSE "0";

    -- r_uid107_zeroCounter_uid37_fpAccTest(BITJOIN,106)@7
    r_uid107_zeroCounter_uid37_fpAccTest_q <= redist15_vCount_uid68_zeroCounter_uid37_fpAccTest_q_3_q & redist14_vCount_uid76_zeroCounter_uid37_fpAccTest_q_3_q & redist13_vCount_uid82_zeroCounter_uid37_fpAccTest_q_2_q & redist12_vCount_uid88_zeroCounter_uid37_fpAccTest_q_2_q & redist11_vCount_uid94_zeroCounter_uid37_fpAccTest_q_1_q & redist10_vCount_uid100_zeroCounter_uid37_fpAccTest_q_1_q & vCount_uid106_zeroCounter_uid37_fpAccTest_q;

    -- resExpSub_uid43_fpAccTest(SUB,42)@7
    resExpSub_uid43_fpAccTest_a <= STD_LOGIC_VECTOR("0" & rShiftConstant_uid15_fpAccTest_q);
    resExpSub_uid43_fpAccTest_b <= STD_LOGIC_VECTOR("000" & r_uid107_zeroCounter_uid37_fpAccTest_q);
    resExpSub_uid43_fpAccTest_o <= STD_LOGIC_VECTOR(UNSIGNED(resExpSub_uid43_fpAccTest_a) - UNSIGNED(resExpSub_uid43_fpAccTest_b));
    resExpSub_uid43_fpAccTest_q <= resExpSub_uid43_fpAccTest_o(9 downto 0);

    -- finalExponent_uid44_fpAccTest(BITSELECT,43)@7
    finalExponent_uid44_fpAccTest_in <= resExpSub_uid43_fpAccTest_q(7 downto 0);
    finalExponent_uid44_fpAccTest_b <= finalExponent_uid44_fpAccTest_in(7 downto 0);

    -- ShiftedOutComparator_uid38_fpAccTest(CONSTANT,37)
    ShiftedOutComparator_uid38_fpAccTest_q <= "1011110";

    -- accResOutOfExpRange_uid39_fpAccTest(LOGICAL,38)@7
    accResOutOfExpRange_uid39_fpAccTest_q <= "1" WHEN ShiftedOutComparator_uid38_fpAccTest_q = r_uid107_zeroCounter_uid37_fpAccTest_q ELSE "0";

    -- finalExpUpdated_uid45_fpAccTest(MUX,44)@7
    finalExpUpdated_uid45_fpAccTest_s <= accResOutOfExpRange_uid39_fpAccTest_q;
    finalExpUpdated_uid45_fpAccTest_combproc: PROCESS (finalExpUpdated_uid45_fpAccTest_s, en, finalExponent_uid44_fpAccTest_b, zeroExponent_uid42_fpAccTest_q)
    BEGIN
        CASE (finalExpUpdated_uid45_fpAccTest_s) IS
            WHEN "0" => finalExpUpdated_uid45_fpAccTest_q <= finalExponent_uid44_fpAccTest_b;
            WHEN "1" => finalExpUpdated_uid45_fpAccTest_q <= zeroExponent_uid42_fpAccTest_q;
            WHEN OTHERS => finalExpUpdated_uid45_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- leftShiftStage3Idx1Rng1_uid188_normalizationShifter_uid40_fpAccTest(BITSELECT,187)@7
    leftShiftStage3Idx1Rng1_uid188_normalizationShifter_uid40_fpAccTest_in <= leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_q(94 downto 0);
    leftShiftStage3Idx1Rng1_uid188_normalizationShifter_uid40_fpAccTest_b <= leftShiftStage3Idx1Rng1_uid188_normalizationShifter_uid40_fpAccTest_in(94 downto 0);

    -- leftShiftStage3Idx1_uid189_normalizationShifter_uid40_fpAccTest(BITJOIN,188)@7
    leftShiftStage3Idx1_uid189_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage3Idx1Rng1_uid188_normalizationShifter_uid40_fpAccTest_b & GND_q;

    -- leftShiftStage2Idx3Rng6_uid183_normalizationShifter_uid40_fpAccTest(BITSELECT,182)@7
    leftShiftStage2Idx3Rng6_uid183_normalizationShifter_uid40_fpAccTest_in <= leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q(89 downto 0);
    leftShiftStage2Idx3Rng6_uid183_normalizationShifter_uid40_fpAccTest_b <= leftShiftStage2Idx3Rng6_uid183_normalizationShifter_uid40_fpAccTest_in(89 downto 0);

    -- leftShiftStage2Idx3_uid184_normalizationShifter_uid40_fpAccTest(BITJOIN,183)@7
    leftShiftStage2Idx3_uid184_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage2Idx3Rng6_uid183_normalizationShifter_uid40_fpAccTest_b & rightShiftStage2Idx3Pad6_uid142_alignmentShifter_uid17_fpAccTest_q;

    -- leftShiftStage2Idx2Rng4_uid180_normalizationShifter_uid40_fpAccTest(BITSELECT,179)@7
    leftShiftStage2Idx2Rng4_uid180_normalizationShifter_uid40_fpAccTest_in <= leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q(91 downto 0);
    leftShiftStage2Idx2Rng4_uid180_normalizationShifter_uid40_fpAccTest_b <= leftShiftStage2Idx2Rng4_uid180_normalizationShifter_uid40_fpAccTest_in(91 downto 0);

    -- leftShiftStage2Idx2_uid181_normalizationShifter_uid40_fpAccTest(BITJOIN,180)@7
    leftShiftStage2Idx2_uid181_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage2Idx2Rng4_uid180_normalizationShifter_uid40_fpAccTest_b & zs_uid92_zeroCounter_uid37_fpAccTest_q;

    -- leftShiftStage2Idx1Rng2_uid177_normalizationShifter_uid40_fpAccTest(BITSELECT,176)@7
    leftShiftStage2Idx1Rng2_uid177_normalizationShifter_uid40_fpAccTest_in <= leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q(93 downto 0);
    leftShiftStage2Idx1Rng2_uid177_normalizationShifter_uid40_fpAccTest_b <= leftShiftStage2Idx1Rng2_uid177_normalizationShifter_uid40_fpAccTest_in(93 downto 0);

    -- leftShiftStage2Idx1_uid178_normalizationShifter_uid40_fpAccTest(BITJOIN,177)@7
    leftShiftStage2Idx1_uid178_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage2Idx1Rng2_uid177_normalizationShifter_uid40_fpAccTest_b & zs_uid98_zeroCounter_uid37_fpAccTest_q;

    -- leftShiftStage1Idx3Rng24_uid172_normalizationShifter_uid40_fpAccTest(BITSELECT,171)@7
    leftShiftStage1Idx3Rng24_uid172_normalizationShifter_uid40_fpAccTest_in <= leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q(71 downto 0);
    leftShiftStage1Idx3Rng24_uid172_normalizationShifter_uid40_fpAccTest_b <= leftShiftStage1Idx3Rng24_uid172_normalizationShifter_uid40_fpAccTest_in(71 downto 0);

    -- leftShiftStage1Idx3_uid173_normalizationShifter_uid40_fpAccTest(BITJOIN,172)@7
    leftShiftStage1Idx3_uid173_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage1Idx3Rng24_uid172_normalizationShifter_uid40_fpAccTest_b & rightShiftStage1Idx3Pad24_uid131_alignmentShifter_uid17_fpAccTest_q;

    -- leftShiftStage1Idx2Rng16_uid169_normalizationShifter_uid40_fpAccTest(BITSELECT,168)@7
    leftShiftStage1Idx2Rng16_uid169_normalizationShifter_uid40_fpAccTest_in <= leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q(79 downto 0);
    leftShiftStage1Idx2Rng16_uid169_normalizationShifter_uid40_fpAccTest_b <= leftShiftStage1Idx2Rng16_uid169_normalizationShifter_uid40_fpAccTest_in(79 downto 0);

    -- leftShiftStage1Idx2_uid170_normalizationShifter_uid40_fpAccTest(BITJOIN,169)@7
    leftShiftStage1Idx2_uid170_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage1Idx2Rng16_uid169_normalizationShifter_uid40_fpAccTest_b & zs_uid80_zeroCounter_uid37_fpAccTest_q;

    -- leftShiftStage1Idx1Rng8_uid166_normalizationShifter_uid40_fpAccTest(BITSELECT,165)@7
    leftShiftStage1Idx1Rng8_uid166_normalizationShifter_uid40_fpAccTest_in <= leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q(87 downto 0);
    leftShiftStage1Idx1Rng8_uid166_normalizationShifter_uid40_fpAccTest_b <= leftShiftStage1Idx1Rng8_uid166_normalizationShifter_uid40_fpAccTest_in(87 downto 0);

    -- leftShiftStage1Idx1_uid167_normalizationShifter_uid40_fpAccTest(BITJOIN,166)@7
    leftShiftStage1Idx1_uid167_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage1Idx1Rng8_uid166_normalizationShifter_uid40_fpAccTest_b & zeroExponent_uid42_fpAccTest_q;

    -- leftShiftStage0Idx2Rng64_uid160_normalizationShifter_uid40_fpAccTest(BITSELECT,159)@7
    leftShiftStage0Idx2Rng64_uid160_normalizationShifter_uid40_fpAccTest_in <= redist20_accValuePositive_uid35_fpAccTest_q_4_outputreg_q(31 downto 0);
    leftShiftStage0Idx2Rng64_uid160_normalizationShifter_uid40_fpAccTest_b <= leftShiftStage0Idx2Rng64_uid160_normalizationShifter_uid40_fpAccTest_in(31 downto 0);

    -- leftShiftStage0Idx2_uid161_normalizationShifter_uid40_fpAccTest(BITJOIN,160)@7
    leftShiftStage0Idx2_uid161_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage0Idx2Rng64_uid160_normalizationShifter_uid40_fpAccTest_b & zs_uid66_zeroCounter_uid37_fpAccTest_q;

    -- leftShiftStage0Idx1Rng32_uid157_normalizationShifter_uid40_fpAccTest(BITSELECT,156)@7
    leftShiftStage0Idx1Rng32_uid157_normalizationShifter_uid40_fpAccTest_in <= redist20_accValuePositive_uid35_fpAccTest_q_4_outputreg_q(63 downto 0);
    leftShiftStage0Idx1Rng32_uid157_normalizationShifter_uid40_fpAccTest_b <= leftShiftStage0Idx1Rng32_uid157_normalizationShifter_uid40_fpAccTest_in(63 downto 0);

    -- leftShiftStage0Idx1_uid158_normalizationShifter_uid40_fpAccTest(BITJOIN,157)@7
    leftShiftStage0Idx1_uid158_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage0Idx1Rng32_uid157_normalizationShifter_uid40_fpAccTest_b & zs_uid74_zeroCounter_uid37_fpAccTest_q;

    -- redist20_accValuePositive_uid35_fpAccTest_q_4(DELAY,220)
    redist20_accValuePositive_uid35_fpAccTest_q_4 : dspba_delay
    GENERIC MAP ( width => 96, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => accValuePositive_uid35_fpAccTest_q, xout => redist20_accValuePositive_uid35_fpAccTest_q_4_q, ena => en(0), clk => clk, aclr => areset );

    -- redist20_accValuePositive_uid35_fpAccTest_q_4_outputreg(DELAY,226)
    redist20_accValuePositive_uid35_fpAccTest_q_4_outputreg : dspba_delay
    GENERIC MAP ( width => 96, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => redist20_accValuePositive_uid35_fpAccTest_q_4_q, xout => redist20_accValuePositive_uid35_fpAccTest_q_4_outputreg_q, ena => en(0), clk => clk, aclr => areset );

    -- leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest(MUX,163)@7
    leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_s <= leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_b;
    leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_combproc: PROCESS (leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_s, en, redist20_accValuePositive_uid35_fpAccTest_q_4_outputreg_q, leftShiftStage0Idx1_uid158_normalizationShifter_uid40_fpAccTest_q, leftShiftStage0Idx2_uid161_normalizationShifter_uid40_fpAccTest_q, rightShiftStage0Idx3Pad96_uid120_alignmentShifter_uid17_fpAccTest_q)
    BEGIN
        CASE (leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_s) IS
            WHEN "00" => leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q <= redist20_accValuePositive_uid35_fpAccTest_q_4_outputreg_q;
            WHEN "01" => leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage0Idx1_uid158_normalizationShifter_uid40_fpAccTest_q;
            WHEN "10" => leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage0Idx2_uid161_normalizationShifter_uid40_fpAccTest_q;
            WHEN "11" => leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q <= rightShiftStage0Idx3Pad96_uid120_alignmentShifter_uid17_fpAccTest_q;
            WHEN OTHERS => leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest(MUX,174)@7
    leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_s <= leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_c;
    leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_combproc: PROCESS (leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_s, en, leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q, leftShiftStage1Idx1_uid167_normalizationShifter_uid40_fpAccTest_q, leftShiftStage1Idx2_uid170_normalizationShifter_uid40_fpAccTest_q, leftShiftStage1Idx3_uid173_normalizationShifter_uid40_fpAccTest_q)
    BEGIN
        CASE (leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_s) IS
            WHEN "00" => leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage0_uid164_normalizationShifter_uid40_fpAccTest_q;
            WHEN "01" => leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage1Idx1_uid167_normalizationShifter_uid40_fpAccTest_q;
            WHEN "10" => leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage1Idx2_uid170_normalizationShifter_uid40_fpAccTest_q;
            WHEN "11" => leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage1Idx3_uid173_normalizationShifter_uid40_fpAccTest_q;
            WHEN OTHERS => leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest(MUX,185)@7
    leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_s <= leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_d;
    leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_combproc: PROCESS (leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_s, en, leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q, leftShiftStage2Idx1_uid178_normalizationShifter_uid40_fpAccTest_q, leftShiftStage2Idx2_uid181_normalizationShifter_uid40_fpAccTest_q, leftShiftStage2Idx3_uid184_normalizationShifter_uid40_fpAccTest_q)
    BEGIN
        CASE (leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_s) IS
            WHEN "00" => leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage1_uid175_normalizationShifter_uid40_fpAccTest_q;
            WHEN "01" => leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage2Idx1_uid178_normalizationShifter_uid40_fpAccTest_q;
            WHEN "10" => leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage2Idx2_uid181_normalizationShifter_uid40_fpAccTest_q;
            WHEN "11" => leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage2Idx3_uid184_normalizationShifter_uid40_fpAccTest_q;
            WHEN OTHERS => leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select(BITSELECT,199)@7
    leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_b <= r_uid107_zeroCounter_uid37_fpAccTest_q(6 downto 5);
    leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_c <= r_uid107_zeroCounter_uid37_fpAccTest_q(4 downto 3);
    leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_d <= r_uid107_zeroCounter_uid37_fpAccTest_q(2 downto 1);
    leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_e <= r_uid107_zeroCounter_uid37_fpAccTest_q(0 downto 0);

    -- leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest(MUX,190)@7
    leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest_s <= leftShiftStageSel6Dto5_uid163_normalizationShifter_uid40_fpAccTest_merged_bit_select_e;
    leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest_combproc: PROCESS (leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest_s, en, leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_q, leftShiftStage3Idx1_uid189_normalizationShifter_uid40_fpAccTest_q)
    BEGIN
        CASE (leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest_s) IS
            WHEN "0" => leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage2_uid186_normalizationShifter_uid40_fpAccTest_q;
            WHEN "1" => leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest_q <= leftShiftStage3Idx1_uid189_normalizationShifter_uid40_fpAccTest_q;
            WHEN OTHERS => leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- fracR_uid46_fpAccTest(BITSELECT,45)@7
    fracR_uid46_fpAccTest_in <= leftShiftStage3_uid191_normalizationShifter_uid40_fpAccTest_q(92 downto 0);
    fracR_uid46_fpAccTest_b <= fracR_uid46_fpAccTest_in(92 downto 70);

    -- R_uid47_fpAccTest(BITJOIN,46)@7
    R_uid47_fpAccTest_q <= redist21_accumulatorSign_uid29_fpAccTest_b_4_q & finalExpUpdated_uid45_fpAccTest_q & fracR_uid46_fpAccTest_b;

    -- xOut(GPOUT,4)@7
    r <= R_uid47_fpAccTest_q;
    xo <= redist19_oRXOverflowFlagFeedback_uid52_fpAccTest_q_5_q;
    xu <= redist17_oRXUnderflowFlagFeedback_uid58_fpAccTest_q_5_q;
    ao <= redist16_oRAccOverflowFlagFeedback_uid62_fpAccTest_q_4_q;

END normal;
