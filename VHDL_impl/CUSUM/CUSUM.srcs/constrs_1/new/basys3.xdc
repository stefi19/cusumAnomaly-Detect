## ===============================================================
## CLOCK (100 MHz)
## ===============================================================
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]


## ===============================================================
## BUTTONS
## btn_inc  -> BTNC (center button)
## rst      -> BTNU (up button)
## ===============================================================

set_property PACKAGE_PIN U18 [get_ports btn_inc]
set_property IOSTANDARD LVCMOS33 [get_ports btn_inc]

set_property PACKAGE_PIN T18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]


## ===============================================================
## LED (single LED from top.vhd)
## led -> LED0 on Basys3
## ===============================================================

set_property PACKAGE_PIN U16 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]


## ===============================================================
## 7-SEGMENT DISPLAY
## cat[6:0] segments
## an[3:0]  anodes
## ===============================================================

# Segments (cat)
set_property PACKAGE_PIN W7 [get_ports {cat[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cat[0]}]

set_property PACKAGE_PIN W6 [get_ports {cat[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cat[1]}]

set_property PACKAGE_PIN U8 [get_ports {cat[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cat[2]}]

set_property PACKAGE_PIN V8 [get_ports {cat[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cat[3]}]

set_property PACKAGE_PIN U5 [get_ports {cat[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cat[4]}]

set_property PACKAGE_PIN V5 [get_ports {cat[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cat[5]}]

set_property PACKAGE_PIN U7 [get_ports {cat[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cat[6]}]


# Anodes (an)
set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]

set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]

set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]

set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]
