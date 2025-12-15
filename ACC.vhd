LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY acc IS

	PORT(
		clk         : IN  STD_LOGIC;
		rst_n       : IN  STD_LOGIC;
		load_enable : IN  STD_LOGIC;
		data_in     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		data_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);

END ENTITY;

ARCHITECTURE archi OF acc IS
	SIGNAL intern_memory : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN

	PROCESS(clk, rst_n)
	BEGIN
		IF rst_n = '0' THEN
			intern_memory <= (OTHERS => '0');
		ELSE
			IF rising_edge(clk) THEN
				IF load_enable = '1' THEN
					intern_memory <= data_in;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
	data_out <= intern_memory;
	
END archi;