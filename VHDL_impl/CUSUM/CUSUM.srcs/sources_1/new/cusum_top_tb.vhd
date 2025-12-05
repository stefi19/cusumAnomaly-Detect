
    library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;
    use STD.TEXTIO.ALL;
    use IEEE.STD_LOGIC_TEXTIO.ALL;

    entity cusum_top_tb is
    end cusum_top_tb;

    architecture tb of cusum_top_tb is
      -- DUT component (matches `cusum_top` entity)
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

      -- File paths
      constant INPUT_FILE_NAME  : string := "D:/Facultate/Year3/Sem1/SCS/Assignament 5/cusumAnomaly-Detect/output/Thermistor_binary.csv";
      constant OUTPUT_FILE_NAME : string := "D:/Facultate/Year3/Sem1/SCS/Assignament 5/cusumAnomaly-Detect/output/cusum_results.csv";

      -- AXIS signals
      signal s_axis_a_tvalid : std_logic := '0';
      signal s_axis_a_tready : std_logic := '0';
      signal s_axis_a_tdata  : std_logic_vector(31 downto 0) := (others => '0');

      signal s_axis_b_tvalid : std_logic := '0';
      signal s_axis_b_tready : std_logic := '0';
      signal s_axis_b_tdata  : std_logic_vector(31 downto 0) := (others => '0');

      signal m_axis_label_tvalid : std_logic := '0';
      signal m_axis_label_tready : std_logic := '1'; -- always ready to accept labels
      signal m_axis_label_tdata  : std_logic := '0';

      -- CUSUM parameters
      signal s_axis_drift_tdata     : std_logic_vector(31 downto 0) := x"3D4CCCCD"; -- 0.05
      signal s_axis_threshold_tdata : std_logic_vector(31 downto 0) := x"40A00000"; -- 5.0

      -- control & counters
      signal end_of_reading : std_logic := '0';
      signal rd_count : integer := 0;
      signal wr_count : integer := 0;
      signal finished : boolean := false;

    begin
      -- instantiate DUT
      UUT: cusum_top
        port map(
          aclk => aclk,
          reset => reset,
          s_axis_a_tvalid => s_axis_a_tvalid,
          s_axis_a_tready => s_axis_a_tready,
          s_axis_a_tdata => s_axis_a_tdata,
          s_axis_b_tvalid => s_axis_b_tvalid,
          s_axis_b_tready => s_axis_b_tready,
          s_axis_b_tdata => s_axis_b_tdata,
          m_axis_label_tvalid => m_axis_label_tvalid,
          m_axis_label_tready => m_axis_label_tready,
          m_axis_label_tdata => m_axis_label_tdata,
          s_axis_drift_tdata => s_axis_drift_tdata,
          s_axis_threshold_tdata => s_axis_threshold_tdata
        );

      -- Clock
      clk_proc: process
      begin
        while now < 100 ms loop
          aclk <= '0';
          wait for T/2;
          aclk <= '1';
          wait for T/2;
        end loop;
        wait;
      end process clk_proc;

      -- Reset pulse
      reset_proc: process
      begin
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait;
      end process reset_proc;

      -- Driver: read CSV and feed DUT. CSV format: index, binary32
      driver_proc: process(aclk)
        file sensor_file : text open read_mode is INPUT_FILE_NAME;
        variable file_line : line;
        variable i_char : character;
        variable comma_seen : boolean;
        variable bin_str : string(1 to 32);
        variable ch : character;
        variable idx : integer;
        variable cur_sample, prev_sample_var : std_logic_vector(31 downto 0);
        variable header_skipped : boolean := false;
        variable file_opened : boolean := false;
      begin
        if rising_edge(aclk) then
          if reset = '1' then
            s_axis_a_tvalid <= '0';
            s_axis_b_tvalid <= '0';
            s_axis_a_tdata <= (others => '0');
            s_axis_b_tdata <= (others => '0');
            rd_count <= 0;
            end_of_reading <= '0';
            prev_sample_var := (others => '0');
            header_skipped := false;
            file_opened := false;
          elsif end_of_reading = '0' then
            if not file_opened then
              report "Opening CSV: " & INPUT_FILE_NAME;
              file_opened := true;
            end if;

            if not endfile(sensor_file) then
              -- only advance when DUT is ready to accept (handshake)
              if s_axis_a_tready = '1' then
                -- read next line
                readline(sensor_file, file_line);
                -- skip header
                if not header_skipped then
                  header_skipped := true;
                  -- if header contained text, ignore that line
                else
                  -- parse line to find comma and 32-bit binary string after it
                  comma_seen := false;
                  idx := 0;
                  for i in 1 to file_line'length loop
                    read(file_line, ch);
                    if ch = ',' then
                      comma_seen := true;
                      exit;
                    end if;
                  end loop;
                  -- read next 32 chars as binary string (skip possible spaces)
                  if comma_seen then
                    -- consume any spaces
                    loop
                      exit when file_line'length = 0;
                      read(file_line, ch);
                      exit when ch = '0' or ch = '1';
                    end loop;
                    bin_str(1) := ch;
                    for i in 2 to 32 loop
                      read(file_line, ch);
                      bin_str(i) := ch;
                    end loop;

                    -- convert to std_logic_vector
                    for i in 1 to 32 loop
                      if bin_str(i) = '1' then
                        cur_sample(32-i) := '1';
                      else
                        cur_sample(32-i) := '0';
                      end if;
                    end loop;

                    -- drive DUT: present cur_sample on A, prev on B
                    s_axis_a_tdata <= cur_sample;
                    s_axis_a_tvalid <= '1';
                    s_axis_b_tdata <= prev_sample_var;
                    s_axis_b_tvalid <= '1';

                    -- advance prev/sample counters when handshake occurs
                    if s_axis_a_tvalid = '1' and s_axis_a_tready = '1' then
                      prev_sample_var := cur_sample;
                      rd_count <= rd_count + 1;
                    end if;
                  else
                    -- malformed line: ignore
                    report "Malformed CSV line encountered" severity warning;
                  end if;
                end if;
              end if; -- s_axis_a_tready
            else
              -- EOF
              file_close(sensor_file);
              end_of_reading <= '1';
              s_axis_a_tvalid <= '0';
              s_axis_b_tvalid <= '0';
              finished <= true;
              report "Finished reading CSV. Total samples: " & integer'image(rd_count);
            end if;
          end if;
        end if;
      end process driver_proc;

      -- Writer: write labels to output CSV
      writer_proc: process(aclk)
        file results : text open write_mode is OUTPUT_FILE_NAME;
        variable out_line : line;
        variable idx_var : integer := 0;
      begin
        if rising_edge(aclk) then
          if idx_var = 0 then
            write(out_line, string'("index,label"));
            writeline(results, out_line);
            idx_var := 1;
          end if;

          if m_axis_label_tvalid = '1' and m_axis_label_tready = '1' then
            write(out_line, rd_count - 1); -- the label corresponds to previous sample index
            write(out_line, string'(","));
            write(out_line, m_axis_label_tdata);
            writeline(results, out_line);
            wr_count <= wr_count + 1;
          end if;

          if finished = true and end_of_reading = '1' then
            file_close(results);
            report "Results written: " & integer'image(wr_count);
          end if;
        end if;
      end process writer_proc;

      -- Small monitor for console
      monitor_proc: process(aclk)
      begin
        if rising_edge(aclk) then
          if m_axis_label_tvalid = '1' and m_axis_label_tready = '1' then
            if m_axis_label_tdata = '1' then
              report "ANOMALY at sample " & integer'image(rd_count - 1) severity note;
            else
              -- normal
            end if;
          end if;
        end if;
      end process monitor_proc;

      -- Stop simulation when finished
      stop_proc: process
      begin
        wait until finished = true;
        wait for 1000 ns; -- flush
        report "Testbench finished" severity note;
        wait;
      end process stop_proc;
    end tb;