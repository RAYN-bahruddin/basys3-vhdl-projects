# Basys3 FPGA Digital Systems & VGA Engine (VHDL)

Kumpulan 6 proyek sistem digital dalam bahasa **VHDL** untuk papan **Digilent Basys3 (`xc7a35tcpg236-1`)**, dilengkapi fitur pengembangan (**Novelty**) berupa **Mesin VGA 12-Bit (640x480 @ 60 Hz)** yang merender *7-segment* virtual ke monitor secara *real-time*.

## 1. Pemetaan Folder GitHub ke Vivado
Jika Anda membuka langsung **`slot_machine.xpr`**, seluruh susunan sudah otomatis siap pakai. Jika menyalin file secara manual ke proyek baru, masukkan sesuai foldernya:
* `slot_machine.srcs/sources_1/new/*.vhd` -> **Design Sources**
* `slot_machine.srcs/sim_1/new/*_tb.vhd` -> **Simulation Sources**
* `slot_machine.srcs/constrs_1/new/*.xdc` -> **Constraints**

## 2. Susunan Hierarki Otomatis di Vivado
Di GitHub seluruh file di `sources_1/new` tampil urut abjad, namun di dalam **Design Sources** Vivado otomatis mengelompokkan file pendukung (`debounce`, `game_text`, `lcd_hd44780`, `seg7_ctrl`, `vga_sync`, `vga_digit_renderer`) ke dalam masing-masing *Top Module*:

```text
Design Sources
├── slot_machine_vga_top.vhd         [Proyek 6: Slot Machine + VGA]
│   ├── vga_sync.vhd
│   └── vga_digit_renderer.vhd
├── slot_machine_lcd_top.vhd         [Proyek 5: Slot Machine + LCD 16x2]
│   ├── debounce.vhd
│   ├── game_text.vhd
│   └── lcd_hd44780.vhd
├── slot_machine_top_v2.vhd          [Proyek 4: Slot Machine 7-Segment]
│   ├── debounce.vhd
│   └── seg7_ctrl.vhd
├── calculator_top.vhd               [Proyek 2: Kalkulator Integer]
│   └── seg7_ctrl.vhd
├── float_calculator_top.vhd         [Proyek 3: Kalkulator Mini-Float]
│   └── seg7_ctrl.vhd
└── blink_top.vhd                    [Proyek 1: LED Blink 1 Hz]
```

## 3. Tabel Pengaturan per Proyek
Pilih satu proyek yang ingin dijalankan, lalu atur **Top Module**, **Testbench**, dan **Constraint** sesuai tabel berikut:

| No | Proyek | Design (`Set as Top`) | File Pendukung Wajib | Simulation (`Set as Top`) | Constraint Aktif (`.xdc`) | Durasi Sim |
| :- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **LED Blink 1 Hz** | `blink_top` | *(Mandiri)* | `blink_tb` | `basys3_all.xdc` | `1100 ms` |
| **2** | **Integer Calculator** | `calculator_top` | `seg7_ctrl.vhd` | `calculator_tb` | `basys3_all.xdc` | `5 ms` |
| **3** | **Mini-Float Calc** | `float_calculator_top` | `seg7_ctrl.vhd` | `float_calculator_tb` | `basys3_all.xdc` | `5 ms` |
| **4** | **Slot Machine 7-Seg** | `slot_machine_top_v2` | `debounce.vhd`, `seg7_ctrl.vhd` | `slot_machine_tb` | `basys3_all.xdc` | `400 ms` |
| **5** | **Slot Machine LCD** | `slot_machine_lcd_top` | `debounce.vhd`, `game_text.vhd`, `lcd_hd44780.vhd` | `slot_machine_lcd_tb` | `basys3_all.xdc` | `400 ms` |
| **6** | **Slot Machine VGA** | `slot_machine_vga_top` | `vga_sync.vhd`, `vga_digit_renderer.vhd` | `slot_machine_vga_tb` | `basys3_slot_vga.xdc` | `35 ms` |

## 4. Cara Menjalankan di Vivado (4 Langkah)
1. **Buka Proyek:** Jalankan Vivado, klik **Open Project**, lalu pilih `slot_machine.xpr` (pastikan lokasi folder tanpa spasi, misal `D:\slot_machine`).
2. **Atur Top & Constraint:** Klik kanan modul utama pilihan Anda -> **Set as Top**, klik kanan *testbench* pasangannya -> **Set as Top**, lalu aktifkan **hanya satu** file `.xdc` yang sesuai (`Set as Target Constraint File`).
3. **Simulasi:** Klik **Run Simulation -> Run Behavioral Simulation**, lalu ketik `restart; run 35 ms; wave zoom full` di **Tcl Console**.
4. **Upload ke Basys3:** Klik **Generate Bitstream**, lalu buka **Open Hardware Manager -> Auto Connect -> Program Device**.

## 5. Kontrol Pin & Fitur VGA (`slot_machine_vga_top`)
Modul ini menampilkan angka ke **7-segment papan Basys3** dan **monitor VGA 640x480 @ 60 Hz** secara bersamaan (berubah warna emas saat *Jackpot*):
* **`btnC` (Tengah):** Putar gulungan (*Spin*).
* **`btnR` (Kanan):** Reset permainan.
* **`sw[0]`:** Mode *Cheat Jackpot* (`1` = hasil berhenti dipaksa `7-7-7`).
* **`sw[1]`:** Mode *Fast Spin* (`1` = percepat putaran untuk simulasi; posisikan ke `0` saat di papan fisik).
* **`led[2:0]`:** Indikator ganjil-genap tiap gulungan (`1` = ganjil, `0` = genap); **seluruh `led[15:0]`** menyala penuh saat *Jackpot*.
