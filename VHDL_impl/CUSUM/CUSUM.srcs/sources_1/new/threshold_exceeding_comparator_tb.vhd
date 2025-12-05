library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity threshold_exceeding_comparator_tb is
end threshold_exceeding_comparator_tb;

architecture Behavioral of threshold_exceeding_comparator_tb is
  signal clk : std_logic := '0';

  -- inputs
  signal s_axis_a_tvalid : std_logic := '0';
  signal s_axis_a_tready : std_logic;
  signal s_axis_a_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  signal s_axis_b_tvalid : std_logic := '0';
  signal s_axis_b_tready : std_logic;
  signal s_axis_b_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  signal s_axis_threshold_tdata : std_logic_vector(31 downto 0) := (others => '0');

  -- outputs
  signal m_axis_result_tvalid : std_logic;
  signal m_axis_result_tready : std_logic := '1';
  signal m_axis_result_tdata  : std_logic;

  signal m_axis_gplus_tvalid  : std_logic;
  signal m_axis_gplus_tready  : std_logic := '1';
  signal m_axis_gplus_tdata   : std_logic_vector(31 downto 0);

  signal m_axis_gminus_tvalid : std_logic;
  signal m_axis_gminus_tready : std_logic := '1';
  signal m_axis_gminus_tdata  : std_logic_vector(31 downto 0);

begin

  -- instantiate DUT
  DUT: entity work.threshold_exceeding_comparator
    port map(
      aclk => clk,
      s_axis_a_tvalid => s_axis_a_tvalid,
      s_axis_a_tready => s_axis_a_tready,
      s_axis_a_tdata  => s_axis_a_tdata,
      s_axis_b_tvalid => s_axis_b_tvalid,
      s_axis_b_tready => s_axis_b_tready,
      s_axis_b_tdata  => s_axis_b_tdata,
      s_axis_threshold_tdata => s_axis_threshold_tdata,
      m_axis_gplus_tvalid  => m_axis_gplus_tvalid,
      m_axis_gplus_tready  => m_axis_gplus_tready,
      m_axis_gplus_tdata   => m_axis_gplus_tdata,
      m_axis_gminus_tvalid => m_axis_gminus_tvalid,
      m_axis_gminus_tready => m_axis_gminus_tready,
      m_axis_gminus_tdata  => m_axis_gminus_tdata,
      m_axis_result_tvalid => m_axis_result_tvalid,
      m_axis_result_tready => m_axis_result_tready,
      m_axis_result_tdata  => m_axis_result_tdata
    );

  -- clock generator
  clk_proc: process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process clk_proc;

  stim: process
  begin
    -- wait for a few cycles
    wait for 20 ns;

    -- TEST 1: neither exceed (a=5, b=3, thresh=10) -> flag=0, gplus=5, gminus=3
    s_axis_a_tdata <= x"00000005";
    s_axis_b_tdata <= x"00000003";
    s_axis_threshold_tdata <= x"0000000A"; -- 10
    s_axis_a_tvalid <= '1';
    s_axis_b_tvalid <= '1';
    wait until s_axis_a_tready = '1' and s_axis_b_tready = '1';
    -- wait for outputs to become valid
    wait until m_axis_result_tvalid = '1' and m_axis_gplus_tvalid = '1' and m_axis_gminus_tvalid = '1';
    assert m_axis_result_tdata = '0' report "TB: TEST1 flag expected 0" severity error;
    assert m_axis_gplus_tdata = x"00000005" report "TB: TEST1 g+ data mismatch" severity error;
    assert m_axis_gminus_tdata = x"00000003" report "TB: TEST1 g- data mismatch" severity error;
    report "TB: TEST1 passed" severity note;
    s_axis_a_tvalid <= '0';
    s_axis_b_tvalid <= '0';
    wait until m_axis_result_tvalid = '0';
    wait for 20 ns;

    -- TEST 2: a exceeds (a=20, b=3, thresh=10) -> flag=1
    s_axis_a_tdata <= x"00000014"; -- 20
    s_axis_b_tdata <= x"00000003";
    s_axis_threshold_tdata <= x"0000000A"; -- 10
    s_axis_a_tvalid <= '1';
    s_axis_b_tvalid <= '1';
    wait until s_axis_a_tready = '1' and s_axis_b_tready = '1';
    wait until m_axis_result_tvalid = '1' and m_axis_gplus_tvalid = '1' and m_axis_gminus_tvalid = '1';
    assert m_axis_result_tdata = '1' report "TB: TEST2 flag expected 1" severity error;
    assert m_axis_gplus_tdata = x"00000014" report "TB: TEST2 g+ data mismatch" severity error;
    assert m_axis_gminus_tdata = x"00000003" report "TB: TEST2 g- data mismatch" severity error;
    report "TB: TEST2 passed" severity note;
    s_axis_a_tvalid <= '0';
    s_axis_b_tvalid <= '0';
    wait until m_axis_result_tvalid = '0';
    wait for 20 ns;

    -- TEST 3: b exceeds (a=5, b=50, thresh=10) -> flag=1
    s_axis_a_tdata <= x"00000005";
    s_axis_b_tdata <= x"00000032"; -- 50
    s_axis_threshold_tdata <= x"0000000A"; -- 10
    s_axis_a_tvalid <= '1';
    s_axis_b_tvalid <= '1';
    wait until s_axis_a_tready = '1' and s_axis_b_tready = '1';
    wait until m_axis_result_tvalid = '1' and m_axis_gplus_tvalid = '1' and m_axis_gminus_tvalid = '1';
    assert m_axis_result_tdata = '1' report "TB: TEST3 flag expected 1" severity error;
    assert m_axis_gplus_tdata = x"00000005" report "TB: TEST3 g+ data mismatch" severity error;
    assert m_axis_gminus_tdata = x"00000032" report "TB: TEST3 g- data mismatch" severity error;
    report "TB: TEST3 passed" severity note;
    s_axis_a_tvalid <= '0';
    s_axis_b_tvalid <= '0';
    wait until m_axis_result_tvalid = '0';
    wait for 20 ns;

    -- TEST 4: equal to threshold (a=10,b=9,th=10) -> flag=0 (because we use >)
    s_axis_a_tdata <= x"0000000A";
    s_axis_b_tdata <= x"00000009";
    s_axis_threshold_tdata <= x"0000000A";
    s_axis_a_tvalid <= '1';
    s_axis_b_tvalid <= '1';
    wait until s_axis_a_tready = '1' and s_axis_b_tready = '1';
    wait until m_axis_result_tvalid = '1' and m_axis_gplus_tvalid = '1' and m_axis_gminus_tvalid = '1';
    assert m_axis_result_tdata = '0' report "TB: TEST4 flag expected 0" severity error;
    report "TB: TEST4 passed" severity note;
    s_axis_a_tvalid <= '0';
    s_axis_b_tvalid <= '0';

    wait for 50 ns;
    report "All comparator tests completed" severity note;
    wait;
  end process stim;

end Behavioral;
