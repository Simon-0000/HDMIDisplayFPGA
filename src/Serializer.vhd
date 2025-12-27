library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity Serializer is 
  generic(
    N: positive
  );
  port(
    clk : in std_logic;
    reset : in std_logic;
    data_in : in std_logic_vector(N-1 downto 0);
    data_out : out std_logic
  );
end Serializer;

architecture SerializerArch of Serializer is
signal counter : natural := 0;
signal data_temp : std_logic_vector(N-1 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then 
          counter <= 0;
          data_temp <= data_in;
          data_out <= data_in(0);
      else
        if counter = N-1 then
          counter <= 0;
          data_temp <= data_in;
          data_out <= data_in(0);
        else
          counter <= counter + 1;
          data_out <= data_temp(counter + 1);
        end if;
      end if;

    end if;
  end process;
end SerializerArch;