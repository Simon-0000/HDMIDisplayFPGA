create_clock -name clk_osc -period 37.037 -waveform {0 18.518} [get_ports {clk}]
create_generated_clock -name clk_pixel -source [get_ports {clk}] -multiply_by 14 -divide_by 15 [get_nets {clk_pixel_buffered}]
create_generated_clock -name clk_bit -source [get_ports {clk}] -multiply_by 14 -divide_by 3 [get_nets {clk_bit_buffered}]
create_generated_clock -name clk_hpram_in -source [get_ports {clk}] -multiply_by 5 [get_pins {pll_hyperram/pllvr_inst/CLKOUT}] 
create_generated_clock -name clk_hpram_out -source [get_ports {clk}] -multiply_by 5 -divide_by 2 [get_pins {pll_hyperram/pllvr_inst/CLKOUTD}]
create_generated_clock -name clk_hpram_internal -source [get_pins {pll_hyperram/pllvr_inst/CLKOUT}] -divide_by 2 [get_pins {hyperramControllerInstance/u_hpram_top/clkdiv_s0/CLKOUT}]

# We group ALL internal HyperRAM clocks as asynchronous to the pixel domain
# This prevents the -10ns paths from being analyzed at all
set_clock_groups -asynchronous -group [get_clocks {clk_osc}] -group [get_clocks {clk_pixel clk_bit}] -group [get_clocks {clk_hpram_in clk_hpram_out}]