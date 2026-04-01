library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RGB565_Pattern_Generator is
    generic(
        H_BITS : positive := 10;
        V_BITS : positive := 10
    );
    port(
        clk      : in std_logic;
        reset    : in std_logic;
        pos_x    : in unsigned(H_BITS - 1 downto 0);
        pos_y    : in unsigned(V_BITS - 1 downto 0);
        data_out : out std_logic_vector(15 downto 0)
    );
end RGB565_Pattern_Generator;

architecture rtl of RGB565_Pattern_Generator is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                data_out <= (others => '0');
            else
                if pos_x < 213 then
                    data_out <= "0000000101001111";
                elsif pos_x < 426 then
                    data_out <= "1111111010000010";
                else
                    data_out <= "1100100010000100";
                end if;
            end if;
        end if;
    end process;
end rtl;