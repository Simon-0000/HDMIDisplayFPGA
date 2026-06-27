--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.11.03 Education
--Part Number: GW1NSR-LV4CQN48PC6/I5
--Device: GW1NSR-4C
--Created Time: Sat Jun 27 17:48:34 2026

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component block_framebuffer_FIFO
	port (
		Data: in std_logic_vector(31 downto 0);
		Reset: in std_logic;
		WrClk: in std_logic;
		RdClk: in std_logic;
		WrEn: in std_logic;
		RdEn: in std_logic;
		Almost_Empty: out std_logic;
		Almost_Full: out std_logic;
		Q: out std_logic_vector(31 downto 0);
		Empty: out std_logic;
		Full: out std_logic
	);
end component;

your_instance_name: block_framebuffer_FIFO
	port map (
		Data => Data,
		Reset => Reset,
		WrClk => WrClk,
		RdClk => RdClk,
		WrEn => WrEn,
		RdEn => RdEn,
		Almost_Empty => Almost_Empty,
		Almost_Full => Almost_Full,
		Q => Q,
		Empty => Empty,
		Full => Full
	);

----------Copy end-------------------
