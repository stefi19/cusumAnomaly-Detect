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
    -- active-low reset for AXI-style components (optional)
    aresetn   : IN  STD_LOGIC := '1';
    btn_inc   : IN  STD_LOGIC;  -- external button / increment signal (raw)
    -- AXI4-Stream master interface (when stream_en = '1' the ROM will
    -- continuously present data and advance on m_axis_tready handshakes)
    stream_en : IN  STD_LOGIC := '0';
    m_axis_tvalid : OUT STD_LOGIC; -- AXI-Stream valid from ROM
    m_axis_tready : IN  STD_LOGIC; -- AXI-Stream ready from downstream
    m_axis_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- legacy outputs kept for compatibility
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
  signal m_tv       : std_logic := '0';

  -- Note: for this behavioral ROM model we derive values deterministically from the address
  -- (xt = zero-extended address). Replace the value generation with an initialized memory
  -- if you want arbitrary ROM contents (can be loaded from a file in elaboration).
  function word_for_addr(a : unsigned) return std_logic_vector is
  begin
    return std_logic_vector(resize(a, 32)); -- zero-extend the 11-bit address into 32 bits
  end function;

begin
  -- Synchronize button to clock domain and detect rising edge.
  -- Address can be advanced either by the external button (`btn_inc`) or by
  -- the AXI-Stream handshake when `stream_en = '1'`.
  process(aclk)
  begin
    if rising_edge(aclk) then
      -- synchronize button
      btn_sync0 <= btn_inc;
      btn_sync1 <= btn_sync0;
      btn_prev  <= btn_sync1;

      -- reset behaviour
      if aresetn = '0' then
        addr_reg <= (others => '0');
        m_tv <= '0';
      else
        -- stream mode: present data and advance on handshake
        if stream_en = '1' then
          m_tv <= '1';
          -- advance when downstream accepts (valid && ready)
          if m_tv = '1' and m_axis_tready = '1' then
            if addr_reg = to_unsigned(2047, addr_reg'length) then
              addr_reg <= (others => '0');
            else
              addr_reg <= addr_reg + 1;
            end if;
          end if;
        else
          -- not streaming: produce single-step on button rising edge
          m_tv <= '0';
          if (btn_prev = '0') and (btn_sync1 = '1') then
            if addr_reg = to_unsigned(2047, addr_reg'length) then
              addr_reg <= (others => '0');
            else
              addr_reg <= addr_reg + 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- AXI-Stream outputs
  m_axis_tdata  <= word_for_addr(addr_reg);
  m_axis_tvalid <= m_tv;

  -- legacy outputs
  xt <= word_for_addr(addr_reg);
  xt_minus1 <= word_for_addr((addr_reg - 1) mod 2048);

end Behavioral;
