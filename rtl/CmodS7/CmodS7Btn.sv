module CmodS7Btn #(
  CLK_FREQ 
) (
  input clk, 
  input rst, 
  input [1:0] btn_i, 
  output [1:0] btn_o
); 

  localparam BTN_DW = 2; 
  localparam EN_FREQ = 1e3;    // milliseconds
  localparam STEADY_STATE_EN_COUNT = 10;    // 10 milliseconds debounce

  wire en;

  EnableGenerator #(
    .CLK_FREQ(CLK_FREQ), 
    .EN_FREQ(EN_FREQ)
  ) en_gen (
    .clk(clk), 
    .rst(rst), 
    .en_o(en)
  );

  Debounce_wide #(
    .DW(BTN_DW), 
    .STEADY_STATE_EN_COUNT(STEADY_STATE_EN_COUNT)
  ) btn_debounce (
    .clk(clk), 
    .rst(rst), 
    .en_i(en),
    .in(btn_i), 
    .out(btn_o)
  );

endmodule
