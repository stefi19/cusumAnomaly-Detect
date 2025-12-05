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

      -- File paths: use absolute path so simulator can open file reliably
      constant INPUT_FILE_NAME  : string := "D:/Facultate/Year3/Sem1/SCS/Assignament 5/cusumAnomaly-Detect/VHDL_impl/CUSUM/CUSUM.srcs/sources_1/new/Thermistor_binary.csv";
      constant OUTPUT_FILE_NAME : string := "D:/Facultate/Year3/Sem1/SCS/Assignament 5/cusumAnomaly-Detect/VHDL_impl/CUSUM/CUSUM.srcs/sources_1/new/cusum_top_results.csv";

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
      -- Default CUSUM parameters (scaled integers: 2.0°C -> 200, 0.5°C -> 50)
      constant THRESHOLD : integer := 200;
      constant DRIFT     : integer := 50;
      signal s_axis_drift_tdata     : std_logic_vector(31 downto 0) := std_logic_vector(to_signed(DRIFT, 32));
      signal s_axis_threshold_tdata : std_logic_vector(31 downto 0) := std_logic_vector(to_signed(THRESHOLD, 32));

      -- Hardcoded sample inputs (CSV lines 540..599 hardcoded as 32-bit vectors)
        -- Hardcoded sample inputs (CSV lines 543..600 as requested)
        constant N_SAMPLES : integer := 58;
        type sample_array_t is array(0 to N_SAMPLES-1) of std_logic_vector(31 downto 0);
        constant samples : sample_array_t := (
          std_logic_vector'("00000000000000000000100110111101"), -- 543
          std_logic_vector'("00000000000000000000100111010001"), -- 544
          std_logic_vector'("00000000000000000000100111000111"), -- 545
          std_logic_vector'("11111111111111111110000011101100"), -- 546
          std_logic_vector'("11111111111111111110000011101100"), -- 547
          std_logic_vector'("11111111111111111110000011101100"), -- 548
          std_logic_vector'("11111111111111111110000011101100"), -- 549
          std_logic_vector'("11111111111111111110000011101100"), -- 550
          std_logic_vector'("11111111111111111110000011101100"), -- 551
          std_logic_vector'("11111111111111111110001000100110"), -- 552
          std_logic_vector'("11111111111111111110001000100110"), -- 553
          std_logic_vector'("11111111111111111110001000100110"), -- 554
          std_logic_vector'("11111111111111111110001000100110"), -- 555
          std_logic_vector'("11111111111111111110001000100110"), -- 556
          std_logic_vector'("11111111111111111110001000100110"), -- 557
          std_logic_vector'("11111111111111111110001000100110"), -- 558
          std_logic_vector'("11111111111111111110001000100110"), -- 559
          std_logic_vector'("11111111111111111110001000100110"), -- 560
          std_logic_vector'("11111111111111111110001100101011"), -- 561
          std_logic_vector'("11111111111111111110001100101011"), -- 562
          std_logic_vector'("11111111111111111110001100101011"), -- 563
          std_logic_vector'("11111111111111111110001100101011"), -- 564
          std_logic_vector'("11111111111111111110001100101011"), -- 565
          std_logic_vector'("11111111111111111110001100101011"), -- 566
          std_logic_vector'("11111111111111111110001100101011"), -- 567
          std_logic_vector'("11111111111111111110001100101011"), -- 568
          std_logic_vector'("11111111111111111110001100101011"), -- 569
          std_logic_vector'("11111111111111111110001100101011"), -- 570
          std_logic_vector'("11111111111111111110001100101011"), -- 571
          std_logic_vector'("11111111111111111110001100101011"), -- 572
          std_logic_vector'("11111111111111111110001100101011"), -- 573
          std_logic_vector'("11111111111111111110001100101011"), -- 574
          std_logic_vector'("11111111111111111110001100101011"), -- 575
          std_logic_vector'("11111111111111111110001100101011"), -- 576
          std_logic_vector'("11111111111111111110001100101011"), -- 577
          std_logic_vector'("11111111111111111110001100101011"), -- 578
          std_logic_vector'("11111111111111111110001100101011"), -- 579
          std_logic_vector'("11111111111111111110001100101011"), -- 580
          std_logic_vector'("11111111111111111110001100101011"), -- 581
          std_logic_vector'("11111111111111111110001100101011"), -- 582
          std_logic_vector'("11111111111111111110001100101011"), -- 583
          std_logic_vector'("11111111111111111110001100101011"), -- 584
          std_logic_vector'("11111111111111111110001100101011"), -- 585
          std_logic_vector'("11111111111111111110001000100110"), -- 586
          std_logic_vector'("11111111111111111110001100101011"), -- 587
          std_logic_vector'("11111111111111111110001100101011"), -- 588
          std_logic_vector'("11111111111111111110001100101011"), -- 589
          std_logic_vector'("11111111111111111110001100101011"), -- 590
          std_logic_vector'("11111111111111111110001100101011"), -- 591
          std_logic_vector'("11111111111111111110001100101011"), -- 592
          std_logic_vector'("00000000000000000000101001111101"), -- 593
          std_logic_vector'("11111111111111111110001100101011"), -- 594
          std_logic_vector'("00000000000000000000101000110110"), -- 595
          std_logic_vector'("00000000000000000000101000101100"), -- 596
          std_logic_vector'("00000000000000000000101000101100"), -- 597
          std_logic_vector'("00000000000000000000101000100010"), -- 598
          std_logic_vector'("00000000000000000000101000101100"), -- 599
          std_logic_vector'("00000000000000000000101000101100")  -- 600
        );

      -- control & counters
      signal end_of_reading : std_logic := '0';
      signal rd_count : integer := 0;
      signal wr_count : integer := 0;
      signal finished : boolean := false;

      -- Output CSV file declared at architecture scope to avoid open/close
      file results : text open write_mode is OUTPUT_FILE_NAME;

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
        -- run clock indefinitely for simulation/debugging
        loop
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

      -- Driver: feed hardcoded samples to DUT (handshake-aware)
      driver_proc: process(aclk)
        variable idx : integer range 0 to N_SAMPLES := 0;
      begin
        if rising_edge(aclk) then
          if reset = '1' then
            s_axis_a_tvalid <= '0';
            s_axis_b_tvalid <= '0';
            s_axis_a_tdata <= (others => '0');
            s_axis_b_tdata <= (others => '0');
            rd_count <= 0;
            end_of_reading <= '0';
            finished <= false;
            idx := 0;
          elsif end_of_reading = '0' then
            -- present sample when DUT can accept
            if idx < N_SAMPLES then
              -- put current/previous samples on the bus
              if idx = 0 then
                s_axis_b_tdata <= (others => '0');
              else
                s_axis_b_tdata <= samples(idx-1);
              end if;
              s_axis_a_tdata <= samples(idx);
              s_axis_a_tvalid <= '1';
              s_axis_b_tvalid <= '1';

              -- advance when handshake completes
              if s_axis_a_tvalid = '1' and s_axis_a_tready = '1' then
                rd_count <= rd_count + 1;
                -- report each time a sample is successfully handed to the DUT
                report "Driver: sent sample index " & integer'image(rd_count) severity note;
                idx := idx + 1;
                if idx = N_SAMPLES then
                  -- finished sending all samples
                  end_of_reading <= '1';
                  s_axis_a_tvalid <= '0';
                  s_axis_b_tvalid <= '0';
                  finished <= true;
                  report "Finished sending hardcoded samples. Total samples: " & integer'image(rd_count);
                end if;
              end if;
            end if;
          end if;
        end if;
      end process driver_proc;

      -- Writer: write labels to output CSV (index,label)
      writer_proc: process(aclk)
        -- Use architecture-scoped file `results` (opened once at elaboration)
        variable out_line : line;
        variable header_written : boolean := false;
        variable no_label_cycles : integer := 0;
        variable file_closed_var : boolean := false;
        constant NOLABEL_TIMEOUT : integer := 200; -- cycles to wait after last label
      begin
        if rising_edge(aclk) then
          if not header_written then
            write(out_line, string'("index,label"));
            writeline(results, out_line);
            header_written := true;
          end if;

          if not file_closed_var then
            if m_axis_label_tvalid = '1' and m_axis_label_tready = '1' then
              -- reset idle counter when we see labels
              no_label_cycles := 0;
              -- only write anomalies (label = '1')
              if m_axis_label_tdata = '1' then
                write(out_line, rd_count - 1);
                write(out_line, string'(","));
                write(out_line, string'("1"));
                writeline(results, out_line);
                wr_count <= wr_count + 1;
              end if;
            else
              -- if we've finished sending samples, start counting idle cycles
              if finished = true and end_of_reading = '1' then
                no_label_cycles := no_label_cycles + 1;
              end if;
            end if;

            -- close file when we've been idle long enough after finishing
            if finished = true and end_of_reading = '1' and no_label_cycles >= NOLABEL_TIMEOUT then
              file_close(results);
              file_closed_var := true;
              report "Results written (anomalies only): " & integer'image(wr_count);
            end if;
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