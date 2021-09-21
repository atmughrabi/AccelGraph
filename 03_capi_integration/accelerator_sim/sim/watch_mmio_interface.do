echo Watching MMIO interface waveforms

# PSL to AFU signals
add wave -position insertpoint -group "MMIO Interface" sim:/top/a0/ha_mmval
add wave -position insertpoint -group "MMIO Interface" sim:/top/a0/ha_mmcfg
add wave -position insertpoint -group "MMIO Interface" sim:/top/a0/ha_mmrnw
add wave -position insertpoint -group "MMIO Interface" sim:/top/a0/ha_mmdw
add wave -position insertpoint -group "MMIO Interface" -radix hexadecimal sim:/top/a0/ha_mmad
add wave -position insertpoint -group "MMIO Interface" sim:/top/a0/ha_mmadpar
add wave -position insertpoint -group "MMIO Interface" -radix hexadecimal sim:/top/a0/ha_mmdata
add wave -position insertpoint -group "MMIO Interface" sim:/top/a0/ha_mmdatapar

# AFU to PSL signals
add wave -position insertpoint -group "MMIO Interface" -color yellow sim:/top/a0/ah_mmack
add wave -position insertpoint -group "MMIO Interface" -color yellow -radix hexadecimal sim:/top/a0/ah_mmdata
add wave -position insertpoint -group "MMIO Interface" -color yellow sim:/top/a0/ah_mmdatapar
