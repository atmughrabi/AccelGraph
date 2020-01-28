echo Watching Command interface waveforms

# PSL to AFU signals
add wave -position insertpoint -group "Command Interface" -radix decimal sim:/top/a0/ha_croom

# AFU to PSL signals
add wave -position insertpoint -group "Command Interface" -color yellow sim:/top/a0/ah_cvalid
add wave -position insertpoint -group "Command Interface" -color yellow -radix hexadecimal sim:/top/a0/ah_ctag
add wave -position insertpoint -group "Command Interface" -color yellow sim:/top/a0/ah_ctagpar
add wave -position insertpoint -group "Command Interface" -color yellow -radix hexadecimal sim:/top/a0/ah_com
add wave -position insertpoint -group "Command Interface" -color yellow sim:/top/a0/ah_compar
add wave -position insertpoint -group "Command Interface" -color yellow sim:/top/a0/ah_cabt
add wave -position insertpoint -group "Command Interface" -color yellow -radix hexadecimal sim:/top/a0/ah_cea
add wave -position insertpoint -group "Command Interface" -color yellow sim:/top/a0/ah_ceapar
add wave -position insertpoint -group "Command Interface" -color yellow -radix hexadecimal sim:/top/a0/ah_cch
add wave -position insertpoint -group "Command Interface" -color yellow -radix decimal sim:/top/a0/ah_csize