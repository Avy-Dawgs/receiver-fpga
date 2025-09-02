/*
* Test of signal chain.
*/
module StreamTest
(
  input clk, 
  input [0:0] btn,
  output ck_io13
); 

  localparam CLK_FREQ = 125_000_000;
  localparam FREQ = 457_000;
  localparam SAMP_RATE = 10_000_000; 
  localparam PW_MS = 70; 
  localparam PRI_MS = 1000; 
  localparam DW = 12;
  localparam GOERTZEL_SIZE = 2**16;
  localparam GOERTZEL_FRAC_BITS = 4;
  localparam UART_BAUD = 115_200;

  wire rst;

  wire [DW - 1:0] source_data;
  wire source_valid;

  // uart connections 
  wire uart_tx;
  wire uart_fifo_full; 
  wire uart_fifo_empty;
  wire uart_wr_en;
  logic uart_data;

  logic [15:0] goertzel_input;
  wire [31:0] goertzel_power;
  wire goertzel_done; 

  wire [15:0] dB_power; 
  wire dB_power_valid;

  assign rst = btn[0];
  assign ck_io13 = uart_tx;

  assign goertzel_input = {{16-DW{1'h0}}, source_data};

  assign uart_data = dB_power[7:0];

  // pulsed sine
  PulsedSine
  #(
    .CLK_FREQ(CLK_FREQ), 
    .FREQ(FREQ), 
    .SAMP_RATE(SAMP_RATE), 
    .PW_MS(PW_MS), 
    .PRI_MS(PRI_MS), 
    .DW(DW)
  ) 
  source 
  (
    .clk(clk), 
    .rst(rst), 
    .data_o(source_data), 
    .valid_o(source_valid)
  );

  // goertzel 
  GoertzelPower
  #(
    .FREQ(FREQ), 
    .SIZE(GOERTZEL_SIZE), 
    .SAMP_RATE(SAMP_RATE), 
    .FRAC_BITS(GOERTZEL_FRAC_BITS)
  ) 
  GoertzelPower
  (
    .clk(clk), 
    .rst(rst), 
    .start_i(1'h1), 
    .data_i(goertzel_input), 
    .valid_i(source_valid), 
    .done_o(goertzel_done), 
    .power_o(goertzel_power), 
  );

  // dB conversion 
  PowerConverter 
  dB_converter
  (
    .clk(clk), 
    .rst(rst), 
    .power_i(goertzel_power), 
    .amplifier_gain_i('h0), 
    .valid_i(goertzel_done), 
    .rssi_dBFS_o(), 
    .adc_dB_o(dB_power), 
    .valid_o(dB_power_valid)
  );

  // uart 
  UartTx 
  #(
    .CLK_FREQ(CLK_FREQ), 
    .BAUD(UART_BAUD)
  ) 
  uart
  (
    .clk(clk), 
    .rst(rst), 
    .data_i(dB_power), 
    .wr_en_i(uart_wr_en), 
    .tx_o(uart_tx), 
    .fifo_full_o(uart_fifo_full), 
    .fifo_empty_o(uart_fifo_empty)
  );

endmodule
