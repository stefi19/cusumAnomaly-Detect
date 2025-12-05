library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        btn_inc : in std_logic;
        clk     : in std_logic;
        rst     : in std_logic;
        cat     : out std_logic_vector(6 downto 0);
        an      : out std_logic_vector(3 downto 0);
        led     : out std_logic
    );
end top;

architecture Behavioral of top is

    -- Debounced button
    signal debounced_btn : std_logic;

    -- 11-bit counter
    signal address       : std_logic_vector(10 downto 0);

    -- ROM outputs
    signal dout_curr     : std_logic_vector(31 downto 0);
    signal dout_prev     : std_logic_vector(31 downto 0);

    -- CUSUM AXIS signals
    signal s_axis_a_tvalid : std_logic := '0';
    signal s_axis_a_tready : std_logic;
    signal s_axis_a_tdata  : std_logic_vector(31 downto 0);

    signal s_axis_b_tvalid : std_logic := '0';
    signal s_axis_b_tready : std_logic;
    signal s_axis_b_tdata  : std_logic_vector(31 downto 0);

    signal m_axis_label_tvalid : std_logic;
    signal m_axis_label_tready : std_logic := '1';
    signal m_axis_label_tdata  : std_logic;

    constant DRIFT_CONST  : std_logic_vector(31 downto 0) := x"00000032"; -- 50
    constant THRESH_CONST : std_logic_vector(31 downto 0) := x"000000C8"; -- 200


    -- Decimal digits for display
    signal addr_int : integer range 0 to 2048 := 0;  -- 1-2048
    signal d0, d1, d2, d3 : std_logic_vector(3 downto 0);

begin

    --------------------------------------------------------------------------
    -- Debouncer
    --------------------------------------------------------------------------
    DEBOUNCE_inst : entity work.debouncer(Behavioral)
        port map(
            clk => clk,
            btn => btn_inc,
            en  => debounced_btn
        );

    --------------------------------------------------------------------------
    -- 11-bit counter (increments on button)
    --------------------------------------------------------------------------
    COUNTER_inst : entity work.counter11(Behavioral)
        port map(
            clk    => clk,
            reset  => rst,
            enable => debounced_btn,
            count  => address
        );

    --------------------------------------------------------------------------
    -- Add +1 so display starts at 1 instead of 0
    --------------------------------------------------------------------------
    addr_int <= to_integer(unsigned(address)) + 1;

    --------------------------------------------------------------------------
    -- ROM provides previous/current values
    --------------------------------------------------------------------------
    ROM_inst : entity work.rom(Behavioral)
        port map(
            address => address,
            curr    => dout_curr,
            prev    => dout_prev
        );

    --------------------------------------------------------------------------
    -- Map ROM outputs to CUSUM inputs
    --------------------------------------------------------------------------
    s_axis_a_tdata  <= dout_prev;
    s_axis_b_tdata  <= dout_curr;

    s_axis_a_tvalid <= debounced_btn;
    s_axis_b_tvalid <= debounced_btn;

    --------------------------------------------------------------------------
    -- CUSUM top-level block
    --------------------------------------------------------------------------
    CUSUM_inst : entity work.cusum_top(Behavioral)
        port map(
            aclk => clk,
            reset => rst,

            s_axis_a_tvalid => s_axis_a_tvalid,
            s_axis_a_tready => s_axis_a_tready,
            s_axis_a_tdata  => s_axis_a_tdata,

            s_axis_b_tvalid => s_axis_b_tvalid,
            s_axis_b_tready => s_axis_b_tready,
            s_axis_b_tdata  => s_axis_b_tdata,

            m_axis_label_tvalid => m_axis_label_tvalid,
            m_axis_label_tready => m_axis_label_tready,
            m_axis_label_tdata  => m_axis_label_tdata,

            s_axis_drift_tdata => DRIFT_CONST,
            s_axis_threshold_tdata => THRESH_CONST
        );

    --------------------------------------------------------------------------
    -- Decimal digit extraction (with leading zero blanking)
    --------------------------------------------------------------------------
    d0 <= std_logic_vector(to_unsigned(addr_int mod 10, 4));

    d1 <= std_logic_vector(to_unsigned((addr_int / 10) mod 10, 4))
           when addr_int >= 10 else "1111";

    d2 <= std_logic_vector(to_unsigned((addr_int / 100) mod 10, 4))
           when addr_int >= 100 else "1111";

    d3 <= std_logic_vector(to_unsigned((addr_int / 1000) mod 10, 4))
           when addr_int >= 1000 else "1111";

    --------------------------------------------------------------------------
    -- LED lights when anomaly detected
    --------------------------------------------------------------------------
    led <= m_axis_label_tdata;

    --------------------------------------------------------------------------
    -- 7-seg display driver
    --------------------------------------------------------------------------
    DISPLAY_inst : entity work.display_7seg(Behavioral)
        port map(
            digit0 => d0,
            digit1 => d1,
            digit2 => d2,
            digit3 => d3,
            clk    => clk,
            cat    => cat,
            an     => an
        );

end Behavioral;
