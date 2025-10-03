/*
* Controls the signal chain, and the amplifier gain.
*/
module Control
(
  input clk, 
  input rst, 
  input power_i, // TODO width
  input valid_i,
  output dc_block_en_o, 
  output goertzel_start_o, 
  output hga_bypass_o,    // high gain amp enable (stage 1)
  output pga_gain_o   // TODO width
); 
  
  // how long to wait after changing HGA
  localparam HGA_SET_SETTLE_TIME = 0;
  // how long to wait after setting PGA
  localparam PGA_SET_SETTLE_TIME = 0;


  /*
  * MODULES
  */

  // pulse repetition interval counter 

  // settle time timer

endmodule
