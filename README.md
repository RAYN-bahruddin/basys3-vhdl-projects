# Basys3 FPGA Projects (VHDL)

Implementasi 5 proyek desain digital untuk papan **Digilent Basys3 (Xilinx Artix-7 xc7a35tcpg236-1)** menggunakan bahasa **VHDL**:
1. **Blink (link_top.vhd)**: Pembagi frekuensi clock 100 MHz menjadi kedipan LED 1 Hz.
2. **Calculator Int (calculator_top.vhd)**: ALU integer 4-bit (+, -, *, /) dengan tampilan 7-segment.
3. **Calculator Float (loat_calculator_top.vhd)**: Aritmetika mini-float 7-bit (Sign, Exponent, Mantissa, Denormal, Inf, NaN).
4. **Slot Machine 7-Segment (slot_machine_top_v2.vhd)**: Gim slot machine berbasis FSM dan 3x LFSR RNG.
5. **Slot Machine LCD 16x2 (slot_machine_lcd_top.vhd)**: Gim slot machine dengan driver LCD HD44780 mode 4-bit via Pmod JA.
