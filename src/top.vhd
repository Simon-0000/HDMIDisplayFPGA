library ieee; 
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  entity top is
    generic(
      H_ACTIVE : positive := 640;
      H_FRONT_PORCH : positive := 16;
      H_SYNC : positive := 96;
      H_BACK_PORCH : positive := 48;

      V_ACTIVE : positive := 480;
      V_FRONT_PORCH : positive := 10;
      V_SYNC : positive := 2;
      V_BACK_PORCH : positive := 33
    );
    port(
      clk: in std_logic;
      resetn: in std_logic;
      clk_pixel: out std_logic;
      r: out std_logic;
      g: out std_logic;
      b: out std_logic;
      uart0_txd : out std_logic;
      uart0_rxd : in std_logic;

      O_hpram_ck      : out std_logic_vector(0 downto 0);
      O_hpram_ck_n    : out std_logic_vector(0 downto 0);
      IO_hpram_dq     : inout std_logic_vector(7 downto 0);
      IO_hpram_rwds   : inout std_logic_vector(0 downto 0);
      O_hpram_cs_n    : out std_logic_vector(0 downto 0);
      O_hpram_reset_n : out std_logic_vector(0 downto 0)
    );
  end top;

  architecture top_arch of top is

  component Pllvr_DDR_Pixel
    port (
      clkout: out std_logic;
      reset: in std_logic;
      clkin: in std_logic
    );
  end component;
  component Pllvr_Hyperram
    port (
      clkout: out std_logic;
      lock: out std_logic;
      clkoutd: out std_logic;
      reset: in std_logic;
      clkin: in std_logic
    );
  end component;
  component Clkdiv_Pixel_Bit
    port (
      clkout: out std_logic;
      hclkin: in std_logic;
      resetn: in std_logic
    );
  end component;
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
  component Video_Frame_Buffer_Top
    port (
      I_rst_n: in std_logic;
      I_dma_clk: in std_logic;
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

  component PixelArbiter
    generic(
      APB_PIXEL_VALUE_ADDR: std_logic_vector(7 downto 0) := x"00";
      APB_PIXEL_INDEX_ADDR: std_logic_vector(7 downto 0) := x"04";
      H_ACTIVE: positive := 640;
      V_ACTIVE: positive := 480;
      BLOCK_SIZE: positive := 16
    );
    port (
      apb_master_clk: in std_logic;
      apb_master_prst: in std_logic;
      apb_master_penable: in std_logic;
      apb_master_pwrite: in std_logic;
      apb_master_paddr: in std_logic_vector(7 downto 0);
      apb_master_pwdata: in std_logic_vector(31 downto 0);
      apb_master_pselX: in std_logic;
      apb_master_preadyX: out std_logic;

      hyperram_wr_data: out std_logic_vector(31 downto 0);
      hyperram_addr: out std_logic_vector(21 downto 0);
      hyperram_cmd: out std_logic;
      hyperram_cmd_en: out std_logic;
      hyperram_data_mask: out std_logic_vector(3 downto 0);

      framebuffer_cmd: in std_logic;
      framebuffer_cmd_en: in std_logic;
      framebuffer_addr: in std_logic_vector(21 downto 0);
      framebuffer_wr_data: in std_logic_vector(31 downto 0);
      framebuffer_data_mask: in std_logic_vector(3 downto 0)
    );
  end component;

  component BUFG
   port(
     O:out std_logic;
     I:in std_logic
     );
  end component;
  
  component TMDS_encoder
    port (
      clk : in std_logic;
      reset : in std_logic;
      D : in std_logic_vector(7 downto 0);
      C1_C0 : in std_logic_vector(1 downto 0);
      DE : in std_logic;
      q_out : out std_logic_vector(9 downto 0)
    );
  end component;

  component Serializer 
    port(
      data_in : in std_logic_vector(9 downto 0);
      f_clk : in std_logic;
      clk : in std_logic;
      reset : in std_logic;
      data_out : out std_logic
    );
  end component;
  
  component VideoTimingGenerator is
    generic(
      H_BITS : positive := 10;
      V_BITS : positive := 10;
      H_ACTIVE : positive := 640;
      H_FRONT_PORCH : positive := 16;
      H_SYNC : positive := 96;
      H_BACK_PORCH : positive := 48;
      V_ACTIVE : positive := 480;
      V_FRONT_PORCH : positive := 10;
      V_SYNC : positive := 2;
      V_BACK_PORCH : positive := 33
    );
    port(
      clk: in std_logic;
      reset: in std_logic;
      pos_x: out unsigned(H_BITS - 1 downto 0);
      pos_y: out unsigned(V_BITS - 1 downto 0);
      DE : out std_logic;
      C1_C0 : out std_logic_vector(1 downto 0)
    );
  end component;
  
  component RGB565_Pattern_Generator
    generic(
      H_BITS : positive := 10;
      V_BITS : positive := 10
    );
    port(
      pos_x : in unsigned(H_BITS - 1 downto 0);
      pos_y : in unsigned(V_BITS - 1 downto 0);
      data_out: out std_logic_vector(15 downto 0)
    );
  end component;

  signal reset : std_logic;
  signal pllvr_hyperram_lock : std_logic;

  signal clk_bit_temp : std_logic;
  signal clk_bit_buffered : std_logic;
  signal clk_pixel_temp : std_logic;
  signal clk_pixel_buffered : std_logic;
  signal clk_hyperram_in_temp : std_logic;
  signal clk_hyperram_in_buffered : std_logic;
  signal clk_hyperram_out_temp : std_logic;
  signal clk_hyperram_out_buffered : std_logic;
  attribute syn_keep : boolean;
  attribute syn_keep of clk_pixel_buffered : signal is true;
  attribute syn_keep of clk_pixel_temp : signal is true;

  --Hyperram control
  signal arbiter_wr_data : std_logic_vector(31 downto 0);
  signal arbiter_addr : std_logic_vector(21 downto 0);
  signal arbiter_cmd : std_logic;
  signal arbiter_cmd_en : std_logic;
  signal arbiter_data_mask : std_logic_vector(3 downto 0);

  signal framebuffer_wr_data : std_logic_vector(31 downto 0);
  signal framebuffer_addr : std_logic_vector(21 downto 0);
  signal framebuffer_cmd : std_logic;
  signal framebuffer_cmd_en : std_logic;
  signal framebuffer_data_mask : std_logic_vector(3 downto 0);

  signal rd_data : std_logic_vector(31 downto 0);
  signal rd_data_valid : std_logic;
  signal init_calib : std_logic;

  --
  signal vout_data: std_logic_vector(15 downto 0) := "1111111111111111";

  signal red_D : std_logic_vector(7 downto 0) := "11111111";
  signal green_D : std_logic_vector(7 downto 0) := "11111111";
  signal blue_D : std_logic_vector(7 downto 0) := "11111111";

  signal red_q_out : std_logic_vector(9 downto 0);
  signal green_q_out : std_logic_vector(9 downto 0);
  signal blue_q_out : std_logic_vector(9 downto 0);
  signal C1_C0  : std_logic_vector(1 downto 0);
  signal DE : std_logic;
  signal pos_x : unsigned(9 downto 0) := to_unsigned(0,10);
  signal pos_y : unsigned(9 downto 0) := to_unsigned(0,10);

  signal master_pclk: std_logic;
  signal master_prst: std_logic;
  signal master_penable: std_logic;
  signal master_paddr: std_logic_vector(7 downto 0);
  signal master_pwrite: std_logic;
  signal master_pwdata: std_logic_vector(31 downto 0);
  signal master_pstrb: std_logic_vector(3 downto 0);
  signal master_pprot: std_logic_vector(2 downto 0);
  signal master_psel1: std_logic;
  signal master_prdata1: std_logic_vector(31 downto 0);
  signal master_pready1: std_logic;
  signal master_pslverr1: std_logic := '0';

  signal debug_fifo_empty : std_logic;

  signal cmd_en_pipe : std_logic;
  signal addr_pipe   : std_logic_vector(21 downto 0);
  signal wr_data_pipe : std_logic_vector(31 downto 0);
  attribute syn_preserve : boolean;
  attribute syn_preserve of cmd_en_pipe : signal is true;
  signal por_resetn : std_logic := '0';
  signal por_cnt    : unsigned(15 downto 0) := (others => '0');
  signal vout_den : std_logic;
  begin
    --Reset 
    reset <= not(resetn);

    --CLOCKS 
    pll_pixel_ddr: Pllvr_DDR_Pixel port map (
        clkout => clk_bit_temp,
        reset => reset,
        clkin => clk
    );

    pll_hyperram: Pllvr_Hyperram
    port map (
        clkout => clk_hyperram_in_temp,
        lock => pllvr_hyperram_lock,
        clkoutd => clk_hyperram_out_temp,
        reset => reset,
        clkin => clk
    );

    clkDivPixelBit: Clkdiv_Pixel_Bit port map (
        clkout => clk_pixel_temp,
        hclkin => clk_bit_buffered,
        resetn => resetn
    );
    
    bufg_clk_bit:BUFG
      port map(
      O=>clk_bit_buffered,
      I=>clk_bit_temp
     );
     
    bufg_clk_pixel:BUFG
      port map(
      O=>clk_pixel_buffered,
      I=>clk_pixel_temp
     );

--    HYPERRAM 
    process(clk)
    begin
        if rising_edge(clk) then
            if pllvr_hyperram_lock = '0' then
                por_cnt <= (others => '0');
                por_resetn <= '0';
            elsif por_cnt < x"FFFF" then
                por_cnt <= por_cnt + 1;
                por_resetn <= '0';
            else
                por_resetn <= '1';
            end if;
        end if;
    end process;

   hyperramControllerInstance: HyperRAM_Memory_Interface_Top port map (
      clk => clk,
      memory_clk => clk_hyperram_in_temp,
      pll_lock => pllvr_hyperram_lock,
      rst_n => por_resetn,
      O_hpram_ck => O_hpram_ck,
      O_hpram_ck_n => O_hpram_ck_n,
      IO_hpram_dq => IO_hpram_dq,
      IO_hpram_rwds => IO_hpram_rwds,
      O_hpram_cs_n => O_hpram_cs_n,
      O_hpram_reset_n => O_hpram_reset_n,
      wr_data => arbiter_wr_data,
      rd_data => rd_data,
      rd_data_valid => rd_data_valid,
      addr => arbiter_addr,
      cmd => arbiter_cmd,
      cmd_en => arbiter_cmd_en,
      init_calib => init_calib,
      clk_out => clk_hyperram_out_buffered,
      data_mask => arbiter_data_mask
    );

  videoFramebuffer: Video_Frame_Buffer_Top port map (
      I_rst_n            => por_resetn,
      I_dma_clk          => clk_hyperram_out_buffered,
      I_vin0_clk         => '0', 
      I_vin0_vs_n        => '1', 
      I_vin0_de          => '0', 
      I_vin0_data        => (others => '0'), 
      O_vin0_fifo_full   => open,
      I_vout0_clk        => clk_pixel_buffered,
      I_vout0_vs_n       => C1_C0(1), 
      I_vout0_de         => DE,
      O_vout0_den        => vout_den,
      O_vout0_data       => vout_data,
      O_vout0_fifo_empty => debug_fifo_empty,
      O_cmd              => framebuffer_cmd,
      O_cmd_en           => framebuffer_cmd_en,
      O_addr             => framebuffer_addr,
      O_wr_data          => framebuffer_wr_data,
      O_data_mask        => framebuffer_data_mask,
      I_rd_data_valid    => rd_data_valid,
      I_rd_data          => rd_data,
      I_init_calib       => init_calib
    );
    red_D   <= vout_data(15 downto 11) & "000";
    green_D <= vout_data(10 downto 5) & "00";
    blue_D  <= vout_data(4 downto 0) & "000";

  hardcoreM3: Gowin_EMPU_Top
    port map (
      sys_clk => clk_hyperram_out_buffered,
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
      reset_n => resetn
    );
  pixel_Arbiter: PixelArbiter
    port map(
      apb_master_clk => master_pclk,
      apb_master_prst => master_prst,
      apb_master_penable => master_penable,
      apb_master_pwrite => master_pwrite,
      apb_master_paddr => master_paddr,
      apb_master_pwdata => master_pwdata,
      apb_master_pselX => master_psel1,
      apb_master_preadyX => master_pready1,

      hyperram_wr_data => arbiter_wr_data,
      hyperram_addr => arbiter_addr,
      hyperram_cmd => arbiter_cmd,
      hyperram_cmd_en => arbiter_cmd_en,
      hyperram_data_mask => arbiter_data_mask,

      framebuffer_cmd => framebuffer_cmd,
      framebuffer_cmd_en => framebuffer_cmd_en,
      framebuffer_addr => framebuffer_addr,
      framebuffer_wr_data => framebuffer_wr_data,
      framebuffer_data_mask => framebuffer_data_mask 
    );


    videoTiming : VideoTimingGenerator port map(
      clk => clk_pixel_buffered,
      reset => reset,
      pos_x => pos_x,
      pos_y => pos_y,
      DE => DE,
      C1_C0 => C1_C0
    );

  red_TMDS : TMDS_encoder port map(
      clk => clk_pixel_buffered,
      reset => reset,
      D => red_D,
      C1_C0 => "00",
      DE => vout_den,
      q_out => red_q_out
    );

    green_TMDS : TMDS_encoder port map(
      clk => clk_pixel_buffered,
      reset => reset,
      D => green_D,
      C1_C0 => "00",
      DE => vout_den,
      q_out => green_q_out
    );

    blue_TMDS : TMDS_encoder port map(
      clk => clk_pixel_buffered,
      reset => reset,
      D => blue_D,
      C1_C0 => C1_C0,
      DE => vout_den,
      q_out => blue_q_out
    );

    ser_red : Serializer
    port map (
      data_in => red_q_out,
      f_clk => clk_bit_buffered,
      clk => clk_pixel_buffered,
      reset => reset,
      data_out => r
    );
    ser_green : Serializer
    port map (
      data_in => green_q_out,
      f_clk => clk_bit_buffered,
      clk => clk_pixel_buffered,
      reset => reset,
      data_out => g
    );
    ser_blue : Serializer
    port map (
      data_in => blue_q_out,
      f_clk => clk_bit_buffered,
      clk => clk_pixel_buffered,
      reset => reset,
      data_out => b
    );

    clk_pixel <= clk_pixel_buffered;

--    testPattern : RGB565_Pattern_Generator port map(
--      pos_x => pos_x,
--      pos_y => pos_y,
--      data_out => vin_data
--    );

  end top_arch;