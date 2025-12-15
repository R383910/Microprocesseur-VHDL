LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY microprocesseur IS
	PORT(
		clk_50    : IN  STD_LOGIC;
		rst_n     : IN  STD_LOGIC;
		rx_line   : IN  STD_LOGIC;
		leds      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		tx_line   : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE archi OF microprocesseur IS

	COMPONENT rom
		PORT(
			clk      : IN  STD_LOGIC;
			address  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			data_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT alu
		PORT(
			entry_a    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			entry_b    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			operation  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
			output     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			zero_flag  : OUT STD_LOGIC;
			carry_flag : OUT STD_LOGIC
		);
	END COMPONENT;
	
	COMPONENT acc
		PORT(
			clk         : IN  STD_LOGIC;
			rst_n       : IN  STD_LOGIC;
			load_enable : IN  STD_LOGIC;
			data_in     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			data_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT pc
		PORT(
			clk         : IN  STD_LOGIC;
			rst_n       : IN  STD_LOGIC;
			load_enable : IN  STD_LOGIC;
			entry       : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			address     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT control_unit
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
	END COMPONENT;
	
	COMPONENT ram
		PORT(
			clk          : IN  STD_LOGIC;
			write_enable : IN  STD_LOGIC;
			address      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			data_in      : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			data_out     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT uart_tx
		PORT(
			clk       : IN  STD_LOGIC;
			start     : IN  STD_LOGIC;
			data_in   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			tx_serial : OUT STD_LOGIC;
			in_use    : OUT STD_LOGIC
		);
	END COMPONENT;
	
	COMPONENT uart_rx
		PORT(
			clk       : IN  STD_LOGIC;
			rx_serial : IN  STD_LOGIC;
			data_out  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			rx_dv     : OUT STD_LOGIC
		);
	END COMPONENT;
	
	COMPONENT fifo
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
	END COMPONENT;
	
	COMPONENT instruction_ram
		PORT(
			clk          : IN  STD_LOGIC;
			write_enable : IN  STD_LOGIC;
			address      : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			data_in      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			data_out     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT stack_pointer
		PORT(
			clk         : IN  STD_LOGIC;
			rst_n       : IN  STD_LOGIC;
			push_en     : IN  STD_LOGIC;
			pop_en      : IN  STD_LOGIC;
			address     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;
	
	SIGNAL internal_clk    : STD_LOGIC;
	SIGNAL addr_bus        : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL operande_propre : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL alu_res         : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL acc_val         : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ctrl_mem_write  : STD_LOGIC;
	SIGNAL ctrl_alu_src    : STD_LOGIC;
	SIGNAL ctrl_write      : STD_LOGIC;
	SIGNAL ctrl_jump       : STD_LOGIC;
	SIGNAL ctrl_alu_op     : STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL ctrl_uart_send  : STD_LOGIC;
	SIGNAL alu_zero        : STD_LOGIC; 
	SIGNAL ram_out         : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL alu_entry_b_mux : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	SIGNAL fifo_dout       : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL fifo_empty      : STD_LOGIC;
	SIGNAL uart_busy       : STD_LOGIC;
	SIGNAL trigger_transfer: STD_LOGIC;
	
	SIGNAL rx_data_link   : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL rx_dv_link     : STD_LOGIC;                   
	SIGNAL fifo_rx_dout   : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL fifo_rx_empty  : STD_LOGIC;
	SIGNAL ctrl_uart_read : STD_LOGIC;
	
	SIGNAL high_byte_buffer : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ctrl_load_high   : STD_LOGIC;
	SIGNAL ctrl_iram_write  : STD_LOGIC;
	SIGNAL ctrl_run_ram     : STD_LOGIC;
	
	SIGNAL rom_out         : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL iram_out        : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL instruction_bus : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL iram_address    : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	SIGNAL ctrl_stack_push  : STD_LOGIC;
	SIGNAL ctrl_stack_pop   : STD_LOGIC;
	
	SIGNAL ram_address           : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL stack_pointer_address : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	SIGNAL ctrl_is_call : STD_LOGIC;
	SIGNAL ctrl_is_ret  : STD_LOGIC;
	
	SIGNAL pc_entry_mux : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL ram_data_in_mux : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	SIGNAL pc_plus_un   : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL iram_data_in : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN

	pc_plus_un <= STD_LOGIC_VECTOR(UNSIGNED(addr_bus) + 1);

	internal_clk <= clk_50;
	
	instruction_bus <= iram_out WHEN ctrl_run_ram = '1' ELSE rom_out;
	
	operande_propre <= instruction_bus(7 DOWNTO 0);

	PROCESS(internal_clk)
	BEGIN
		IF rising_edge(internal_clk) THEN
			IF ctrl_load_high = '1' THEN
					high_byte_buffer <= acc_val;
			END IF;
		END IF;
	END PROCESS;
	
	rom_unit : rom 
		PORT MAP(
			clk      => internal_clk, 
			address  => addr_bus, 
			data_out => rom_out
		);
		
	iram_unit : instruction_ram
		PORT MAP(
			clk          => internal_clk,
			write_enable => ctrl_iram_write,
			address      => iram_address,
			data_in      => iram_data_in,
			data_out     => iram_out
		);
	iram_data_in <= high_byte_buffer & acc_val;
		
	iram_address <= ram_out WHEN ctrl_iram_write = '1' ELSE operande_propre;
	
	control_unit1 : control_unit 
		PORT MAP(
			clk         => internal_clk,
			rst_n       => rst_n,
			instruction => instruction_bus,
			z_flag      => alu_zero, 
			rx_empty    => fifo_rx_empty,
			acc_write   => ctrl_write, 
			pc_jump     => ctrl_jump, 
			alu_op      => ctrl_alu_op, 
			mem_write   => ctrl_mem_write, 
			alu_src     => ctrl_alu_src, 
			uart_send   => ctrl_uart_send,
			uart_read   => ctrl_uart_read,
			load_high   => ctrl_load_high,
			iram_write  => ctrl_iram_write,
			run_ram     => ctrl_run_ram,
			stack_push  => ctrl_stack_push,
			stack_pop   => ctrl_stack_pop,
			is_call     => ctrl_is_call,
			is_ret      => ctrl_is_ret
		);
		
	alu_unit : alu 
		PORT MAP(
			entry_a    => acc_val, 
			entry_b    => alu_entry_b_mux, 
			operation  => ctrl_alu_op, 
			output     => alu_res, 
			zero_flag  => alu_zero,
			carry_flag => OPEN
		);
	
	acc_unit : acc 
		PORT MAP(
			clk         => internal_clk, 
			rst_n       => rst_n, 
			load_enable => ctrl_write, 
			data_in     => alu_res, 
			data_out    => acc_val
		);
	
	pc_unit : pc 
		PORT MAP(
			clk         => internal_clk, 
			rst_n       => rst_n, 
			load_enable => ctrl_jump, 
			entry       => pc_entry_mux, 
			address     => addr_bus
		);
		
	pc_entry_mux <= (high_byte_buffer & ram_out) WHEN ctrl_is_ret = '1' 
                ELSE (high_byte_buffer & operande_propre);
	
	ram_unit : ram 
		PORT MAP(
			clk          => internal_clk, 
			write_enable => ctrl_mem_write, 
			address      => ram_address, 
			data_in      => ram_data_in_mux, 
			data_out     => ram_out
		);
	
	ram_data_in_mux <= pc_plus_un(7 DOWNTO 0) WHEN ctrl_is_call = '1' ELSE acc_val;
		
	stack_pointer_unit : stack_pointer
		PORT MAP(
			clk         => internal_clk,
			rst_n       => rst_n,
			push_en     => ctrl_stack_push,
			pop_en      => ctrl_stack_pop,
			address     => stack_pointer_address
		);
		
	ram_address <= stack_pointer_address WHEN ctrl_stack_push = '1' OR ctrl_stack_pop = '1' 
						ELSE (high_byte_buffer & operande_propre);

	trigger_transfer <= (NOT fifo_empty) AND (NOT uart_busy);
	
	fifo_tx_unit : fifo
		PORT MAP(
			clk      => internal_clk,
			rst_n    => rst_n,
			write_en => ctrl_uart_send,
			data_in  => acc_val,
			read_en  => trigger_transfer,
			data_out => fifo_dout,
			empty    => fifo_empty,
			full     => OPEN
		);
		
	uart_tx_unit : uart_tx
		PORT MAP(
			clk       => internal_clk,
			start     => trigger_transfer,
			data_in   => fifo_dout,
			tx_serial => tx_line,
			in_use    => uart_busy
		);
		
	fifo_rx_unit : fifo
		PORT MAP(
			clk      => internal_clk,
			rst_n    => rst_n,
			write_en => rx_dv_link,
			data_in  => rx_data_link,
			read_en  => ctrl_uart_read,
			data_out => fifo_rx_dout,
			empty    => fifo_rx_empty,
			full     => OPEN
		);
		
	uart_rx_unit : uart_rx
		PORT MAP(
			clk       => internal_clk,
			rx_serial => rx_line,
			data_out  => rx_data_link,
			rx_dv     => rx_dv_link
		);

	alu_entry_b_mux <= ram_out      WHEN ctrl_alu_src = '1'   ELSE
							fifo_rx_dout WHEN ctrl_uart_read = '1' ELSE
							operande_propre;
							
	leds <= acc_val;

END archi;