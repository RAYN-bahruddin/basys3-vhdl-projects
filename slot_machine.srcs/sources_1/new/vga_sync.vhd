library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_sync is
    Port (
        clk      : in  STD_LOGIC; -- 100 MHz Basys3
        rst      : in  STD_LOGIC;
        hsync    : out STD_LOGIC;
        vsync    : out STD_LOGIC;
        video_on : out STD_LOGIC;
        pixel_x  : out STD_LOGIC_VECTOR(9 downto 0);
        pixel_y  : out STD_LOGIC_VECTOR(9 downto 0)
    );
end entity vga_sync;

architecture Behavioral of vga_sync is
    constant H_DISPLAY : integer := 640;
    constant H_FP      : integer := 16;
    constant H_SYNC    : integer := 96;
    constant H_BP      : integer := 48;
    constant H_TOTAL   : integer := 800;

    constant V_DISPLAY : integer := 480;
    constant V_FP      : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BP      : integer := 33;
    constant V_TOTAL   : integer := 525;

    signal clk_div  : unsigned(1 downto 0) := (others => '0');
    signal pix_tick : STD_LOGIC := '0';
    signal h_count  : integer range 0 to H_TOTAL - 1 := 0;
    signal v_count  : integer range 0 to V_TOTAL - 1 := 0;
begin

    -- Pembagi frekuensi 100 MHz -> pulsa enable 25 MHz
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_div  <= (others => '0');
                pix_tick <= '0';
            else
                clk_div <= clk_div + 1;
                if clk_div = "11" then
                    pix_tick <= '1';
                else
                    pix_tick <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Counter koordinat Horizontal & Vertikal
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                h_count <= 0;
                v_count <= 0;
            elsif pix_tick = '1' then
                if h_count = H_TOTAL - 1 then
                    h_count <= 0;
                    if v_count = V_TOTAL - 1 then
                        v_count <= 0;
                    else
                        v_count <= v_count + 1;
                    end if;
                else
                    h_count <= h_count + 1;
                end if;
            end if;
        end if;
    end process;

    hsync    <= '0' when (h_count >= (H_DISPLAY + H_FP) and h_count < (H_DISPLAY + H_FP + H_SYNC)) else '1';
    vsync    <= '0' when (v_count >= (V_DISPLAY + V_FP) and v_count < (V_DISPLAY + V_FP + V_SYNC)) else '1';
    video_on <= '1' when (h_count < H_DISPLAY and v_count < V_DISPLAY) else '0';
    pixel_x  <= std_logic_vector(to_unsigned(h_count, 10));
    pixel_y  <= std_logic_vector(to_unsigned(v_count, 10));

end architecture Behavioral;