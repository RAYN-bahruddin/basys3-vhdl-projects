library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity slot_machine_tb is
end entity slot_machine_tb;

architecture Sim of slot_machine_tb is
    signal clk  : STD_LOGIC := '0';
    signal btnC : STD_LOGIC := '0';
    signal btnU : STD_LOGIC := '0';
    signal led  : STD_LOGIC_VECTOR(15 downto 0);
    signal seg  : STD_LOGIC_VECTOR(6 downto 0);
    signal an   : STD_LOGIC_VECTOR(3 downto 0);
    signal dp   : STD_LOGIC;

    constant CLK_PERIOD : time := 10 ns; -- 100 MHz
begin

    uut : entity work.slot_machine_top_v2
        port map (
            clk  => clk,
            btnC => btnC,
            btnU => btnU,
            led  => led,
            seg  => seg,
            an   => an,
            dp   => dp
        );

    -- Pembangkit clock 100 MHz
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus uji tekan tombol Spin & Stop 3 reel
    stim_proc : process
    begin
        wait for 100 ns;

        -- Tekan 1: Mulai spin semua reel
        btnC <= '1';
        wait for 15 ms; -- Melewati debounce 10 ms
        btnC <= '0';
        wait for 100 ms;

        -- Tekan 2: Hentikan reel 1
        btnC <= '1';
        wait for 15 ms;
        btnC <= '0';
        wait for 100 ms;

        -- Tekan 3: Hentikan reel 2
        btnC <= '1';
        wait for 15 ms;
        btnC <= '0';
        wait for 100 ms;

        -- Tekan 4: Hentikan reel 3 & evaluasi skor
        btnC <= '1';
        wait for 15 ms;
        btnC <= '0';
        wait for 200 ms;

        -- Reset kredit
        btnU <= '1';
        wait for 15 ms;
        btnU <= '0';
        wait for 50 ms;

        assert false report "Simulasi Slot Machine selesai." severity failure;
    end process;

end architecture Sim;