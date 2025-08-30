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
  output hga_en_o,    // high gain amp enable (stage 1)
  output pga_gain_o   // TODO width
); 


  /*
  * MODULES
  */

  // pulse repetition interval counter 

  // settle time timer

endmodule
