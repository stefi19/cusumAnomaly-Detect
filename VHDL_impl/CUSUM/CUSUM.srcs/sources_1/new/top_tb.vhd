library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity top_tb is
end entity;

architecture tb of top_tb is
  signal clk    : std_logic := '0';
  signal rst    : std_logic := '1';
  signal btn_inc: std_logic := '0';

  signal cat : std_logic_vector(6 downto 0);
  signal an  : std_logic_vector(3 downto 0);
  signal led : std_logic;

  constant CLK_PERIOD : time := 10 ns; -- 100 MHz

  -- temporary storage for decoded digits
  type digit_array is array(0 to 3) of std_logic_vector(3 downto 0);
  signal digits : digit_array := (others => (others => '1'));

  -- helper: decode 7-seg cat pattern to 4-bit nibble (uses same encoding as display_7seg.vhd)
  function cat_to_nibble(c : std_logic_vector(6 downto 0)) return std_logic_vector is
    variable r : std_logic_vector(3 downto 0) := "0000";
  begin
    case c is
      when "1111001" => r := "0001"; -- 1
      when "0100100" => r := "0010"; -- 2
      when "0110000" => r := "0011"; -- 3
      when "0011001" => r := "0100"; -- 4
      when "0010010" => r := "0101"; -- 5
      when "0000010" => r := "0110"; -- 6
      when "1111000" => r := "0111"; -- 7
      when "0000000" => r := "1000"; -- 8
      when "0010000" => r := "1001"; -- 9
      when "1000000" => r := "0000"; -- 0 (others)
      when "1111111" => r := "1111"; -- blank
      when others     => r := "1111"; -- treat unknown as blank
    end case;
    return r;
  end function;

begin
  -- instantiate DUT
  UUT: entity work.top(Behavioral)
    port map(
      btn_inc => btn_inc,
      clk     => clk,
      rst     => rst,
      cat     => cat,
      an      => an,
      led     => led
    );

  -- clock
  clk_proc: process
  begin
    while now < 20 ms loop
      clk <= '0';
      wait for CLK_PERIOD/2;
      clk <= '1';
      wait for CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -- reset then drive button pulses (long pulses for debouncer)
  stim_proc: process
  begin
    -- initial reset
    rst <= '1';
    btn_inc <= '0';
    wait for 200 ns;
    rst <= '0';

    -- wait for system to settle
    wait for 1 us;

    -- generate 16 button presses with long duration to pass the debouncer
    for i in 0 to 15 loop
      -- assert button long enough (100 us)
      btn_inc <= '1';
      wait for 120 us;
      btn_inc <= '0';
      -- wait between presses
      wait for 200 us;
    end loop;

    -- wait some time for pipeline to drain
    wait for 2 ms;
    report "Simulation finished" severity note;
    wait;
  end process;

  -- CSV output file for (time_ns,index,led)
  file out_file : text open write_mode is "top_tb_log.csv";

  -- capture multiplexed 7-seg digits and write CSV lines periodically
  monitor_proc: process(clk)
    variable last_report_time : time := 0 ns;
    variable val : integer := 0;
    variable L : line;
  begin
    if rising_edge(clk) then
      -- detect active digit (an is active-low)
      for idx in 0 to 3 loop
        if an(idx) = '0' then
          digits(idx) <= cat_to_nibble(cat);
        end if;
      end loop;

      -- write header once at time 0
      if last_report_time = 0 ns then
        write(L, string'("time_ns,index,led"));
        writeline(out_file, L);
        last_report_time := 1 ns; -- mark header written
      end if;

      -- write assembled number every 1 ms
      if now - last_report_time >= 1 ms then
        -- assemble numeric value, treat blank ("1111") as omitted
        val := 0;
        for j in 3 downto 0 loop
          if digits(j) = "1111" then
            null;
          else
            val := val * 10 + to_integer(unsigned(digits(j)));
          end if;
        end loop;
        -- write CSV: time (ns), index, led
        write(L, integer'image(integer(now / 1 ns)));
        write(L, string'(","));
        write(L, integer'image(val));
        write(L, string'(","));
        write(L, std_logic'image(led));
        writeline(out_file, L);
        last_report_time := now;
      end if;
    end if;
  end process;

end architecture tb;
