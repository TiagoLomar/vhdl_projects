library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spi_master is
end entity;

use work.spi_component_pkg.all;

architecture arc of tb_spi_master is

    constant CLK_HALF_PERIOD : time := 10 ns;

    constant FRAME_LENGTH : integer range 0 to 64 := 8;
    constant CPOL         : std_logic := '1';
    constant CPHA         : std_logic := '1';
    constant CLK_DIVIDER  : integer range 0 to 100 := 25; -- sclk = clk/(2*CLK_DIVIDER)

    constant BUFFER_SIZE : integer range 0 to 10 := 4;

    type spi_buffer_type is array(natural range <>) of std_logic_vector(FRAME_LENGTH - 1 downto 0);

    signal clk_i,rst_n_i,en_i,dv_o     : std_logic;
    signal miso_i,mosi_o,sclk_o,ss_n_o : std_logic;
    signal data_i,data_o               : std_logic_vector(FRAME_LENGTH - 1 downto 0);

    signal master_buffer : spi_buffer_type (BUFFER_SIZE - 1 downto 0) := (x"A9",x"00",x"C4","10101010");
    signal slave_buffer  : spi_buffer_type (BUFFER_SIZE - 1 downto 0) := (x"10",x"C0","01010111","01010101");

    
    begin

        T_spi_master : spi_master
            generic map(FRAME_LENGTH => FRAME_LENGTH,
                        CPOL         => CPOL,
                        CPHA         => CPHA,
                        CLK_DIVIDER  => CLK_DIVIDER
                        )
            port    map(clk_i   => clk_i,
                        rst_n_i => rst_n_i,
                        en_i    => en_i,
                        dv_o    => dv_o,
                        data_i  => data_i,
                        data_o  => data_o,
                        miso_i  => miso_i,
                        mosi_o  => mosi_o,
                        sclk_o  => sclk_o,
                        ss_n_o  => ss_n_o
                        );

        PROC_SEQ : process
            variable test_master, test_slave  : std_logic_vector(FRAME_LENGTH - 1 downto 0);
            begin
                rst_n_i <= '0';
                wait until rising_edge(clk_i);
                wait until rising_edge(clk_i);
                rst_n_i <= '1';
                en_i <= '0';

                for i in 0 to BUFFER_SIZE - 1 loop
                    test_master := slave_buffer(i);
                    test_slave  := master_buffer(i);
                    wait for 1 ns;

                    data_i <= master_buffer(i);
                    wait until rising_edge(clk_i);
                    wait until rising_edge(clk_i);
                    en_i <='1';
                    wait until dv_o = '1';
                    wait until dv_o = '0';
                    en_i <= '0';
                    master_buffer(i) <= data_o;
                    wait until rising_edge(clk_i);

                    report "Buffer position " & integer'image(i) severity note;
                    report "Slave send: " & integer'image(to_integer(unsigned(test_master)))& 
                           " Master receive: " & integer'image(to_integer(unsigned(master_buffer(i))))severity note;
                    report "Master send: " & integer'image(to_integer(unsigned(test_slave)))& 
                           " Slave receive: " & integer'image(to_integer(unsigned(slave_buffer(i)))) severity note;
                           
                    --test check
                    assert master_buffer(i) = test_master report "Master buffer in position " & integer'image(i) & " is not correct" severity failure;
                    assert slave_buffer(i) = test_slave report "Slave buffer in position " & integer'image(i) & " is not correct" severity failure;

                end loop;

                wait until rising_edge(clk_i);
                report "End testbentch" severity failure;
                


        end process;

        PROC_SPI_SLAVE_MODEL : process
            begin
                for i in 0 to BUFFER_SIZE - 1 loop
                    wait until ss_n_o = '0';
                    if CPHA = '0' then
                        miso_i <= slave_buffer(i)(FRAME_LENGTH - 1);
                    end if;
                    for j in FRAME_LENGTH - 1  downto 0 loop
                        if CPOL = '0' then
                            wait until rising_edge(sclk_o);
                            if CPHA = '0' then
                                slave_buffer(i)(j) <= mosi_o;
                                wait until falling_edge(sclk_o);
                                if j > 0 then
                                    miso_i <= slave_buffer(i)(j-1);
                                end if;
                            else
                                miso_i <= slave_buffer(i)(j);
                                wait until falling_edge(sclk_o);
                                slave_buffer(i)(j) <= mosi_o;
                            end if;
                        else
                            wait until falling_edge(sclk_o);
                            if CPHA = '0' then
                                slave_buffer(i)(j) <= mosi_o;
                                wait until rising_edge(sclk_o);
                                if j > 0 then
                                    miso_i <= slave_buffer(i)(j-1);
                                end if;
                            else
                                miso_i <= slave_buffer(i)(j);
                                wait until rising_edge(sclk_o);
                                slave_buffer(i)(j) <= mosi_o;
                            end if;
                        end if;
                    end loop;
                    wait until ss_n_o = '1';
                end loop;
        end process;

        PROC_CLK : process
            begin
                clk_i <= '0';
                wait for CLK_HALF_PERIOD;
                clk_i <= '1';
                wait for CLK_HALF_PERIOD;
        end process;

end architecture;