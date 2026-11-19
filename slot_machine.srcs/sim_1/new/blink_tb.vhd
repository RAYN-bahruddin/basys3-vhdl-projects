library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity blink_tb is
end entity blink_tb;

architecture Sim of blink_tb is
    signal clk : STD_LOGIC := '0';
    signal led : STD_LOGIC_VECTOR(15 downto 0);
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz
begin

    uut : entity work.blink_top
        port map (
            clk => clk,
            led => led
        );

    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

end architecture Sim;