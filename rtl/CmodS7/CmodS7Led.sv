/*
* Controls the LEDS on a Digilent Cmod S7. 
* Uses PWM to lower the brightness. 
*/
module CmodS7Led #(
  CLK_FREQ,
  PWM_FREQ
  ) (
  input clk, 
  input rst, 
  input led0_r_i, 
  input led0_g_i, 
  input led0_b_i,
  output led0_r_o, 
  output led0_g_o, 
  output led0_b_o,
  input [3:0] led_i,
  output [3:0] led_o
); 

  localparam CLK_CYC_PER_PWM_CYC = CLK_FREQ / PWM_FREQ;
  localparam MAX_COUNT = CLK_CYC_PER_PWM_CYC  - 1;
  localparam CBITS = $clog2(MAX_COUNT);


  reg [CBITS - 1:0] count;
  logic duty_50;
  logic duty_25;


  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      count <= 'h0;
    end 
    else begin 
      count <= count + 1'h1;
    end
  end


  assign duty_50 = (count[CBITS-1] == 1'h1);
  assign duty_25 = (count[CBITS-1 -: 2] == 2'h3);
  assign led_o = {4{duty_50}} & led_i;
  assign led0_r_o = ~(led0_r_i & duty_25);
  assign led0_g_o = ~(led0_g_i & duty_25);
  assign led0_b_o = ~(led0_b_i & duty_25);

endmodule
