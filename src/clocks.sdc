create_clock -name clk_osc -period 37.037 -waveform {0 18.518} [get_ports {clk}]
create_generated_clock -name clk_bit -source [get_ports {clk}] -multiply_by 14 -divide_by 3 [get_nets {clk_bit_temp}]
create_generated_clock -name clk_pixel -source [get_ports {clk}] -multiply_by 14 -divide_by 15 [get_nets {clk_pixel_temp}]
create_generated_clock -name clk_hpram_in -source [get_ports {clk}] -multiply_by 4 [get_nets {clk_hyperram_in_temp}]
create_generated_clock -name clk_hpram_out -source [get_ports {clk}] -multiply_by 2 [get_nets {clk_hyperram_out_temp}]

set_clock_groups -asynchronous -group [get_clocks {clk_osc}] -group [get_clocks {clk_pixel clk_bit}] -group [get_clocks {clk_hpram_in clk_hpram_out}]