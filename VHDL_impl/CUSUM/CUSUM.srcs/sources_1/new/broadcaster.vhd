library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity broadcaster is
  Port (
    aclk : IN STD_LOGIC;
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_a1_tvalid : OUT STD_LOGIC;
    m_axis_a1_tready : IN STD_LOGIC;
    m_axis_a1_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_a2_tvalid : OUT STD_LOGIC;
    m_axis_a2_tready : IN STD_LOGIC;
    m_axis_a2_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
end broadcaster;

architecture Behavioral of broadcaster is

    type state_type is (S_READ, S_WRITE);
    signal state : state_type := S_READ;

    signal buffer_a : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal internal_ready, external_ready, inputs_valid : STD_LOGIC := '0';
    signal a1_done, a2_done : STD_LOGIC := '0';

begin
    s_axis_tready <= external_ready;

    internal_ready <= '1' when state = S_READ else '0';
    inputs_valid <= s_axis_tvalid;
    external_ready <= internal_ready and inputs_valid;

    m_axis_a1_tvalid <= '1' when state = S_WRITE and a1_done = '0' else '0';
    m_axis_a1_tdata <= buffer_a;

    m_axis_a2_tvalid <= '1' when state = S_WRITE and a2_done = '0' else '0';
    m_axis_a2_tdata <= buffer_a;

    process(aclk)
    begin
        if rising_edge(aclk) then
            case state is
                when S_READ =>
                    if external_ready = '1' and inputs_valid = '1' then
                        buffer_a <= s_axis_tdata;
                        a1_done <= '0';
                        a2_done <= '0';
                        state <= S_WRITE;
                    end if;

                when S_WRITE =>
                    if m_axis_a1_tvalid = '1' and m_axis_a1_tready = '1' then
                        a1_done <= '1';
                    end if;
                    if m_axis_a2_tvalid = '1' and m_axis_a2_tready = '1' then
                        a2_done <= '1';
                    end if;

                    if a1_done = '1' and a2_done = '1' then
                        state <= S_READ;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
