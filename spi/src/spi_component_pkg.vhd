library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package spi_component_pkg is
    component spi_master is
        generic (FRAME_LENGTH : integer range 0 to 64 := 8;
                CPOL        : std_logic := '1';  --Polarity of clock
                CPHA        : std_logic := '0';  --Phase clock
                CLK_DIVIDER : integer range 0 to 100 := 25  --Divisor of the master clock to generating the sclk
                );
        port(clk_i, rst_n_i,en_i      : in  std_logic;
            dv_o                 : out std_logic;
            data_i               : in  std_logic_vector(FRAME_LENGTH - 1 downto 0);
            data_o               : out  std_logic_vector(FRAME_LENGTH - 1 downto 0);
            miso_i               : in  std_logic; --Master In Slave Out
            mosi_o               : out std_logic; --Master Out Slave In
            sclk_o               : out std_logic; --Serial clock
            ss_n_o               : out std_logic  --slaver select
            );
        end component;

        component spi_slave is
            generic (FRAME_LENGTH : integer range 0 to 64 := 8;
                     CPOL        : std_logic := '1';  --Polarity of clock
                     CPHA        : std_logic := '0'  --Phase clock
            );
            port(clk_i, rst_n_i       : in  std_logic;
                    dv_o                 : out std_logic;
                    data_i               : in  std_logic_vector(FRAME_LENGTH - 1 downto 0);
                    data_o               : out std_logic_vector(FRAME_LENGTH - 1 downto 0);
                    miso_o               : out std_logic; --Master In Slave Out
                    mosi_i               : in  std_logic; --Master Out Slave In
                    sclk_i               : in  std_logic; --Serial clock
                    ss_n_i               : in  std_logic  --slaver select
            );
            end component;
end package;