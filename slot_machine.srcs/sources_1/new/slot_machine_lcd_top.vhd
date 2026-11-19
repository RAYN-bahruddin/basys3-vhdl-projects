library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity slot_machine_lcd_top is
    Port (
        clk  : in  STD_LOGIC;
        btnC : in  STD_LOGIC;
        btnU : in  STD_LOGIC;
        led  : out STD_LOGIC_VECTOR(15 downto 0);
        JA   : out STD_LOGIC_VECTOR(7 downto 0)
    );
end entity slot_machine_lcd_top;

architecture Behavioral of slot_machine_lcd_top is
    type state_t is (ST_IDLE, ST_SPIN_ALL, ST_SPIN_23, ST_SPIN_3, ST_EVAL, ST_WIN);
    signal state : state_t := ST_IDLE;

    signal spin_pulse  : STD_LOGIC;
    signal reset_pulse : STD_LOGIC;

    signal lfsr1 : STD_LOGIC_VECTOR(15 downto 0) := x"1D2B";
    signal lfsr2 : STD_LOGIC_VECTOR(15 downto 0) := x"84E9";
    signal lfsr3 : STD_LOGIC_VECTOR(15 downto 0) := x"F3A7";

    constant TICK_MAX : integer := 8_000_000;
    signal tick_cnt   : integer range 0 to TICK_MAX - 1 := 0;
    signal step_tick  : STD_LOGIC := '0';

    signal reel1, reel2, reel3 : unsigned(2 downto 0) := "000";
    signal credits             : integer range 0 to 99 := 10;
    signal win_code            : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal win_timer           : integer range 0 to 30 := 0;
    signal led_pattern         : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

    signal lcd_line1, lcd_line2 : STD_LOGIC_VECTOR(127 downto 0);
begin

    u_deb_spin : entity work.debounce
        port map (clk => clk, rst => '0', btn_in => btnC, btn_clean => open, btn_pulse => spin_pulse);

    u_deb_rst : entity work.debounce
        port map (clk => clk, rst => '0', btn_in => btnU, btn_clean => open, btn_pulse => reset_pulse);

    process(clk)
    begin
        if rising_edge(clk) then
            lfsr1 <= lfsr1(14 downto 0) & (lfsr1(15) xor lfsr1(13) xor lfsr1(12) xor lfsr1(10));
            lfsr2 <= lfsr2(14 downto 0) & (lfsr2(15) xor lfsr2(14) xor lfsr2(12) xor lfsr2(3));
            lfsr3 <= lfsr3(14 downto 0) & (lfsr3(15) xor lfsr3(11) xor lfsr3(9)  xor lfsr3(4));

            if tick_cnt = TICK_MAX - 1 then
                tick_cnt  <= 0;
                step_tick <= '1';
            else
                tick_cnt  <= tick_cnt + 1;
                step_tick <= '0';
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_pulse = '1' then
                state       <= ST_IDLE;
                credits     <= 10;
                win_code    <= "00";
                reel1       <= "000";
                reel2       <= "000";
                reel3       <= "000";
                led_pattern <= (others => '0');
            else
                case state is
                    when ST_IDLE =>
                        win_code    <= "00";
                        led_pattern <= std_logic_vector(to_unsigned(credits, 16));
                        if spin_pulse = '1' and credits > 0 then
                            credits  <= credits - 1;
                            win_code <= "01";
                            state    <= ST_SPIN_ALL;
                        end if;

                    when ST_SPIN_ALL =>
                        if step_tick = '1' then
                            reel1       <= unsigned(lfsr1(2 downto 0));
                            reel2       <= unsigned(lfsr2(2 downto 0));
                            reel3       <= unsigned(lfsr3(2 downto 0));
                            led_pattern <= led_pattern(14 downto 0) & (not led_pattern(15));
                        end if;
                        if spin_pulse = '1' then state <= ST_SPIN_23; end if;

                    when ST_SPIN_23 =>
                        if step_tick = '1' then
                            reel2       <= unsigned(lfsr2(2 downto 0));
                            reel3       <= unsigned(lfsr3(2 downto 0));
                            led_pattern <= led_pattern(14 downto 0) & (not led_pattern(15));
                        end if;
                        if spin_pulse = '1' then state <= ST_SPIN_3; end if;

                    when ST_SPIN_3 =>
                        if step_tick = '1' then
                            reel3       <= unsigned(lfsr3(2 downto 0));
                            led_pattern <= led_pattern(14 downto 0) & (not led_pattern(15));
                        end if;
                        if spin_pulse = '1' then state <= ST_EVAL; end if;

                    when ST_EVAL =>
                        if (reel1 = reel2) and (reel2 = reel3) then
                            if credits + 10 > 99 then credits <= 99; else credits <= credits + 10; end if;
                            win_code    <= "11";
                            win_timer   <= 25;
                            led_pattern <= x"FFFF";
                            state       <= ST_WIN;
                        elsif (reel1 = reel2) or (reel2 = reel3) or (reel1 = reel3) then
                            if credits + 3 > 99 then credits <= 99; else credits <= credits + 3; end if;
                            win_code    <= "10";
                            win_timer   <= 15;
                            led_pattern <= x"5555";
                            state       <= ST_WIN;
                        else
                            win_code    <= "00";
                            led_pattern <= (others => '0');
                            state       <= ST_IDLE;
                        end if;

                    when ST_WIN =>
                        if step_tick = '1' then
                            led_pattern <= not led_pattern;
                            if win_timer = 0 then
                                state <= ST_IDLE;
                            else
                                win_timer <= win_timer - 1;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    led <= led_pattern;

    u_text : entity work.game_text
        port map (
            reel1     => reel1,
            reel2     => reel2,
            reel3     => reel3,
            credits   => credits,
            win_code  => win_code,
            line1_out => lcd_line1,
            line2_out => lcd_line2
        );

    u_lcd : entity work.lcd_hd44780
        port map (
            clk   => clk,
            rst   => '0',
            line1 => lcd_line1,
            line2 => lcd_line2,
            JA    => JA
        );

end architecture Behavioral;