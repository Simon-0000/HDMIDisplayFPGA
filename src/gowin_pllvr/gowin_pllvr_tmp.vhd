--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.11.03 Education
--Part Number: GW1NSR-LV4CQN48PC6/I5
--Device: GW1NSR-4C
--Created Time: Sun Dec 21 19:43:26 2025

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_PLLVR
    port (
        clkout: out std_logic;
        clkoutd: out std_logic;
        reset: in std_logic;
        clkin: in std_logic;
        vren: in std_logic
    );
end component;

your_instance_name: Gowin_PLLVR
    port map (
        clkout => clkout,
        clkoutd => clkoutd,
        reset => reset,
        clkin => clkin,
        vren => vren
    );

----------Copy end-------------------
