library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ClockDomainCrossing is
generic
(
  N : positive := 1
);
port(
  clk : in std_logic;
  data_in : in std_logic_vector(N - 1 downto 0);
  data_out : out std_logic_vector(N - 1 downto 0)
);
end ClockDomainCrossing;

architecture ClockDomainCrossing_arch of ClockDomainCrossing is
signal data_temp : std_logic_vector(N - 1 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      data_temp <= data_in;
      data_out <= data_temp;
    end if;
  end process;
end ClockDomainCrossing_arch;

