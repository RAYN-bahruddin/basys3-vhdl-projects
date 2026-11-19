library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_hd44780 is
    Port (
        clk   : in  STD_LOGIC;
        rst   : in  STD_LOGIC;
        line1 : in  STD_LOGIC_VECTOR(127 downto 0); -- 16 karakter ASCII (kiri di MSB)
        line2 : in  STD_LOGIC_VECTOR(127 downto 0); -- 16 karakter ASCII (kiri di MSB)
        JA    : out STD_LOGIC_VECTOR(7 downto 0)    -- Pmod JA
    );
end entity lcd_hd44780;

architecture Behavioral of lcd_hd44780 is
    type lcd_state_t is (
        PWR_WAIT, INIT_33_1, INIT_33_2, INIT_32,
        FUNC_SET, DISP_ON, ENTRY_MODE, CLEAR_DISP,
        SET_LINE1, WRITE_LINE1, SET_LINE2, WRITE_LINE2,
        SEND_HI, SEND_LO
    );

    signal state      : lcd_state_t := PWR_WAIT;
    signal next_state : lcd_state_t := INIT_33_1;

    signal timer       : integer range 0 to 5_000_000 := 0;
    signal sub_step    : integer range 0 to 3 := 0;
    signal char_idx    : integer range 0 to 15 := 0;

    signal byte_buf    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal rs_buf      : STD_LOGIC := '0';
    signal nibble_only : STD_LOGIC := '0';

    signal lcd_db      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal lcd_rs      : STD_LOGIC := '0';
    signal lcd_e       : STD_LOGIC := '0';

    constant DELAY_40MS : integer := 4_000_000; -- 40 ms @ 100 MHz
    constant DELAY_5MS  : integer := 500_000;   -- 5 ms
    constant DELAY_2MS  : integer := 200_000;   -- 2 ms
    constant DELAY_50US : integer := 5_000;     -- 50 us
    constant PULSE_E    : integer := 100;       -- 1 us lebar pulsa E
begin

    process(clk)
        variable cur_char : STD_LOGIC_VECTOR(7 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state       <= PWR_WAIT;
                timer       <= 0;
                sub_step    <= 0;
                char_idx    <= 0;
                lcd_e       <= '0';
                lcd_rs      <= '0';
                nibble_only <= '0';
            else
                case state is
                    when PWR_WAIT =>
                        if timer = DELAY_40MS then
                            timer <= 0;
                            state <= INIT_33_1;
                        else
                            timer <= timer + 1;
                        end if;

                    when INIT_33_1 =>
                        byte_buf    <= x"30";
                        rs_buf      <= '0';
                        nibble_only <= '1';
                        next_state  <= INIT_33_2;
                        state       <= SEND_HI;

                    when INIT_33_2 =>
                        if timer = DELAY_5MS then
                            timer       <= 0;
                            byte_buf    <= x"30";
                            rs_buf      <= '0';
                            nibble_only <= '1';
                            next_state  <= INIT_32;
                            state       <= SEND_HI;
                        else
                            timer <= timer + 1;
                        end if;

                    when INIT_32 =>
                        byte_buf    <= x"20"; -- Beralih ke mode 4-bit
                        rs_buf      <= '0';
                        nibble_only <= '1';
                        next_state  <= FUNC_SET;
                        state       <= SEND_HI;

                    when FUNC_SET =>
                        byte_buf    <= x"28"; -- 4-bit, 2 baris, 5x8 dots
                        rs_buf      <= '0';
                        nibble_only <= '0';
                        next_state  <= DISP_ON;
                        state       <= SEND_HI;

                    when DISP_ON =>
                        byte_buf   <= x"0C"; -- Display ON, Cursor OFF
                        rs_buf     <= '0';
                        next_state <= ENTRY_MODE;
                        state      <= SEND_HI;

                    when ENTRY_MODE =>
                        byte_buf   <= x"06"; -- Auto increment cursor
                        rs_buf     <= '0';
                        next_state <= CLEAR_DISP;
                        state      <= SEND_HI;

                    when CLEAR_DISP =>
                        byte_buf   <= x"01"; -- Clear Display
                        rs_buf     <= '0';
                        next_state <= SET_LINE1;
                        state      <= SEND_HI;

                    when SET_LINE1 =>
                        if timer = DELAY_2MS then
                            timer      <= 0;
                            char_idx   <= 0;
                            byte_buf   <= x"80"; -- Alamat DDRAM baris 1
                            rs_buf     <= '0';
                            next_state <= WRITE_LINE1;
                            state      <= SEND_HI;
                        else
                            timer <= timer + 1;
                        end if;

                    when WRITE_LINE1 =>
                        for b in 0 to 7 loop
                            cur_char(b) := line1(120 - (char_idx * 8) + b);
                        end loop;
                        byte_buf   <= cur_char;
                        rs_buf     <= '1';
                        if char_idx = 15 then
                            next_state <= SET_LINE2;
                        else
                            char_idx   <= char_idx + 1;
                            next_state <= WRITE_LINE1;
                        end if;
                        state <= SEND_HI;

                    when SET_LINE2 =>
                        char_idx   <= 0;
                        byte_buf   <= x"C0"; -- Alamat DDRAM baris 2
                        rs_buf     <= '0';
                        next_state <= WRITE_LINE2;
                        state      <= SEND_HI;

                    when WRITE_LINE2 =>
                        for b in 0 to 7 loop
                            cur_char(b) := line2(120 - (char_idx * 8) + b);
                        end loop;
                        byte_buf   <= cur_char;
                        rs_buf     <= '1';
                        if char_idx = 15 then
                            next_state <= SET_LINE1;
                        else
                            char_idx   <= char_idx + 1;
                            next_state <= WRITE_LINE2;
                        end if;
                        state <= SEND_HI;

                    when SEND_HI =>
                        lcd_rs <= rs_buf;
                        lcd_db <= byte_buf(7 downto 4);
                        if sub_step = 0 then
                            lcd_e <= '0';
                            if timer = PULSE_E then timer <= 0; sub_step <= 1; else timer <= timer + 1; end if;
                        elsif sub_step = 1 then
                            lcd_e <= '1';
                            if timer = PULSE_E then timer <= 0; sub_step <= 2; else timer <= timer + 1; end if;
                        else
                            lcd_e <= '0';
                            if timer = DELAY_50US then
                                timer    <= 0;
                                sub_step <= 0;
                                if nibble_only = '1' then
                                    state <= next_state;
                                else
                                    state <= SEND_LO;
                                end if;
                            else
                                timer <= timer + 1;
                            end if;
                        end if;

                    when SEND_LO =>
                        lcd_rs <= rs_buf;
                        lcd_db <= byte_buf(3 downto 0);
                        if sub_step = 0 then
                            lcd_e <= '0';
                            if timer = PULSE_E then timer <= 0; sub_step <= 1; else timer <= timer + 1; end if;
                        elsif sub_step = 1 then
                            lcd_e <= '1';
                            if timer = PULSE_E then timer <= 0; sub_step <= 2; else timer <= timer + 1; end if;
                        else
                            lcd_e <= '0';
                            if timer = DELAY_50US then
                                timer    <= 0;
                                sub_step <= 0;
                                state    <= next_state;
                            else
                                timer <= timer + 1;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    JA(3 downto 0) <= lcd_db;
    JA(4)          <= lcd_rs;
    JA(5)          <= '0'; -- RW selalu mode tulis (Write)
    JA(6)          <= lcd_e;
    JA(7)          <= '0';

end architecture Behavioral;