/*
* PWM of LEDs and debouncing of buttons.
*/
module CmodS7Bsm #(
  CLK_FREQ, 
  LED_PWM_FREQ
) (
  input clk, 
  input rst, 

  input [1:0] btn_i, 
  output [1:0] btn_o,

  input [3:0] led_i,
  output [3:0] led_o,
  input led0_r_i, 
  input led0_g_i, 
  input led0_b_i,
  output led0_r_o, 
  output led0_g_o, 
  output led0_b_o
);

  CmodS7Btn #(
    .CLK_FREQ(CLK_FREQ)
  ) btn_debounce (
    .clk(clk), 
    .rst(rst), 
    .btn_i(btn_i), 
    .btn_o(btn_o)
  );

  // led controller
  CmodS7Led #(
    .CLK_FREQ(CLK_FREQ), 
    .PWM_FREQ(LED_PWM_FREQ)
  ) led_ctrl (
    .clk(clk), 
    .rst(rst), 
    .led0_r_i(led0_r_i), 
    .led0_g_i(led0_g_i), 
    .led0_b_i(led0_b_i),
    .led0_r_o(led0_r_o), 
    .led0_g_o(led0_g_o), 
    .led0_b_o(led0_b_o),
    .led_i(led_i), 
    .led_o(led_o)
  );

endmodule
