library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity counter11 is
  Port (
    clk    : IN  STD_LOGIC;
    reset  : IN  STD_LOGIC;
    enable : IN  STD_LOGIC;
    count  : OUT STD_LOGIC_VECTOR(10 DOWNTO 0)
  );
end counter11;

architecture Behavioral of counter11 is
  signal cnt : STD_LOGIC_VECTOR(10 DOWNTO 0) := (others => '0');
begin
  -- output assignment
  count <= cnt;

  process(clk, reset)
  begin
    if reset = '1' then
      cnt <= (others => '0');
    elsif rising_edge(clk) then
      if enable = '1' then
        cnt <= cnt + 1; -- wraps naturally due to vector width
      end if;
    end if;
  end process;

end Behavioral;
