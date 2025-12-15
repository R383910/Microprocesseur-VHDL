LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pc IS
	PORT(
		clk         : IN  STD_LOGIC;
		rst_n       : IN  STD_LOGIC;
		load_enable : IN  STD_LOGIC;
		entry       : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		address     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE archi OF pc IS
	SIGNAL intern_value : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN
	PROCESS(clk, rst_n)
	BEGIN
		IF rst_n = '0' THEN
			intern_value <= (OTHERS => '0');
		ELSE
			IF rising_edge(clk) THEN
				IF load_enable = '1' THEN
                intern_value <= entry;
            ELSE
                intern_value <= STD_LOGIC_VECTOR(UNSIGNED(intern_value) + 1);
            END IF;
			END IF;
		END IF;
	END PROCESS;
	
	address <= intern_value;
	
END archi;