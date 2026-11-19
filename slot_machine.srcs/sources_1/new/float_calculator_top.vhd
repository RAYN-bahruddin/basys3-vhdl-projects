library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity float_calculator_top is
    Port (
        clk : in  STD_LOGIC;
        sw  : in  STD_LOGIC_VECTOR(15 downto 0);
        led : out STD_LOGIC_VECTOR(15 downto 0);
        seg : out STD_LOGIC_VECTOR(6 downto 0);
        an  : out STD_LOGIC_VECTOR(3 downto 0);
        dp  : out STD_LOGIC
    );
end entity float_calculator_top;

architecture Behavioral of float_calculator_top is
    signal res_float  : STD_LOGIC_VECTOR(6 downto 0);
    signal res_mag    : integer range 0 to 131071 := 0; -- Skala tetap: 1.0 = 4096
    signal res_sign   : STD_LOGIC := '0';
    signal flag_zero  : STD_LOGIC := '0';
    signal flag_den   : STD_LOGIC := '0';
    signal flag_inf   : STD_LOGIC := '0';
    signal flag_nan   : STD_LOGIC := '0';

    signal d0, d1, d2, d3 : STD_LOGIC_VECTOR(4 downto 0);
    signal dp_vec         : STD_LOGIC_VECTOR(3 downto 0);
begin

    process(sw)
        -- Ekstraksi field S[6], E[5:3], M[2:0]
        variable sa, sb       : STD_LOGIC;
        variable ea, eb       : integer range 0 to 7;
        variable ma, mb       : integer range 0 to 7;
        variable sig_a, sig_b : integer range 0 to 15;
        variable exp_a, exp_b : integer range -2 to 3;

        variable a_zero, b_zero : boolean;
        variable a_inf,  b_inf  : boolean;
        variable a_nan,  b_nan  : boolean;

        variable mag_a, mag_b   : integer range 0 to 131071;
        variable s_mag_a        : integer;
        variable s_mag_b        : integer;
        variable s_mag_r        : integer;
        variable u_mag_r        : integer;
        variable r_sign         : STD_LOGIC;

        variable pack_e         : integer range 0 to 7;
        variable pack_m         : integer range 0 to 7;
        variable norm_val       : integer;
        variable shift_cnt      : integer;
    begin
        sa := sw(6);
        ea := to_integer(unsigned(sw(5 downto 3)));
        ma := to_integer(unsigned(sw(2 downto 0)));

        sb := sw(13);
        eb := to_integer(unsigned(sw(12 downto 10)));
        mb := to_integer(unsigned(sw(9 downto 7)));

        a_zero := (ea = 0 and ma = 0);
        b_zero := (eb = 0 and mb = 0);
        a_inf  := (ea = 7 and ma = 0);
        b_inf  := (eb = 7 and mb = 0);
        a_nan  := (ea = 7 and ma /= 0);
        b_nan  := (eb = 7 and mb /= 0);

        -- Unpack significand & exponent efektif (bias = 3)
        if ea = 0 then
            sig_a := ma;      -- Denormal: 0.M * 2^(-2)
            exp_a := -2;
        else
            sig_a := 8 + ma;  -- Normal: 1.M * 2^(E-3)
            exp_a := ea - 3;
        end if;

        if eb = 0 then
            sig_b := mb;
            exp_b := -2;
        else
            sig_b := 8 + mb;
            exp_b := eb - 3;
        end if;

        -- Ubah ke representasi integer berskala 2^12 (1.0 = 4096)
        mag_a := sig_a * (2 ** (exp_a + 9));
        mag_b := sig_b * (2 ** (exp_b + 9));

        if sa = '1' then s_mag_a := -mag_a; else s_mag_a := mag_a; end if;
        if sb = '1' then s_mag_b := -mag_b; else s_mag_b := mag_b; end if;

        flag_nan  <= '0';
        flag_inf  <= '0';
        flag_zero <= '0';
        flag_den  <= '0';
        r_sign    := '0';
        u_mag_r   := 0;

        -- Penanganan kasus spesial (NaN / Inf)
        if a_nan or b_nan then
            flag_nan  <= '1';
            res_float <= "0111111"; -- NaN
        elsif (a_inf and b_inf and ((sw(15 downto 14) = "00" and sa /= sb) or (sw(15 downto 14) = "01" and sa = sb))) or
              ((a_inf or b_inf) and (a_zero or b_zero) and sw(15 downto 14) = "10") or
              (a_inf and b_inf and sw(15 downto 14) = "11") or
              (a_zero and b_zero and sw(15 downto 14) = "11") then
            flag_nan  <= '1';
            res_float <= "0111111"; -- NaN (0/0, Inf-Inf, 0*Inf, Inf/Inf)
        elsif a_inf or b_inf or (b_zero and sw(15 downto 14) = "11") then
            flag_inf <= '1';
            if sw(15 downto 14) = "00" then
                if a_inf then r_sign := sa; else r_sign := sb; end if;
            elsif sw(15 downto 14) = "01" then
                if a_inf then r_sign := sa; else r_sign := not sb; end if;
            else
                r_sign := sa xor sb;
            end if;
            res_float <= r_sign & "111000"; -- +/- Inf
        else
            -- Operasi aritmetika standar
            case sw(15 downto 14) is
                when "00" => -- A + B
                    s_mag_r := s_mag_a + s_mag_b;
                    if s_mag_r < 0 then
                        r_sign  := '1';
                        u_mag_r := -s_mag_r;
                    else
                        r_sign  := '0';
                        u_mag_r := s_mag_r;
                    end if;

                when "01" => -- A - B
                    s_mag_r := s_mag_a - s_mag_b;
                    if s_mag_r < 0 then
                        r_sign  := '1';
                        u_mag_r := -s_mag_r;
                    else
                        r_sign  := '0';
                        u_mag_r := s_mag_r;
                    end if;

                when "10" => -- A * B
                    r_sign  := sa xor sb;
                    u_mag_r := (mag_a * mag_b) / 4096;

                when others => -- A / B
                    r_sign  := sa xor sb;
                    u_mag_r := (mag_a * 4096) / mag_b;
            end case;

            -- Normalisasi & pengemasan ke 7-bit mini-float (dengan denormal)
            if u_mag_r < 64 then
                flag_zero <= '1';
                res_float <= r_sign & "000000";
            elsif u_mag_r >= 63488 then
                -- Overflow ke +/- Infinity (>= 15.5)
                flag_inf  <= '1';
                res_float <= r_sign & "111000";
            elsif u_mag_r < 1024 then
                -- Rentang Denormal (E = 0): langkah = 128 (2^-5 * 4096)
                flag_den  <= '1';
                pack_m    := (u_mag_r + 64) / 128;
                if pack_m >= 8 then
                    res_float <= r_sign & "001000"; -- Naik ke normal terkecil
                elsif pack_m = 0 then
                    flag_zero <= '1';
                    flag_den  <= '0';
                    res_float <= r_sign & "000000";
                else
                    res_float <= r_sign & "000" & std_logic_vector(to_unsigned(pack_m, 3));
                end if;
            else
                -- Rentang Normal (E = 1..6)
                shift_cnt := 0;
                norm_val  := u_mag_r;
                for i in 0 to 5 loop
                    if norm_val >= 2048 then
                        norm_val  := norm_val / 2;
                        shift_cnt := shift_cnt + 1;
                    end if;
                end loop;

                pack_e := shift_cnt + 1;
                pack_m := ((norm_val - 1024) + 64) / 128;
                if pack_m >= 8 then
                    pack_m := 0;
                    pack_e := pack_e + 1;
                end if;

                if pack_e >= 7 then
                    flag_inf  <= '1';
                    res_float <= r_sign & "111000";
                else
                    res_float <= r_sign & std_logic_vector(to_unsigned(pack_e, 3)) & std_logic_vector(to_unsigned(pack_m, 3));
                end if;
            end if;
        end if;

        res_sign <= r_sign;
        res_mag  <= u_mag_r;
    end process;

    -- Konversi nilai desimal ke 7-segment (format X.XX atau XX.X)
    process(flag_nan, flag_inf, res_sign, res_mag)
        variable scaled_100 : integer;
        variable d_int1     : integer range 0 to 9;
        variable d_int0     : integer range 0 to 9;
        variable d_frac1    : integer range 0 to 9;
        variable d_frac0    : integer range 0 to 9;
    begin
        if flag_nan = '1' then
            d3 <= "10000"; d2 <= "10011"; d1 <= "01010"; d0 <= "10011"; -- " nAn"
            dp_vec <= "0000";
        elsif flag_inf = '1' then
            if res_sign = '1' then d3 <= "10001"; else d3 <= "10000"; end if;
            d2 <= "10100"; d1 <= "10011"; d0 <= "01111"; -- "-InF" atau " InF"
            dp_vec <= "0000";
        else
            scaled_100 := (res_mag * 100) / 4096;
            if scaled_100 >= 1000 then
                -- Format: -XX.X (misal 15.0)
                d_int1  := (scaled_100 / 1000) mod 10;
                d_int0  := (scaled_100 / 100) mod 10;
                d_frac1 := (scaled_100 / 10) mod 10;

                if res_sign = '1' then d3 <= "10001"; else d3 <= "10000"; end if;
                d2 <= std_logic_vector(to_unsigned(d_int1, 5));
                d1 <= std_logic_vector(to_unsigned(d_int0, 5));
                d0 <= std_logic_vector(to_unsigned(d_frac1, 5));
                dp_vec <= "0010"; -- Titik desimal di digit 1
            else
                -- Format: -X.XX (misal 3.75)
                d_int0  := (scaled_100 / 100) mod 10;
                d_frac1 := (scaled_100 / 10) mod 10;
                d_frac0 := scaled_100 mod 10;

                if res_sign = '1' then d3 <= "10001"; else d3 <= "10000"; end if;
                d2 <= std_logic_vector(to_unsigned(d_int0, 5));
                d1 <= std_logic_vector(to_unsigned(d_frac1, 5));
                d0 <= std_logic_vector(to_unsigned(d_frac0, 5));
                dp_vec <= "0100"; -- Titik desimal di digit 2
            end if;
        end if;
    end process;

    led(6 downto 0)   <= res_float;
    led(11 downto 7)  <= (others => '0');
    led(12)           <= flag_zero;
    led(13)           <= flag_den;
    led(14)           <= flag_inf;
    led(15)           <= flag_nan;

    u_seg7 : entity work.seg7_ctrl
        port map (
            clk    => clk,
            rst    => '0',
            digit0 => d0,
            digit1 => d1,
            digit2 => d2,
            digit3 => d3,
            dp_in  => dp_vec,
            seg    => seg,
            an     => an,
            dp     => dp
        );

end architecture Behavioral;