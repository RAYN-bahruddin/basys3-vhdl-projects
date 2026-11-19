library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity slot_machine_vga_top is
    Port (
        clk      : in  STD_LOGIC;
        btnC     : in  STD_LOGIC;
        btnR     : in  STD_LOGIC;
        sw       : in  STD_LOGIC_VECTOR(15 downto 0);
        led      : out STD_LOGIC_VECTOR(15 downto 0);
        seg      : out STD_LOGIC_VECTOR(6 downto 0);
        dp       : out STD_LOGIC;
        an       : out STD_LOGIC_VECTOR(3 downto 0);
        Hsync    : out STD_LOGIC;
        Vsync    : out STD_LOGIC;
        vgaRed   : out STD_LOGIC_VECTOR(3 downto 0);
        vgaGreen : out STD_LOGIC_VECTOR(3 downto 0);
        vgaBlue  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end entity slot_machine_vga_top;

architecture Behavioral of slot_machine_vga_top is
    type state_t is (IDLE, SPIN_123, SPIN_23, SPIN_3, CHECK_WIN);
    signal state : state_t := IDLE;

    -- 3 LFSR RNG independen
    signal lfsr1 : STD_LOGIC_VECTOR(15 downto 0) := x"ACE1";
    signal lfsr2 : STD_LOGIC_VECTOR(15 downto 0) := x"BEEF";
    signal lfsr3 : STD_LOGIC_VECTOR(15 downto 0) := x"CAFE";

    -- Nilai digit tampilan (0..9)
    signal spin_cnt : unsigned(3 downto 0) := (others => '0');
    signal reel1    : STD_LOGIC_VECTOR(3 downto 0) := "0111"; -- 7
    signal reel2    : STD_LOGIC_VECTOR(3 downto 0) := "0111"; -- 7
    signal reel3    : STD_LOGIC_VECTOR(3 downto 0) := "0111"; -- 7
    signal win_flag : STD_LOGIC := '0';

    -- Debounce & Edge Detector tombol btnC
    signal btn_sync  : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal btn_clean : STD_LOGIC := '0';
    signal btn_prev  : STD_LOGIC := '0';
    signal spin_trig : STD_LOGIC := '0';
    signal db_cnt    : integer range 0 to 1_000_000 := 0;

    -- Timer putaran gulungan
    signal step_timer : integer range 0 to 50_000_000 := 0;
    signal step_count : integer range 0 to 15 := 0;

    -- Multiplexer 7-Segment fisik
    signal mux_cnt  : unsigned(17 downto 0) := (others => '0');
    signal cur_nib  : STD_LOGIC_VECTOR(3 downto 0);

    -- Sinyal internal penghubung VGA
    signal w_video_on : STD_LOGIC;
    signal w_pix_x    : STD_LOGIC_VECTOR(9 downto 0);
    signal w_pix_y    : STD_LOGIC_VECTOR(9 downto 0);

    function to_bcd(v : STD_LOGIC_VECTOR(3 downto 0)) return STD_LOGIC_VECTOR is
        variable u : unsigned(3 downto 0);
    begin
        u := unsigned(v);
        if u > 9 then
            u := u - 10;
        end if;
        return std_logic_vector(u);
    end function;
begin

    -- 1. Debounce tombol btnC (10 ms di hardware, 100 ns jika sw(1)='1')
    process(clk)
        variable db_limit : integer;
    begin
        if rising_edge(clk) then
            if sw(1) = '1' then
                db_limit := 10;
            else
                db_limit := 1_000_000;
            end if;

            btn_sync <= btn_sync(0) & btnC;
            if btn_sync(1) /= btn_clean then
                if db_cnt >= db_limit then
                    btn_clean <= btn_sync(1);
                    db_cnt    <= 0;
                else
                    db_cnt <= db_cnt + 1;
                end if;
            else
                db_cnt <= 0;
            end if;

            btn_prev  <= btn_clean;
            spin_trig <= btn_clean and (not btn_prev);
        end if;
    end process;

    -- 2. Pembangkit Angka Acak (3x LFSR 16-bit)
    process(clk)
    begin
        if rising_edge(clk) then
            lfsr1 <= lfsr1(14 downto 0) & (lfsr1(15) xor lfsr1(13) xor lfsr1(12) xor lfsr1(10));
            lfsr2 <= lfsr2(14 downto 0) & (lfsr2(15) xor lfsr2(14) xor lfsr2(12) xor lfsr2(3));
            lfsr3 <= lfsr3(14 downto 0) & (lfsr3(15) xor lfsr3(11) xor lfsr3(9)  xor lfsr3(5));
        end if;
    end process;

    -- 3. FSM Utama Slot Machine
    process(clk)
        variable tick_limit : integer;
    begin
        if rising_edge(clk) then
            if sw(1) = '1' then
                tick_limit := 100_000;   -- 1 ms per langkah (cepat untuk simulasi)
            else
                tick_limit := 8_000_000; -- 80 ms per langkah (nyaman dilihat di hardware)
            end if;

            if btnR = '1' then
                state      <= IDLE;
                spin_cnt   <= (others => '0');
                reel1      <= "0111";
                reel2      <= "0111";
                reel3      <= "0111";
                win_flag   <= '0';
                step_timer <= 0;
                step_count <= 0;
            else
                case state is
                    when IDLE =>
                        if spin_trig = '1' then
                            win_flag   <= '0';
                            step_timer <= 0;
                            step_count <= 0;
                            if spin_cnt = 9 then
                                spin_cnt <= (others => '0');
                            else
                                spin_cnt <= spin_cnt + 1;
                            end if;
                            state <= SPIN_123;
                        end if;

                    when SPIN_123 =>
                        if step_timer >= tick_limit then
                            step_timer <= 0;
                            reel1 <= to_bcd(lfsr1(3 downto 0));
                            reel2 <= to_bcd(lfsr2(3 downto 0));
                            reel3 <= to_bcd(lfsr3(3 downto 0));
                            if step_count = 5 then
                                step_count <= 0;
                                if sw(0) = '1' then reel1 <= "0111"; end if;
                                state <= SPIN_23;
                            else
                                step_count <= step_count + 1;
                            end if;
                        else
                            step_timer <= step_timer + 1;
                        end if;

                    when SPIN_23 =>
                        if step_timer >= tick_limit then
                            step_timer <= 0;
                            reel2 <= to_bcd(lfsr2(3 downto 0));
                            reel3 <= to_bcd(lfsr3(3 downto 0));
                            if step_count = 5 then
                                step_count <= 0;
                                if sw(0) = '1' then reel2 <= "0111"; end if;
                                state <= SPIN_3;
                            else
                                step_count <= step_count + 1;
                            end if;
                        else
                            step_timer <= step_timer + 1;
                        end if;

                    when SPIN_3 =>
                        if step_timer >= tick_limit then
                            step_timer <= 0;
                            reel3 <= to_bcd(lfsr3(3 downto 0));
                            if step_count = 5 then
                                step_count <= 0;
                                if sw(0) = '1' then reel3 <= "0111"; end if;
                                state <= CHECK_WIN;
                            else
                                step_count <= step_count + 1;
                            end if;
                        else
                            step_timer <= step_timer + 1;
                        end if;

                    when CHECK_WIN =>
                        if (reel1 = reel2) and (reel2 = reel3) then
                            win_flag <= '1';
                        else
                            win_flag <= '0';
                        end if;
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    -- Indikator LED papan Basys3
    led <= (others => '1') when win_flag = '1' else
           ("0000000000000" & reel1(0) & reel2(0) & reel3(0));

    -- 4. Multiplexer 7-Segment Fisik Basys3 (Active Low)
    process(clk)
    begin
        if rising_edge(clk) then
            mux_cnt <= mux_cnt + 1;
        end if;
    end process;

    process(mux_cnt, spin_cnt, reel1, reel2, reel3)
    begin
        case mux_cnt(17 downto 16) is
            when "00" =>
                an      <= "1110"; -- Digit paling kanan (AN0)
                cur_nib <= reel3;
            when "01" =>
                an      <= "1101"; -- AN1
                cur_nib <= reel2;
            when "10" =>
                an      <= "1011"; -- AN2
                cur_nib <= reel1;
            when others =>
                an      <= "0111"; -- Digit paling kiri (AN3)
                cur_nib <= std_logic_vector(spin_cnt);
        end case;
    end process;

    dp <= '0' when mux_cnt(17 downto 16) = "11" else '1'; -- Titik pemisah setelah digit spin

    with cur_nib select
        seg <= "1000000" when "0000", -- 0
               "1111001" when "0001", -- 1
               "0100100" when "0010", -- 2
               "0110000" when "0011", -- 3
               "0011001" when "0100", -- 4
               "0010010" when "0101", -- 5
               "0000010" when "0110", -- 6
               "1111000" when "0111", -- 7
               "0000000" when "1000", -- 8
               "0010000" when "1001", -- 9
               "1111111" when others;

    -- 5. Instansiasi Modul VGA Sync & Virtual 7-Segment Renderer
    u_vga_sync : entity work.vga_sync
        port map (
            clk      => clk,
            rst      => btnR,
            hsync    => Hsync,
            vsync    => Vsync,
            video_on => w_video_on,
            pixel_x  => w_pix_x,
            pixel_y  => w_pix_y
        );

    u_vga_disp : entity work.vga_digit_renderer
        port map (
            clk       => clk,
            video_on  => w_video_on,
            pixel_x   => w_pix_x,
            pixel_y   => w_pix_y,
            d3        => std_logic_vector(spin_cnt),
            d2        => reel1,
            d1        => reel2,
            d0        => reel3,
            highlight => win_flag,
            vgaRed    => vgaRed,
            vgaGreen  => vgaGreen,
            vgaBlue   => vgaBlue
        );

end architecture Behavioral;