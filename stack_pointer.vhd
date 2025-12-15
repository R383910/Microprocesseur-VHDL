LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY stack_pointer IS
	PORT(
		clk         : IN  STD_LOGIC;
		rst_n       : IN  STD_LOGIC;
		push_en     : IN  STD_LOGIC;
		pop_en      : IN  STD_LOGIC;
		address     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE archi OF stack_pointer IS
	SIGNAL intern_value : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN
	PROCESS(clk, rst_n)
	BEGIN
		IF rst_n = '0' THEN
			intern_value <= (OTHERS => '1');
		ELSE
			IF rising_edge(clk) THEN
				IF push_en = '1' THEN
                intern_value <= STD_LOGIC_VECTOR(UNSIGNED(intern_value) -1);
            ELSE
               IF pop_en = '1' THEN
						intern_value <= STD_LOGIC_VECTOR(UNSIGNED(intern_value) +1);
					END IF;
            END IF;
			END IF;
		END IF;
	END PROCESS;
	
	address <= intern_value;
	
END archi;