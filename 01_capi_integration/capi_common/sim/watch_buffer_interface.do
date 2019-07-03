echo Watching Buffer interface waveforms

# PSL to AFU signals
add wave -position insertpoint -group "Buffer Interface" -radix hexadecimal sim:/top/a0/ha_brtag
add wave -position insertpoint -group "Buffer Interface" sim:/top/a0/ha_brtagpar
add wave -position insertpoint -group "Buffer Interface" -radix hexadecimal sim:/top/a0/ha_brad

add wave -position insertpoint -group "Buffer Interface" sim:/top/a0/ha_bwvalid
add wave -position insertpoint -group "Buffer Interface" -radix hexadecimal sim:/top/a0/ha_bwtag
add wave -position insertpoint -group "Buffer Interface" sim:/top/a0/ha_bwtagpar
add wave -position insertpoint -group "Buffer Interface" -radix hexadecimal sim:/top/a0/ha_bwad
add wave -position insertpoint -group "Buffer Interface" -radix hexadecimal sim:/top/a0/ha_bwdata
add wave -position insertpoint -group "Buffer Interface" sim:/top/a0/ha_bwpar

# AFU to PSL signals
add wave -position insertpoint -group "Buffer Interface" -color yellow -radix decimal sim:/top/a0/ah_brlat
add wave -position insertpoint -group "Buffer Interface" -color yellow -radix hexadecimal sim:/top/a0/ah_brdata
add wave -position insertpoint -group "Buffer Interface" -color yellow sim:/top/a0/ah_brpar