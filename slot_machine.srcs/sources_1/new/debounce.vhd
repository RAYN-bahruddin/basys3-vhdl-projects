library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce is
    Generic (
        CNT_MAX : integer := 1_000_000 -- ~10 ms pada clock 100 MHz
    );
    Port (
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;
        btn_in    : in  STD_LOGIC;
        btn_clean : out STD_LOGIC;
        btn_pulse : out STD_LOGIC  -- Pulsa 1 siklus saat ditekan (rising edge)
    );
end entity debounce;

architecture Behavioral of debounce is
    signal sync_0, sync_1 : STD_LOGIC := '0';
    signal state          : STD_LOGIC := '0';
    signal state_prev     : STD_LOGIC := '0';
    signal cnt            : integer range 0 to CNT_MAX := 0;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sync_0     <= '0';
                sync_1     <= '0';
                state      <= '0';
                state_prev <= '0';
                cnt        <= 0;
            else
                -- 2-stage synchronizer
                sync_0 <= btn_in;
                sync_1 <= sync_0;

                if sync_1 /= state then
                    if cnt = CNT_MAX then
                        state <= sync_1;
                        cnt   <= 0;
                    else
                        cnt <= cnt + 1;
                    end if;
                else
                    cnt <= 0;
                end if;

                state_prev <= state;
            end if;
        end if;
    end process;

    btn_clean <= state;
    btn_pulse <= '1' when (state = '1' and state_prev = '0') else '0';

end architecture Behavioral;