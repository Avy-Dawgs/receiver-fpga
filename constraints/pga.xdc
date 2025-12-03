# MOSI 
# half period is 20ns, need 5 ns setup time, 5 ns hold time
set_output_delay -clock pga_sck_mmcm -max 2 [get_ports pio42] -clock_fall
set_output_delay -clock pga_sck_mmcm -min -2 [get_ports pio42] -clock_fall
# CS_N
# half period is 20 ns, need 15 ns setup time, 0 ns hold time
set_output_delay -clock pga_sck_mmcm -max 2 [get_ports pio44] -clock_fall
set_output_delay -clock pga_sck_mmcm -min 0 [get_ports pio44] -clock_fall

# set_property SLEW FAST [get_ports pio42] 
# set_property SLEW FAST [get_ports pio44]
