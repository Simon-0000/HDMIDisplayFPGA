--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.11.03 Education
--Part Number: GW1NSR-LV4CQN48PC6/I5
--Device: GW1NSR-4C
--Created Time: Fri Jan  9 21:01:00 2026

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_EMPU_Top
	port (
		sys_clk: in std_logic;
		gpio: inout std_logic_vector(15 downto 0);
		uart0_rxd: in std_logic;
		uart0_txd: out std_logic;
		reset_n: in std_logic
	);
end component;

your_instance_name: Gowin_EMPU_Top
	port map (
		sys_clk => sys_clk,
		gpio => gpio,
		uart0_rxd => uart0_rxd,
		uart0_txd => uart0_txd,
		reset_n => reset_n
	);

----------Copy end-------------------
