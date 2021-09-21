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
         data_o               : out  std_logic_vector(FRAME_LENGTH - 1 downto 0);
         miso_i               : in  std_logic; --Master In Slave Out
         mosi_o               : out std_logic; --Master Out Slave In
         sclk_o               : out std_logic; --Serial clock
         ss_n_o               : out std_logic  --slaver select
    );
end entity;

architecture arc of spi_master is

    type state_type is (IDLE, START, TRANSFER, STOP, FINISH);

    signal state : state_type;
    signal shift_reg : std_logic_vector(data_i'range);
    
    signal en_sclk_counter : std_logic;
    signal sclk : std_logic;
    signal sclk_counter : integer range 0 to CLK_DIVIDER;
    signal sclk_rising_edge, sclk_falling_edge : std_logic;
    signal r1_edge,r2_edge :std_logic;
    signal index : integer range -1 to FRAME_LENGTH;
   

    begin
        sclk_o <= r2_edge;
        sclk_rising_edge <= not(r2_edge) and r1_edge;
        sclk_falling_edge <= r2_edge and not(r1_edge);

        TRANSFER_PROC : process(clk_i,rst_n_i)
            begin
                if rst_n_i = '0' then
                    shift_reg <= (others=> '0');
                    dv_o <= '0';
                    mosi_o <= '0';
                    ss_n_o <= '1';
                    en_sclk_counter <= '0';
                    state <= IDLE;
                elsif rising_edge(clk_i) then
                    case state is
                        when IDLE =>
                            dv_o <= '0';
                            mosi_o <= '0';
                            ss_n_o <= '1';
                            en_sclk_counter <= '0';
                            if en_i = '1' then
                                state <= START;
                            else
                                state <= IDLE;
                            end if;
                        when START =>
                            dv_o <= '1';
                            ss_n_o <= '0';
                            en_sclk_counter <= '1';
                            index <= FRAME_LENGTH - 1;
                            shift_reg <= data_i;
                            if CPHA = '0' then
                                mosi_o <= data_i(FRAME_LENGTH - 1);
                            end if;
                            state <= TRANSFER;
                        when TRANSFER =>
                            
                            if index >= 0 then
                                if sclk_rising_edge = '1' then
                                    if CPOL = '0' then
                                        if CPHA = '0' then --read miso
                                            shift_reg(index) <= miso_i;
                                            index <= index - 1;
                                        else --write mosi
                                            mosi_o <= shift_reg(index);
                                        end if;
                                    else
                                        if CPHA = '0' then --write miso
                                            mosi_o <= shift_reg(index);
                                        else --read mosi
                                            shift_reg(index) <= miso_i;
                                            index <= index - 1;
                                        end if;

                                    end if;
                                end if;

                                if sclk_falling_edge = '1' then
                                    if CPOL = '0' then
                                        if CPHA = '0' then --write miso
                                            mosi_o <= shift_reg(index);
                                        else --read mosi
                                            shift_reg(index) <= miso_i;
                                            index <= index - 1;
                                        end if;
                                    else
                                        if CPHA = '0' then --read miso
                                            shift_reg(index) <= miso_i;
                                            index <= index - 1;
                                        else --write mosi
                                            mosi_o <= shift_reg(index);
                                        end if;
                                    end if;
                                end if;
                            else
                                state <= STOP;
                            end if;

                        when STOP =>

                            if (sclk_falling_edge = '1' or sclk_rising_edge = '1') then
                                state <= FINISH;
                            end if;

                        when FINISH =>
                            en_sclk_counter <= '0';
                            dv_o <= '0';
                            ss_n_o <= '1';
                            data_o <= shift_reg;
                            state <= IDLE;
                    end case;
                end if;
        end process;

        SCLK_PROC : process(clk_i)
            begin
                if en_sclk_counter = '0' then
                    sclk_counter <= 0;
                    sclk <= CPOL;
                elsif rising_edge (clk_i) then
                    if sclk_counter < CLK_DIVIDER - 2 then
                        sclk_counter <= sclk_counter + 1;
                    else
                        sclk_counter <= 0;
                        sclk <= not sclk;
                    end if;
                end if;
        end process;

        EDGE_PROC : process(clk_i, rst_n_i)
            begin
                if rst_n_i = '0' then
                    r1_edge <= '1';
                    r2_edge <= '1';
                elsif rising_edge(clk_i) then
                    r1_edge <= sclk;
                    r2_edge <= r1_edge;
                end if;
        end process;

end architecture;



