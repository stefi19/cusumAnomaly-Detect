library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity broadcaster is
  Port (
    aclk             : in  std_logic;

    s_axis_tvalid    : in  std_logic;
    s_axis_tready    : out std_logic;
    s_axis_tdata     : in  std_logic_vector(31 downto 0);

    m_axis_a1_tvalid : out std_logic;
    m_axis_a1_tready : in  std_logic;
    m_axis_a1_tdata  : out std_logic_vector(31 downto 0);

    m_axis_a2_tvalid : out std_logic;
    m_axis_a2_tready : in  std_logic;
    m_axis_a2_tdata  : out std_logic_vector(31 downto 0)
  );
end broadcaster;

architecture Behavioral of broadcaster is
  type state_type is (S_READ, S_WAIT_CONSUME);
  signal s : state_type := S_READ;

  -- ✅ semnal intern care ține datele broadcastate
  signal data_reg : std_logic_vector(31 downto 0) := (others => '0');

  -- ✅ handshake intern ready acceptabil pentru citire internă
  signal axis_accept_int : std_logic := '0';

  -- ✅ valid intern: ridicat când avem date de livrat, resetat când sunt consumate
  signal out_valid_int : std_logic := '0';
  signal a1_done_int  : std_logic := '0';
  signal a2_done_int  : std_logic := '0';
begin
  ---------------------------------------------------------------------------
  -- READY inbound: acceptăm DOAR în S_READ state
  ---------------------------------------------------------------------------
  axis_accept_int <= '1' when s = S_READ else '0';
  s_axis_tready   <= axis_accept_int;

  -- ridicăm valid intern doar când intrăm în broadcast stage
  m_axis_a1_tvalid <= out_valid_int when a1_done_int = '0' else '0';
  m_axis_a2_tvalid <= out_valid_int when a2_done_int = '0' else '0';

  ---------------------------------------------------------------------------
  -- Broadcast data: porturile doar reflectă intern reg
  ---------------------------------------------------------------------------
  m_axis_a1_tdata <= data_reg;
  m_axis_a2_tdata <= data_reg;

  ---------------------------------------------------------------------------
  -- STATE MACHINE
  ---------------------------------------------------------------------------
  process(aclk)
  begin
    if rising_edge(aclk) then
      case s is

        when S_READ =>
          if s_axis_tvalid = '1' and axis_accept_int = '1' then
            data_reg <= s_axis_tdata;
            out_valid_int <= '1';  -- start broadcast (intern)
            a1_done_int  <= '0';
            a1_done_int  <= '0';
            s <= S_WAIT_CONSUME;
          end if;

        when S_WAIT_CONSUME =>
          -- nu citim din porturile OUT, ci doar feedback-ul extern ready
          if out_valid_int = '1' then
            if m_axis_a1_tready = '1' and a1_done_int = '0' then
              a1_done_int <= '1';
            end if;
            if m_axis_a2_tready = '1' and a2_done_int = '0' then
              a2_done_int <= '1';
            end if;
          end if;

          -- când ambele outputs au consumat intern broadcast valid -> revenim la read
          if a1_done_int = '1' and a2_done_int = '1' then
            out_valid_int <= '0';      -- oprim broadcast stage (intern)
            s <= S_READ;
          end if;

      end case;
    end if;
  end process;

end Behavioral;
