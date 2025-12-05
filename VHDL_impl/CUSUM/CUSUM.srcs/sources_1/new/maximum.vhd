----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2025 11:17:42 AM
-- Design Name: 
-- Module Name: maximum - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity maximum is
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
end maximum;

architecture Behavioral of maximum is
type state_type is (S_READ, S_WRITE);
	signal state : state_type := S_READ;

	signal result : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal zero : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal internal_ready, external_ready, inputs_valid : STD_LOGIC := '0';

begin
	-- ready/valid handshake wiring
	s_axis_a_tready <= external_ready;

	internal_ready <= '1' when state = S_READ else '0';
	inputs_valid <= s_axis_a_tvalid;
	external_ready <= internal_ready and inputs_valid;

	m_axis_result_tvalid <= '1' when state = S_WRITE else '0';
	m_axis_result_tdata <= result;

	process(aclk)
	begin
		if rising_edge(aclk) then
			if reset = '1' then
				state <= S_READ;
				result <= zero;
			else
				case state is
					when S_READ =>
						if external_ready = '1' and inputs_valid = '1' then
							-- perform comp
							-- Treat negative when MSB (bit 31) = '1' (explicit sign-bit check)
							if s_axis_a_tdata(31) = '1' then
								result <= zero;
							else
								result <= s_axis_a_tdata;
							end if;
							state <= S_WRITE;
						end if;

					when S_WRITE =>
						if m_axis_result_tready = '1' then
							state <= S_READ;
						end if;
				end case;
			end if;
		end if;
	end process;

end Behavioral;