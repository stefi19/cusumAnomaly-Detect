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
--we need 13 FIFOs
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
component broadcaster is
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
end component;
-- we need 2 zero saturators
component maximum is
Port (
    aclk : IN STD_LOGIC;
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

  -- AXI handshake signals for FIFOs (stream control)
  signal FIFO1_data_ready,  FIFO1_data_valid  : std_logic := '0';
  signal FIFO2_data_ready,  FIFO2_data_valid  : std_logic := '0';
  signal FIFO3_data_ready,  FIFO3_data_valid  : std_logic := '0';
  signal FIFO4_data_ready,  FIFO4_data_valid  : std_logic := '0';
  signal FIFO5_data_ready,  FIFO5_data_valid  : std_logic := '0';
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
  signal MAX1_in_ready,  MAX1_in_valid  : std_logic := '0';
  signal MAX2_in_ready,  MAX2_in_valid  : std_logic := '0';
  signal MAX1_out_ready, MAX1_out_valid : std_logic := '0';
  signal MAX2_out_ready, MAX2_out_valid : std_logic := '0';

  -- Comparator for threshold exceed logic (1-bit anomaly label)
  signal THC_in_ready, THC_in_valid : std_logic := '0';
  signal THC_label : std_logic := '0';

  -- selection signal for iteration (drives both MUX1 and MUX2)
  signal sel : std_logic := '0';
begin

--fifo 1 - input a from top module ports fifo 2 - input b from top module ports first sub - inputs from the outputs of fifo1 and fifo2 fifo3 - input is output of the first sub broadcaster - input is output of fifo3 first adder - input from output of broadcaster, and input from output of MUX1 first sub - input from output of broadcaster, and input from output of MUX2 fifo4 - input is output of the first adder fifo5 - input is output of the first sub second sub - input is output of fifo4 and the other input is drift from top module ports third sub - input is output of fifo5 and the other input is drift from top module ports fifo6 - input is output of the second sub fifo7 - input is output of the third sub maximum1 - input is the output of fifo6 maximum2 - input is the output of fifo7 fifo8 - input is output of maximum1 fifo9 - input is output of maximum2 thresholdcomp - input is output of fifo8, input is output of fifo9, input is threshold from top module ports, output is label result out from top module port fifo10 - input is output of thresholdcomp (g+) fifo11 - input is output of thresholdcomp(g-) (so actually we just need 11 fifos) MUX1 - input from fifo10 and the other input is 0, the selection is a signal sel MUX2 - input from fifo11 and the other input is 0, the selection is the same signal sel sel will tell if it's the first iteration or not



end Behavioral;
