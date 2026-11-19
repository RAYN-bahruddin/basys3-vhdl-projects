library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity slot_machine_vga_tb is
end entity slot_machine_vga_tb;

architecture Behavioral of slot_machine_vga_tb is
    signal clk      : STD_LOGIC := '0';
    signal btnC     : STD_LOGIC := '0';
    signal btnR     : STD_LOGIC := '0';
    signal sw       : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal led      : STD_LOGIC_VECTOR(15 downto 0);
    signal seg      : STD_LOGIC_VECTOR(6 downto 0);
    signal dp       : STD_LOGIC;
    signal an       : STD_LOGIC_VECTOR(3 downto 0);
    signal Hsync    : STD_LOGIC;
    signal Vsync    : STD_LOGIC;
    signal vgaRed   : STD_LOGIC_VECTOR(3 downto 0);
    signal vgaGreen : STD_LOGIC_VECTOR(3 downto 0);
    signal vgaBlue  : STD_LOGIC_VECTOR(3 downto 0);

    constant CLK_PERIOD : time := 10 ns; -- 100 MHz
begin

    uut : entity work.slot_machine_vga_top
        port map (
            clk      => clk,
            btnC     => btnC,
            btnR     => btnR,
            sw       => sw,
            led      => led,
            seg      => seg,
            dp       => dp,
            an       => an,
            Hsync    => Hsync,
            Vsync    => Vsync,
            vgaRed   => vgaRed,
            vgaGreen => vgaGreen,
            vgaBlue  => vgaBlue
        );

    -- Clock 100 MHz
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus Pengujian Slot Machine + VGA
    stim_proc : process
    begin
        -- Aktifkan sw(1)='1' (Fast Spin) dan sw(0)='1' (Test Jackpot 7-7-7)
        sw(1) <= '1';
        sw(0) <= '1';

        -- Reset awal
        btnR <= '1';
        wait for 100 ns;
        btnR <= '0';
        wait for 100 ns;

        -- Tekan tombol Spin (btnC)
        btnC <= '1';
        wait for 500 ns;
        btnC <= '0';

        -- Tunggu 18 ms agar gulungan berhenti & 1 frame penuh VGA (16.8 ms) selesai dirender
        wait for 18 ms;

        -- Putaran kedua tanpa cheat jackpot (sw(0)='0')
        sw(0) <= '0';
        btnC <= '1';
        wait for 500 ns;
        btnC <= '0';

        wait;
    end process;

end architecture Behavioral;