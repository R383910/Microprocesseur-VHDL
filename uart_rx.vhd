LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY uart_rx IS
	PORT(
		clk       : IN  STD_LOGIC;
		rx_serial : IN  STD_LOGIC;
		data_out  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		rx_dv     : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE archi OF uart_rx IS

	CONSTANT CLK_PER_BIT : INTEGER := 5208;
	
	TYPE state_type IS (IDLE, RX_START_BIT, RX_DATA_BITS, RX_STOP_BIT, CLEANUP);
	SIGNAL state : state_type := IDLE;
	
	SIGNAL timer : INTEGER RANGE 0 TO CLK_PER_BIT := 0;
	SIGNAL index : INTEGER RANGE 0 TO 7 := 0;
	SIGNAL rx_byte_temp : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

BEGIN

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            
            CASE state IS

                WHEN IDLE =>
                    rx_dv <= '0';
                    timer <= 0;
                    index <= 0;
                    
                    IF rx_serial = '0' THEN
                        state <= RX_START_BIT;
                    ELSE
                        state <= IDLE;
                    END IF;

                WHEN RX_START_BIT =>
                    IF timer < (CLK_PER_BIT / 2) - 1 THEN
                        timer <= timer + 1;
                        state <= RX_START_BIT;
                    ELSE
                        IF rx_serial = '0' THEN
                            timer <= 0;
                            state <= RX_DATA_BITS;
                        ELSE
                            state <= IDLE;
                        END IF;
                    END IF;

                WHEN RX_DATA_BITS =>
                    IF timer < CLK_PER_BIT - 1 THEN
                        timer <= timer + 1;
                        state <= RX_DATA_BITS;
                    ELSE
                        timer <= 0;
                        rx_byte_temp(index) <= rx_serial;
                        
                        IF index < 7 THEN
                            index <= index + 1;
                            state <= RX_DATA_BITS;
                        ELSE
                            index <= 0;
                            state <= RX_STOP_BIT;
                        END IF;
                    END IF;

                WHEN RX_STOP_BIT =>
                    IF timer < CLK_PER_BIT - 1 THEN
                        timer <= timer + 1;
                        state <= RX_STOP_BIT;
                    ELSE
                        timer <= 0;
                        state <= CLEANUP;
                    END IF;

                WHEN CLEANUP =>
                    data_out <= rx_byte_temp;
                    rx_dv    <= '1';
                    state    <= IDLE;
                    
            END CASE;
        END IF;
    END PROCESS;

END archi;