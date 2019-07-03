echo Watching Job interface waveforms

# Clock signal
add wave -position insertpoint -group "Job Interface" sim:/top/a0/ha_pclock

# PSL to AFU signals
add wave -position insertpoint -group "Job Interface" sim:/top/a0/ha_jval
add wave -position insertpoint -group "Job Interface" -radix hexadecimal sim:/top/a0/ha_jcom
add wave -position insertpoint -group "Job Interface" sim:/top/a0/ha_jcompar
add wave -position insertpoint -group "Job Interface" -radix hexadecimal sim:/top/a0/ha_jea
add wave -position insertpoint -group "Job Interface" sim:/top/a0/ha_jeapar

# AFU to PSL signals
add wave -position insertpoint -group "Job Interface" -color yellow sim:/top/a0/ah_jrunning
add wave -position insertpoint -group "Job Interface" -color yellow sim:/top/a0/ah_jdone
add wave -position insertpoint -group "Job Interface" -color yellow sim:/top/a0/ah_jcack
add wave -position insertpoint -group "Job Interface" -color yellow -radix hexadecimal sim:/top/a0/ah_jerror
add wave -position insertpoint -group "Job Interface" -color yellow sim:/top/a0/ah_jyield

# Other signals
add wave -position insertpoint -group "Job Interface" sim:/top/a0/ah_tbreq
add wave -position insertpoint -group "Job Interface" sim:/top/a0/ah_paren
