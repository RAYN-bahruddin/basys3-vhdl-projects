library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity float_calculator_tb is
end entity float_calculator_tb;

architecture Sim of float_calculator_tb is
    signal clk : STD_LOGIC := '0';
    signal sw  : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal led : STD_LOGIC_VECTOR(15 downto 0);
    signal seg : STD_LOGIC_VECTOR(6 downto 0);
    signal an  : STD_LOGIC_VECTOR(3 downto 0);
    signal dp  : STD_LOGIC;
    constant CLK_PERIOD : time := 10 ns;
begin

    uut : entity work.float_calculator_top
        port map (
            clk => clk, sw => sw, led => led, seg => seg, an => an, dp => dp
        );

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_proc : process
    begin
        -- Format 7-bit mini-float: S(1) | E(3, bias=3) | M(3)
        -- 1.5  = 0_011_100 ("0011100")
        -- 2.25 = 0_100_001 ("0100001")
        -- Tes 1: 1.5 + 2.25 = 3.75 (Op = 00)
        sw <= "00" & "0100001" & "0011100";
        wait for 1 ms;

        -- Tes 2: 1.5 - 2.25 = -0.75 (Op = 01)
        sw <= "01" & "0100001" & "0011100";
        wait for 1 ms;

        -- Tes 3: 1.5 * 2.25 = 3.375 (Op = 10)
        sw <= "10" & "0100001" & "0011100";
        wait for 1 ms;

        -- Tes 4: 1.5 / 0.0 = Inf (Op = 11)
        sw <= "11" & "0000000" & "0011100";
        wait for 1 ms;

        wait;
    end process;

end architecture Sim;