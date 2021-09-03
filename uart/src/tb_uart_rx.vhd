library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.uart_component_pkg.all;

entity tb_uart_rx is
end tb_uart_rx;

architecture arc of tb_uart_rx is
    -- Numero de Bits = 8
    -- Baud Rate = 115200 bits/seg
    -- Parity = None
    -- Stop bit = none
    constant c_NUM_DATA_BIT : integer := 8;
    constant c_CLK_PER_BIT : integer := 434;
    constant c_BOUND_TIME : time := 8680 ns;--8.68
    constant c_CLK_TIME : time := 10 ns; --clk frequencie 50Mhz

    signal clk : std_logic;
    signal rx_serial, rx_dv : std_logic;
    signal rx_byte : std_logic_vector(c_NUM_DATA_BIT -1 downto 0);

    procedure send_data_uart ( data : in std_logic_vector(c_NUM_DATA_BIT - 1 downto 0);
                              signal  serial_data : out std_logic) is
        begin
            serial_data <= '1';
            wait for c_BOUND_TIME;
            serial_data <= '0';
            wait for c_BOUND_TIME;
            for i in data'reverse_range loop
                serial_data <= data(i);
                wait for c_BOUND_TIME;
            end loop;
            serial_data <= '1';
            wait for c_BOUND_TIME;
    end procedure;


    begin

        T_UART_RX : uart_rx 
            port map(i_clk => clk, i_rx_serial => rx_serial, o_rx_dv => rx_dv, o_rx_byte => rx_byte);

        PROC_SEQ : process
            begin
                send_data_uart("10101010",rx_serial);

                wait until rising_edge(clk);
                wait until rising_edge(clk);  
                report "End of testbench" severity failure;
        end process;
        
        PROC_CHECK_RX : process
            begin
                wait until rx_dv =  '1';
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                assert "10101010" = rx_byte report "Data reciver is not equal data send" severity failure; 
                
        end process;

        PROC_CLK : process
            begin
                clk <= '0';
                wait for c_CLK_TIME;
                clk <= '1';
                wait for c_CLK_TIME;
        end process;



end architecture;