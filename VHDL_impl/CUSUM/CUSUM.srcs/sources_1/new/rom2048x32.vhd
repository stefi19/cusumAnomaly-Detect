library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- rom2048x32.vhd
-- Simple dual-read ROM model (2048 x 32-bit)
-- Provides xt = ROM[addr] and xt_minus1 = ROM[addr-1] (wrap-around)
-- Address is advanced by a button/enable input (edge-detected).

entity rom2048x32 is
  Port (
    aclk      : IN  STD_LOGIC;
    btn_inc   : IN  STD_LOGIC;  -- external button / increment signal (raw)
    xt        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- ROM[addr]
    xt_minus1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)  -- ROM[addr-1]
  );
end rom2048x32;

architecture Behavioral of rom2048x32 is
  -- address register (11 bits for 2048 locations)
  signal addr_reg   : unsigned(10 downto 0) := (others => '0');
  signal btn_sync0  : std_logic := '0';
  signal btn_sync1  : std_logic := '0';
  signal btn_prev   : std_logic := '0';

  -- Note: for this behavioral ROM model we derive values deterministically from the address
  -- (xt = zero-extended address). Replace the value generation with an initialized memory
  -- if you want arbitrary ROM contents (can be loaded from a file in elaboration).
  function word_for_addr(a : unsigned) return std_logic_vector is
  begin
    return std_logic_vector(resize(a, 32)); -- zero-extend the 11-bit address into 32 bits
  end function;

begin
  -- Synchronize button to clock domain and detect rising edge
  process(aclk)
  begin
    if rising_edge(aclk) then
      btn_sync0 <= btn_inc;
      btn_sync1 <= btn_sync0;
      btn_prev  <= btn_sync1;
      -- on rising edge of synchronized button, increment address
      if (btn_prev = '0') and (btn_sync1 = '1') then
        if addr_reg = to_unsigned(2047, addr_reg'length) then
          addr_reg <= (others => '0');
        else
          addr_reg <= addr_reg + 1;
        end if;
      end if;
    end if;
  end process;
  -- outputs
  xt <= word_for_addr(addr_reg);
  -- compute previous address with wrap-around
  xt_minus1 <= word_for_addr((addr_reg - 1) mod 2048);

end Behavioral;
