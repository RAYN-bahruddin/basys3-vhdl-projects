library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seg7_ctrl is
    Port (
        clk    : in  STD_LOGIC;
        rst    : in  STD_LOGIC;
        digit0 : in  STD_LOGIC_VECTOR(4 downto 0); -- Kanan (AN0)
        digit1 : in  STD_LOGIC_VECTOR(4 downto 0); -- AN1
        digit2 : in  STD_LOGIC_VECTOR(4 downto 0); -- AN2
        digit3 : in  STD_LOGIC_VECTOR(4 downto 0); -- Kiri (AN3)
        dp_in  : in  STD_LOGIC_VECTOR(3 downto 0); -- Aktif tinggi per digit
        seg    : out STD_LOGIC_VECTOR(6 downto 0); -- CA..CG (aktif rendah)
        an     : out STD_LOGIC_VECTOR(3 downto 0); -- AN0..AN3 (aktif rendah)
        dp     : out STD_LOGIC                     -- Decimal point (aktif rendah)
    );
end entity seg7_ctrl;

architecture Behavioral of seg7_ctrl is
    signal refresh_cnt : unsigned(17 downto 0) := (others => '0');
    signal sel         : STD_LOGIC_VECTOR(1 downto 0);
    signal cur_char    : STD_LOGIC_VECTOR(4 downto 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                refresh_cnt <= (others => '0');
            else
                refresh_cnt <= refresh_cnt + 1;
            end if;
        end if;
    end process;

    sel <= std_logic_vector(refresh_cnt(17 downto 16));

    -- Pemilihan Anoda dan karakter aktif
    process(sel, digit0, digit1, digit2, digit3, dp_in)
    begin
        case sel is
            when "00" =>
                an       <= "1110";
                cur_char <= digit0;
                dp       <= not dp_in(0);
            when "01" =>
                an       <= "1101";
                cur_char <= digit1;
                dp       <= not dp_in(1);
            when "10" =>
                an       <= "1011";
                cur_char <= digit2;
                dp       <= not dp_in(2);
            when others =>
                an       <= "0111";
                cur_char <= digit3;
                dp       <= not dp_in(3);
        end case;
    end process;

    -- Decoder karakter ke 7-Segment (aktif rendah: bit 0 = CA, bit 6 = CG)
    process(cur_char)
    begin
        case cur_char is
            when "00000" => seg <= "1000000"; -- 0
            when "00001" => seg <= "1111001"; -- 1
            when "00010" => seg <= "0100100"; -- 2
            when "00011" => seg <= "0110000"; -- 3
            when "00100" => seg <= "0011001"; -- 4
            when "00101" => seg <= "0010010"; -- 5
            when "00110" => seg <= "0000010"; -- 6
            when "00111" => seg <= "1111000"; -- 7
            when "01000" => seg <= "0000000"; -- 8
            when "01001" => seg <= "0010000"; -- 9
            when "01010" => seg <= "0001000"; -- A
            when "01011" => seg <= "0000011"; -- b
            when "01100" => seg <= "1000110"; -- C
            when "01101" => seg <= "0100001"; -- d
            when "01110" => seg <= "0000110"; -- E
            when "01111" => seg <= "0001110"; -- F
            when "10000" => seg <= "1111111"; -- Blank (kosong)
            when "10001" => seg <= "0111111"; -- Tanda minus (-)
            when "10010" => seg <= "0101111"; -- Huruf 'r'
            when "10011" => seg <= "0101011"; -- Huruf 'n'
            when "10100" => seg <= "1001111"; -- Huruf 'I'
            when "10101" => seg <= "0110110"; -- Simbol bar (= / tiga garis)
            when others  => seg <= "1111111";
        end case;
    end process;

end architecture Behavioral;