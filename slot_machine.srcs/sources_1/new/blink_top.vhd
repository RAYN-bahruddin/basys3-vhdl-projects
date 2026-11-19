library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity blink_top is
    Port (
        clk : in  STD_LOGIC;
        led : out STD_LOGIC_VECTOR(15 downto 0)
    );
end entity blink_top;

architecture Behavioral of blink_top is
    constant HALF_PERIOD : integer := 50_000_000; -- 0.5 detik pada 100 MHz
    signal counter       : integer range 0 to HALF_PERIOD - 1 := 0;
    signal blink_reg     : STD_LOGIC := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if counter = HALF_PERIOD - 1 then
                counter   <= 0;
                blink_reg <= not blink_reg;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    led(0)           <= blink_reg;
    led(14 downto 1) <= (others => '0');
    led(15)          <= not blink_reg;

end architecture Behavioral;