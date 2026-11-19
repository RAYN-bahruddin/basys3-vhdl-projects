library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity calculator_tb is
end entity calculator_tb;

architecture Sim of calculator_tb is
    signal clk : STD_LOGIC := '0';
    signal sw  : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal led : STD_LOGIC_VECTOR(15 downto 0);
    signal seg : STD_LOGIC_VECTOR(6 downto 0);
    signal an  : STD_LOGIC_VECTOR(3 downto 0);
    signal dp  : STD_LOGIC;
    constant CLK_PERIOD : time := 10 ns;
begin

    uut : entity work.calculator_top
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
        -- Format sw: [9:8]=Opcode, [7:4]=B, [3:0]=A
        -- Tes 1: 7 + 5 = 12 (Opcode 00, B=0101, A=0111)
        sw <= "000000" & "00" & "0101" & "0111";
        wait for 1 ms;

        -- Tes 2: 3 - 9 = -6 (Opcode 01, B=1001, A=0011)
        sw <= "000000" & "01" & "1001" & "0011";
        wait for 1 ms;

        -- Tes 3: 12 * 11 = 132 (Opcode 10, B=1011, A=1100)
        sw <= "000000" & "10" & "1011" & "1100";
        wait for 1 ms;

        -- Tes 4: 8 / 0 = Err (Opcode 11, B=0000, A=1000)
        sw <= "000000" & "11" & "0000" & "1000";
        wait for 1 ms;

        wait;
    end process;

end architecture Sim;