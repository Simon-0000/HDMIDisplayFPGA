library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PixelArbiter is
  generic(
    APB_PIXEL_VALUE_ADDR : std_logic_vector(7 downto 0) := x"00";
    APB_PIXEL_INDEX_ADDR : std_logic_vector(7 downto 0) := x"04";
    H_ACTIVE : positive := 640;
    V_ACTIVE : positive := 480;
    BLOCK_SIZE : positive := 16
  );
  port (
    apb_master_clk : in std_logic;
    apb_master_prst : in std_logic;
    apb_master_penable : in std_logic;
    apb_master_pwrite : in std_logic;

    apb_master_paddr : in std_logic_vector(7 downto 0);
    apb_master_pwdata : in std_logic_vector(31 downto 0);

    apb_master_psel1 : in std_logic;
    apb_master_pready1 : out std_logic
  );
end PixelArbiter;

architecture structural of PixelArbiter is
constant BLOCK_COUNT_H : positive := H_ACTIVE/BLOCK_SIZE;
constant BLOCK_COUNT_V : positive := V_ACTIVE/BLOCK_SIZE;
signal block_index : natural range 0 to (BLOCK_COUNT_H * BLOCK_COUNT_V) - 1:= 0;
signal pixel_index : natural range 0 to (BLOCK_SIZE * BLOCK_SIZE) - 1 := 0;

begin
 process (apb_master_clk)
  begin
    if rising_edge(apb_master_clk) then
      if apb_master_prst = '0' then
        apb_master_pready1 <= '0';
        block_index <= 0;
        pixel_index <= 0;
      else
        apb_master_pready1 <= '1'; -- REPLACE FOR BETTER LOGIC LINKED TO WHEN HYPERRAM IS AVAILABLE
        if apb_master_psel1 = '1' and apb_master_penable = '1' and apb_master_pwrite = '1' then
          if apb_master_paddr(7 downto 0) = APB_PIXEL_VALUE_ADDR then
--            TODO set the pixel value here using apb_master_pwdata(24 downto 0)
            pixel_index <= pixel_index + 1;
          elsif apb_master_paddr(7 downto 0) = APB_PIXEL_INDEX_ADDR then
            block_index <= to_integer(unsigned(apb_master_pwdata));
            pixel_index <= 0;
          end if;
        else
        -- Nothing is written, do nothing
        end if;
      end if;
    end if;
  end process;
end architecture structural; 