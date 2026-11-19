# Basys3 FPGA Digital Systems & VGA Engine (VHDL)

Implementasi sistem digital pada papan **Digilent Basys3 (Xilinx Artix-7 `xc7a35tcpg236-1`)** menggunakan **VHDL**, dilengkapi ekstensi perangkat keras (**Novelty**) berupa **Mesin VGA 12-Bit (640x480 @ 60 Hz)** yang merender tampilan *7-segment* virtual ke monitor eksternal secara *real-time*.

## Spesifikasi Hardware & Software
* **Target FPGA:** Digilent Basys3 (`xc7a35tcpg236-1`)
* **Clock Utama:** 100 MHz Oscillator (`W5`)
* **IDE:** Xilinx Vivado Design Suite (2025.1 atau kompatibel)

## Daftar Proyek & Konfigurasi Vivado

| No | Nama Proyek | Top Module (`Design`) | Testbench (`Simulation`) | Constraint (`.xdc`) | Durasi Simulasi |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **LED Blink 1 Hz** | `blink_top` | `blink_tb` | `basys3_all.xdc` | `1100 ms` |
| **2** | **Integer Calculator** | `calculator_top` | `calculator_tb` | `basys3_all.xdc` | `5 ms` |
| **3** | **Mini-Float Calculator** | `float_calculator_top` | `float_calculator_tb` | `basys3_all.xdc` | `5 ms` |
| **4** | **Slot Machine (7-Seg)** | `slot_machine_top_v2` | `slot_machine_tb` | `basys3_all.xdc` | `400 ms` |
| **5** | **Slot Machine (LCD 16x2)** | `slot_machine_lcd_top` | `slot_machine_lcd_tb` | `basys3_all.xdc` | `400 ms` |
| **6** | **Slot Machine + VGA 12-Bit** | `slot_machine_vga_top` | `slot_machine_vga_tb` | `basys3_slot_vga.xdc` | `35 ms` |

## Fitur Unggulan (Novelty): Mesin VGA 12-Bit Virtual 7-Segment
Pada **`slot_machine_vga_top.vhd`**, FPGA bekerja sebagai *Dual-Display Hardware Renderer* tanpa *frame buffer* BRAM maupun *soft-core* CPU:
* **`vga_sync.vhd`**: Membagi *clock* 100 MHz menjadi *pixel tick* 25 MHz dan menghasilkan sinyal sinkronisasi VGA 640x480 @ 60 Hz (`Hsync` pin `P19`, `Vsync` pin `R19`).
* **`vga_digit_renderer.vhd`**: Merender 4 kotak *7-segment* virtual (1 digit penghitung *spin* + 3 digit gulungan *slot*) menggunakan output warna 12-bit (`vgaRed[3:0]`, `vgaGreen[3:0]`, `vgaBlue[3:0]`). Saat *Jackpot* (`7-7-7` atau 3 angka sama), warna digit otomatis berubah menjadi emas menyala dan 16 LED papan Basys3 menyala penuh.

### Kontrol Pin (`slot_machine_vga_top`)
* **`btnC` (Tengah):** Putar gulungan (*Spin*).
* **`btnR` (Kanan):** Reset sistem.
* **`sw[0]`:** *Mode Cheat Jackpot* (`1` = hasil berhenti dipaksa `7-7-7`).
* **`sw[1]`:** *Mode Fast Spin* (`1` = percepat putaran untuk simulasi; ubah ke `0` saat upload ke board fisik).

## Langkah Implementasi di Vivado
1. Buka file proyek **`slot_machine.xpr`** di Vivado (pastikan folder berada di jalur tanpa spasi, misalnya `D:\slot_machine`).
2. Pada panel **Sources**, klik kanan modul utama pilihan Anda (misalnya `slot_machine_vga_top`) -> **Set as Top**.
3. Pada **Simulation Sources**, klik kanan *testbench* pasangannya (`slot_machine_vga_tb`) -> **Set as Top**.
4. Pada **Constraints**, aktifkan hanya file `.xdc` yang sesuai (`basys3_slot_vga.xdc`) -> **Set as Target Constraint File**.
5. Klik **Run Simulation -> Run Behavioral Simulation**, lalu jalankan `restart; run 35 ms; wave zoom full` pada **Tcl Console**.
6. Untuk unggah ke board fisik Basys3, posisikan `sw[1]` ke `0`, klik **Generate Bitstream**, lalu program perangkat melalui **Hardware Manager**.
