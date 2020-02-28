# -------------------------------------------------------------------------- #
# Project Settings                                                           #
# -------------------------------------------------------------------------- #
#set_global_assignment -name PROJECT_OUTPUT_DIRECTORY quartus_output

set_global_assignment -name FAMILY "Stratix V"
set_global_assignment -name DEVICE 5SGXMA7H2F35C2
set_global_assignment -name TOP_LEVEL_ENTITY psl_fpga
set_global_assignment -name ORIGINAL_QUARTUS_VERSION 11.0
set_global_assignment -name PROJECT_CREATION_TIME_DATE "15:53:12  OCTOBER 25, 2011"
set_global_assignment -name LAST_QUARTUS_VERSION "18.1.0 Standard Edition"
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_FIT -section_id Top
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT -section_id Top
set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS ON
set_global_assignment -name REMOVE_DUPLICATE_REGISTERS ON
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "psl_cd:cd"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "psl_cd:cd"
set_global_assignment -name PARTITION_COLOR 39423 -section_id "psl_cd:cd"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "psl_ct:ct"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "psl_ct:ct"
set_global_assignment -name PARTITION_COLOR 52377 -section_id "psl_ct:ct"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "psl_rx:rx"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "psl_rx:rx"
set_global_assignment -name PARTITION_COLOR 16776960 -section_id "psl_rx:rx"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "psl_li:li"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "psl_li:li"
set_global_assignment -name PARTITION_COLOR 16711935 -section_id "psl_li:li"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "psl_jm:jm"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "psl_jm:jm"
set_global_assignment -name PARTITION_COLOR 65535 -section_id "psl_jm:jm"
set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "2.5 V"
set_global_assignment -name OPTIMIZE_HOLD_TIMING "ALL PATHS"
set_global_assignment -name OPTIMIZE_MULTI_CORNER_TIMING ON
set_global_assignment -name FIT_ONLY_ONE_ATTEMPT ON
set_global_assignment -name ENABLE_BENEFICIAL_SKEW_OPTIMIZATION ON

set_global_assignment -name SAVE_DISK_SPACE OFF
set_global_assignment -name FLOW_DISABLE_ASSEMBLER OFF
set_global_assignment -name FLOW_ENABLE_RTL_VIEWER ON
set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL
set_global_assignment -name ALLOW_POWER_UP_DONT_CARE OFF
set_global_assignment -name OPTIMIZE_POWER_DURING_SYNTHESIS OFF
set_global_assignment -name HDL_MESSAGE_LEVEL LEVEL3

#set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to pci_pi_npor
set_global_assignment -name PLACEMENT_EFFORT_MULTIPLIER 4
set_global_assignment -name ROUTER_TIMING_OPTIMIZATION_LEVEL MAXIMUM
set_global_assignment -name ENABLE_HOLD_BACK_OFF OFF
set_global_assignment -name INI_VARS "vpr_net_rr_default_lab_source_level=0;vpr_sp_clk_abs_gband_int=100;vpr_short_path_non_io_guardband_localized_ff_to_ff_factor=0.5"

set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC ON

set_global_assignment -name TIMEQUEST_DO_CCPP_REMOVAL ON
set_global_assignment -name TIMEQUEST_DO_REPORT_TIMING OFF
set_global_assignment -name TIMEQUEST_REPORT_NUM_WORST_CASE_TIMING_PATHS 100
set_global_assignment -name USE_TIMEQUEST_TIMING_ANALYZER ON
set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON
set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC_FOR_AREA ON
set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_RETIMING ON
set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON
set_global_assignment -name PHYSICAL_SYNTHESIS_EFFORT NORMAL
set_global_assignment -name SEED 14

set_global_assignment -name PARTITION_NETLIST_TYPE POST_FIT -section_id "psl_accel:a0"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "psl_accel:a0"
set_global_assignment -name PARTITION_COLOR 39423 -section_id "psl_accel:a0"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_FIT -section_id "psl:p"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "psl:p"
set_global_assignment -name PARTITION_COLOR 52377 -section_id "psl:p"
set_global_assignment -name LL_ENABLED ON -section_id "psl:p"
set_global_assignment -name LL_AUTO_SIZE OFF -section_id "psl:p"
set_global_assignment -name LL_STATE LOCKED -section_id "psl:p"
set_global_assignment -name LL_RESERVED OFF -section_id "psl:p"
set_global_assignment -name LL_SECURITY_ROUTING_INTERFACE OFF -section_id "psl:p"
set_global_assignment -name LL_IGNORE_IO_BANK_SECURITY_CONSTRAINT OFF -section_id "psl:p"
set_global_assignment -name LL_PR_REGION OFF -section_id "psl:p"
set_global_assignment -name LL_WIDTH 105 -section_id "psl:p"
set_global_assignment -name LL_HEIGHT 68 -section_id "psl:p"
set_global_assignment -name LL_ORIGIN X0_Y1 -section_id "psl:p"
set_instance_assignment -name LL_MEMBER_OF "psl:p" -to "psl:p" -section_id "psl:p"

set_global_assignment -name LL_ROUTING_REGION_EXPANSION_SIZE 2147483647 -section_id "psl:p"

set_global_assignment -name FITTER_EFFORT "STANDARD FIT"
set_global_assignment -name FITTER_AGGRESSIVE_ROUTABILITY_OPTIMIZATION AUTOMATICALLY

set_global_assignment -name PARTITION_NETLIST_TYPE POST_FIT -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name PARTITION_COLOR 16776960 -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name PARTITION_IMPORT_EXISTING_LOGICLOCK_REGIONS UPDATE_CONFLICTING -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_ENABLED ON -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_AUTO_SIZE OFF -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_STATE LOCKED -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_RESERVED OFF -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_SECURITY_ROUTING_INTERFACE OFF -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_IGNORE_IO_BANK_SECURITY_CONSTRAINT OFF -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_PR_REGION OFF -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_ROUTING_REGION_EXPANSION_SIZE 2147483647 -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_WIDTH 7 -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_HEIGHT 48 -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_ORIGIN X1_Y1 -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_instance_assignment -name LL_MEMBER_OF "alt_xcvr_reconfig:alt_xcvr_reconfig_0" -to "psl_pcihip0:pcihip0|pcie_wrap0:p|alt_xcvr_reconfig:alt_xcvr_reconfig_0" -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"

set_global_assignment -name ENABLE_SIGNALTAP OFF
set_global_assignment -name USE_SIGNALTAP_FILE soft_reconfig.stp
set_global_assignment -name OPTIMIZATION_TECHNIQUE SPEED

# -------------------------------------------------------------------------- #
# Global Settings                                                            #
# -------------------------------------------------------------------------- #
set_global_assignment -name NOMINAL_CORE_SUPPLY_VOLTAGE 0.9V
set_global_assignment -name VCCT_GXBL_USER_VOLTAGE 1.0V
set_global_assignment -name VCCT_GXBR_USER_VOLTAGE 1.0V
set_global_assignment -name VCCR_GXBL_USER_VOLTAGE 1.0V
set_global_assignment -name VCCR_GXBR_USER_VOLTAGE 1.0V
set_global_assignment -name VCCA_GXBL_USER_VOLTAGE 3.0V
set_global_assignment -name VCCA_GXBR_USER_VOLTAGE 3.0V
set_global_assignment -name POWER_HSSI_VCCHIP_LEFT "Opportunistically power off"
set_global_assignment -name POWER_HSSI_VCCHIP_RIGHT "Opportunistically power off"

set_global_assignment -name SIGNALTAP_FILE soft_reconfig.stp

set_global_assignment -name LL_CORE_ONLY OFF -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_global_assignment -name LL_CORE_ONLY OFF -section_id "psl:p"
set_global_assignment -name OPTIMIZATION_MODE "HIGH PERFORMANCE EFFORT"

set_global_assignment -name LL_ENABLED ON -section_id "psl_accel:a0"
set_global_assignment -name LL_AUTO_SIZE OFF -section_id "psl_accel:a0"
set_global_assignment -name LL_STATE LOCKED -section_id "psl_accel:a0"
set_global_assignment -name LL_RESERVED OFF -section_id "psl_accel:a0"
set_global_assignment -name LL_CORE_ONLY OFF -section_id "psl_accel:a0"
set_global_assignment -name LL_REGION_SECURITY_LEVEL UNSECURED -section_id "psl_accel:a0"
set_global_assignment -name LL_SECURITY_ROUTING_INTERFACE OFF -section_id "psl_accel:a0"
set_global_assignment -name LL_IGNORE_IO_BANK_SECURITY_CONSTRAINT OFF -section_id "psl_accel:a0"
set_global_assignment -name LL_PR_REGION OFF -section_id "psl_accel:a0"
set_global_assignment -name LL_ROUTING_REGION_EXPANSION_SIZE 2147483647 -section_id "psl_accel:a0"
set_global_assignment -name LL_RECT X0_Y69 -width 106 -height 60 -section_id "psl_accel:a0"
set_global_assignment -name LL_RECT X106_Y0 -width 105 -height 129 -section_id "psl_accel:a0"
set_instance_assignment -name LL_MEMBER_OF "psl_accel:a0" -to "psl_accel:a0" -section_id "psl_accel:a0"
set_global_assignment -name LL_ENABLED ON -section_id "psl_flash:f"
set_global_assignment -name LL_RESERVED OFF -section_id "psl_flash:f"
set_global_assignment -name LL_CORE_ONLY OFF -section_id "psl_flash:f"
set_global_assignment -name LL_SECURITY_ROUTING_INTERFACE OFF -section_id "psl_flash:f"
set_global_assignment -name LL_IGNORE_IO_BANK_SECURITY_CONSTRAINT OFF -section_id "psl_flash:f"
set_global_assignment -name LL_PR_REGION OFF -section_id "psl_flash:f"
set_global_assignment -name LL_ROUTING_REGION_EXPANSION_SIZE 2147483647 -section_id "psl_flash:f"
set_instance_assignment -name LL_MEMBER_OF "psl_flash:f" -to "psl_flash:f" -section_id "psl_flash:f"
set_global_assignment -name LL_HEIGHT 15 -section_id "psl_flash:f"
set_global_assignment -name LL_WIDTH 14 -section_id "psl_flash:f"
set_global_assignment -name LL_ORIGIN X7_Y114 -section_id "psl_flash:f"
set_global_assignment -name LL_STATE LOCKED -section_id "psl_flash:f"
set_global_assignment -name LL_AUTO_SIZE OFF -section_id "psl_flash:f"
set_global_assignment -name SMART_RECOMPILE ON

set_global_assignment -name ROUTER_LCELL_INSERTION_AND_LOGIC_DUPLICATION ON
set_global_assignment -name QII_AUTO_PACKED_REGISTERS NORMAL
set_global_assignment -name ADV_NETLIST_OPT_SYNTH_WYSIWYG_REMAP ON
set_global_assignment -name MUX_RESTRUCTURE OFF
set_global_assignment -name STATE_MACHINE_PROCESSING "ONE-HOT"
set_global_assignment -name ROUTER_CLOCKING_TOPOLOGY_ANALYSIS ON
set_global_assignment -name PHYSICAL_SYNTHESIS_ASYNCHRONOUS_SIGNAL_PIPELINING ON
set_global_assignment -name VERILOG_INPUT_VERSION SYSTEMVERILOG_2005
set_global_assignment -name VERILOG_SHOW_LMF_MAPPING_MESSAGES OFF






set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "wed_control:wed_control_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "wed_control:wed_control_instant"
set_global_assignment -name PARTITION_COLOR 16711935 -section_id "wed_control:wed_control_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "response_statistics_control:response_statistics_control_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "response_statistics_control:response_statistics_control_instant"
set_global_assignment -name PARTITION_COLOR 65535 -section_id "response_statistics_control:response_statistics_control_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "done_control:done_control_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "done_control:done_control_instant"
set_global_assignment -name PARTITION_COLOR 16777164 -section_id "done_control:done_control_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_data_read_control:cu_edge_data_read_control_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_data_read_control:cu_edge_data_read_control_instant"
set_global_assignment -name PARTITION_COLOR 10198015 -section_id "cu_edge_data_read_control:cu_edge_data_read_control_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "demux_bus:read_data_0_cu_demux_bus_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "demux_bus:read_data_0_cu_demux_bus_instant"
set_global_assignment -name PARTITION_COLOR 32896 -section_id "demux_bus:read_data_0_cu_demux_bus_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "demux_bus:read_data_1_cu_demux_bus_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "demux_bus:read_data_1_cu_demux_bus_instant"
set_global_assignment -name PARTITION_COLOR 14622752 -section_id "demux_bus:read_data_1_cu_demux_bus_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_11__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_11__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 2105567 -section_id "cu_vertex_pagerank:generate_pagerank_cu_11__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_3__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_3__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 2154272 -section_id "cu_vertex_pagerank:generate_pagerank_cu_3__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_5__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_5__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 16037301 -section_id "cu_vertex_pagerank:generate_pagerank_cu_5__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_6__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_6__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 11908596 -section_id "cu_vertex_pagerank:generate_pagerank_cu_6__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_1__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_1__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 11924661 -section_id "cu_vertex_pagerank:generate_pagerank_cu_1__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_2__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_2__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 16774902 -section_id "cu_vertex_pagerank:generate_pagerank_cu_2__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_4__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_4__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 16709301 -section_id "cu_vertex_pagerank:generate_pagerank_cu_4__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_0__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_0__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 16168438 -section_id "cu_vertex_pagerank:generate_pagerank_cu_0__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_7__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_7__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 2088670 -section_id "cu_vertex_pagerank:generate_pagerank_cu_7__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_9__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_9__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 14671391 -section_id "cu_vertex_pagerank:generate_pagerank_cu_9__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_10__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_10__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 14622686 -section_id "cu_vertex_pagerank:generate_pagerank_cu_10__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_8__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_8__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 13356493 -section_id "cu_vertex_pagerank:generate_pagerank_cu_8__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "demux_bus:write_response_demux_bus_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "demux_bus:write_response_demux_bus_instant"
set_global_assignment -name PARTITION_COLOR 13487498 -section_id "demux_bus:write_response_demux_bus_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "demux_bus:read_response_demux_bus_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "demux_bus:read_response_demux_bus_instant"
set_global_assignment -name PARTITION_COLOR 13470413 -section_id "demux_bus:read_response_demux_bus_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "array_struct_type_demux_bus:read_data_1_array_struct_type_demux_bus_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "array_struct_type_demux_bus:read_data_1_array_struct_type_demux_bus_instant"
set_global_assignment -name PARTITION_COLOR 4917256 -section_id "array_struct_type_demux_bus:read_data_1_array_struct_type_demux_bus_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "array_struct_type_demux_bus:read_data_0_array_struct_type_demux_bus_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "array_struct_type_demux_bus:read_data_0_array_struct_type_demux_bus_instant"
set_global_assignment -name PARTITION_COLOR 723017 -section_id "array_struct_type_demux_bus:read_data_0_array_struct_type_demux_bus_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_12__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_12__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 608520 -section_id "cu_vertex_pagerank:generate_pagerank_cu_12__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_13__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_13__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 15246243 -section_id "cu_vertex_pagerank:generate_pagerank_cu_13__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_14__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_14__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 15442784 -section_id "cu_vertex_pagerank:generate_pagerank_cu_14__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank:generate_pagerank_cu_15__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank:generate_pagerank_cu_15__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_COLOR 15163555 -section_id "cu_vertex_pagerank:generate_pagerank_cu_15__cu_vertex_pagerank_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "mmio:mmio_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "mmio:mmio_instant"
set_global_assignment -name PARTITION_COLOR 7614769 -section_id "mmio:mmio_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_job_control:cu_vertex_job_control_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_job_control:cu_vertex_job_control_instant"
set_global_assignment -name PARTITION_COLOR 3486068 -section_id "cu_vertex_job_control:cu_vertex_job_control_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant"
set_global_assignment -name PARTITION_COLOR 3241009 -section_id "cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant"
set_global_assignment -name PARTITION_COLOR 16218746 -section_id "cu_edge_job_control:cu_edge_job_control_instant"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_2"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_2"
set_global_assignment -name PARTITION_COLOR 16742965 -section_id "cu_edge_job_control:cu_edge_job_control_instant_2"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_3"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_3"
set_global_assignment -name PARTITION_COLOR 8271226 -section_id "cu_edge_job_control:cu_edge_job_control_instant_3"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_4"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_4"
set_global_assignment -name PARTITION_COLOR 10443611 -section_id "cu_edge_job_control:cu_edge_job_control_instant_4"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_5"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_5"
set_global_assignment -name PARTITION_COLOR 6249374 -section_id "cu_edge_job_control:cu_edge_job_control_instant_5"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_6"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_6"
set_global_assignment -name PARTITION_COLOR 6004315 -section_id "cu_edge_job_control:cu_edge_job_control_instant_6"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_7"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_7"
set_global_assignment -name PARTITION_COLOR 13586512 -section_id "cu_edge_job_control:cu_edge_job_control_instant_7"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_8"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_8"
set_global_assignment -name PARTITION_COLOR 14045195 -section_id "cu_edge_job_control:cu_edge_job_control_instant_8"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_9"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_9"
set_global_assignment -name PARTITION_COLOR 5507920 -section_id "cu_edge_job_control:cu_edge_job_control_instant_9"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_10"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_10"
set_global_assignment -name PARTITION_COLOR 13599876 -section_id "cu_edge_job_control:cu_edge_job_control_instant_10"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_11"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_11"
set_global_assignment -name PARTITION_COLOR 8815817 -section_id "cu_edge_job_control:cu_edge_job_control_instant_11"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_12"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_12"
set_global_assignment -name PARTITION_COLOR 8767876 -section_id "cu_edge_job_control:cu_edge_job_control_instant_12"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_13"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_13"
set_global_assignment -name PARTITION_COLOR 15017767 -section_id "cu_edge_job_control:cu_edge_job_control_instant_13"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_14"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_14"
set_global_assignment -name PARTITION_COLOR 15149024 -section_id "cu_edge_job_control:cu_edge_job_control_instant_14"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_15"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_15"
set_global_assignment -name PARTITION_COLOR 6807591 -section_id "cu_edge_job_control:cu_edge_job_control_instant_15"
set_global_assignment -name PARTITION_NETLIST_TYPE POST_SYNTH -section_id "cu_edge_job_control:cu_edge_job_control_instant_16"
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "cu_edge_job_control:cu_edge_job_control_instant_16"
set_global_assignment -name PARTITION_COLOR 16232110 -section_id "cu_edge_job_control:cu_edge_job_control_instant_16"
set_global_assignment -name ALLOW_ANY_ROM_SIZE_FOR_RECOGNITION ON
set_global_assignment -name ALLOW_ANY_RAM_SIZE_FOR_RECOGNITION ON
set_global_assignment -name ALLOW_ANY_SHIFT_REGISTER_SIZE_FOR_RECOGNITION ON
set_global_assignment -name ALLOW_SHIFT_REGISTER_MERGING_ACROSS_HIERARCHIES ALWAYS
set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top
set_instance_assignment -name PARTITION_HIERARCHY altxc_79511 -to "psl_pcihip0:pcihip0|pcie_wrap0:p|alt_xcvr_reconfig:alt_xcvr_reconfig_0" -section_id "alt_xcvr_reconfig:alt_xcvr_reconfig_0"
set_instance_assignment -name PARTITION_HIERARCHY p_d2061 -to "psl:p" -section_id "psl:p"
set_instance_assignment -name PARTITION_HIERARCHY a0_8a551 -to "psl_accel:a0" -section_id "psl_accel:a0"
set_instance_assignment -name PARTITION_HIERARCHY wedco_d36e1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|wed_control:wed_control_instant" -section_id "wed_control:wed_control_instant"
set_instance_assignment -name PARTITION_HIERARCHY respo_58791 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|afu_control:afu_control_instant|response_statistics_control:response_statistics_control_instant" -section_id "response_statistics_control:response_statistics_control_instant"
set_instance_assignment -name PARTITION_HIERARCHY donec_df931 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|done_control:done_control_instant" -section_id "done_control:done_control_instant"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_65651 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant|cu_edge_data_read_control:cu_edge_data_read_control_instant" -section_id "cu_edge_data_read_control:cu_edge_data_read_control_instant"
set_instance_assignment -name PARTITION_HIERARCHY readd_97ab1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant|demux_bus:read_data_0_cu_demux_bus_instant" -section_id "demux_bus:read_data_0_cu_demux_bus_instant"
set_instance_assignment -name PARTITION_HIERARCHY readd_a6071 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant|demux_bus:read_data_1_cu_demux_bus_instant" -section_id "demux_bus:read_data_1_cu_demux_bus_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_96fd1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[11].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_11__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_2a061 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[3].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_3__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_78aa1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[5].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_5__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_01f11 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[6].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_6__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_7cf01 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[1].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_1__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_702e1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[2].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_2__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_fa6b1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[4].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_4__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_a1ff1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[0].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_0__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_b4cf1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[7].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_7__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_2a081 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[9].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_9__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_8b961 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[10].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_10__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_34e81 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[8].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_8__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY write_38be1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant|demux_bus:write_response_demux_bus_instant" -section_id "demux_bus:write_response_demux_bus_instant"
set_instance_assignment -name PARTITION_HIERARCHY readr_50101 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant|demux_bus:read_response_demux_bus_instant" -section_id "demux_bus:read_response_demux_bus_instant"
set_instance_assignment -name PARTITION_HIERARCHY readd_b04f1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant|array_struct_type_demux_bus:read_data_1_array_struct_type_demux_bus_instant" -section_id "array_struct_type_demux_bus:read_data_1_array_struct_type_demux_bus_instant"
set_instance_assignment -name PARTITION_HIERARCHY readd_e13c1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant|array_struct_type_demux_bus:read_data_0_array_struct_type_demux_bus_instant" -section_id "array_struct_type_demux_bus:read_data_0_array_struct_type_demux_bus_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_0fff1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[12].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_12__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_29cf1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[13].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_13__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_4b861 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[14].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_14__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY gener_d6061 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[15].cu_vertex_pagerank_instant" -section_id "cu_vertex_pagerank:generate_pagerank_cu_15__cu_vertex_pagerank_instant"
set_instance_assignment -name PARTITION_HIERARCHY mmioi_d2a51 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|mmio:mmio_instant" -section_id "mmio:mmio_instant"
set_instance_assignment -name PARTITION_HIERARCHY cuver_ab501 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_vertex_job_control:cu_vertex_job_control_instant" -section_id "cu_vertex_job_control:cu_vertex_job_control_instant"
set_instance_assignment -name PARTITION_HIERARCHY cuver_21071 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant" -section_id "cu_vertex_pagerank_arbiter_control:cu_vertex_pagerank_arbiter_control_instant"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_8a1a1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[1].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_7bc11 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[0].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_2"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_bc0c1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[2].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_3"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_914e1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[3].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_4"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_5ab61 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[4].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_5"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_6e001 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[5].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_6"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_a1ba1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[6].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_7"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_dccc1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[7].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_8"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_2b171 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[8].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_9"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_8b961 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[9].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_10"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_50fe1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[10].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_11"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_900e1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[11].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_12"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_2f1b1 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[12].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_13"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_2cb21 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[13].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_14"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_61971 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[14].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_15"
set_instance_assignment -name PARTITION_HIERARCHY cuedg_50781 -to "psl_accel:a0|afu:afu0|cached_afu:svAFU|cu_control:cu_control_instant|cu_graph_algorithm_control:cu_graph_algorithm_control_instant|cu_vertex_pagerank:generate_pagerank_cu[15].cu_vertex_pagerank_instant|cu_edge_job_control:cu_edge_job_control_instant" -section_id "cu_edge_job_control:cu_edge_job_control_instant_16"