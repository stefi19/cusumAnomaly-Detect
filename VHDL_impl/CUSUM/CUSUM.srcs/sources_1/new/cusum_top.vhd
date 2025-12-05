library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cusum_top is
   Port ( aclk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tready : OUT STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_b_tvalid : IN STD_LOGIC;
    s_axis_b_tready : OUT STD_LOGIC;
    s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_label_tvalid : OUT STD_LOGIC;
    m_axis_label_tready : IN STD_LOGIC;
    m_axis_label_tdata : OUT STD_LOGIC;
    s_axis_drift_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_threshold_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0) 
     );
end cusum_top;

architecture Behavioral of cusum_top is
--we need 11 FIFOs
COMPONENT axis_data_fifo_0
  PORT (
    s_axis_aresetn : IN STD_LOGIC;
    s_axis_aclk : IN STD_LOGIC;
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) 
  );
END COMPONENT;
component subtractor is
	Port (
		aclk : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		s_axis_a_tvalid : IN STD_LOGIC;
		s_axis_a_tready : OUT STD_LOGIC;
		s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		s_axis_b_tvalid : IN STD_LOGIC;
		s_axis_b_tready : OUT STD_LOGIC;
		s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		m_axis_result_tvalid : OUT STD_LOGIC;
		m_axis_result_tready : IN STD_LOGIC;
		m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
end component;
component adder is
  Port (
    aclk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tready : OUT STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_b_tvalid : IN STD_LOGIC;
    s_axis_b_tready : OUT STD_LOGIC;
    s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_result_tvalid : OUT STD_LOGIC;
    m_axis_result_tready : IN STD_LOGIC;
    m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
end component;
--we also need the broadcaster
COMPONENT axis_broadcaster_0
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axis_tready : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axis_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
  );
END COMPONENT;
-- we need 2 zero saturators
component maximum is
Port (
    aclk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tready : OUT STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_result_tvalid : OUT STD_LOGIC;
    m_axis_result_tready : IN STD_LOGIC;
    m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
end component;
-- one threshold comp
component threshold_exceeding_comparator is
  Port ( 
    aclk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tready : OUT STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_b_tvalid : IN STD_LOGIC;
    s_axis_b_tready : OUT STD_LOGIC;
    s_axis_b_tdata : IN STD_LOGIC_VECTOR( 31 DOWNTO 0);
    s_axis_threshold_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_result_tvalid : OUT STD_LOGIC;
    m_axis_result_tready : IN STD_LOGIC;
    m_axis_result_tdata : OUT STD_LOGIC;
    m_axis_gplus_tvalid  : OUT STD_LOGIC;
    m_axis_gplus_tready  : IN  STD_LOGIC;
    m_axis_gplus_tdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_gminus_tvalid : OUT STD_LOGIC;
    m_axis_gminus_tready : IN  STD_LOGIC;
    m_axis_gminus_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
end component;
 -- active-low reset for AXIS style components
  signal resetn : std_logic := '1';

  -- FIFO output data signals (32-bit busses)
  signal FIFO1_out  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO2_out  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO3_out  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO4_out  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO5_out  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO6_out  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO7_out  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO8_out  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO9_out  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO10_out : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO11_out : std_logic_vector(31 downto 0) := (others => '0');
  -- FIFOs inserted after broadcaster to decouple BROAD -> ADD/SUB
  signal FIFO_BR1_out : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO_BR2_out : std_logic_vector(31 downto 0) := (others => '0');

  -- FIFO input data signals (for connecting outputs into next stage)
  signal FIFO3_in  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO4_in  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO5_in  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO6_in  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO7_in  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO8_in  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO9_in  : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO10_in : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO11_in : std_logic_vector(31 downto 0) := (others => '0');

  -- FIFOs after broadcaster handshake signals
  signal FIFO_BR1_data_valid, FIFO_BR1_data_ready : std_logic := '0';
  signal FIFO_BR2_data_valid, FIFO_BR2_data_ready : std_logic := '0';
  signal BR1_to_ADD1_ready : std_logic := '0';
  signal BR2_to_SUB2_ready : std_logic := '0';

  -- AXI handshake signals for FIFOs (stream control)
  signal FIFO1_data_valid  : std_logic := '0';  -- only need data_valid for FIFO1
  signal FIFO2_data_valid  : std_logic := '0';  -- only need data_valid for FIFO2  
  signal FIFO3_data_valid  : std_logic := '0';  -- only need data_valid for FIFO3
  signal FIFO4_data_valid  : std_logic := '0';  -- only need data_valid for FIFO4
  signal FIFO5_data_valid  : std_logic := '0';  -- only need data_valid for FIFO5
  signal FIFO6_data_ready,  FIFO6_data_valid  : std_logic := '0';
  signal FIFO7_data_ready,  FIFO7_data_valid  : std_logic := '0';
  signal FIFO8_data_ready,  FIFO8_data_valid  : std_logic := '0';
  signal FIFO9_data_ready,  FIFO9_data_valid  : std_logic := '0';
  signal FIFO10_data_ready, FIFO10_data_valid : std_logic := '0';
  signal FIFO11_data_ready, FIFO11_data_valid : std_logic := '0';

  -- SUB and ADDER result outputs (31-bit vectors between processing stages)
  signal SUB1_result  : std_logic_vector(31 downto 0) := (others => '0');
  signal SUB2_result  : std_logic_vector(31 downto 0) := (others => '0');
  signal SUB3_result  : std_logic_vector(31 downto 0) := (others => '0');
  signal SUB4_result  : std_logic_vector(31 downto 0) := (others => '0');
  signal ADDER_result : std_logic_vector(31 downto 0) := (others => '0');
  signal MAX1_result  : std_logic_vector(31 downto 0) := (others => '0');
  signal MAX2_result  : std_logic_vector(31 downto 0) := (others => '0');

  -- Handshake control for subtractor/adder modules
  signal SUB1_result_ready,  SUB1_result_valid  : std_logic := '0';
  signal SUB2_result_ready,  SUB2_result_valid  : std_logic := '0';
  signal SUB3_result_ready,  SUB3_result_valid  : std_logic := '0';
  signal SUB4_result_ready,  SUB4_result_valid  : std_logic := '0';
  signal ADDER_result_ready, ADDER_result_valid : std_logic := '0';
  -- Ready signals for FIFO to Consumer connections  
  signal FIFO1_to_SUB1_ready : std_logic := '0';  -- ready signal from SUB1 A input to FIFO1
  signal FIFO2_to_SUB1_ready : std_logic := '0';  -- ready signal from SUB1 B input to FIFO2
  signal FIFO3_to_BR_ready : std_logic := '0';    -- ready signal from Broadcaster to FIFO3
  signal FIFO4_to_SUB3_ready : std_logic := '0';  -- ready signal from SUB3 to FIFO4
  signal FIFO5_to_SUB4_ready : std_logic := '0';  -- ready signal from SUB4 to FIFO5
  signal DRIFT_to_SUB3_ready : std_logic := '0';  -- ready signal from SUB3 for DRIFT input
  signal DRIFT_to_SUB4_ready : std_logic := '0';  -- ready signal from SUB4 for DRIFT input
  signal MAX1_in_ready,  MAX1_in_valid  : std_logic := '0';
  signal MAX2_in_ready,  MAX2_in_valid  : std_logic := '0';
  signal MAX1_out_ready, MAX1_out_valid : std_logic := '0';
  signal MAX2_out_ready, MAX2_out_valid : std_logic := '0';

  -- Comparator for threshold exceed logic (1-bit anomaly label)
  signal THC_in_ready, THC_in_valid : std_logic := '0';
  signal THC_label : std_logic := '0';

  -- Internal signal to capture comparator label valid (drive port from this)
  signal label_valid_sig : std_logic := '0';

  -- signals for comparator g+ / g- AXIS outputs
  signal TH_gplus_tvalid : std_logic := '0';
  signal TH_gplus_tready : std_logic := '0';
  signal TH_gplus_tdata  : std_logic_vector(31 downto 0) := (others => '0');
  signal TH_gminus_tvalid : std_logic := '0';
  signal TH_gminus_tready : std_logic := '0';
  signal TH_gminus_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  -- selection signal for iteration (drives both MUX1 and MUX2)
  signal sel : std_logic := '0';
  -- report guard for sel flip (avoid repeated reports)
  signal sel_reported : std_logic := '0';
  -- selection tracking: remember when feedback from FIFOs has been seen
  -- so first iteration uses zeros and subsequent iterations forward FIFO feedback.
  signal feedback_seen : std_logic := '0';
  -- MUX placeholders (will be implemented later). Tie defaults to zero for now.
  signal MUX1_out : std_logic_vector(31 downto 0) := (others => '0');
  signal MUX1_valid, MUX1_ready : std_logic := '0';
  signal MUX2_out : std_logic_vector(31 downto 0) := (others => '0');
  signal MUX2_valid, MUX2_ready : std_logic := '0';
  -- broadcaster intermediate AXIS signals
  signal BR_a1_tvalid : std_logic := '0';
  signal BR_a1_tready : std_logic := '0';
  signal BR_a1_tdata  : std_logic_vector(31 downto 0) := (others => '0');
  signal BR_a2_tvalid : std_logic := '0';
  signal BR_a2_tready : std_logic := '0';
  signal BR_a2_tdata  : std_logic_vector(31 downto 0) := (others => '0');
  -- drift input as an always-valid AXI-like source for subs
  signal DRIFT_valid : std_logic := '1';
  signal DRIFT_ready : std_logic := '0';
  signal DRIFT_data  : std_logic_vector(31 downto 0) := (others => '0');
begin
  -- Combine ready signals: DRIFT is ready when both SUB3 and SUB4 are ready for it
  DRIFT_ready <= DRIFT_to_SUB3_ready and DRIFT_to_SUB4_ready;

-- Drive active-low reset for AXIS-based FIFOs
    resetn <= not reset;

  -- Note: do not drive FIFO_*_data_ready or MAX*_out_ready here with constants.
  -- Those ready signals are outputs from downstream modules (e.g. MAX, comparator)
  -- and driving them from this architecture with constants can create multiple drivers
  -- when the instantiated IP also drives the same nets. Let the downstream
  -- components drive their ready outputs, or drive consumer-ready signals at
  -- the appropriate place in the design/testbench.

    ------------------------------------------------------------------
    -- STAGE 1: ingest inputs via FIFO1/FIFO2 -> SUB1 -> FIFO3
    -- FIFO1: input stream from top-level a
    FIFO1_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => s_axis_a_tvalid,
        s_axis_tready  => s_axis_a_tready,
        s_axis_tdata   => s_axis_a_tdata,
        m_axis_tvalid  => FIFO1_data_valid,
        m_axis_tready  => FIFO1_to_SUB1_ready,  -- INPUT: ready signal from SUB1 A input
        m_axis_tdata   => FIFO1_out
      );

    -- FIFO2: input stream from top-level b
    FIFO2_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => s_axis_b_tvalid,
        s_axis_tready  => s_axis_b_tready,
        s_axis_tdata   => s_axis_b_tdata,
        m_axis_tvalid  => FIFO2_data_valid,
        m_axis_tready  => FIFO2_to_SUB1_ready,  -- INPUT: ready signal from SUB1 B input
        m_axis_tdata   => FIFO2_out
      );

    -- SUB1: subtractor between FIFO1 and FIFO2
    SUB1_inst : subtractor
      port map(
        aclk => aclk,
        reset => reset,
        s_axis_a_tvalid => FIFO1_data_valid,
        s_axis_a_tready => FIFO1_to_SUB1_ready,  -- OUTPUT: SUB1 drives ready for FIFO1
        s_axis_a_tdata  => FIFO1_out,
        s_axis_b_tvalid => FIFO2_data_valid,
        s_axis_b_tready => FIFO2_to_SUB1_ready,  -- OUTPUT: SUB1 drives ready for FIFO2
        s_axis_b_tdata  => FIFO2_out,
        m_axis_result_tvalid => SUB1_result_valid,
        m_axis_result_tready => SUB1_result_ready,
        m_axis_result_tdata  => SUB1_result
      );

    -- FIFO3: buffer SUB1 output
    FIFO3_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => SUB1_result_valid,
        s_axis_tready  => SUB1_result_ready,
        s_axis_tdata   => SUB1_result,
        m_axis_tvalid  => FIFO3_data_valid,
        m_axis_tready  => FIFO3_to_BR_ready,  -- INPUT: ready signal from Broadcaster
        m_axis_tdata   => FIFO3_out
      );

    -- STAGE 2: broadcaster (fans out FIFO3 -> FIFO4 & FIFO5)
    -- broadcaster: takes FIFO3_out and produces two outputs a1 and a2
    BROAD_inst : axis_broadcaster_0
      port map(
        aclk => aclk,
        aresetn => resetn,
        s_axis_tvalid  => FIFO3_data_valid,
        s_axis_tready => FIFO3_to_BR_ready,  -- OUTPUT: Broadcaster drives ready for FIFO3
        s_axis_tdata   => FIFO3_out,
        m_axis_tvalid(0) => BR_a1_tvalid,
        m_axis_tvalid(1) => BR_a2_tvalid,
        m_axis_tready(0) => BR_a1_tready,
        m_axis_tready(1) => BR_a2_tready,
        m_axis_tdata(31 downto 0)  => BR_a1_tdata,
        m_axis_tdata(63 downto 32) => BR_a2_tdata
      );

    -- Insert small FIFOs after the broadcaster to decouple BROAD -> ADD/SUB
    -- FIFO_BR1: buffer broadcaster output a1 before ADD1
    FIFO_BR1_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => BR_a1_tvalid,
        s_axis_tready  => BR_a1_tready,
        s_axis_tdata   => BR_a1_tdata,
        m_axis_tvalid  => FIFO_BR1_data_valid,
        m_axis_tready  => BR1_to_ADD1_ready,
        m_axis_tdata   => FIFO_BR1_out
      );

    -- FIFO_BR2: buffer broadcaster output a2 before SUB2
    FIFO_BR2_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => BR_a2_tvalid,
        s_axis_tready  => BR_a2_tready,
        s_axis_tdata   => BR_a2_tdata,
        m_axis_tvalid  => FIFO_BR2_data_valid,
        m_axis_tready  => BR2_to_SUB2_ready,
        m_axis_tdata   => FIFO_BR2_out
      );

    -- STAGE 3: first adder and first subtractor
    -- Broadcaster outputs feed the adder/sub directly (no FIFO between them)
    -- First adder: input A from FIFO_BR1 (buffered broadcaster output), input B from MUX1
    ADD1_inst : adder
      port map(
        aclk => aclk,
        reset => reset,
        s_axis_a_tvalid => FIFO_BR1_data_valid,
        s_axis_a_tready => BR1_to_ADD1_ready,
        s_axis_a_tdata  => FIFO_BR1_out,
        s_axis_b_tvalid => MUX1_valid,
        s_axis_b_tready => MUX1_ready,
        s_axis_b_tdata  => MUX1_out,
        m_axis_result_tvalid => ADDER_result_valid,
        m_axis_result_tready => ADDER_result_ready,
        m_axis_result_tdata  => ADDER_result
      );

    -- First subtractor: input A from FIFO_BR2 (buffered broadcaster output), input B from MUX2
    SUB2_inst : subtractor
      port map(
        aclk => aclk,
        reset => reset,
        s_axis_a_tvalid => FIFO_BR2_data_valid,
        s_axis_a_tready => BR2_to_SUB2_ready,
        s_axis_a_tdata  => FIFO_BR2_out,
        s_axis_b_tvalid => MUX2_valid,
        s_axis_b_tready => MUX2_ready,
        s_axis_b_tdata  => MUX2_out,
        m_axis_result_tvalid => SUB2_result_valid,
        m_axis_result_tready => SUB2_result_ready,
        m_axis_result_tdata  => SUB2_result
      );

    -- FIFO4: buffer ADDER result (placed after the adder)
    FIFO4_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => ADDER_result_valid,
        s_axis_tready  => ADDER_result_ready,
        s_axis_tdata   => ADDER_result,
        m_axis_tvalid  => FIFO4_data_valid,
        m_axis_tready  => FIFO4_to_SUB3_ready,  -- INPUT: ready signal from SUB3
        m_axis_tdata   => FIFO4_out
      );

    -- FIFO5: buffer subtractor (first) result (placed after the subtractor)
    FIFO5_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => SUB2_result_valid,
        s_axis_tready  => SUB2_result_ready,
        s_axis_tdata   => SUB2_result,
        m_axis_tvalid  => FIFO5_data_valid,
        m_axis_tready  => FIFO5_to_SUB4_ready,  -- INPUT: ready signal from SUB4
        m_axis_tdata   => FIFO5_out
      );

--  -- MUX1 / MUX2 (AXI-aware selectors): choose between zero and FIFO10/FIFO11 feedback based on `sel`.
--  -- When sel = '1' select feedback (FIFO10/FIFO11). When sel = '0' select constant-zero.
--  -- Output valid follows the selected source; when selecting zero the stream is always valid.
--  -- When sel='1' only forward FIFO data if FIFO reports valid; otherwise output zero.
--  -- MUX forwards feedback only after feedback_seen is set (i.e. FIFOs produced feedback once).
--  MUX1_out <= FIFO10_out when (sel = '1' and feedback_seen = '1' and FIFO10_data_valid = '1') else (others => '0');
--  MUX1_valid <= (sel = '1' and feedback_seen = '1' and FIFO10_data_valid = '1') or (sel = '0');
--  -- drive FIFO10 ready only when feedback is enabled so back-pressure flows into FIFO10 only when selected
--  FIFO10_data_ready <= MUX1_ready when (sel = '1' and feedback_seen = '1') else '0';

--  MUX2_out <= FIFO11_out when (sel = '1' and feedback_seen = '1' and FIFO11_data_valid = '1') else (others => '0');
--  MUX2_valid <= (sel = '1' and feedback_seen = '1' and FIFO11_data_valid = '1') or (sel = '0');
--  FIFO11_data_ready <= MUX2_ready when (sel = '1' and feedback_seen = '1') else '0';
-- MUX1 valid (boolean condition converted explicitly to std_logic)
-- MUX1 valid: when sel='0' we drive a zero stream (valid), when sel='1' forward FIFO10 when available
MUX1_valid <= '1' when (sel = '0') else
             '1' when (sel = '1' and feedback_seen = '1' and FIFO10_data_valid = '1') else
             '0';

-- MUX1 data path stays unchanged
MUX1_out <= FIFO10_out when (sel = '1' and feedback_seen = '1' and FIFO10_data_valid = '1')
           else (others => '0');

-- drive FIFO10 ready only when selected, and convert boolean → std_logic
-- Drive FIFO10 ready from the MUX consumer ready when feedback is selected.
-- When sel='1' and feedback_seen is set, forward the adder/subtractor ready
-- (MUX1_ready) to the FIFO so back-pressure is respected. Otherwise deassert.
FIFO10_data_ready <= MUX1_ready when (sel = '1' and feedback_seen = '1')
                    else '0';

------------------------------------------------------------------

-- MUX2 valid (boolean → std_logic)
-- MUX2 valid: when sel='0' we drive a zero stream (valid), when sel='1' forward FIFO11 when available
MUX2_valid <= '1' when (sel = '0') else
             '1' when (sel = '1' and feedback_seen = '1' and FIFO11_data_valid = '1') else
             '0';

-- MUX2 data path
MUX2_out <= FIFO11_out when (sel = '1' and feedback_seen = '1' and FIFO11_data_valid = '1')
           else (others => '0');

-- drive FIFO11 ready when selected
-- Same for FIFO11: drive its ready from MUX2_ready when feedback selected.
FIFO11_data_ready <= MUX2_ready when (sel = '1' and feedback_seen = '1')
                    else '0';


  -- Latch that remembers when any feedback FIFO produced data. Once set it remains set
  -- for subsequent iterations (so only the very first iteration emits zeros).
  feedback_latch_proc: process(aclk)
  begin
    if rising_edge(aclk) then
      if reset = '1' then
        feedback_seen <= '0';
      else
        if FIFO10_data_valid = '1' and FIFO11_data_valid = '1' then
          feedback_seen <= '1';
        end if;
      end if;
    end if;
  end process feedback_latch_proc;

  -- Make the MUX selection follow the feedback latch: start with zeros
  -- (sel = '0') and switch to feedback when feedback_seen is set.
  sel <= feedback_seen;

  -- Report when we switch from initial-zero iteration to feedback mode
  sel_report_proc: process(aclk)
  begin
    if rising_edge(aclk) then
      if reset = '1' then
        sel_reported <= '0';
      else
        if feedback_seen = '1' and sel_reported = '0' then
          report "cusum_top: sel switched to feedback mode" severity note;
          sel_reported <= '1';
        end if;
      end if;
    end if;
  end process sel_report_proc;

  -- Debug trace: report key handshake/assert signals to help locate pipeline stalls.
  debug_trace_proc: process(aclk)
  begin
    if rising_edge(aclk) then
      if reset = '0' then
        if FIFO3_data_valid = '1' then
          report "TRACE: FIFO3_data_valid=1" severity note;
        end if;
        if FIFO1_data_valid = '1' then
          report "VAL: FIFO1_out=" & integer'image(to_integer(signed(FIFO1_out))) severity note;
        end if;
        if FIFO2_data_valid = '1' then
          report "VAL: FIFO2_out=" & integer'image(to_integer(signed(FIFO2_out))) severity note;
        end if;
        if SUB1_result_valid = '1' then
          report "VAL: SUB1_result=" & integer'image(to_integer(signed(SUB1_result))) severity note;
        end if;
        if FIFO4_data_valid = '1' then
          report "VAL: FIFO4_out=" & integer'image(to_integer(signed(FIFO4_out))) severity note;
        end if;
        if BR_a1_tvalid = '1' then
          report "VAL: BR_a1_tdata=" & integer'image(to_integer(signed(BR_a1_tdata))) severity note;
        end if;
        if ADDER_result_valid = '1' then
          report "VAL: ADDER_result=" & integer'image(to_integer(signed(ADDER_result))) severity note;
        end if;
        if SUB2_result_valid = '1' then
          report "VAL: SUB2_result=" & integer'image(to_integer(signed(SUB2_result))) severity note;
        end if;
        if FIFO6_data_valid = '1' then
          report "VAL: FIFO6_out=" & integer'image(to_integer(signed(FIFO6_out))) severity note;
        end if;
        if FIFO8_data_valid = '1' then
          report "VAL: FIFO8_out=" & integer'image(to_integer(signed(FIFO8_out))) severity note;
        end if;
        if BR_a1_tvalid = '1' then
          report "TRACE: BR_a1_tvalid=1" severity note;
        end if;
        if FIFO_BR1_data_valid = '1' then
          report "TRACE: FIFO_BR1_data_valid=1" severity note;
        end if;
        if BR1_to_ADD1_ready = '1' then
          report "TRACE: BR1_to_ADD1_ready=1" severity note;
        end if;
        if FIFO4_data_valid = '1' then
          report "TRACE: FIFO4_data_valid=1" severity note;
        end if;
        if FIFO6_data_valid = '1' then
          report "TRACE: FIFO6_data_valid=1" severity note;
        end if;
        if FIFO8_data_valid = '1' then
          report "TRACE: FIFO8_data_valid=1" severity note;
        end if;
        if TH_gplus_tvalid = '1' then
          report "TRACE: TH_gplus_tvalid=1" severity note;
        end if;
        if label_valid_sig = '1' then
          report "TRACE: label_valid_sig=1" severity note;
        end if;
      end if;
    end if;
  end process debug_trace_proc;

    ------------------------------------------------------------------
    -- STAGE 4: subtract drift from adder/sub outputs (SUB3/SUB4) -> FIFO6/FIFO7 -> MAX1/MAX2 -> FIFO8/FIFO9
    -- Drive DRIFT_data from top-level drift port and keep it always valid
    DRIFT_data <= s_axis_drift_tdata;
    DRIFT_valid <= '1';

    -- SUB3: input A from FIFO4 (adder result), input B from drift
    SUB3_inst : subtractor
      port map(
        aclk => aclk,
        reset => reset,
        s_axis_a_tvalid => FIFO4_data_valid,
        s_axis_a_tready => FIFO4_to_SUB3_ready,  -- OUTPUT: SUB3 drives this ready signal
        s_axis_a_tdata  => FIFO4_out,
        s_axis_b_tvalid => DRIFT_valid,
        s_axis_b_tready => DRIFT_to_SUB3_ready,  -- OUTPUT: SUB3 drives its own DRIFT ready signal
        s_axis_b_tdata  => DRIFT_data,
        m_axis_result_tvalid => SUB3_result_valid,
        m_axis_result_tready => SUB3_result_ready,
        m_axis_result_tdata  => SUB3_result
      );

    -- SUB4: input A from FIFO5 (first subtractor result), input B from drift
    SUB4_inst : subtractor
      port map(
        aclk => aclk,
        reset => reset,
        s_axis_a_tvalid => FIFO5_data_valid,
        s_axis_a_tready => FIFO5_to_SUB4_ready,  -- OUTPUT: SUB4 drives this ready signal
        s_axis_a_tdata  => FIFO5_out,
        s_axis_b_tvalid => DRIFT_valid,
        s_axis_b_tready => DRIFT_to_SUB4_ready,  -- OUTPUT: SUB4 drives its own DRIFT ready signal
        s_axis_b_tdata  => DRIFT_data,
        m_axis_result_tvalid => SUB4_result_valid,
        m_axis_result_tready => SUB4_result_ready,
        m_axis_result_tdata  => SUB4_result
      );

    -- FIFO6: buffer SUB3 output
    FIFO6_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => SUB3_result_valid,
        s_axis_tready  => SUB3_result_ready,
        s_axis_tdata   => SUB3_result,
        m_axis_tvalid  => FIFO6_data_valid,
        m_axis_tready  => FIFO6_data_ready,
        m_axis_tdata   => FIFO6_out
      );

    -- FIFO7: buffer SUB4 output
    FIFO7_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => SUB4_result_valid,
        s_axis_tready  => SUB4_result_ready,
        s_axis_tdata   => SUB4_result,
        m_axis_tvalid  => FIFO7_data_valid,
        m_axis_tready  => FIFO7_data_ready,
        m_axis_tdata   => FIFO7_out
      );

    -- MAX1: take FIFO6_out, output MAX1_result
    MAX1_inst : maximum
      port map(
        aclk => aclk,
        reset => reset,
        s_axis_a_tvalid => FIFO6_data_valid,
        s_axis_a_tready => FIFO6_data_ready,
        s_axis_a_tdata  => FIFO6_out,
        m_axis_result_tvalid => MAX1_out_valid,
        m_axis_result_tready => MAX1_out_ready,
        m_axis_result_tdata  => MAX1_result
      );

    -- MAX2: take FIFO7_out, output MAX2_result
    MAX2_inst : maximum
      port map(
        aclk => aclk,
        reset => reset,
        s_axis_a_tvalid => FIFO7_data_valid,
        s_axis_a_tready => FIFO7_data_ready,
        s_axis_a_tdata  => FIFO7_out,
        m_axis_result_tvalid => MAX2_out_valid,
        m_axis_result_tready => MAX2_out_ready,
        m_axis_result_tdata  => MAX2_result
      );

    -- FIFO8: buffer MAX1 result
    FIFO8_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => MAX1_out_valid,
        s_axis_tready  => MAX1_out_ready,
        s_axis_tdata   => MAX1_result,
        m_axis_tvalid  => FIFO8_data_valid,
        m_axis_tready  => FIFO8_data_ready,
        m_axis_tdata   => FIFO8_out
      );

    -- FIFO9: buffer MAX2 result
    FIFO9_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => MAX2_out_valid,
        s_axis_tready  => MAX2_out_ready,
        s_axis_tdata   => MAX2_result,
        m_axis_tvalid  => FIFO9_data_valid,
        m_axis_tready  => FIFO9_data_ready,
        m_axis_tdata   => FIFO9_out
      );

    ------------------------------------------------------------------
    -- STAGE 5: threshold comparator (takes FIFO8_out, FIFO9_out, threshold) -> label + g+/g- outputs
    THRESH_inst : threshold_exceeding_comparator
      port map(
        aclk => aclk,
        reset => reset,
        s_axis_a_tvalid => FIFO8_data_valid,
        s_axis_a_tready => FIFO8_data_ready,
        s_axis_a_tdata  => FIFO8_out,
        s_axis_b_tvalid => FIFO9_data_valid,
        s_axis_b_tready => FIFO9_data_ready,
        s_axis_b_tdata  => FIFO9_out,
        s_axis_threshold_tdata => s_axis_threshold_tdata,
        m_axis_result_tvalid => label_valid_sig,
        m_axis_result_tready => m_axis_label_tready,
        m_axis_result_tdata  => m_axis_label_tdata,
        m_axis_gplus_tvalid  => TH_gplus_tvalid,
        m_axis_gplus_tready  => TH_gplus_tready,
        m_axis_gplus_tdata   => TH_gplus_tdata,
        m_axis_gminus_tvalid => TH_gminus_tvalid,
        m_axis_gminus_tready => TH_gminus_tready,
        m_axis_gminus_tdata  => TH_gminus_tdata
      );

    -- Drive the top-level output port from the internal label valid signal
    m_axis_label_tvalid <= label_valid_sig;

    -- FIFO10: buffer comparator g+ output
    FIFO10_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => TH_gplus_tvalid,
        s_axis_tready  => TH_gplus_tready,
        s_axis_tdata   => TH_gplus_tdata,
        m_axis_tvalid  => FIFO10_data_valid,
        m_axis_tready  => FIFO10_data_ready,
        m_axis_tdata   => FIFO10_out
      );

    -- FIFO11: buffer comparator g- output
    FIFO11_inst : axis_data_fifo_0
      port map(
        s_axis_aresetn => resetn,
        s_axis_aclk    => aclk,
        s_axis_tvalid  => TH_gminus_tvalid,
        s_axis_tready  => TH_gminus_tready,
        s_axis_tdata   => TH_gminus_tdata,
        m_axis_tvalid  => FIFO11_data_valid,
        m_axis_tready  => FIFO11_data_ready,
        m_axis_tdata   => FIFO11_out
      );

    ------------------------------------------------------------------

--fifo 1 - input a from top module ports fifo 2 - input b from top module ports first sub - inputs from the outputs of fifo1 and fifo2 fifo3 - input is output of the first sub broadcaster - input is output of fifo3 first adder - input from output of broadcaster, and input from output of MUX1 first sub - input from output of broadcaster, and input from output of MUX2 fifo4 - input is output of the first adder fifo5 - input is output of the first sub second sub - input is output of fifo4 and the other input is drift from top module ports third sub - input is output of fifo5 and the other input is drift from top module ports fifo6 - input is output of the second sub fifo7 - input is output of the third sub maximum1 - input is the output of fifo6 maximum2 - input is the output of fifo7 fifo8 - input is output of maximum1 fifo9 - input is output of maximum2 thresholdcomp - input is output of fifo8, input is output of fifo9, input is threshold from top module ports, output is label result out from top module port fifo10 - input is output of thresholdcomp (g+) fifo11 - input is output of thresholdcomp(g-) (so actually we just need 11 fifos) MUX1 - input from fifo10 and the other input is 0, the selection is a signal sel MUX2 - input from fifo11 and the other input is 0, the selection is the same signal sel sel will tell if it's the first iteration or not

end Behavioral;

