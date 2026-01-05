library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RGB565_Pattern_Generator is
  generic(
    H_BITS : positive := 10; -- must match with the H_ACTIVE + .... = screen width size
    V_BITS : positive := 10
  );
  port(
    clk : in std_logic;
    reset : in std_logic;
    pos_x : in unsigned(H_BITS - 1 downto 0);
    pos_y : in unsigned(V_BITS - 1 downto 0);
    data_out: out std_logic_vector(15 downto 0)
  );
end RGB565_Pattern_Generator;

architecture RGB565_Pattern_Generator_arch of RGB565_Pattern_Generator is

begin
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        data_out <= (others=>'0');
      else
        if pos_x < 200 then
            data_out <= "1111100000000000"; 
        elsif pos_x < 400 then
            data_out <= "0000011111100000";
        else
            data_out <= "0000000000011111";
        end if;
      end if;
    end if;
  end process;
end RGB565_Pattern_Generator_arch;