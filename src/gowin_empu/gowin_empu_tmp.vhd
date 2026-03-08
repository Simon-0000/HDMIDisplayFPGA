--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.11.03 Education
--Part Number: GW1NSR-LV4CQN48PC6/I5
--Device: GW1NSR-4C
--Created Time: Thu Feb 26 21:15:37 2026

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_EMPU_Top
	port (
		sys_clk: in std_logic;
		uart0_rxd: in std_logic;
		uart0_txd: out std_logic;
		master_pclk: out std_logic;
		master_prst: out std_logic;
		master_penable: out std_logic;
		master_paddr: out std_logic_vector(7 downto 0);
		master_pwrite: out std_logic;
		master_pwdata: out std_logic_vector(31 downto 0);
		master_pstrb: out std_logic_vector(3 downto 0);
		master_pprot: out std_logic_vector(2 downto 0);
		master_psel1: out std_logic;
		master_prdata1: in std_logic_vector(31 downto 0);
		master_pready1: in std_logic;
		master_pslverr1: in std_logic;
		reset_n: in std_logic
	);
end component;

your_instance_name: Gowin_EMPU_Top
	port map (
		sys_clk => sys_clk,
		uart0_rxd => uart0_rxd,
		uart0_txd => uart0_txd,
		master_pclk => master_pclk,
		master_prst => master_prst,
		master_penable => master_penable,
		master_paddr => master_paddr,
		master_pwrite => master_pwrite,
		master_pwdata => master_pwdata,
		master_pstrb => master_pstrb,
		master_pprot => master_pprot,
		master_psel1 => master_psel1,
		master_prdata1 => master_prdata1,
		master_pready1 => master_pready1,
		master_pslverr1 => master_pslverr1,
		reset_n => reset_n
	);

----------Copy end-------------------
