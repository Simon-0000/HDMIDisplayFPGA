--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.11.03 Education
--Part Number: GW1NSR-LV4CQN48PC6/I5
--Device: GW1NSR-4C
--Created Time: Fri Jan  2 22:46:30 2026

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Video_Frame_Buffer_Top
	port (
		I_rst_n: in std_logic;
		I_dma_clk: in std_logic;
		I_wr_halt: in std_logic_vector(0 downto 0);
		I_rd_halt: in std_logic_vector(0 downto 0);
		I_vin0_clk: in std_logic;
		I_vin0_vs_n: in std_logic;
		I_vin0_de: in std_logic;
		I_vin0_data: in std_logic_vector(15 downto 0);
		O_vin0_fifo_full: out std_logic;
		I_vout0_clk: in std_logic;
		I_vout0_vs_n: in std_logic;
		I_vout0_de: in std_logic;
		O_vout0_den: out std_logic;
		O_vout0_data: out std_logic_vector(15 downto 0);
		O_vout0_fifo_empty: out std_logic;
		O_cmd: out std_logic;
		O_cmd_en: out std_logic;
		O_addr: out std_logic_vector(21 downto 0);
		O_wr_data: out std_logic_vector(31 downto 0);
		O_data_mask: out std_logic_vector(3 downto 0);
		I_rd_data_valid: in std_logic;
		I_rd_data: in std_logic_vector(31 downto 0);
		I_init_calib: in std_logic
	);
end component;

your_instance_name: Video_Frame_Buffer_Top
	port map (
		I_rst_n => I_rst_n,
		I_dma_clk => I_dma_clk,
		I_wr_halt => I_wr_halt,
		I_rd_halt => I_rd_halt,
		I_vin0_clk => I_vin0_clk,
		I_vin0_vs_n => I_vin0_vs_n,
		I_vin0_de => I_vin0_de,
		I_vin0_data => I_vin0_data,
		O_vin0_fifo_full => O_vin0_fifo_full,
		I_vout0_clk => I_vout0_clk,
		I_vout0_vs_n => I_vout0_vs_n,
		I_vout0_de => I_vout0_de,
		O_vout0_den => O_vout0_den,
		O_vout0_data => O_vout0_data,
		O_vout0_fifo_empty => O_vout0_fifo_empty,
		O_cmd => O_cmd,
		O_cmd_en => O_cmd_en,
		O_addr => O_addr,
		O_wr_data => O_wr_data,
		O_data_mask => O_data_mask,
		I_rd_data_valid => I_rd_data_valid,
		I_rd_data => I_rd_data,
		I_init_calib => I_init_calib
	);

----------Copy end-------------------
