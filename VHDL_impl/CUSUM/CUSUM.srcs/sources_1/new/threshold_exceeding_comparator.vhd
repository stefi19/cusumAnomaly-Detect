library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity threshold_exceeding_comparator is
    Port ( 
        aclk : IN STD_LOGIC;

        -- Input streams: g+ (A) and g- (B)
        s_axis_a_tvalid : IN STD_LOGIC;
        s_axis_a_tready : OUT STD_LOGIC;
        s_axis_a_tdata  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        s_axis_b_tvalid : IN STD_LOGIC;
        s_axis_b_tready : OUT STD_LOGIC;
        s_axis_b_tdata  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Threshold input (no tvalid/tready in original design)
        s_axis_threshold_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Outputs: saturated/zeroed streams and a 1-bit label
        m_axis_gplus_tvalid  : OUT STD_LOGIC;
        m_axis_gplus_tready  : IN  STD_LOGIC;
        m_axis_gplus_tdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

        m_axis_gminus_tvalid : OUT STD_LOGIC;
        m_axis_gminus_tready : IN  STD_LOGIC;
        m_axis_gminus_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

        m_axis_result_tvalid : OUT STD_LOGIC;
        m_axis_result_tready : IN STD_LOGIC;
        m_axis_result_tdata  : OUT STD_LOGIC
    );
end threshold_exceeding_comparator;

architecture Behavioral of threshold_exceeding_comparator is

    -- Internal registers
    signal gP_reg, gM_reg, threshold_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal gP_valid_i, gM_valid_i : std_logic := '0';

    -- Output registers
    signal gpp_reg, gmp_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal label_reg : std_logic := '0';
    signal out_valid : std_logic := '0';

    signal gp_ready_buf, gm_ready_buf : std_logic := '0';

begin

    ---------------------------------------------------------------------------
    -- READY signals: accept when internal register is free
    ---------------------------------------------------------------------------
    gp_ready_buf <= not gP_valid_i;
    s_axis_a_tready <= gp_ready_buf;

    gm_ready_buf <= not gM_valid_i;
    s_axis_b_tready <= gm_ready_buf;

    ---------------------------------------------------------------------------
    -- Outputs VALID / DATA
    ---------------------------------------------------------------------------
    m_axis_gplus_tvalid   <= out_valid;
    m_axis_gplus_tdata    <= gpp_reg;

    m_axis_gminus_tvalid  <= out_valid;
    m_axis_gminus_tdata   <= gmp_reg;

    m_axis_result_tvalid  <= out_valid;
    m_axis_result_tdata   <= label_reg;

    ---------------------------------------------------------------------------
    -- Main FSM / datapath
    ---------------------------------------------------------------------------
    process(aclk)
    begin
        if rising_edge(aclk) then

            -- capture inputs when valid and internal buffer free
            if s_axis_a_tvalid = '1' and gp_ready_buf = '1' then
                gP_reg <= s_axis_a_tdata;
                gP_valid_i <= '1';
            end if;

            if s_axis_b_tvalid = '1' and gm_ready_buf = '1' then
                gM_reg <= s_axis_b_tdata;
                gM_valid_i <= '1';
            end if;

            -- threshold register: always sample current threshold input
            threshold_reg <= s_axis_threshold_tdata;

            -- When both inputs and threshold are available and output not busy, compute
            if gP_valid_i = '1' and gM_valid_i = '1' and out_valid = '0' then
                -- Always forward inputs to outputs; only set label when threshold is exceeded
                gpp_reg <= gP_reg;
                gmp_reg <= gM_reg;
                if (unsigned(gP_reg) > unsigned(threshold_reg)) or (unsigned(gM_reg) > unsigned(threshold_reg)) then
                    label_reg <= '1';
                else
                    label_reg <= '0';
                end if;

                out_valid <= '1';

                -- consume inputs
                gP_valid_i <= '0';
                gM_valid_i <= '0';
            end if;

            -- clear output when downstream ready
            if out_valid = '1' and m_axis_gplus_tready = '1' and m_axis_gminus_tready = '1' and m_axis_result_tready = '1' then
                out_valid <= '0';
            end if;

        end if;
    end process;

end Behavioral;