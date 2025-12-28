create_clock -name clk_osc -period 37.037 -waveform {0 18.518} [get_ports {clk}]
create_clock -name clk_pixel -period 39.72 -waveform {0 19.86} [get_pins {bufg_clk_pixel/O}]
create_clock -name clk_serial -period 7.94 -waveform {0 3.97} [get_pins {bufg_clk_bit/O}]