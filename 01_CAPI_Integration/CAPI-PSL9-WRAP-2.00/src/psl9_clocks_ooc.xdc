
create_clock -period 4.000 -name psl_clk -waveform {0.000 2.000} [get_ports PSL_CLK]
create_clock -period 4.000 -name afu_clk -waveform {0.000 2.000} [get_ports AFU_CLK]
create_clock -period 4.000 -name pslhip_clk -waveform {0.000 2.000} [get_ports PCIHIP_PSL_CLK]

