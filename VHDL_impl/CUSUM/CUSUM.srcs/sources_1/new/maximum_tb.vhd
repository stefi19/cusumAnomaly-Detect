library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity maximum_tb is
end maximum_tb;

architecture tb of maximum_tb is
  constant CLK_PERIOD : time := 20 ns;

  signal aclk : std_logic := '0';

  -- DUT signals
  signal s_axis_a_tvalid : std_logic := '0';
  signal s_axis_a_tready : std_logic;
  signal s_axis_a_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  signal m_axis_result_tvalid : std_logic;
  signal m_axis_result_tready : std_logic := '1';
  signal m_axis_result_tdata  : std_logic_vector(31 downto 0);

begin
  -- clock
  aclk <= not aclk after CLK_PERIOD/2;

  -- instantiate DUT
  UUT: entity work.maximum
    port map(
      aclk => aclk,
      s_axis_a_tvalid => s_axis_a_tvalid,
      s_axis_a_tready => s_axis_a_tready,
      s_axis_a_tdata  => s_axis_a_tdata,
      m_axis_result_tvalid => m_axis_result_tvalid,
      m_axis_result_tready => m_axis_result_tready,
      m_axis_result_tdata  => m_axis_result_tdata
    );

  stim_proc: process
    -- test vectors: record + array (proper VHDL syntax)
    type tv_t is record
      indata  : std_logic_vector(31 downto 0);
      expected: std_logic_vector(31 downto 0);
    end record;

    type tv_array is array(0 to 4) of tv_t;

    constant tests : tv_array := (
      0 => (indata => std_logic_vector(to_signed(-1, 32)), expected => std_logic_vector(to_signed(0,32))), -- -1 -> 0
      1 => (indata => std_logic_vector(to_signed(5, 32)), expected => std_logic_vector(to_signed(5,32))), -- 5 -> 5
      2 => (indata => std_logic_vector(to_signed(0, 32)), expected => std_logic_vector(to_signed(0,32))), -- 0 -> 0
      3 => (indata => std_logic_vector(to_signed(-100, 32)), expected => std_logic_vector(to_signed(0,32))), -- negative -> 0
      4 => (indata => std_logic_vector(to_signed(2147483647, 32)), expected => std_logic_vector(to_signed(2147483647,32)))  -- large positive -> same
    );

  begin
    wait for 50 ns; -- allow time to settle

    for idx in tests'range loop
      s_axis_a_tdata <= tests(idx).indata;
      s_axis_a_tvalid <= '1';

      -- wait until DUT asserts ready on rising edge
      wait until rising_edge(aclk) and s_axis_a_tready = '1';
      s_axis_a_tvalid <= '0';

      -- wait for DUT to present valid result
      wait until m_axis_result_tvalid = '1';

      -- check result (simple assert, no hex formatting helpers used)
      assert m_axis_result_tdata = tests(idx).expected
        report "maximum_tb: test " & integer'image(idx) & " failed" severity error;

      report "maximum_tb: test " & integer'image(idx) & " passed" severity note;

      -- wait for DUT to drop valid (consumer ready = '1' so it should)
      wait until m_axis_result_tvalid = '0';
      wait for 2 * CLK_PERIOD;
    end loop;

    report "All maximum tests completed" severity note;
    wait;
  end process;

end tb;
