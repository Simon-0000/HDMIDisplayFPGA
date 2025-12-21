--https://glenwing.github.io/docs/DVI-1.0.pdf
library ieee; 
use ieee.std_logic_1164.all;

entity TMDS_encoder is 
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
    clk : in std_logic;
    rst : in std_logic;
    data_in : in std_logic_vector(7 downto 0);
    c_hsync_vsync : in std_logic_vector(1 downto 0);
    display_enable : in std_logic;
    data_out : out std_logic_vector(9 downto 0)
  );
end TMDS_encoder;

architecture TMDS_encoder_arch of TMDS_encoder is
  signal disparity : integer range -32 to 31 := 0;
begin
  process(clk, rst)
  variable data_out_temp : std_logic_vector(9 downto 0);
  variable nbr_1 : integer range 0 to 8 := 0;
  begin
    if rising_edge(clk) then
      if rst = '1' then 
        
      else
        if display_enable = '1' then
           --Count nbr of ones
--          for i in 0 to 7
        else
          disparity <= 0;
          case c_hsync_vsync is 
            when "00" => data_out_temp := "0010101011";
            when "01" => data_out_temp := "1101010100";
            when "10" => data_out_temp := "0010101010";
            when "11" => data_out_temp := "1101010101";
            when others => data_out_temp := "1101010101";
          end case;
          data_out_temp := "1101010100";
        end if;
      end if;
      data_out <= data_out_temp;
    end if;
  end process;

end TMDS_encoder_arch;