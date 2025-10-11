/*
* Top level for gain control simulation.
*/
module gain_ctrl_top (
  input clk,
  input rst,
  input [11:0] adc_in,
  input adc_valid,
  output hga_bypass,
  output signed [7:0] pga_gain
);

// include datapath, and control

endmodule
