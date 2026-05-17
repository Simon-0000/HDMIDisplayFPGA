library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity PixelArbiter is
  generic(
    APB_PIXEL_VALUE_ADDR: std_logic_vector(7 downto 0) := x"00";
    APB_PIXEL_INDEX_ADDR: std_logic_vector(7 downto 0) := x"04";
    H_ACTIVE: positive := 640;
    V_ACTIVE: positive := 480;
    BLOCK_SIZE: positive := 16
  );
  port (
    apb_master_clk: in std_logic;
    apb_master_prst: in std_logic;
    apb_master_penable: in std_logic;
    apb_master_pwrite: in std_logic;
    apb_master_paddr: in std_logic_vector(7 downto 0);
    apb_master_pwdata: in std_logic_vector(31 downto 0);
    apb_master_pselX: in std_logic;
    apb_master_preadyX: out std_logic;

    hyperram_wr_data: out std_logic_vector(31 downto 0);
    hyperram_addr: out std_logic_vector(21 downto 0);
    hyperram_cmd: out std_logic;
    hyperram_cmd_en: out std_logic;
    hyperram_data_mask: out std_logic_vector(3 downto 0);

    framebuffer_cmd: in std_logic;
    framebuffer_cmd_en: in std_logic;
    framebuffer_addr: in std_logic_vector(21 downto 0);
    framebuffer_wr_data: in std_logic_vector(31 downto 0);
    framebuffer_data_mask: in std_logic_vector(3 downto 0)
  );
end PixelArbiter;

architecture structural of PixelArbiter is
type state_type is (IDLE, SETUP_PIXEL, WRITE_PIXEL);

constant BLOCK_COUNT_H: positive := H_ACTIVE/BLOCK_SIZE;
constant BLOCK_COUNT_V: positive := V_ACTIVE/BLOCK_SIZE;
signal block_index: natural range 0 to (BLOCK_COUNT_H * BLOCK_COUNT_V) - 1:= 0;
signal pixel_pair_index: natural range 0 to ((BLOCK_SIZE * BLOCK_SIZE) / 2) - 1 := 0;
signal pixel_pair_memory_index: natural := 0;
signal state: state_type := IDLE;
signal pixel_write_request: std_logic := '0';

constant arbiter_cmd: std_logic := '1';
signal arbiter_cmd_en: std_logic := '0';
signal arbiter_addr: std_logic_vector(21 downto 0) := (others => '0');
signal arbiter_wr_data: std_logic_vector(31 downto 0) := (others => '0');
constant arbiter_data_mask: std_logic_vector(3 downto 0) := "0000";

begin
 process (apb_master_clk)
  begin
    if rising_edge(apb_master_clk) then
      if apb_master_prst = '0' then
        pixel_write_request <= '0';
        arbiter_wr_data <= (others =>'0');
        block_index <= 0;
        pixel_pair_index <= 0;
        pixel_pair_memory_index <= 0;
      else
        pixel_write_request <= '0';
        if apb_master_pselX = '1' and apb_master_penable = '1' and apb_master_pwrite = '1' and state = IDLE then
          if apb_master_paddr(7 downto 0) = APB_PIXEL_VALUE_ADDR then
            pixel_pair_memory_index <= (block_index * ((BLOCK_SIZE * BLOCK_SIZE) / 2)) + pixel_pair_index;
            pixel_pair_index <= pixel_pair_index + 1;
            pixel_write_request <= '1';
            arbiter_wr_data <= apb_master_pwdata;
          elsif apb_master_paddr(7 downto 0) = APB_PIXEL_INDEX_ADDR then
            block_index <= to_integer(unsigned(apb_master_pwdata));
            pixel_pair_index <= 0;
          end if;
        end if;
      end if;
    end if;
  end process;


  process (apb_master_clk) -- State machine
  begin
    if rising_edge(apb_master_clk) then
      if apb_master_prst = '0' then
        state <= IDLE;
      else
        case state is
          when IDLE =>
            arbiter_cmd_en <= '0';
            if pixel_write_request = '1' then
              state <= SETUP_PIXEL;
            end if;
          when SETUP_PIXEL => 
            state <= WRITE_PIXEL;
            arbiter_addr <= std_logic_vector(to_unsigned(pixel_pair_memory_index, 22));
          when WRITE_PIXEL =>
            arbiter_cmd_en <= '1';
            state <= IDLE;
        end case;
      end if;
    end if;
  end process;
  apb_master_preadyX <= '1' when (state = IDLE) else '0';

  hyperram_cmd       <= arbiter_cmd when (state /= IDLE) else framebuffer_cmd;
  hyperram_cmd_en    <= arbiter_cmd_en when (state /= IDLE) else framebuffer_cmd_en;
  hyperram_addr      <= arbiter_addr when (state /= IDLE) else framebuffer_addr;
  hyperram_wr_data   <= arbiter_wr_data when (state /= IDLE) else framebuffer_wr_data;
  hyperram_data_mask <= arbiter_data_mask when (state /= IDLE) else framebuffer_data_mask;
end architecture structural; 