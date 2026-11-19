library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_text is
    Port (
        reel1     : in  unsigned(2 downto 0);
        reel2     : in  unsigned(2 downto 0);
        reel3     : in  unsigned(2 downto 0);
        credits   : in  integer range 0 to 99;
        win_code  : in  STD_LOGIC_VECTOR(1 downto 0); -- "00"=Idle, "01"=Spin, "10"=Win2, "11"=Jackpot
        line1_out : out STD_LOGIC_VECTOR(127 downto 0);
        line2_out : out STD_LOGIC_VECTOR(127 downto 0)
    );
end entity game_text;

architecture Behavioral of game_text is

    function str_to_slv(s : string(1 to 16)) return STD_LOGIC_VECTOR is
        variable res : STD_LOGIC_VECTOR(127 downto 0);
    begin
        for i in 1 to 16 loop
            res(127 - (i - 1) * 8 downto 120 - (i - 1) * 8) :=
                std_logic_vector(to_unsigned(character'pos(s(i)), 8));
        end loop;
        return res;
    end function;

    function sym_to_char(sym : unsigned(2 downto 0)) return character is
    begin
        case sym is
            when "000"  => return '7';
            when "001"  => return '$';
            when "010"  => return '#';
            when "011"  => return '@';
            when "100"  => return '*';
            when "101"  => return '+';
            when "110"  => return '%';
            when others => return '&';
        end case;
    end function;

begin

    process(reel1, reel2, reel3, credits, win_code)
        variable l1 : string(1 to 16);
        variable l2 : string(1 to 16);
        variable c_tens, c_ones : integer range 0 to 9;
    begin
        c_tens := (credits / 10) mod 10;
        c_ones := credits mod 10;

        -- Baris 1: "  [7] [7] [7]   "
        l1 := "  [" & sym_to_char(reel1) & "] [" & sym_to_char(reel2) & "] [" & sym_to_char(reel3) & "]   ";

        -- Baris 2: Status & Kredit
        case win_code is
            when "11" =>
                l2 := "JACKPOT! +10 CR ";
            when "10" =>
                l2 := "NICE WIN! +3 CR ";
            when "01" =>
                l2 := "SPINNING...     ";
            when others =>
                l2 := "CREDITS: " & character'val(48 + c_tens) & character'val(48 + c_ones) & "     ";
        end case;

        line1_out <= str_to_slv(l1);
        line2_out <= str_to_slv(l2);
    end process;

end architecture Behavioral;