library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity cusum_only_tb is
end entity;

architecture tb of cusum_only_tb is
  -- clock & reset
  signal aclk : std_logic := '0';
  signal reset: std_logic := '1';

  -- AXIS inputs to DUT
  signal s_axis_a_tvalid : std_logic := '0';
  signal s_axis_a_tready : std_logic;
  signal s_axis_a_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  signal s_axis_b_tvalid : std_logic := '0';
  signal s_axis_b_tready : std_logic;
  signal s_axis_b_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  -- comparator/drift/threshold
  signal s_axis_drift_tdata : std_logic_vector(31 downto 0) := (others => '0');
  signal s_axis_threshold_tdata : std_logic_vector(31 downto 0) := x"000000C8"; -- 200

  -- label output from DUT
  signal m_axis_label_tvalid : std_logic;
  signal m_axis_label_tready : std_logic := '1';
  signal m_axis_label_tdata  : std_logic;

  constant CLK_PERIOD : time := 10 ns;

  -- sample arrays (hardcoded pairs prev & curr)
  type int_arr is array(natural range <>) of integer;
  constant PREV_SAMPLES : int_arr := (
    300,305,310,315,320,325,330,335,340,345,350,355,360,365,370,375,380,385,390,395
  );
  constant CURR_SAMPLES : int_arr := (
    300,305,310,315,320,325,560,335,340,345,350,355,580,365,370,375,380,385,600,395
  );

  constant N_SAMPLES : natural := PREV_SAMPLES'length;

  -- CSV log (write to the sources_1/new folder so it's easy to find)
  file out_file : text open write_mode is "d:/Facultate/Year3/Sem1/SCS/Assignament 5/cusumAnomaly-Detect/VHDL_impl/CUSUM/CUSUM.srcs/sources_1/new/cusum_only_log.csv";

begin

  -- Instantiate DUT
  UUT: entity work.cusum_top(Behavioral)
    port map(
      aclk => aclk,
      reset => reset,
      s_axis_a_tvalid => s_axis_a_tvalid,
      s_axis_a_tready => s_axis_a_tready,
      s_axis_a_tdata  => s_axis_a_tdata,
      s_axis_b_tvalid => s_axis_b_tvalid,
      s_axis_b_tready => s_axis_b_tready,
      s_axis_b_tdata  => s_axis_b_tdata,
      m_axis_label_tvalid => m_axis_label_tvalid,
      m_axis_label_tready => m_axis_label_tready,
      m_axis_label_tdata  => m_axis_label_tdata,
      s_axis_drift_tdata => s_axis_drift_tdata,
      s_axis_threshold_tdata => s_axis_threshold_tdata
    );

  -- clock process
  clk_proc: process
  begin
    while now < 50 ms loop
      aclk <= '0';
      wait for CLK_PERIOD/2;
      aclk <= '1';
      wait for CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -- stimulus: reset then feed samples
  stim_proc: process
    variable L : line;
    variable deadline : time;
  begin
    -- reset
    reset <= '1';
    wait for 100 ns;
    reset <= '0';
    wait for 200 ns;

    -- header
    write(L, string'("sample_idx,time_ns,label"));
    writeline(out_file, L);
    report "Wrote CSV header to cusum_only_log.csv" severity note;

    for i in 0 to integer(N_SAMPLES)-1 loop
      -- load data
      s_axis_a_tdata <= std_logic_vector(to_unsigned(PREV_SAMPLES(i),32));
      s_axis_b_tdata <= std_logic_vector(to_unsigned(CURR_SAMPLES(i),32));

      -- assert both valids
      s_axis_a_tvalid <= '1';
      s_axis_b_tvalid <= '1';

            -- wait for both ready (with timeout)
            wait until (s_axis_a_tready = '1' and s_axis_b_tready = '1') or now > 40 ms;

            -- deassert valids
            s_axis_a_tvalid <= '0';
            s_axis_b_tvalid <= '0';

            -- report accepted inputs when both consumer-ready were seen
            report "Driver: accepted sample " & integer'image(i) &
              " a=" & integer'image(to_integer(signed(s_axis_a_tdata))) &
              " b=" & integer'image(to_integer(signed(s_axis_b_tdata))) severity note;

            -- wait for label result: wait until DUT asserts label or timeout
            -- lengthened timeout to reduce spurious misses on slow cycles
            deadline := now + 10 us;
            wait until (m_axis_label_tvalid = '1' and m_axis_label_tready = '1') or now > deadline;

      -- log current label state (if valid then use it, else log 0)
      write(L, integer'image(i));
      write(L, string'(","));
      write(L, integer'image(integer(now / 1 ns)));
      write(L, string'(","));
      if m_axis_label_tvalid = '1' then
        write(L, std_logic'image(m_axis_label_tdata));
      else
        write(L, string'("'0'"));
      end if;
      writeline(out_file, L);
      if m_axis_label_tvalid = '1' then
        report "Wrote CSV: idx=" & integer'image(i) & " time_ns=" & integer'image(integer(now / 1 ns)) & " label=" & std_logic'image(m_axis_label_tdata) severity note;
      else
        report "Wrote CSV: idx=" & integer'image(i) & " time_ns=" & integer'image(integer(now / 1 ns)) & " label=0" severity warning;
      end if;

      -- short gap between samples (shortened so simulation progresses faster)
      wait for 100 ns;
    end loop;

    report "CUSUM-only TB finished" severity note;
    wait;
  end process;

  -- monitor: report when label is produced
  monitor_proc: process(aclk)
  begin
    if rising_edge(aclk) then
      if m_axis_label_tvalid = '1' and m_axis_label_tready = '1' then
        report "Label produced: " & std_logic'image(m_axis_label_tdata) severity note;
      end if;
    end if;
  end process;

end architecture tb;
