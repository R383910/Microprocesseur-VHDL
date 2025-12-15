LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY rom IS
	PORT(
		clk      : IN  STD_LOGIC;
		address  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE archi OF rom IS
	TYPE rom_type IS ARRAY (0 TO 4095) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	SIGNAL rom_block : rom_type := (others => (others => '0'));
	
	ATTRIBUTE ram_init_file : string;
	ATTRIBUTE ram_init_file OF rom_block : SIGNAL IS "programme.mif";

BEGIN

	PROCESS(clk)
	BEGIN
		IF rising_edge(clk) THEN
			data_out <= rom_block(to_integer(unsigned(address)));
		END IF;
	END PROCESS;

END archi;