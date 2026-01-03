--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.11.03 Education
--Part Number: GW1NSR-LV4CQN48PC6/I5
--Device: GW1NSR-4C
--Created Time: Fri Jan  2 21:29:09 2026

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Pllvr_DDR_Pixel
    port (
        clkout: out std_logic;
        reset: in std_logic;
        clkin: in std_logic
    );
end component;

your_instance_name: Pllvr_DDR_Pixel
    port map (
        clkout => clkout,
        reset => reset,
        clkin => clkin
    );

----------Copy end-------------------
