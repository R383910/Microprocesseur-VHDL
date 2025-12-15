LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY uart_tx IS
	PORT(
		clk       : IN  STD_LOGIC;
		start     : IN  STD_LOGIC;
		data_in   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		tx_serial : OUT STD_LOGIC;
		in_use    : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE archi OF uart_tx IS

    CONSTANT CLK_PER_BIT : INTEGER := 5208;

    TYPE state_type IS (IDLE, TX_START, TX_DATA, TX_STOP);
    SIGNAL state : state_type := IDLE;

    SIGNAL timer   : INTEGER RANGE 0 TO CLK_PER_BIT := 0;
    SIGNAL index   : INTEGER RANGE 0 TO 7 := 0;
    SIGNAL data_buffer : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            
            CASE state IS
                
                WHEN IDLE =>
                    tx_serial <= '1';
                    in_use <= '0';
                    timer <= 0;
                    index <= 0;
                    
                    IF start = '1' THEN
                        data_buffer <= data_in;
                        state <= TX_START;
                        in_use <= '1';
                    END IF;

                WHEN TX_START =>
                    tx_serial <= '0';
                    
                    IF timer < CLK_PER_BIT - 1 THEN
                        timer <= timer + 1;
                    ELSE
                        timer <= 0;
                        state <= TX_DATA;
                    END IF;

                WHEN TX_DATA =>
                    tx_serial <= data_buffer(index);
                    
                    IF timer < CLK_PER_BIT - 1 THEN
                        timer <= timer + 1;
                    ELSE
                        timer <= 0;
                        IF index < 7 THEN
                            index <= index + 1;
                        ELSE
                            index <= 0;
                            state <= TX_STOP;
                        END IF;
                    END IF;

                WHEN TX_STOP =>
                    tx_serial <= '1';
                    
                    IF timer < CLK_PER_BIT - 1 THEN
                        timer <= timer + 1;
                    ELSE
                        state <= IDLE;
                        in_use <= '0';
                    END IF;
                    
            END CASE;
        END IF;
    END PROCESS;

END archi;