create_clock -name clk_osc -period 37.037 -waveform {0 18.518} [get_ports {clk}]
create_generated_clock -name clk_serial -source [get_ports {clk}] -multiply_by 14 -divide_by 3 [get_nets {clk_bit_buffered}]
create_generated_clock -name clk_pixel -source [get_ports {clk}] -multiply_by 14 -divide_by 15 [get_nets {clk_pixel_buffered}]
set_clock_groups -asynchronous -group [get_clocks {clk_osc}] -group [get_clocks {clk_pixel}]