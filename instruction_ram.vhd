LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY instruction_ram IS
	PORT(
		clk          : IN  STD_LOGIC;
		write_enable : IN  STD_LOGIC;
		address      : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		data_in      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_out     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE archi OF instruction_ram IS
	TYPE instruction_ram_type IS ARRAY (0 TO 4095) OF STD_LOGIC_VECTOR(15 DOWNTO 0);

	SIGNAL instruction_ram_block : instruction_ram_type;

BEGIN

	PROCESS(clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF write_enable = '1' THEN
				instruction_ram_block(to_integer(unsigned(address))) <= data_in;
			END IF;
			data_out <= instruction_ram_block(to_integer(unsigned(address)));
		END IF;
	END PROCESS;

END archi;