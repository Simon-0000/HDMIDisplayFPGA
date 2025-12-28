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
      rst: in std_logic;
      clk_pixel: out std_logic;
      r: out std_logic;
      g: out std_logic;
      b: out std_logic
    );
  end top;

  architecture top_arch of top is

  component Gowin_PLLVR is
      port (
          clkout: out std_logic;
          reset: in std_logic;
          clkin: in std_logic
      );
  end component;
  component Gowin_CLKDIV is
      port (
          clkout: out std_logic;
          hclkin: in std_logic;
          resetn: in std_logic
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

  component Serializer is 
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
  signal reset : std_logic;
  signal clk_bit_temp : std_logic;
  signal clk_bit_buffered : std_logic;

  signal clk_pixel_temp : std_logic;
  signal clk_pixel_buffered : std_logic;

  attribute syn_keep : boolean;

  attribute syn_keep of clk_pixel_buffered : signal is true;
  attribute syn_keep of clk_pixel_temp : signal is true;



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

  begin
    reset <= not(rst);
    pll : Gowin_PLLVR port map(
      clkout => clk_bit_temp,
      reset => reset,
      clkin => clk
    );
    clkDiv : Gowin_CLKDIV port map(
        clkout => clk_pixel_temp,
        hclkin => clk_bit_temp,
        resetn => rst
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

    red_TMDS : TMDS_encoder port map(
      clk => clk_pixel_buffered,
      reset => reset,
      D => red_D,
      C1_C0 => "00",
      DE => DE,
      q_out => red_q_out
    );
    
    green_TMDS : TMDS_encoder port map(
      clk => clk_pixel_buffered,
      reset => reset,
      D => green_D,
      C1_C0 => "00",
      DE => DE,
      q_out => green_q_out
    );

    blue_TMDS : TMDS_encoder port map(
      clk => clk_pixel_buffered,
      reset => reset,
      D => blue_D,
      C1_C0 => C1_C0,
      DE => DE,
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

    videoTiming : VideoTimingGenerator port map(
      clk => clk_pixel_buffered,
      reset => reset,
      pos_x => pos_x,
      pos_y => pos_y,
      DE => DE,
      C1_C0 => C1_C0
    );
    
  end top_arch;

