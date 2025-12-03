library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity broadcaster_tb is
end broadcaster_tb;

architecture Behavioral of broadcaster_tb is
  signal clk : std_logic := '0';

  -- inputs
  signal s_axis_tvalid : std_logic := '0';
  signal s_axis_tready : std_logic;
  signal s_axis_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  -- outputs
  signal m_axis_a1_tvalid : std_logic;
  signal m_axis_a1_tready : std_logic := '1';
  signal m_axis_a1_tdata  : std_logic_vector(31 downto 0);

  signal m_axis_a2_tvalid : std_logic;
  signal m_axis_a2_tready : std_logic := '1';
  signal m_axis_a2_tdata  : std_logic_vector(31 downto 0);

begin

  uut: entity work.broadcaster(Behavioral)
    port map(
      aclk => clk,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready,
      s_axis_tdata  => s_axis_tdata,
      m_axis_a1_tvalid => m_axis_a1_tvalid,
      m_axis_a1_tready => m_axis_a1_tready,
      m_axis_a1_tdata  => m_axis_a1_tdata,
      m_axis_a2_tvalid => m_axis_a2_tvalid,
      m_axis_a2_tready => m_axis_a2_tready,
      m_axis_a2_tdata  => m_axis_a2_tdata
    );

  -- clock
  clk_proc: process
  begin
    clk <= '0'; wait for 5 ns;
    clk <= '1'; wait for 5 ns;
  end process clk_proc;

  stim: process
  begin
    wait for 20 ns;

    -- TEST 1: both downstream ready immediately
    s_axis_tdata <= x"000000AA";
    s_axis_tvalid <= '1';
    wait until s_axis_tready = '1';
    -- once accepted, wait for outputs valid
    wait until m_axis_a1_tvalid = '1' and m_axis_a2_tvalid = '1';
    -- both should present the same data
    assert m_axis_a1_tdata = x"000000AA" report "TB: TEST1 a1 data mismatch" severity error;
    assert m_axis_a2_tdata = x"000000AA" report "TB: TEST1 a2 data mismatch" severity error;
    report "TB: TEST1 passed" severity note;
    s_axis_tvalid <= '0';
    wait until m_axis_a1_tvalid = '0' and m_axis_a2_tvalid = '0';
    wait for 20 ns;

    -- TEST 2: a1 not ready initially, a2 ready
    m_axis_a1_tready <= '0';
    m_axis_a2_tready <= '1';
    s_axis_tdata <= x"00000055";
    s_axis_tvalid <= '1';
    wait until s_axis_tready = '1';
    -- outputs will assert valid
    wait until m_axis_a1_tvalid = '1' and m_axis_a2_tvalid = '1';
    -- a2 should be able to accept immediately
    assert m_axis_a2_tdata = x"00000055" report "TB: TEST2 a2 data mismatch" severity error;
    -- a1 should be waiting (not accepted yet)
    assert m_axis_a1_tvalid = '1' report "TB: TEST2 a1 valid expected" severity error;
    report "TB: TEST2 pre-accept checks passed" severity note;
    -- now allow a1 to accept
    wait for 20 ns;
    m_axis_a1_tready <= '1';
    -- wait for acceptance
    wait until m_axis_a1_tvalid = '0' and m_axis_a2_tvalid = '0';
    s_axis_tvalid <= '0';
    report "TB: TEST2 passed" severity note;
    wait for 20 ns;

    -- TEST 3: toggle readiness (a1 toggles), ensure acceptance only when ready
    m_axis_a1_tready <= '0';
    m_axis_a2_tready <= '0';
    s_axis_tdata <= x"000000FF";
    s_axis_tvalid <= '1';
    wait until s_axis_tready = '1';
    wait until m_axis_a1_tvalid = '1' and m_axis_a2_tvalid = '1';
    -- toggle a1 ready after a few cycles
    wait for 30 ns;
    m_axis_a1_tready <= '1';
    wait for 10 ns;
    m_axis_a2_tready <= '1';
    -- wait for both to accept
    wait until m_axis_a1_tvalid = '0' and m_axis_a2_tvalid = '0';
    s_axis_tvalid <= '0';
    report "TB: TEST3 passed" severity note;

    wait for 50 ns;
    report "Broadcaster TB completed" severity note;
    wait;
  end process stim;

end Behavioral;
