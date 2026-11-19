library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity slot_machine_top_v2 is
    Port (
        clk  : in  STD_LOGIC;
        btnC : in  STD_LOGIC; -- Mulai spin & hentikan reel 1 -> 2 -> 3
        btnU : in  STD_LOGIC; -- Reset kredit ke 5
        led  : out STD_LOGIC_VECTOR(15 downto 0);
        seg  : out STD_LOGIC_VECTOR(6 downto 0);
        an   : out STD_LOGIC_VECTOR(3 downto 0);
        dp   : out STD_LOGIC
    );
end entity slot_machine_top_v2;

architecture Behavioral of slot_machine_top_v2 is
    type state_t is (ST_IDLE, ST_SPIN_ALL, ST_SPIN_23, ST_SPIN_3, ST_EVAL, ST_WIN);
    signal state : state_t := ST_IDLE;

    signal spin_pulse  : STD_LOGIC;
    signal reset_pulse : STD_LOGIC;

    -- 3x 16-bit LFSR RNG dengan seed berbeda
    signal lfsr1 : STD_LOGIC_VECTOR(15 downto 0) := x"ACE1";
    signal lfsr2 : STD_LOGIC_VECTOR(15 downto 0) := x"BEEF";
    signal lfsr3 : STD_LOGIC_VECTOR(15 downto 0) := x"CAFE";

    -- Pembagi kecepatan putaran reel & efek LED (~12 Hz)
    constant TICK_MAX : integer := 8_000_000;
    signal tick_cnt   : integer range 0 to TICK_MAX - 1 := 0;
    signal step_tick  : STD_LOGIC := '0';

    signal reel1, reel2, reel3 : unsigned(2 downto 0) := "111";
    signal credits             : integer range 0 to 9 := 5;
    signal win_timer           : integer range 0 to 30 := 0;
    signal led_pattern         : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

    signal d0, d1, d2, d3 : STD_LOGIC_VECTOR(4 downto 0);
begin

    u_deb_spin : entity work.debounce
        port map (clk => clk, rst => '0', btn_in => btnC, btn_clean => open, btn_pulse => spin_pulse);

    u_deb_rst : entity work.debounce
        port map (clk => clk, rst => '0', btn_in => btnU, btn_clean => open, btn_pulse => reset_pulse);

    -- LFSR 16-bit berjalan terus setiap siklus clock untuk entropi acak
    process(clk)
    begin
        if rising_edge(clk) then
            lfsr1 <= lfsr1(14 downto 0) & (lfsr1(15) xor lfsr1(13) xor lfsr1(12) xor lfsr1(10));
            lfsr2 <= lfsr2(14 downto 0) & (lfsr2(15) xor lfsr2(14) xor lfsr2(12) xor lfsr2(3));
            lfsr3 <= lfsr3(14 downto 0) & (lfsr3(15) xor lfsr3(11) xor lfsr3(9)  xor lfsr3(4));
        end if;
    end process;

    -- Generator tick animasi
    process(clk)
    begin
        if rising_edge(clk) then
            if tick_cnt = TICK_MAX - 1 then
                tick_cnt  <= 0;
                step_tick <= '1';
            else
                tick_cnt  <= tick_cnt + 1;
                step_tick <= '0';
            end if;
        end if;
    end process;

    -- FSM Utama Slot Machine
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_pulse = '1' then
                state       <= ST_IDLE;
                credits     <= 5;
                reel1       <= "111";
                reel2       <= "111";
                reel3       <= "111";
                led_pattern <= (others => '0');
            else
                case state is
                    when ST_IDLE =>
                        led_pattern <= std_logic_vector(to_unsigned(credits, 16));
                        if spin_pulse = '1' and credits > 0 then
                            credits <= credits - 1;
                            state   <= ST_SPIN_ALL;
                        end if;

                    when ST_SPIN_ALL =>
                        if step_tick = '1' then
                            reel1       <= unsigned(lfsr1(2 downto 0));
                            reel2       <= unsigned(lfsr2(2 downto 0));
                            reel3       <= unsigned(lfsr3(2 downto 0));
                            led_pattern <= led_pattern(14 downto 0) & (not led_pattern(15));
                        end if;
                        if spin_pulse = '1' then
                            state <= ST_SPIN_23;
                        end if;

                    when ST_SPIN_23 =>
                        if step_tick = '1' then
                            reel2       <= unsigned(lfsr2(2 downto 0));
                            reel3       <= unsigned(lfsr3(2 downto 0));
                            led_pattern <= led_pattern(14 downto 0) & (not led_pattern(15));
                        end if;
                        if spin_pulse = '1' then
                            state <= ST_SPIN_3;
                        end if;

                    when ST_SPIN_3 =>
                        if step_tick = '1' then
                            reel3       <= unsigned(lfsr3(2 downto 0));
                            led_pattern <= led_pattern(14 downto 0) & (not led_pattern(15));
                        end if;
                        if spin_pulse = '1' then
                            state <= ST_EVAL;
                        end if;

                    when ST_EVAL =>
                        if (reel1 = reel2) and (reel2 = reel3) then
                            -- Jackpot 3 simbol sama (+5 kredit)
                            if credits + 5 > 9 then credits <= 9; else credits <= credits + 5; end if;
                            win_timer   <= 24;
                            led_pattern <= x"AAAA";
                            state       <= ST_WIN;
                        elsif (reel1 = reel2) or (reel2 = reel3) or (reel1 = reel3) then
                            -- Menang parsial 2 simbol sama (+2 kredit)
                            if credits + 2 > 9 then credits <= 9; else credits <= credits + 2; end if;
                            win_timer   <= 12;
                            led_pattern <= x"5555";
                            state       <= ST_WIN;
                        else
                            led_pattern <= (others => '0');
                            state       <= ST_IDLE;
                        end if;

                    when ST_WIN =>
                        -- Efek LED berkedip/api saat menang
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

    d3 <= std_logic_vector(to_unsigned(credits, 5));     -- Kiri: sisa kredit
    d2 <= "00" & std_logic_vector(reel1);                -- Reel 1
    d1 <= "00" & std_logic_vector(reel2);                -- Reel 2
    d0 <= "00" & std_logic_vector(reel3);                -- Reel 3

    led <= led_pattern;

    u_seg7 : entity work.seg7_ctrl
        port map (
            clk    => clk,
            rst    => '0',
            digit0 => d0,
            digit1 => d1,
            digit2 => d2,
            digit3 => d3,
            dp_in  => "1000", -- Pemisah titik antara kredit dan reel
            seg    => seg,
            an     => an,
            dp     => dp
        );

end architecture Behavioral;