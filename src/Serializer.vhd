library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Serializer is 
  port(
    data_in : in std_logic_vector(9 downto 0);
    f_clk : in std_logic;
    clk : in std_logic;
    reset : in std_logic;
    data_out : out std_logic
  );
end Serializer;

architecture SerializerArch of Serializer is
component OSER10
  generic (GSREN:string:="false";
            LSREN:string:="true");
  PORT(
    Q:OUT std_logic;
    D0:IN std_logic;
    D1:IN std_logic;
    D2:IN std_logic;
    D3:IN std_logic;
    D4:IN std_logic;
    D5:IN std_logic;
    D6:IN std_logic;
    D7:IN std_logic;
    D8:IN std_logic;
    D9:IN std_logic;
    FCLK:IN std_logic;
    PCLK:IN std_logic;
    RESET:IN std_logic);
end COMPONENT;


begin
  ser : OSER10 port map(
    Q => data_out,
    D0 => data_in(0),
    D1 => data_in(1),
    D2 => data_in(2),
    D3 => data_in(3),
    D4 => data_in(4),
    D5 => data_in(5),
    D6 => data_in(6),
    D7 => data_in(7),
    D8 => data_in(8),
    D9 => data_in(9),
    FCLK => f_clk,
    PCLK => clk,
    RESET => reset
  );
end SerializerArch;