library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_slave is
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
end entity;

architecture arc of spi_slave is
        type state_type is (IDLE,START,TRANSFER,STOP,FINISH);

        signal state : state_type;
        signal r1_sync, r2_sync, r1_edge, r2_edge : std_logic;
        signal sclk_rising_edge, sclk_falling_edge : std_logic;
        signal shift_reg : std_logic_vector(data_i'range);
        signal index : integer range -1 to FRAME_LENGTH;

    begin
        sclk_rising_edge <= not(r2_edge) and r1_edge;
        sclk_falling_edge <= r2_edge and not(r1_edge);

        TRANSFER_PROC : process(clk_i,rst_n_i)
            begin
                if rst_n_i = '0' then
                    state <= IDLE;
                    miso_o <= '0';
                    dv_o <= '0';
                elsif rising_edge(clk_i) then
                    case state is
                        when IDLE => 
                            dv_o <= '0';
                            miso_o <= '0';
                            if ss_n_i = '0' then
                                state <= START;
                            end if;
                        when START =>
                            dv_o <= '1';
                            index <= FRAME_LENGTH - 1;    
                            shift_reg <= data_i;
                            if CPHA = '0' then
                                miso_o <= data_i(FRAME_LENGTH - 1);
                            end if;
                            state <= TRANSFER;
                        when TRANSFER =>

                            if index >= 0 then
                                if sclk_rising_edge = '1' then
                                    if CPOL = '0' then
                                        if CPHA = '0' then --read miso
                                            shift_reg(index) <= mosi_i;
                                            index <= index - 1;
                                        else --write mosi
                                            miso_o <= shift_reg(index);
                                        end if;
                                    else
                                        if CPHA = '0' then --write miso
                                            miso_o <= shift_reg(index);
                                        else --read mosi
                                            shift_reg(index) <= mosi_i;
                                            index <= index - 1;
                                        end if;

                                    end if;
                                end if;

                                if sclk_falling_edge = '1' then
                                    if CPOL = '0' then
                                        if CPHA = '0' then --write miso
                                            miso_o <= shift_reg(index);
                                        else --read mosi
                                            shift_reg(index) <= mosi_i;
                                            index <= index - 1;
                                        end if;
                                    else
                                        if CPHA = '0' then --read miso
                                            shift_reg(index) <= mosi_i;
                                            index <= index - 1;
                                        else --write mosi
                                            miso_o <= shift_reg(index);
                                        end if;
                                    end if;
                                end if;
                            else
                                state <= STOP;
                            end if;
                        
                        when STOP =>
                            if ss_n_i = '1' then
                                state <= FINISH;
                            end if;
                                               
                        when FINISH =>
                            dv_o <= '0';
                            data_o <= shift_reg;
                            state <= IDLE;
                    end case;


                end if;
        end process;

        SYNC_PROC : process(clk_i,rst_n_i)
            begin
                if rst_n_i = '0' then
                    r1_sync <= '0';
                    r2_sync <= '0';
                elsif rising_edge(clk_i) then
                    r2_sync <= r1_sync;
                    r1_sync <= sclk_i;
                end if;
        end process;

        EDGE_PROC : process(clk_i,rst_n_i)
            begin
                if rst_n_i = '0' then
                    r1_edge <= '0';
                    r2_edge <= '0';
                elsif rising_edge(clk_i) then
                    r2_edge <= r1_edge;
                    r1_edge <= r2_sync;
                end if;
        end process;


end architecture;
