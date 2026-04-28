## =============================================================
## zedboard_vga_top.xdc  —  ZedBoard Constraints
##                           320x240 Image, 2x Scaled to 640x480 VGA
##
## Board  : Digilent ZedBoard (XC7Z020-CLG484-1)
## Source : Digilent official Zedboard-Master.xdc
##
## IO Bank 33 = 3.3V fixed  → VGA, LEDs, HDMI, Clock
## IO Bank 34 = 1.8V        → Buttons
## IO Bank 35 = 1.8V        → Switches
## IO Bank 13 = 3.3V fixed  → Clock (Y9)
## =============================================================

## ── System Clock (100 MHz) — Bank 13 ─────────────────────────
set_property PACKAGE_PIN Y9   [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## ── Slide Switches — Bank 35 (1.8V) ──────────────────────────
## SW0=filters_en  SW1=enhance_en  SW2=select0  SW3=select1
set_property PACKAGE_PIN F22  [get_ports {sw[0]}]
set_property PACKAGE_PIN G22  [get_ports {sw[1]}]
set_property PACKAGE_PIN H22  [get_ports {sw[2]}]
set_property PACKAGE_PIN F21  [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[3]}]

## ── Push Buttons — Bank 34 (1.8V) ────────────────────────────
## BTNC=inc_bright  BTND=dec_bright  BTNL=inc_sat  BTNR=dec_sat
set_property PACKAGE_PIN P16  [get_ports {btn[0]}]
set_property PACKAGE_PIN R16  [get_ports {btn[1]}]
set_property PACKAGE_PIN N15  [get_ports {btn[2]}]
set_property PACKAGE_PIN R18  [get_ports {btn[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {btn[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {btn[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {btn[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {btn[3]}]

## ── LEDs — Bank 33 (3.3V) ────────────────────────────────────
set_property PACKAGE_PIN T22  [get_ports {led[0]}]
set_property PACKAGE_PIN T21  [get_ports {led[1]}]
set_property PACKAGE_PIN U22  [get_ports {led[2]}]
set_property PACKAGE_PIN U21  [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

## ── VGA Output — Bank 33 (3.3V) ──────────────────────────────
## Pins from official Digilent Zedboard-Master.xdc
set_property PACKAGE_PIN AA19 [get_ports vga_hs]
set_property PACKAGE_PIN Y19  [get_ports vga_vs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vs]

## Red [3:0]  (VGA_R1..R4)
set_property PACKAGE_PIN V20  [get_ports {vga_r[0]}]
set_property PACKAGE_PIN U20  [get_ports {vga_r[1]}]
set_property PACKAGE_PIN V19  [get_ports {vga_r[2]}]
set_property PACKAGE_PIN V18  [get_ports {vga_r[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[3]}]

## Green [3:0]  (VGA_G1..G4)
set_property PACKAGE_PIN AB22 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN AA22 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN AB21 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN AA21 [get_ports {vga_g[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[3]}]

## Blue [3:0]  (VGA_B1..B4)
set_property PACKAGE_PIN Y21  [get_ports {vga_b[0]}]
set_property PACKAGE_PIN Y20  [get_ports {vga_b[1]}]
set_property PACKAGE_PIN AB20 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN AB19 [get_ports {vga_b[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[3]}]

## ── Timing exceptions ─────────────────────────────────────────
set_false_path -from [get_ports {sw[*]}]
set_false_path -from [get_ports {btn[*]}]
