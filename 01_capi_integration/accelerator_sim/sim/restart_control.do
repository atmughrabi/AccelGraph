onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group {Job Interface} /top/a0/ha_pclock
add wave -noupdate -group {Job Interface} /top/a0/ha_jval
add wave -noupdate -group {Job Interface} -radix hexadecimal /top/a0/ha_jcom
add wave -noupdate -group {Job Interface} /top/a0/ha_jcompar
add wave -noupdate -group {Job Interface} -radix hexadecimal /top/a0/ha_jea
add wave -noupdate -group {Job Interface} /top/a0/ha_jeapar
add wave -noupdate -group {Job Interface} -color yellow /top/a0/ah_jrunning
add wave -noupdate -group {Job Interface} -color yellow /top/a0/ah_jdone
add wave -noupdate -group {Job Interface} -color yellow /top/a0/ah_jcack
add wave -noupdate -group {Job Interface} -color yellow -radix hexadecimal /top/a0/ah_jerror
add wave -noupdate -group {Job Interface} -color yellow /top/a0/ah_jyield
add wave -noupdate -group {Job Interface} /top/a0/ah_tbreq
add wave -noupdate -group {Job Interface} /top/a0/ah_paren
add wave -noupdate -group {MMIO Interface} /top/a0/ha_mmval
add wave -noupdate -group {MMIO Interface} /top/a0/ha_mmcfg
add wave -noupdate -group {MMIO Interface} /top/a0/ha_mmrnw
add wave -noupdate -group {MMIO Interface} /top/a0/ha_mmdw
add wave -noupdate -group {MMIO Interface} -radix hexadecimal /top/a0/ha_mmad
add wave -noupdate -group {MMIO Interface} /top/a0/ha_mmadpar
add wave -noupdate -group {MMIO Interface} -radix hexadecimal /top/a0/ha_mmdata
add wave -noupdate -group {MMIO Interface} /top/a0/ha_mmdatapar
add wave -noupdate -group {MMIO Interface} -color yellow /top/a0/ah_mmack
add wave -noupdate -group {MMIO Interface} -color yellow -radix hexadecimal /top/a0/ah_mmdata
add wave -noupdate -group {MMIO Interface} -color yellow /top/a0/ah_mmdatapar
add wave -noupdate -group {Command Interface} -radix decimal /top/a0/ha_croom
add wave -noupdate -group {Command Interface} -color yellow /top/a0/ah_cvalid
add wave -noupdate -group {Command Interface} -color yellow -radix hexadecimal /top/a0/ah_ctag
add wave -noupdate -group {Command Interface} -color yellow /top/a0/ah_ctagpar
add wave -noupdate -group {Command Interface} -color yellow -radix hexadecimal /top/a0/ah_com
add wave -noupdate -group {Command Interface} -color yellow /top/a0/ah_compar
add wave -noupdate -group {Command Interface} -color yellow /top/a0/ah_cabt
add wave -noupdate -group {Command Interface} -color yellow -radix hexadecimal /top/a0/ah_cea
add wave -noupdate -group {Command Interface} -color yellow /top/a0/ah_ceapar
add wave -noupdate -group {Command Interface} -color yellow -radix hexadecimal /top/a0/ah_cch
add wave -noupdate -group {Command Interface} -color yellow -radix decimal /top/a0/ah_csize
add wave -noupdate -group {Buffer Interface} /top/a0/ha_brvalid
add wave -noupdate -group {Buffer Interface} -radix hexadecimal /top/a0/ha_brtag
add wave -noupdate -group {Buffer Interface} /top/a0/ha_brtagpar
add wave -noupdate -group {Buffer Interface} -radix hexadecimal /top/a0/ha_brad
add wave -noupdate -group {Buffer Interface} /top/a0/ha_bwvalid
add wave -noupdate -group {Buffer Interface} -radix hexadecimal /top/a0/ha_bwtag
add wave -noupdate -group {Buffer Interface} /top/a0/ha_bwtagpar
add wave -noupdate -group {Buffer Interface} -radix hexadecimal /top/a0/ha_bwad
add wave -noupdate -group {Buffer Interface} -radix hexadecimal /top/a0/ha_bwdata
add wave -noupdate -group {Buffer Interface} /top/a0/ha_bwpar
add wave -noupdate -group {Buffer Interface} -color yellow -radix decimal /top/a0/ah_brlat
add wave -noupdate -group {Buffer Interface} -color yellow -radix hexadecimal /top/a0/ah_brdata
add wave -noupdate -group {Buffer Interface} -color yellow /top/a0/ah_brpar
add wave -noupdate -group {Response Interface} /top/a0/ha_rvalid
add wave -noupdate -group {Response Interface} -radix hexadecimal /top/a0/ha_rtag
add wave -noupdate -group {Response Interface} /top/a0/ha_rtagpar
add wave -noupdate -group {Response Interface} -radix hexadecimal /top/a0/ha_response
add wave -noupdate -group {Response Interface} -radix decimal /top/a0/ha_rcredits
add wave -noupdate -group {Response Interface} /top/a0/ha_rcachestate
add wave -noupdate -group {Response Interface} -radix decimal /top/a0/ha_rcachepos
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/clock
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/enabled_in
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/rstn
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/command_outstanding_in
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/command_tag_in
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/response_in
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/response_tag_id_in
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/credits_in
add wave -noupdate -divider Credits
add wave -noupdate -radix unsigned /top/a0/svAFU/afu_control_instant/restart_command_control_instant/total_credit_count
add wave -noupdate -radix unsigned /top/a0/svAFU/afu_control_instant/restart_command_control_instant/total_credits
add wave -noupdate -radix unsigned /top/a0/svAFU/afu_control_instant/restart_command_control_instant/outstanding_restart_commands
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/is_restart_cmd
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/is_restart_rsp
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_response_in
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/response
add wave -noupdate -divider status
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_pending
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/ready_restart_issue
add wave -noupdate -divider {Commands OUT}
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_command_flag
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_command_flag_latched
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_command_out
add wave -noupdate -divider {Command OUT}
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/command_outstanding_data_out
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/command_outstanding_rd_addr
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/command_outstanding_rd
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/command_outstanding_rd_S2
add wave -noupdate -divider {Command IN}
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/command_outstanding_we
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/command_outstanding_data_in
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/command_outstanding_wr_addr
add wave -noupdate -divider Buffers
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_command_flushed
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/enabled
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_command_send
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_command_buffer_push
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_command_buffer_pop
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_command_buffer_out
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_command_buffer_in
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/restart_command_buffer_status_internal
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/response_type_latched
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/current_state
add wave -noupdate /top/a0/svAFU/afu_control_instant/restart_command_control_instant/next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {53310 ns} 1} {{Cursor 2} {53823 ns} 1}
quietly wave cursor active 2
configure wave -namecolwidth 665
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {53744 ns} {53934 ns}
