library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_digit_renderer is
    Port (
        clk       : in  STD_LOGIC;
        video_on  : in  STD_LOGIC;
        pixel_x   : in  STD_LOGIC_VECTOR(9 downto 0);
        pixel_y   : in  STD_LOGIC_VECTOR(9 downto 0);
        d3        : in  STD_LOGIC_VECTOR(3 downto 0); -- Digit kiri (Jumlah Spin/Kredit)
        d2        : in  STD_LOGIC_VECTOR(3 downto 0); -- Reel 1
        d1        : in  STD_LOGIC_VECTOR(3 downto 0); -- Reel 2
        d0        : in  STD_LOGIC_VECTOR(3 downto 0); -- Reel 3
        highlight : in  STD_LOGIC;                    -- '1' saat Jackpot
        vgaRed    : out STD_LOGIC_VECTOR(3 downto 0);
        vgaGreen  : out STD_LOGIC_VECTOR(3 downto 0);
        vgaBlue   : out STD_LOGIC_VECTOR(3 downto 0)
    );
end entity vga_digit_renderer;

architecture Behavioral of vga_digit_renderer is
begin

    process(clk)
        variable px      : integer range 0 to 1023;
        variable py      : integer range 0 to 1023;
        variable lx      : integer range 0 to 100;
        variable ly      : integer range 0 to 200;
        variable in_box  : boolean;
        variable is_reel : boolean;
        variable cur_dig : STD_LOGIC_VECTOR(3 downto 0);
        variable segs    : STD_LOGIC_VECTOR(6 downto 0);
        variable lit     : boolean;
    begin
        if rising_edge(clk) then
            px := to_integer(unsigned(pixel_x));
            py := to_integer(unsigned(pixel_y));

            if video_on = '0' then
                vgaRed   <= "0000";
                vgaGreen <= "0000";
                vgaBlue  <= "0000";
            else
                in_box  := false;
                is_reel := false;
                lx      := 0;
                cur_dig := "0000";

                -- Posisi 4 kotak digit raksasa di tengah layar (Y: 140..340)
                if (py >= 140 and py <= 340) then
                    ly := py - 140;
                    if (px >= 60 and px <= 160) then
                        in_box := true; is_reel := false; lx := px - 60;  cur_dig := d3;
                    elsif (px >= 210 and px <= 310) then
                        in_box := true; is_reel := true;  lx := px - 210; cur_dig := d2;
                    elsif (px >= 340 and px <= 440) then
                        in_box := true; is_reel := true;  lx := px - 340; cur_dig := d1;
                    elsif (px >= 470 and px <= 570) then
                        in_box := true; is_reel := true;  lx := px - 470; cur_dig := d0;
                    end if;
                end if;

                if in_box then
                    case cur_dig is
                        when "0000" => segs := "1111110"; -- 0
                        when "0001" => segs := "0110000"; -- 1
                        when "0010" => segs := "1101101"; -- 2
                        when "0011" => segs := "1111001"; -- 3
                        when "0100" => segs := "0110011"; -- 4
                        when "0101" => segs := "1011011"; -- 5
                        when "0110" => segs := "1011111"; -- 6
                        when "0111" => segs := "1110000"; -- 7
                        when "1000" => segs := "1111111"; -- 8
                        when "1001" => segs := "1111011"; -- 9
                        when "1010" => segs := "1110111"; -- A
                        when "1011" => segs := "0011111"; -- b
                        when "1100" => segs := "1001110"; -- C
                        when "1101" => segs := "0111101"; -- d
                        when "1110" => segs := "1001111"; -- E
                        when others => segs := "1000111"; -- F
                    end case;

                    lit := false;
                    if (segs(6) = '1' and lx >= 16 and lx <= 84 and ly >= 0   and ly <= 16)  then lit := true; end if; -- a
                    if (segs(5) = '1' and lx >= 84 and lx <= 100 and ly >= 16 and ly <= 92)  then lit := true; end if; -- b
                    if (segs(4) = '1' and lx >= 84 and lx <= 100 and ly >= 108 and ly <= 184) then lit := true; end if; -- c
                    if (segs(3) = '1' and lx >= 16 and lx <= 84 and ly >= 184 and ly <= 200) then lit := true; end if; -- d
                    if (segs(2) = '1' and lx >= 0  and lx <= 16 and ly >= 108 and ly <= 184) then lit := true; end if; -- e
                    if (segs(1) = '1' and lx >= 0  and lx <= 16 and ly >= 16  and ly <= 92)  then lit := true; end if; -- f
                    if (segs(0) = '1' and lx >= 16 and lx <= 84 and ly >= 92  and ly <= 108) then lit := true; end if; -- g

                    if lit then
                        if highlight = '1' then
                            -- Warna Emas menyala saat Jackpot
                            vgaRed <= "1111"; vgaGreen <= "1100"; vgaBlue <= "0000";
                        elsif is_reel then
                            -- Warna Cyan terang untuk 3 gulungan Slot
                            vgaRed <= "0000"; vgaGreen <= "1111"; vgaBlue <= "1110";
                        else
                            -- Warna Hijau Neon untuk penghitung Spin/Skor
                            vgaRed <= "0010"; vgaGreen <= "1111"; vgaBlue <= "0100";
                        end if;
                    else
                        -- Latar kotak segmen redup
                        vgaRed <= "0001"; vgaGreen <= "0010"; vgaBlue <= "0011";
                    end if;

                elsif (px >= 195 and px <= 585 and (py = 125 or py = 355)) then
                    -- Bingkai pemisah area 3 gulungan Slot
                    if highlight = '1' then
                        vgaRed <= "1111"; vgaGreen <= "1010"; vgaBlue <= "0000";
                    else
                        vgaRed <= "0011"; vgaGreen <= "0111"; vgaBlue <= "1111";
                    end if;
                else
                    -- Latar belakang layar utama (Biru gelap / Merah marun saat Jackpot)
                    if highlight = '1' then
                        vgaRed <= "0011"; vgaGreen <= "0001"; vgaBlue <= "0000";
                    else
                        vgaRed <= "0000"; vgaGreen <= "0001"; vgaBlue <= "0010";
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture Behavioral;