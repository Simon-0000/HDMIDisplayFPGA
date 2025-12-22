library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port(
    clk: in std_logic;
    rst: in std_logic;
    bit_clk: out std_logic;
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

signal clk_pixel : std_logic;
signal clk_bit  : std_logic;
signal red_D : std_logic_vector(7 downto 0);
signal red_q_out : std_logic_vector(9 downto 0);
signal DE : std_logic;
begin
  pll : gowin_pllvr port map(
    clkout => clk_bit,
    clkoutd => clk_pixel,
    reset => rst,
    clkin => clk,
    vren => '1'
  );

  r_TMDS : TMDS_encoder port map(
    clk => clk_pixel,
    rst => rst,
    D => red_D,
    C1_C0 => "00",
    DE => DE,
    q_out => red_q_out
  );
  
  --TMDS_R:TMDS_encoder

  
end top_arch;

