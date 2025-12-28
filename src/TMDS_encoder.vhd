library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--variable names and the state machine comes from the DVI specs, page 29: https://glenwing.github.io/docs/DVI-1.0.pdf
entity TMDS_encoder is 
  port(
    clk : in std_logic;
    reset : in std_logic;
    D : in std_logic_vector(7 downto 0);
    C1_C0 : in std_logic_vector(1 downto 0);
    DE : in std_logic;
    q_out : out std_logic_vector(9 downto 0)
  );
end TMDS_encoder;

architecture TMDS_encoder_arch of TMDS_encoder is
  signal Cnt : integer range -32 to 31 := 0; --disparity

  function getNbrOfOnes(data: std_logic_vector) return natural is 
  variable count : natural := 0;
  begin
  for i in data'range loop
    if data(i) = '1' then
      count := count + 1;
    end if;
  end loop;
  return count;
  end function;

begin
  process(clk)
  variable q_m : std_logic_vector(9 downto 0);
  variable N_1_D : natural range 0 to 8 := 0;
  variable N_1_q_m : natural range 0 to 8 := 0;

  begin
    if rising_edge(clk) then
      if reset = '1' then 
        Cnt <= 0;
        q_out <= (others => '0');
      else
        N_1_D := getNbrOfOnes(D);
        if N_1_D > 4 OR (N_1_D = 4 AND D(0) = '0') then 
          --XNOR branch
          q_m(0) := D(0);
          for i in 1 to 7 loop
            q_m(i) := q_m(i-1) XNOR D(i);
          end loop;
          q_m(8) := '0';
        else 
          --XOR branch
          q_m(0) := D(0);
          for i in 1 to 7 loop
            q_m(i) := q_m(i-1) XOR D(i);
          end loop;
          q_m(8) := '1';
        end if;

        if DE = '1' then
          --Drawing Period
          N_1_q_m := getNbrOfOnes(q_m(7 downto 0));
          q_out(8) <= q_m(8);

          if Cnt = 0 OR N_1_q_m = 4 then
            q_out(9) <= not(q_m(8));
            if q_m(8) = '1' then
              q_out(7 downto 0) <= q_m(7 downto 0);
              Cnt <= Cnt + N_1_q_m - (8-N_1_q_m); 
            else
              q_out(7 downto 0) <= not(q_m(7 downto 0));
              Cnt <= Cnt + (8-N_1_q_m) - N_1_q_m; 
            end if;
          else
            if (Cnt > 0 AND N_1_q_m > 4) OR (Cnt < 0 AND N_1_q_m < 4) then
              q_out(9) <= '1';
              q_out(7 downto 0) <= not(q_m(7 downto 0));
              if q_m(8) = '1' then
                Cnt <= Cnt + 2 + (8-N_1_q_m) - N_1_q_m;
              else
                Cnt <= Cnt + (8-N_1_q_m) - N_1_q_m;
              end if;
            else
              q_out(9) <= '0';
              q_out(7 downto 0) <= q_m(7 downto 0);
              if q_m(8) = '0' then 
                  Cnt <= Cnt - 2 + N_1_q_m - (8-N_1_q_m);
              else
                  Cnt <= Cnt + N_1_q_m - (8-N_1_q_m);
              end if;
            end if;
          end if;
        else
          --Blanking period
          Cnt <= 0;
          case C1_C0 is 
            when "00" => q_out <= "1101010100";
            when "01" => q_out <= "0010101011";
            when "10" => q_out <= "0101010100";
            when "11" => q_out <= "1010101011";
            when others => q_out <= "1101010100";
          end case;
        end if;
      end if;
    end if;
  end process;

end TMDS_encoder_arch;