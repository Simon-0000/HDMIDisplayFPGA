library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BlockFramebuffer is
  generic(
    FIFO_INPUT_SIZE: positive := 512;
    FIFO_OUTPUT_SIZE: positive := 512;
    BLOCK_SIZE: positive := 16;
    H_ACTIVE : positive := 640;
    V_ACTIVE : positive := 480;
    MEM_BURST_NUM : positive := 32
  );
  port (
    I_dma_clk: in std_logic;
    I_rst: in std_logic;
    O_cmd: out std_logic;
    O_cmd_en: out std_logic;
    O_addr: out std_logic_vector(21 downto 0);
    O_wr_data: out std_logic_vector(31 downto 0);
    O_data_mask: out std_logic_vector(3 downto 0);
    I_rd_data_valid: in std_logic;
    I_rd_data: in std_logic_vector(31 downto 0);
    I_init_calib: in std_logic;


    I_vin_clk: in std_logic;
    I_vin_wr_enable: in std_logic; 
    I_vin_data: in std_logic_vector(31 downto 0); -- 2 rgb555 emcoded colors with the MSB of each telling us is we dont write to memoryTells us if we leave the memory untouched (skip to next position)

    I_vout_clk: in std_logic;
    I_vout_vs_hs: in std_logic_vector(1 downto 0);
    I_vout_de: in std_logic;
    O_vout_vs_hs: out std_logic_vector(1 downto 0);
    O_vout_de: out std_logic;
    O_vout_data: out std_logic_vector(15 downto 0);
    O_vout_fifo_empty: out std_logic
    
  );
end BlockFramebuffer;

architecture structural of BlockFramebuffer is
  function clog2 (x : positive) return natural is
    variable i : natural := 0;
  begin
    while (2**i < x) loop
      i := i + 1;
    end loop;
    return i;
  end function;

component block_framebuffer_FIFO
	port (
		Data: in std_logic_vector(31 downto 0);
		Reset: in std_logic;
		WrClk: in std_logic;
		RdClk: in std_logic;
		WrEn: in std_logic;
		RdEn: in std_logic;
		Almost_Empty: out std_logic;
		Almost_Full: out std_logic;
		Q: out std_logic_vector(31 downto 0);
		Empty: out std_logic;
		Full: out std_logic
	);
end component;



--type state_type is (IDLE, SETUP_PIXEL, WRITE_PIXEL);

--constant BLOCK_COUNT_H: positive := H_ACTIVE/BLOCK_SIZE;
--constant BLOCK_COUNT_V: positive := V_ACTIVE/BLOCK_SIZE;
--signal block_index: natural range 0 to (BLOCK_COUNT_H * BLOCK_COUNT_V) - 1:= 0;
--signal pixel_pair_index: natural range 0 to ((BLOCK_SIZE * BLOCK_SIZE) / 2) - 1 := 0;
--signal pixel_pair_memory_index: natural := 0;
--signal state: state_type := IDLE;
--signal pixel_write_request: std_logic := '0';

--constant arbiter_cmd: std_logic := '1';
--signal arbiter_cmd_en: std_logic := '0';
--signal arbiter_addr: std_logic_vector(21 downto 0) := (others => '0');
--signal arbiter_wr_data: std_logic_vector(31 downto 0) := (others => '0');
--constant arbiter_data_mask: std_logic_vector(3 downto 0) := "0000";

signal vin_fifo_RdEn: std_logic := '0';
signal vin_fifo_Almost_Empty: std_logic := '0';
signal vin_fifo_Almost_Full: std_logic := '0';
signal vin_fifo_Empty: std_logic := '0';
signal vin_fifo_Full: std_logic := '0';
signal vin_fifo_data_out: std_logic_vector(31 downto 0);

signal vout_fifo_data_in: std_logic_vector(31 downto 0);
signal vout_fifo_WrEn: std_logic := '0';
signal vout_fifo_Almost_Empty: std_logic := '0';
signal vout_fifo_Empty: std_logic := '0';
signal vout_fifo_Almost_Full: std_logic := '0';
signal vout_fifo_Full: std_logic := '0';
signal vout_fifo_data_out: std_logic_vector(31 downto 0);
signal vout_fifo_RdEn : std_logic := '0';
signal vout_read_low_bits : std_logic := '0';

signal mem_write_priority : unsigned(4 downto 0);
signal mem_read_priority : unsigned(4 downto 0);
signal rw_alternate : std_logic := '0';

-- vin and vout indexes
constant NBR_OF_PIXELS : positive := H_ACTIVE * V_ACTIVE;
constant NBR_OF_BLOCK_PIXELS : positive := BLOCK_SIZE * BLOCK_SIZE;
constant NBR_OF_BLOCKS : positive := NBR_OF_PIXELS / NBR_OF_BLOCK_PIXELS;
constant MEM_READ_PIXEL_INDEX_MSB : natural := clog2(NBR_OF_PIXELS) - 1;
constant MEM_WRITE_BLOCK_INDEX_MSB : natural := clog2(NBR_OF_BLOCKS) - 1;
constant MEM_WRITE_BLOCK_PIXEL_INDEX_MSB : natural := clog2(BLOCK_SIZE) - 1;
constant MEM_BURST_INDEX_MSB : natural := clog2(MEM_BURST_NUM) - 1;

signal mem_read_pixel_index : unsigned(MEM_READ_PIXEL_INDEX_MSB downto 0) := (others => '0');
signal mem_write_block_index : unsigned(MEM_WRITE_BLOCK_INDEX_MSB downto 0) := (others => '0');
signal mem_reset_write_block_index : std_logic := '1';
signal mem_write_block_x_pixel_index : unsigned(MEM_WRITE_BLOCK_PIXEL_INDEX_MSB downto 0) := (others => '0');
signal mem_write_block_y_pixel_index : unsigned(MEM_WRITE_BLOCK_PIXEL_INDEX_MSB downto 0) := (others => '0');
signal mem_burst_index : unsigned(MEM_BURST_INDEX_MSB downto 0) := (others => '0');
signal mem_burst_is_active : std_logic := '0';


begin
  vin_fifo: block_framebuffer_FIFO
    port map (
      Data => I_vin_data,
      Reset => I_rst,
      WrClk => I_vin_clk,
      RdClk => I_dma_clk,
      WrEn => I_vin_wr_enable,
      RdEn => vin_fifo_RdEn,
      Almost_Empty => vin_fifo_Almost_Empty,
      Almost_Full => vin_fifo_Almost_Full,
      Q => vin_fifo_data_out,
      Empty => vin_fifo_Empty,
      Full => vin_fifo_Full
    );

  vout_fifo: block_framebuffer_FIFO
    port map (
      Data => vout_fifo_data_in,
      Reset => I_rst,
      WrClk => I_dma_clk,
      RdClk => I_vout_clk,
      WrEn => vout_fifo_WrEn,
      RdEn => vout_fifo_RdEn,
      Almost_Empty => vout_fifo_Almost_Empty,
      Almost_Full => vout_fifo_Almost_Full,
      Q => vout_fifo_data_out,
      Empty => vout_fifo_Empty,
      Full => vout_fifo_Full
    );

  O_vout_fifo_empty <= vout_fifo_Empty;

  mem_write_priority(0) <= rw_alternate;
  mem_read_priority(0) <= not(rw_alternate);
  mem_write_priority(1) <= vin_fifo_Almost_Empty and not(vin_fifo_Empty);
  mem_read_priority(1) <= vout_fifo_Almost_Full and not(vout_fifo_Full);
  mem_write_priority(2) <= not(vin_fifo_Almost_Empty) and not(vin_fifo_Almost_Full);
  mem_read_priority(2) <= not(vout_fifo_Almost_Empty) and not(vout_fifo_Almost_Full);
  mem_write_priority(3) <= vin_fifo_Almost_Full;
  mem_read_priority(3) <= vout_fifo_Almost_Empty;
  mem_write_priority(4) <= vin_fifo_Full;
  mem_read_priority(4) <= vout_fifo_Empty;
  process(I_dma_clk)
  begin
    if rising_edge(I_dma_clk) then
      if I_rst = '1' then
        rw_alternate <= '0';
        vin_fifo_RdEn <= '0';
        vout_fifo_WrEn <= '0';
        O_cmd_en <= '0';
        mem_read_pixel_index <= (others => '0');
        mem_write_block_index <= (others => '0');
        mem_write_block_x_pixel_index <= (others => '0');
        mem_write_block_y_pixel_index <= (others => '0');
        mem_reset_write_block_index <= '1';
        mem_burst_index <= (others => '0');
        mem_burst_is_active <= '0';
        O_data_mask <= (others => '0');

      else
        vin_fifo_RdEn <= '0';
        vout_fifo_WrEn <= '0';
        O_cmd_en <= '0';
        O_data_mask <= (others => '0');

        if I_init_calib = '1' then
          if mem_burst_is_active = '0' then 
            mem_burst_index <= (others => '0');
            rw_alternate <= not rw_alternate;
            if (mem_read_priority > mem_write_priority) and (vout_fifo_Almost_Full = '0') then -- Request read from memory
              O_cmd <= '0';
              O_cmd_en <= '1';
              mem_burst_is_active <= '1';
              O_addr <= std_logic_vector(resize(mem_read_pixel_index, O_addr'length));
              if mem_read_pixel_index >= NBR_OF_PIXELS - MEM_BURST_NUM then
                mem_read_pixel_index <= (others => '0');
              else
                mem_read_pixel_index <= mem_read_pixel_index + MEM_BURST_NUM;
              end if;

            elsif (mem_write_priority > mem_read_priority) and (vin_fifo_Almost_Empty = '0') then -- Write what is in vin fifo and request read for next iteration
              vin_fifo_RdEn <= '1';
              if mem_reset_write_block_index = '1' then -- take note of the block index (first WORD of a burst)
                mem_write_block_index <= unsigned(vin_fifo_data_out(MEM_WRITE_BLOCK_INDEX_MSB downto 0));
                mem_reset_write_block_index <= '0';
              else -- write a stream of pixels to fill the block in memory
                O_cmd <= '1';
                O_cmd_en <= '1';
                mem_burst_is_active <= '1';
                O_wr_data <= vin_fifo_data_out;
                O_addr <= std_logic_vector(to_unsigned(
                  (((to_integer(mem_write_block_index) / (H_ACTIVE / BLOCK_SIZE)) * BLOCK_SIZE) + to_integer(mem_write_block_y_pixel_index)) * H_ACTIVE + 
                  (((to_integer(mem_write_block_index) mod (H_ACTIVE / BLOCK_SIZE)) * BLOCK_SIZE) + to_integer(mem_write_block_x_pixel_index)), 
                  O_addr'length
                ));
                
                if mem_write_block_x_pixel_index = BLOCK_SIZE - 1 then
                  mem_write_block_x_pixel_index <= (others => '0');
                  if mem_write_block_y_pixel_index = BLOCK_SIZE - 1 then
                    mem_write_block_y_pixel_index <= (others => '0');
                    mem_reset_write_block_index <= '1';
                  else
                    mem_write_block_y_pixel_index <= mem_write_block_y_pixel_index + 1;
                  end if;
                else
                  mem_write_block_x_pixel_index <= mem_write_block_x_pixel_index + 1;
                end if;
              end if;
            end if; 
          
          else -- if mem_burst_is_active = '1'
            if I_rd_data_valid = '1' then -- Request write to vout fifo
              vout_fifo_WrEn <= '1';
              vout_fifo_data_in <= I_rd_data;
              if mem_burst_index = MEM_BURST_NUM - 1 then
                mem_burst_index <= (others => '0');
                mem_burst_is_active <= '0';
              else
                mem_burst_index <= mem_burst_index + 1;
              end if;
            end if;
          end if; 
        end if;
      end if;
    end if;
  end process;

  process(I_vout_clk)
  begin
    if rising_edge(I_vout_clk) then
      if I_rst = '1' then
        vout_read_low_bits <= '0';
      elsif I_vout_vs_hs(0) = '1' then 
        vout_read_low_bits <= '0'; -- Resync at start of line
      elsif I_vout_de = '1' then
        vout_read_low_bits <= not vout_read_low_bits; 
      end if;
    end if;
  end process;

  vout_fifo_RdEn <= I_vout_de and vout_read_low_bits; 
  O_vout_data <= vout_fifo_data_out(15 downto 0) when vout_read_low_bits = '0' else vout_fifo_data_out(31 downto 16);
  O_vout_vs_hs <= I_vout_vs_hs;
  O_vout_de    <= I_vout_de;
-- process (apb_master_clk)
--  begin
--    if rising_edge(apb_master_clk) then
--      if apb_master_prst = '0' then
--        pixel_write_request <= '0';
--        arbiter_wr_data <= (others =>'0');
--        block_index <= 0;
--        pixel_pair_index <= 0;
--        pixel_pair_memory_index <= 0;
--      else
--        pixel_write_request <= '0';
--        if apb_master_pselX = '1' and apb_master_penable = '1' and apb_master_pwrite = '1' and state = IDLE then
--          if apb_master_paddr(7 downto 0) = APB_PIXEL_VALUE_ADDR then
--            pixel_pair_memory_index <= (block_index * ((BLOCK_SIZE * BLOCK_SIZE) / 2)) + pixel_pair_index;
--            pixel_pair_index <= pixel_pair_index + 1;
--            pixel_write_request <= '1';
--            arbiter_wr_data <= apb_master_pwdata;
--          elsif apb_master_paddr(7 downto 0) = APB_PIXEL_INDEX_ADDR then
--            block_index <= to_integer(unsigned(apb_master_pwdata));
--            pixel_pair_index <= 0;
--          end if;
--        end if;
--      end if;
--    end if;
--  end process;


--  process (apb_master_clk) -- State machine
--  begin
--    if rising_edge(apb_master_clk) then
--      if apb_master_prst = '0' then
--        state <= IDLE;
--      else
--        case state is
--          when IDLE =>
--            arbiter_cmd_en <= '0';
--            if pixel_write_request = '1' then
--              state <= SETUP_PIXEL;
--            end if;
--          when SETUP_PIXEL => 
--            state <= WRITE_PIXEL;
--            arbiter_addr <= std_logic_vector(to_unsigned(pixel_pair_memory_index, 22));
--          when WRITE_PIXEL =>
--            arbiter_cmd_en <= '1';
--            state <= IDLE;
--        end case;
--      end if;
--    end if;
--  end process;
--  apb_master_preadyX <= '1' when (state = IDLE) else '0';

--  hyperram_cmd       <= arbiter_cmd when (state /= IDLE) else framebuffer_cmd;
--  hyperram_cmd_en    <= arbiter_cmd_en when (state /= IDLE) else framebuffer_cmd_en;
--  hyperram_addr      <= arbiter_addr when (state /= IDLE) else framebuffer_addr;
--  hyperram_wr_data   <= arbiter_wr_data when (state /= IDLE) else framebuffer_wr_data;
--  hyperram_data_mask <= arbiter_data_mask when (state /= IDLE) else framebuffer_data_mask;
end architecture structural; 