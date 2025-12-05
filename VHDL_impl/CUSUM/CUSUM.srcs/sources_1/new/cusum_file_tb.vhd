-- cusum_file_tb.vhd
-- Testbench for cusum_top that reads sensor data from a file
-- Reads 32-bit hexadecimal values from input file and feeds them to the CUSUM algorithm
-- Writes anomaly detection results to a CSV output file

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity cusum_file_tb is
end cusum_file_tb;

architecture tb of cusum_file_tb is
  -- Component declaration for cusum_top
  component cusum_top
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
  end component;

  -- Clock and reset
  constant T : time := 20 ns;
  signal aclk : std_logic := '0';
  signal reset : std_logic := '1';

  -- File paths: use absolute path so simulator can open file reliably
  constant INPUT_FILE_NAME  : string := "D:/Facultate/Year3/Sem1/SCS/Assignament 5/cusumAnomaly-Detect/VHDL_impl/CUSUM/CUSUM.srcs/sources_1/new/Thermistor_binary.csv";
  constant OUTPUT_FILE_NAME : string := "D:/Facultate/Year3/Sem1/SCS/Assignament 5/cusumAnomaly-Detect/VHDL_impl/CUSUM/CUSUM.srcs/sources_1/new/cusum_results.csv";

  -- Input stream A (current sample)
  signal s_axis_a_tvalid : std_logic := '0';
  signal s_axis_a_tready : std_logic := '0';
  signal s_axis_a_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  -- Input stream B (previous sample for delta calculation)
  signal s_axis_b_tvalid : std_logic := '0';
  signal s_axis_b_tready : std_logic := '0';
  signal s_axis_b_tdata  : std_logic_vector(31 downto 0) := (others => '0');

  -- Output stream (anomaly labels)
  signal m_axis_label_tvalid : std_logic := '0';
  signal m_axis_label_tready : std_logic := '1'; -- always ready to accept labels
  signal m_axis_label_tdata  : std_logic := '0';

  -- CUSUM parameters
  signal s_axis_drift_tdata     : std_logic_vector(31 downto 0) := x"40000000"; -- 2.0 in IEEE 754
  signal s_axis_threshold_tdata : std_logic_vector(31 downto 0) := x"40A00000"; -- 5.0 in IEEE 754

  -- Control signals
  signal rd_count : integer := 0;
  signal end_of_reading : std_logic := '0';
  signal prev_sample : std_logic_vector(31 downto 0) := (others => '0');
  signal first_sample_done : std_logic := '0';

begin

  -- Clock generation
  aclk <= not aclk after T / 2;
  
  -- Reset generation
  reset <= '1', '0' after 5 * T;

  -- Device under test instantiation
  dut : cusum_top
    port map (
      aclk                   => aclk,
      reset                  => reset,
      s_axis_a_tvalid        => s_axis_a_tvalid,
      s_axis_a_tready        => s_axis_a_tready,
      s_axis_a_tdata         => s_axis_a_tdata,
      s_axis_b_tvalid        => s_axis_b_tvalid,
      s_axis_b_tready        => s_axis_b_tready,
      s_axis_b_tdata         => s_axis_b_tdata,
      m_axis_label_tvalid    => m_axis_label_tvalid,
      m_axis_label_tready    => m_axis_label_tready,
      m_axis_label_tdata     => m_axis_label_tdata,
      s_axis_drift_tdata     => s_axis_drift_tdata,
      s_axis_threshold_tdata => s_axis_threshold_tdata
    );

  -- Read sensor data from file and feed to CUSUM
  input_process: process (aclk)
    file sensor_file : text open read_mode is INPUT_FILE_NAME;
    variable file_line : line;
    variable current_sample : std_logic_vector(31 downto 0);
    variable read_success : boolean;
    variable comma_pos : integer;
    variable binary_str : string(1 to 32);
    variable char : character;
    variable header_skipped : boolean := false;
  begin
    if rising_edge(aclk) then
      if reset = '1' then
        -- Reset state
        s_axis_a_tvalid <= '0';
        s_axis_b_tvalid <= '0';
        first_sample_done <= '0';
        prev_sample <= (others => '0');
        rd_count <= 0;
        end_of_reading <= '0';
        header_skipped := false;
        
      elsif end_of_reading = '0' then
        -- Check if input A is ready; read when DUT can accept a new sample.
        -- (Don't wait for both A and B ready to avoid potential deadlock/backpressure stalls.)
        -- Only call endfile/readline if the file was successfully opened by the simulator
        if s_axis_a_tready = '1' and not endfile(sensor_file) then
          -- Read next line from file
          readline(sensor_file, file_line);
          
          -- Skip header line if not already done
          if not header_skipped then
            header_skipped := true;
            s_axis_a_tvalid <= '0';
            s_axis_b_tvalid <= '0';
            report "cusum_file_tb: skipped header" severity note;
          elsif file_line'length > 0 then
            -- Find comma position to skip index column
            comma_pos := 0;
            for i in 1 to file_line'length loop
              read(file_line, char);
              if char = ',' then
                comma_pos := i;
                exit;
              end if;
            end loop;
            
            -- Read the binary string (32 bits after comma)
            if comma_pos > 0 and file_line'length >= comma_pos + 32 then
              for i in 1 to 32 loop
                read(file_line, char);
                binary_str(i) := char;
              end loop;
              
              -- Convert binary string to std_logic_vector
              read_success := true;
              for i in 1 to 32 loop
                if binary_str(i) = '1' then
                  current_sample(32-i) := '1';
                elsif binary_str(i) = '0' then
                  current_sample(32-i) := '0';
                else
                  read_success := false;
                  exit;
                end if;
              end loop;
              
              if read_success then
                if first_sample_done = '0' then
                  -- First sample: just store it, don't send yet
                  prev_sample <= current_sample;
                  first_sample_done <= '1';
                  rd_count <= rd_count + 1;
                  s_axis_a_tvalid <= '0';
                  s_axis_b_tvalid <= '0';
                  report "cusum_file_tb: stored first sample (index " & integer'image(rd_count) & ") value=" & integer'image(to_integer(unsigned(current_sample))) severity note;
                else
                  -- Send current sample on A and previous sample on B
                  s_axis_a_tdata <= current_sample;
                  s_axis_a_tvalid <= '1';
                  s_axis_b_tdata <= prev_sample;
                  s_axis_b_tvalid <= '1';
                  
                  -- Update previous sample for next iteration
                  prev_sample <= current_sample;
                  rd_count <= rd_count + 1;
                  report "cusum_file_tb: sent sample (index " & integer'image(rd_count) & ") value=" & integer'image(to_integer(unsigned(current_sample))) severity note;
                end if;
              else
                -- Read failed, deassert valid
                s_axis_a_tvalid <= '0';
                s_axis_b_tvalid <= '0';
              end if;
            else
              -- Invalid format, deassert valid
              s_axis_a_tvalid <= '0';
              s_axis_b_tvalid <= '0';
            end if;
          else
            -- Empty line, deassert valid
            s_axis_a_tvalid <= '0';
            s_axis_b_tvalid <= '0';
          end if;
          
        elsif endfile(sensor_file) then
          -- End of file reached
          report "cusum_file_tb: EOF reached after " & integer'image(rd_count) & " samples" severity note;
          file_close(sensor_file);
          end_of_reading <= '1';
          s_axis_a_tvalid <= '0';
          s_axis_b_tvalid <= '0';
          
        else
          -- Not ready or waiting, deassert valid
          s_axis_a_tvalid <= '0';
          s_axis_b_tvalid <= '0';
        end if;
      end if;
    end if;
  end process input_process;

  -- Write CUSUM results to output file
  output_process: process
    file output_file : text open write_mode is OUTPUT_FILE_NAME;
    variable output_line : line;
    variable sample_index : integer := 0;
  begin
    wait until rising_edge(aclk);
    
    -- Wait for reset to be released
    if reset = '1' then
      wait until reset = '0';
      wait until rising_edge(aclk);
    end if;
    
    -- Write CSV header
    write(output_line, string'("sample_index,anomaly_label"));
    writeline(output_file, output_line);
    
    -- Write first sample with label 0 (no anomaly initially)
    write(output_line, 0);
    write(output_line, string'(",0"));
    writeline(output_file, output_line);
    sample_index := 1;
    
    -- Process CUSUM outputs
    while true loop
      wait until rising_edge(aclk);
      
      -- Check for valid output from CUSUM
      if m_axis_label_tvalid = '1' then
        write(output_line, sample_index);
        write(output_line, string'(","));
        
        if m_axis_label_tdata = '1' then
          write(output_line, string'("1"));
        else
          write(output_line, string'("0"));
        end if;
        
        writeline(output_file, output_line);
        sample_index := sample_index + 1;
      end if;
      
      -- Check if we're done processing
      if end_of_reading = '1' and sample_index >= rd_count then
        file_close(output_file);
        report "CUSUM processing completed. Total samples: " & integer'image(rd_count);
        report "Results written to: " & OUTPUT_FILE_NAME;
        wait; -- End simulation
      end if;
    end loop;
  end process output_process;

end tb;