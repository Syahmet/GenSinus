vcom Module_cordic.vhd
vsim -t ps work.module_cordic
add wave *
add wave -format Analog-Step -radix decimal -height 100 -max 65535 -min -65535 SINUS
add wave -format Analog-Step -radix decimal -height 100 -max 65535 -min -65535 COSINUS
force -freeze sim:/module_cordic/CLK 1 0, 0 {50 ps} -r 100
#force -freeze sim:/module_cordic/ANGLE 30 0

run 8000
