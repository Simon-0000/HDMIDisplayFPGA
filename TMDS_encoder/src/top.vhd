library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  generic(
    H_ACTIVE : positive := 640;
    H_FRONT_PORCH : positive := 16;
    H_SYNC : positive := 96;
    H_BACK_PORCH : positive := 48;

    V_ACTIVE : positive := 640;
    V_FRONT_PORCH : positive := 16;
    V_SYNC : positive := 96;
    V_BACK_PORCH : positive := 48
  );
  port(
    clk: in std_logic; -- 32Mhz
    rst: in std_logic;
    clk_pixel: out std_logic; -- 252Mhz
    r: out std_logic;
    g: out std_logic;
    b: out std_logic
  );
end top;

architecture top_arch of top is

component gowin_pllvr
    port (
      clkout: out std_logic;
      clkoutd: out std_logic;
      reset: in std_logic;
      clkin: in std_logic;
      vren: in std_logic
  );
end component;

component TMDS_encoder
  port (
    clk : in std_logic;
    rst : in std_logic;
    D : in std_logic_vector(7 downto 0);
    C1_C0 : in std_logic_vector(1 downto 0);
    DE : in std_logic;
    q_out : out std_logic_vector(9 downto 0)
  );
end component;

signal clk_bit : std_logic;
signal clk_pixel_temp : std_logic;
signal red_D : std_logic_vector(7 downto 0) := "00000000";
signal green_D : std_logic_vector(7 downto 0) := "11111111";
signal blue_D : std_logic_vector(7 downto 0) := "00000000";

signal red_q_out : std_logic_vector(9 downto 0);
signal green_q_out : std_logic_vector(9 downto 0);
signal blue_q_out : std_logic_vector(9 downto 0);

signal C0_C1 : std_logic_vector(1 downto 0);
signal DE : std_logic;

signal pos_x : natural range 0 to 799 := 0;
signal pos_y : natural range 0 to 524 := 0;

begin
  pll : gowin_pllvr port map(
    clkout => clk_bit,
    clkoutd => clk_pixel_temp,
    reset => rst,
    clkin => clk,
    vren => '1'
  );

  red_TMDS : TMDS_encoder port map(
    clk => clk_pixel_temp,
    rst => rst,
    D => red_D,
    C1_C0 => "00",
    DE => DE,
    q_out => red_q_out
  );
  
  green_TMDS : TMDS_encoder port map(
    clk => clk_pixel_temp,
    rst => rst,
    D => green_D,
    C1_C0 => "00",
    DE => DE,
    q_out => green_q_out
  );

  blue_TMDS : TMDS_encoder port map(
    clk => clk_pixel_temp,
    rst => rst,
    D => blue_D,
    C1_C0 => C0_C1,
    DE => DE,
    q_out => blue_q_out
  );

  clk_pixel <= clk_pixel_temp;
  process(clk_pixel_temp)
    variable pos_x_tmp : natural range 0 to 799 := 0;
    variable pos_y_tmp : natural range 0 to 524 := 0;
    begin
    if pos_x_tmp = 799 then
      pos_x_tmp := 0;
    else
      pos_x_tmp := pos_x_tmp + 1;
    end if;


    if pos_y_tmp = 799 then
      pos_y_tmp := 0;
    else
      pos_y_tmp := pos_y_tmp + 1;
    end if;
 
    pos_x <= pos_x_tmp;
    pos_y <= pos_y_tmp;
    
  end process;

  DE <= '1' when pos_x >= H_FRONT_PORCH AND pos_x < H_FRONT_PORCH + H_ACTIVE else '0';

  
--  C1_C0 <= 
--  process(clk_bit)
--  begin
--    if rising_edge(clk_bit) then
--      red_q_out <= std_logic_vector(shift_right(red_q_out, 1));
--      green_q_out <= std_logic_vector(shift_right(green_q_out, 1));
--      blue_q_out <= std_logic_vector(shift_right(blue_q_out, 1));
--      r <= red_q_out(0);
--      g <= green_q_out(0);
--      b <= blue_q_out(0);
--    end if;
--  end process;
  

  --TMDS_R:TMDS_encoder

  
end top_arch;

