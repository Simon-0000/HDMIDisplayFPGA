library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VideoTimingGenerator is
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
end VideoTimingGenerator;

architecture VideoTimingGenerator_arch of VideoTimingGenerator is
signal pos_x_temp : unsigned(H_BITS-1 downto 0) := (others => '0');
signal pos_y_temp : unsigned(V_BITS-1 downto 0) := (others => '0');

begin
  process(clk)
    begin
    if rising_edge(clk) then
      if reset = '1' then
        pos_x_temp <= (others => '0');
        pos_y_temp <= (others => '0');
      else
        if pos_x_temp = to_unsigned(H_FRONT_PORCH + H_ACTIVE + H_SYNC + H_BACK_PORCH - 1, H_BITS) then
          pos_x_temp <= (others => '0');
          if pos_y_temp = to_unsigned(V_FRONT_PORCH + V_ACTIVE + V_SYNC + V_BACK_PORCH - 1, V_BITS) then
            pos_y_temp <= (others => '0');
          else
            pos_y_temp <= pos_y_temp + 1;
          end if;
        else
          pos_x_temp <= pos_x_temp + 1;
        end if;
      end if;
    end if;  
  end process;

  pos_x <= pos_x_temp;
  pos_y <= pos_y_temp;

  DE <= '1' when pos_x_temp < H_ACTIVE AND pos_y_temp < V_ACTIVE else '0';
  
  C1_C0(0) <= '0' when (pos_x_temp >= H_ACTIVE + H_FRONT_PORCH) and 
                       (pos_x_temp < H_ACTIVE + H_FRONT_PORCH + H_SYNC) 
                  else '1';

  C1_C0(1) <= '0' when (pos_y_temp >= V_ACTIVE + V_FRONT_PORCH) and 
                       (pos_y_temp < V_ACTIVE + V_FRONT_PORCH + V_SYNC) 
                  else '1';
  
end VideoTimingGenerator_arch;