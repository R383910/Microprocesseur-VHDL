LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY alu IS
	PORT(
		entry_a    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		entry_b    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		operation  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
		output     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		zero_flag  : OUT STD_LOGIC;
		carry_flag : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE archi OF alu IS
	SIGNAL res_temp : UNSIGNED(7 DOWNTO 0);
BEGIN

	WITH operation SELECT
	res_temp <= UNSIGNED(entry_b) WHEN "000",
					UNSIGNED(entry_a) + UNSIGNED(entry_b) WHEN "001",
					UNSIGNED(entry_a) - UNSIGNED(entry_b) WHEN "010",
					UNSIGNED(entry_a AND entry_b) WHEN "011",
					UNSIGNED(entry_a OR entry_b) WHEN "100",
					UNSIGNED(entry_a XOR entry_b) WHEN "101",
					(OTHERS => '0') WHEN OTHERS;

    output <= STD_LOGIC_VECTOR(res_temp);

    zero_flag <= '1' WHEN res_temp = 0 ELSE '0';

END archi;