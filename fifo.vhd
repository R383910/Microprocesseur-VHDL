LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fifo IS
	PORT(
		clk       : IN  STD_LOGIC;
		rst_n     : IN  STD_LOGIC;
		
		write_en  : IN  STD_LOGIC;
		data_in   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		
		read_en   : IN  STD_LOGIC;
		data_out  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		
		empty     : OUT STD_LOGIC;
		full      : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE archi OF fifo IS
	TYPE ram_type IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL memory : ram_type;
	
	SIGNAL head : INTEGER RANGE 0 TO 15 := 0;
	SIGNAL tail : INTEGER RANGE 0 TO 15 := 0;
	
	SIGNAL count : INTEGER RANGE 0 TO 16 := 0;
    
BEGIN

	PROCESS(clk, rst_n)
	BEGIN
		IF rst_n = '0' THEN
			head  <= 0;
			tail  <= 0;
			count <= 0;
		ELSIF rising_edge(clk) THEN
			
			IF write_en = '1' AND count < 16 THEN
				memory(head) <= data_in;
				IF head = 15 THEN 
					head <= 0; 
				ELSE 
					head <= head + 1; 
				END IF;
				count <= count + 1;
			END IF;
			
			IF read_en = '1' AND count > 0 THEN
				IF tail = 15 THEN 
					tail <= 0; 
				ELSE 
					tail <= tail + 1; 
				END IF;
					
				IF write_en = '0' THEN
					count <= count - 1;
				END IF;
			ELSIF write_en = '1' AND read_en = '1' THEN
					NULL;
			END IF;
			
		END IF;
	END PROCESS;
	
	data_out <= memory(tail);
	
	empty <= '1' WHEN count = 0 ELSE '0';
	full  <= '1' WHEN count = 16 ELSE '0';

END archi;