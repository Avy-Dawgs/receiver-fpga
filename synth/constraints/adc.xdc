# CS_N 
# 5 ns sck setup after cs_n falling (cs_n always triggered by rising edge, sck pulse width 5.7 ns)
set_output_delay -clock clk_out1_mmcm_core -max 0.7 [get_ports pio16] 
# 5 ns cs_n rising setup after sck fallling 
set_output_delay -clock clk_out1_mmcm_core -min -0.7 [get_ports pio16] 
# MISO 
# estimate trace delay (both directions) as 1 ns, sdo hold time is 1ns
set_input_delay -clock clk_out1_mmcm_core -max 5 [get_ports pio20] -clock_fall 
set_input_delay -clock clk_out1_mmcm_core -min 3 [get_ports pio20] -clock_fall 

set_property SLEW FAST [get_ports pio16]
set_property SLEW FAST [get_ports pio18]
