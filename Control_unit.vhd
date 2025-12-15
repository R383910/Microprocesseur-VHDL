LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY control_unit IS
	PORT(
		clk         : IN  STD_LOGIC;
		rst_n       : IN  STD_LOGIC;
		instruction : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		z_flag      : IN  STD_LOGIC;
		rx_empty    : IN  STD_LOGIC;
		acc_write   : OUT STD_LOGIC;
		pc_jump     : OUT STD_LOGIC;
		alu_op      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		mem_write   : OUT STD_LOGIC;
		alu_src     : OUT STD_LOGIC;
		uart_send   : OUT STD_LOGIC;
		uart_read   : OUT STD_LOGIC;
		load_high   : OUT STD_LOGIC;
		iram_write  : OUT STD_LOGIC;
		run_ram     : OUT STD_LOGIC;
		stack_push  : OUT STD_LOGIC;
		stack_pop   : OUT STD_LOGIC;
		is_call     : OUT STD_LOGIC;
		is_ret      : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE archi OF control_unit IS
	SIGNAL opcode : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL mode_ram_interne : STD_LOGIC := '0'; 
    
BEGIN

	opcode <= instruction(15 DOWNTO 8);

	PROCESS(clk, rst_n)
	BEGIN
		IF rst_n = '0' THEN
			mode_ram_interne <= '0';
		ELSIF rising_edge(clk) THEN
			IF opcode = "00001100" THEN
					mode_ram_interne <= instruction(0);
			END IF;
			
		END IF;
	END PROCESS;
	
	is_call <= '1' WHEN opcode = "00010010" ELSE '0';
	is_ret  <= '1' WHEN opcode = "00010011" ELSE '0';
	
	run_ram <= mode_ram_interne;
	
	acc_write <= '1' WHEN opcode = "00000000" OR -- LDA
								 opcode = "00000001" OR -- ADD
								 opcode = "00000100" OR -- SUB
								 opcode = "00000110" OR -- LDR
								 opcode = "00001000" OR -- IN
								 opcode = "00001101" OR -- AND
								 opcode = "00001110" OR -- OR
								 opcode = "00001111" OR -- XOR
								 opcode = "00010001"    -- POP
								 ELSE '0';
	
	alu_op <= "000" WHEN opcode = "00000000" ELSE -- LDA
				 "001" WHEN opcode = "00000001" ELSE -- ADD
				 "010" WHEN opcode = "00000100" ELSE -- SUB
				 "011" WHEN opcode = "00001101" ELSE -- AND
				 "100" WHEN opcode = "00001110" ELSE -- OR
				 "101" WHEN opcode = "00001111" ELSE -- XOR
				 "000";
	
	pc_jump <= '1' WHEN opcode = "00000111" OR 						   -- JMP
							  (opcode = "00000011" AND z_flag = '1') OR  -- JZ
							  (opcode = "00001001" AND rx_empty ='1') OR -- JE
							  opcode = "00010010" OR 							-- CALL 
							  opcode = "00010011"								-- RET
							  ELSE '0';
	
	mem_write <= '1' WHEN opcode = "00000101" OR -- STA
								 opcode = "00010000" OR -- PUSH
								 opcode = "00010010"    -- CALL
								 ELSE '0'; -- STA
	
	alu_src <= '1' WHEN opcode = "00000110" OR -- LDR
							  opcode = "00010001"    -- POP
							  ELSE '0';
	
	uart_send <= '1' WHEN opcode = "00000010" -- OUT
								 ELSE '0'; 
	
	uart_read <= '1' WHEN opcode = "00001000" -- IN
								 ELSE '0'; 
	
	
	load_high <= '1' WHEN opcode = "00001010" ELSE '0';
	
	iram_write <= '1' WHEN opcode = "00001011" ELSE '0';
	
	stack_push <= '1' WHEN opcode = "00010000" OR -- PUSH
								  opcode = "00010010"    -- CALL
								  ELSE '0';
	stack_pop  <= '1' WHEN opcode = "00010001" OR -- POP
								  opcode = "00010011"    -- RET
								  ELSE '0';
    
END archi;