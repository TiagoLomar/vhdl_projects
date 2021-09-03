library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.uart_component_pkg.all;

entity tb_uart_tx is
end tb_uart_tx;

architecture arc of tb_uart_tx is
    -- Numero de Bits = 8
    -- Baud Rate = 115200 bits/seg
    -- Parity = None
    -- Stop bit = none
    constant c_NUM_DATA_BIT : integer := 8;
    constant c_CLK_PER_BIT : integer := 434;
    constant c_BOUND_TIME : time := 8680 ns;--8.68
    constant c_CLK_TIME : time := 10 ns; --clk frequencie 50Mhz

    signal clk : std_logic;
    signal rx_serial, rx_dv, tx_serial, tx_dv, tx_active, tx_done : std_logic;
    signal rx_byte, tx_byte : std_logic_vector(c_NUM_DATA_BIT -1 downto 0);

    begin
        rx_serial <= tx_serial;

        T_UART_RX : uart_rx 
            port map(i_clk => clk, i_rx_serial => rx_serial, o_rx_dv => rx_dv, o_rx_byte => rx_byte);
        T_UART_TX : uart_tx
            port map(i_clk => clk, i_tx_dv => tx_dv, i_tx_byte => tx_byte, o_tx_active => tx_active, o_tx_serial => tx_serial, o_tx_done => tx_done);

        PROC_SEQ : process
            begin
                tx_dv <= '1';
                tx_byte <= "10101010";
                wait until tx_done = '1';
                tx_dv <= '0';
                wait until rising_edge(clk);
                wait until rising_edge(clk);  
                report "End of testbench" severity failure;

                
        end process;
        
        PROC_CHECK_TX : process
            begin
                wait until tx_dv = '1';
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                assert tx_active = '1' report "tx_active should be 1" severity failure;
                wait until rx_dv =  '1';
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                assert tx_byte = rx_byte report "Data reciver is not equal data send" severity failure; 
               
                
        end process;

        PROC_CLK : process
            begin
                clk <= '0';
                wait for c_CLK_TIME;
                clk <= '1';
                wait for c_CLK_TIME;
        end process;



end architecture;