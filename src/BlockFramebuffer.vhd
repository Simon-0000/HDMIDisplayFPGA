library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BlockFramebuffer is
  generic(
    BLOCK_SIZE: positive := 32; -- in words so 32 means 32 * 2 pixels because 1 word = 2 pixels
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
    I_vin_data: in std_logic_vector(31 downto 0); 

    I_vout_clk: in std_logic;
    I_vout_vs_hs: in std_logic_vector(1 downto 0);
    I_vout_de: in std_logic;
    O_vout_vs_hs: out std_logic_vector(1 downto 0);
    O_vout_de: out std_logic;
    O_vout_data: out std_logic_vector(15 downto 0);
    O_vin_fifo_full: out std_logic;
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

type mem_state_type is (RW_DECISION, READ_BURST, PRE_WRITE_BURST, WRITE_BURST);
signal mem_state : mem_state_type := RW_DECISION;
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

constant NBR_OF_WORDS : positive := H_ACTIVE * V_ACTIVE / 2;
constant WORDS_PER_BLOCK : positive := BLOCK_SIZE * BLOCK_SIZE;
constant NBR_OF_BLOCKS : positive := NBR_OF_WORDS / WORDS_PER_BLOCK;
constant MEM_READ_WORD_INDEX_MSB : natural := clog2(NBR_OF_WORDS) - 1;
constant MEM_WRITE_BLOCK_INDEX_MSB : natural := clog2(NBR_OF_BLOCKS) - 1;
constant MEM_WRITE_BLOCK_PIXEL_INDEX_MSB : natural := clog2(BLOCK_SIZE) - 1;
constant MEM_BURST_INDEX_MSB : natural := clog2(MEM_BURST_NUM) - 1;

signal mem_read_word_index : unsigned(MEM_READ_WORD_INDEX_MSB downto 0) := (others => '0');
signal mem_reset_write_block_index : std_logic := '1';
signal mem_write_block_y_pixel_index : unsigned(MEM_WRITE_BLOCK_PIXEL_INDEX_MSB downto 0) := (others => '0');
signal mem_write_addr : unsigned(21 downto 0) := (others => '0');
signal mem_burst_index : unsigned(MEM_BURST_INDEX_MSB downto 0) := (others => '0');

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

  O_vin_fifo_full <= vin_fifo_Full;
  O_vout_fifo_empty <= vout_fifo_Empty;
  
  mem_read_priority(0) <= not(rw_alternate);
  mem_write_priority(0) <= rw_alternate;
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
        mem_read_word_index <= (others => '0');
        mem_write_addr <= (others=> '0');
        mem_write_block_y_pixel_index <= (others => '0');
        mem_reset_write_block_index <= '1';
        mem_burst_index <= (others => '0');
        O_data_mask <= (others => '0');
        mem_state <= RW_DECISION;
      else
        vin_fifo_RdEn <= '0';
        vout_fifo_WrEn <= '0';
        O_cmd_en <= '0';
        O_data_mask <= (others => '0');

        if I_init_calib = '1' then
          if mem_state = RW_DECISION then 
            rw_alternate <= not rw_alternate;
            if (mem_read_priority > mem_write_priority) and (vout_fifo_Almost_Full = '0') then
              mem_state <= READ_BURST;
              O_cmd <= '0';
              O_cmd_en <= '1';
              O_addr <= std_logic_vector(resize(mem_read_word_index * 4, O_addr'length));
              if mem_read_word_index >= NBR_OF_WORDS - MEM_BURST_NUM then
                mem_read_word_index <= (others => '0');
              else
                mem_read_word_index <= mem_read_word_index + MEM_BURST_NUM;
              end if;

            elsif (mem_write_priority > mem_read_priority) and (vin_fifo_Almost_Empty = '0') then 
              if mem_reset_write_block_index = '1' then 
                mem_reset_write_block_index <= '0';
                mem_write_addr <= unsigned(vin_fifo_data_out(21 downto 0));
                vin_fifo_RdEn <= '1';
                mem_state <= PRE_WRITE_BURST;
              else
                mem_state <= PRE_WRITE_BURST;
              end if;
            end if;  
            
          elsif mem_state = PRE_WRITE_BURST then
            vin_fifo_RdEn <= '0'; 
            mem_state <= WRITE_BURST;

          elsif mem_state = READ_BURST then
            if I_rd_data_valid = '1' then 
              vout_fifo_WrEn <= '1';
              vout_fifo_data_in <= I_rd_data;
              if mem_burst_index = MEM_BURST_NUM - 1 then
                mem_burst_index <= (others => '0');
                mem_state <= RW_DECISION;
              else
                mem_burst_index <= mem_burst_index + 1;
              end if;
            end if;
            
          elsif mem_state = WRITE_BURST then
            if mem_burst_index = 0 then
              O_cmd <= '1';
              O_cmd_en <= '1';
              O_addr <= std_logic_vector(resize(mem_write_addr * 4, O_addr'length));
            end if;
            
            O_wr_data <= vin_fifo_data_out;
            O_data_mask <= (others => '0'); 
            vin_fifo_RdEn <= '1'; 
            
            if mem_burst_index = MEM_BURST_NUM - 1 then
              mem_burst_index <= (others => '0');
              mem_write_addr <= mem_write_addr + (H_ACTIVE / 2);
              mem_state <= RW_DECISION;
              if mem_write_block_y_pixel_index = BLOCK_SIZE - 1 then
                mem_write_block_y_pixel_index <= (others => '0');
                mem_reset_write_block_index <= '1';
              else
                mem_write_block_y_pixel_index <= mem_write_block_y_pixel_index + 1;
              end if;
            else
              mem_burst_index <= mem_burst_index + 1;
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
      elsif I_vout_de = '0' then 
        vout_read_low_bits <= '0';
      else
        vout_read_low_bits <= not vout_read_low_bits; 
      end if;
    end if;
  end process;

  vout_fifo_RdEn <= I_vout_de and vout_read_low_bits; 
  
  process(I_vout_clk)
  begin
    if rising_edge(I_vout_clk) then
      if vout_read_low_bits = '0' then
        O_vout_data <= vout_fifo_data_out(15 downto 0);
      else
        O_vout_data <= vout_fifo_data_out(31 downto 16);
      end if;
      O_vout_vs_hs <= I_vout_vs_hs;
      O_vout_de    <= I_vout_de;
    end if;
  end process;

end architecture structural;