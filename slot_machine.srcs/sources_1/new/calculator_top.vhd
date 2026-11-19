library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity calculator_top is
    Port (
        clk : in  STD_LOGIC;
        sw  : in  STD_LOGIC_VECTOR(15 downto 0);
        led : out STD_LOGIC_VECTOR(15 downto 0);
        seg : out STD_LOGIC_VECTOR(6 downto 0);
        an  : out STD_LOGIC_VECTOR(3 downto 0);
        dp  : out STD_LOGIC
    );
end entity calculator_top;

architecture Behavioral of calculator_top is
    signal op_a      : integer range 0 to 15;
    signal op_b      : integer range 0 to 15;
    signal opcode    : STD_LOGIC_VECTOR(1 downto 0);
    signal abs_res   : integer range 0 to 255;
    signal is_neg    : STD_LOGIC;
    signal div_zero  : STD_LOGIC;

    signal d0, d1, d2, d3 : STD_LOGIC_VECTOR(4 downto 0);
begin

    op_a   <= to_integer(unsigned(sw(3 downto 0)));
    op_b   <= to_integer(unsigned(sw(7 downto 4)));
    opcode <= sw(9 downto 8);

    -- ALU Kombinasional
    process(op_a, op_b, opcode)
    begin
        abs_res  <= 0;
        is_neg   <= '0';
        div_zero <= '0';

        case opcode is
            when "00" => -- Penjumlahan (+)
                abs_res <= op_a + op_b;

            when "01" => -- Pengurangan (-)
                if op_a >= op_b then
                    abs_res <= op_a - op_b;
                    is_neg  <= '0';
                else
                    abs_res <= op_b - op_a;
                    is_neg  <= '1';
                end if;

            when "10" => -- Perkalian (*)
                abs_res <= op_a * op_b;

            when others => -- Pembagian (/)
                if op_b = 0 then
                    abs_res  <= 0;
                    div_zero <= '1';
                else
                    abs_res <= op_a / op_b;
                end if;
        end case;
    end process;

    -- Konversi hasil ke digit 7-segment (BCD + indikator status)
    process(abs_res, is_neg, div_zero)
        variable hundreds : integer range 0 to 9;
        variable tens     : integer range 0 to 9;
        variable ones     : integer range 0 to 9;
    begin
        if div_zero = '1' then
            d3 <= "10000"; -- Blank
            d2 <= "01110"; -- 'E'
            d1 <= "10010"; -- 'r'
            d0 <= "10010"; -- 'r'
        else
            hundreds := abs_res / 100;
            tens     := (abs_res mod 100) / 10;
            ones     := abs_res mod 10;

            d0 <= std_logic_vector(to_unsigned(ones, 5));

            if abs_res >= 10 then
                d1 <= std_logic_vector(to_unsigned(tens, 5));
            else
                d1 <= "10000"; -- Blank leading zero
            end if;

            if abs_res >= 100 then
                d2 <= std_logic_vector(to_unsigned(hundreds, 5));
            else
                d2 <= "10000"; -- Blank leading zero
            end if;

            if is_neg = '1' then
                d3 <= "10001"; -- Tanda minus '-'
            else
                d3 <= "10000"; -- Blank
            end if;
        end if;
    end process;

    -- Tampilkan hasil biner dan flag status pada LED
    led(7 downto 0)   <= std_logic_vector(to_unsigned(abs_res, 8));
    led(12 downto 8)  <= (others => '0');
    led(13)           <= '1' when (abs_res = 0 and div_zero = '0') else '0'; -- Zero flag
    led(14)           <= is_neg;                                             -- Negative flag
    led(15)           <= div_zero;                                           -- Error flag

    u_seg7 : entity work.seg7_ctrl
        port map (
            clk    => clk,
            rst    => '0',
            digit0 => d0,
            digit1 => d1,
            digit2 => d2,
            digit3 => d3,
            dp_in  => "0000",
            seg    => seg,
            an     => an,
            dp     => dp
        );

end architecture Behavioral;