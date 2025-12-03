library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity subtractor_tb is
end subtractor_tb;

architecture Behavioral of subtractor_tb is
  signal clk : std_logic := '0';

  signal s_axis_a_tvalid : std_logic := '0';
  signal s_axis_a_tready : std_logic := '0';
  signal s_axis_a_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  signal s_axis_b_tvalid : std_logic := '0';
  signal s_axis_b_tready : std_logic := '0';
  signal s_axis_b_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  signal m_axis_result_tvalid : std_logic := '0';
  signal m_axis_result_tready : std_logic := '0';
  signal m_axis_result_tdata  : std_logic_vector(31 downto 0) := (others => '0');
begin

  -- Instantiate DUT
  uut: entity work.subtractor(Behavioral)
    port map(
      aclk => clk,
      s_axis_a_tvalid => s_axis_a_tvalid,
      s_axis_a_tready => s_axis_a_tready,
      s_axis_a_tdata  => s_axis_a_tdata,
      s_axis_b_tvalid => s_axis_b_tvalid,
      s_axis_b_tready => s_axis_b_tready,
      s_axis_b_tdata  => s_axis_b_tdata,
      m_axis_result_tvalid => m_axis_result_tvalid,
      m_axis_result_tready => m_axis_result_tready,
      m_axis_result_tdata  => m_axis_result_tdata
    );

  -- Clock
  clk_gen: process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process clk_gen;

  stim: process
    variable expected : std_logic_vector(31 downto 0);
  begin
    -- give DUT time to initialize
    wait for 20 ns;
    m_axis_result_tready <= '1';

    -- Test 1: 0 - 0 = 0
    s_axis_a_tdata <= x"00000000";
    s_axis_b_tdata <= x"00000000";
    s_axis_a_tvalid <= '1';
    s_axis_b_tvalid <= '1';
    wait until s_axis_a_tready = '1' and s_axis_b_tready = '1';
    wait until m_axis_result_tvalid = '1';
    expected := x"00000000";
    assert m_axis_result_tdata = expected
      report "Subtractor TB: test1 failed (0-0)" severity error;
    report "Subtractor TB: test1 passed (0-0)" severity note;
    s_axis_a_tvalid <= '0';
    s_axis_b_tvalid <= '0';
    wait until m_axis_result_tvalid = '0';
    wait for 20 ns;

    -- Test 2: 5 - 0 = 5
    s_axis_a_tdata <= x"00000005";
    s_axis_b_tdata <= x"00000000";
    s_axis_a_tvalid <= '1';
    s_axis_b_tvalid <= '1';
    wait until s_axis_a_tready = '1' and s_axis_b_tready = '1';
    wait until m_axis_result_tvalid = '1';
    expected := x"00000005";
    assert m_axis_result_tdata = expected
      report "Subtractor TB: test2 failed (5-0)" severity error;
    report "Subtractor TB: test2 passed (5-0)" severity note;
    s_axis_a_tvalid <= '0';
    s_axis_b_tvalid <= '0';
    wait until m_axis_result_tvalid = '0';
    wait for 20 ns;

    -- Test 3: 7 - 7 = 0 (same-number test)
    s_axis_a_tdata <= x"00000007";
    s_axis_b_tdata <= x"00000007";
    s_axis_a_tvalid <= '1';
    s_axis_b_tvalid <= '1';
    wait until s_axis_a_tready = '1' and s_axis_b_tready = '1';
    wait until m_axis_result_tvalid = '1';
    expected := x"00000000";
    assert m_axis_result_tdata = expected
      report "Subtractor TB: test3 failed (7-7)" severity error;
    report "Subtractor TB: test3 passed (7-7)" severity note;
    s_axis_a_tvalid <= '0';
    s_axis_b_tvalid <= '0';

    wait for 50 ns;
    report "Subtractor TB: all tests completed" severity note;
    wait;
  end process stim;

end Behavioral;
