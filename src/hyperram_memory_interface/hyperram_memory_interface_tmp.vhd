--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.11.03 Education
--Part Number: GW1NSR-LV4CQN48PC6/I5
--Device: GW1NSR-4C
--Created Time: Sun May 17 22:21:22 2026

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component HyperRAM_Memory_Interface_Top
	port (
		clk: in std_logic;
		memory_clk: in std_logic;
		pll_lock: in std_logic;
		rst_n: in std_logic;
		O_hpram_ck: out std_logic_vector(0 downto 0);
		O_hpram_ck_n: out std_logic_vector(0 downto 0);
		IO_hpram_dq: inout std_logic_vector(7 downto 0);
		IO_hpram_rwds: inout std_logic_vector(0 downto 0);
		O_hpram_cs_n: out std_logic_vector(0 downto 0);
		O_hpram_reset_n: out std_logic_vector(0 downto 0);
		wr_data: in std_logic_vector(31 downto 0);
		rd_data: out std_logic_vector(31 downto 0);
		rd_data_valid: out std_logic;
		addr: in std_logic_vector(21 downto 0);
		cmd: in std_logic;
		cmd_en: in std_logic;
		init_calib: out std_logic;
		clk_out: out std_logic;
		data_mask: in std_logic_vector(3 downto 0)
	);
end component;

your_instance_name: HyperRAM_Memory_Interface_Top
	port map (
		clk => clk,
		memory_clk => memory_clk,
		pll_lock => pll_lock,
		rst_n => rst_n,
		O_hpram_ck => O_hpram_ck,
		O_hpram_ck_n => O_hpram_ck_n,
		IO_hpram_dq => IO_hpram_dq,
		IO_hpram_rwds => IO_hpram_rwds,
		O_hpram_cs_n => O_hpram_cs_n,
		O_hpram_reset_n => O_hpram_reset_n,
		wr_data => wr_data,
		rd_data => rd_data,
		rd_data_valid => rd_data_valid,
		addr => addr,
		cmd => cmd,
		cmd_en => cmd_en,
		init_calib => init_calib,
		clk_out => clk_out,
		data_mask => data_mask
	);

----------Copy end-------------------
