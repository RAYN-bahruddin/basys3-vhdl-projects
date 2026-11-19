library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity slot_machine_lcd_tb is
end entity slot_machine_lcd_tb;

architecture Sim of slot_machine_lcd_tb is
    signal clk  : STD_LOGIC := '0';
    signal btnC : STD_LOGIC := '0';
    signal btnU : STD_LOGIC := '0';
    signal led  : STD_LOGIC_VECTOR(15 downto 0);
    signal JA   : STD_LOGIC_VECTOR(7 downto 0);
    constant CLK_PERIOD : time := 10 ns;
begin

    uut : entity work.slot_machine_lcd_top
        port map (
            clk => clk, btnC => btnC, btnU => btnU, led => led, JA => JA
        );

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_proc : process
    begin
        -- Tunggu inisialisasi LCD HD44780 (~45 ms)
        wait for 50 ms;

        -- Tekan 1: Mulai putaran semua reel
        btnC <= '1'; wait for 15 ms; btnC <= '0';
        wait for 90 ms;

        -- Tekan 2: Hentikan reel 1
        btnC <= '1'; wait for 15 ms; btnC <= '0';
        wait for 90 ms;

        -- Tekan 3: Hentikan reel 2
        btnC <= '1'; wait for 15 ms; btnC <= '0';
        wait for 90 ms;

        -- Tekan 4: Hentikan reel 3 & cek menang
        btnC <= '1'; wait for 15 ms; btnC <= '0';
        wait for 50 ms;

        wait;
    end process;

end architecture Sim;