library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
    generic (FRAME_LENGTH : integer range 0 to 64 := 8;
             CPOL        : std_logic := '1';  --Polarity of clock
             CPHA        : std_logic := '0';  --Phase clock
             CLK_DIVIDER : integer range 0 to 100 := 25  --Divisor of the master clock to generating the sclk
            );
    port(clk_i, rst_n_i, en_i       : in  std_logic;
         dv_o                 : out std_logic;
         data_i               : in  std_logic_vector(FRAME_LENGTH - 1 downto 0);
         data_o               : in  std_logic_vector(FRAME_LENGTH - 1 downto 0);
         miso_i               : in  std_logic; --Master In Slave Out
         mosi_o               : out std_logic; --Master Out Slave In
         sclk_o               : out std_logic; --Serial clock
         ss_n_o               : out std_logic  --slaver select
    );
end entity;

architecture arc of spi_master is

    type state_type is (IDLE, START, TRANSFER, STOP);

    signal state : state_type;
    signal shift_reg : std_logic_vector(data_i'range);
    signal sclk_counter : integer range 0 to (2*CLK_DIVIDER)-1;
    signal index : integer range 0 to FRAME_LENGTH - 1;
    signal sclk : std_logic;

    begin
        sclk_o <= sclk;

        TRANSFER_PROC : process(clk_i,rst_n_i)
            begin
                if rst_n_i = '0' then
                    shift_reg <= (others=> '0');
                    dv_o <= '0';
                    mosi_o <= '0';
                    sclk <= CPOL;
                    ss_n_o <= '1';
                    sclk_counter <= 0;
                    state <= IDLE;
                elsif rising_edge(clk_i) then
                    case state is
                        when IDLE =>
                            dv_o <= '0';
                            mosi_o <= '0';
                            sclk <= CPOL;
                            ss_n_o <= '1';
                            if en_i = '1' then
                                state <= START;
                            else
                                state <= IDLE;
                            end if;
                        when START =>
                            dv_o <= '1';
                            ss_n_o <= '0';
                            sclk_counter <= 0;
                            index <= FRAME_LENGTH - 1;
                            shift_reg <= data_i;
                            state <= START;
                        when TRANSFER =>

                            sclk_counter <= sclk_counter + 1;
                            index <= index - 1;
                            if sclk_counter = CLK_DIVIDER - 1 then
                                sclk <= not sclk;
                                if CPOL = '0' then
                                    if sclk = '0' then --rising sclk edge
                                        if CPHA = '0' then --read miso
                                            shift_reg(index) <= miso_i;
                                        else --write mosi
                                            mosi_o <= shift_reg(index);
                                        end if;
                                    else --falling sclk edge
                                        if CPHA = '0' then --write mosi
                                            mosi_o <= shift_reg(index);
                                        else --read miso
                                            shift_reg(index) <= miso_i;
                                        end if;
                                    end if;
                                else
                                    if sclk = '1' then --falling sclk edge
                                        if CPHA = '0' then --read miso
                                            shift_reg(index) <= miso_i;
                                        else --write mosi
                                            mosi_o <= shift_reg(index);
                                        end if;
                                    else --rising sclk edge
                                        if CPHA = '0' then --write mosi
                                            mosi_o <= shift_reg(index);
                                        else --read miso
                                            shift_reg(index) <= miso_i;
                                        end if;
                                    end if;
                                end if;
                            end if;

                            if index = 0 then
                                state <= STOP;
                            else
                                state <= TRANSFER;
                            end if;

                        when STOP =>
                            sclk <= CPOL;
                            dv_o <= '0';
                            ss_n_o <= '1';
                            state <= IDLE;
                    end case;
                end if;
        end process;

end architecture;



