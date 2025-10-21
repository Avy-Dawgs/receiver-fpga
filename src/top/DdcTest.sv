module DdcTest (
  input clk, 
  input [0:0] btn, 
  input Vp_Vn_0_v_p, 
  input Vp_Vn_0_v_n,
  output ck_io13
); 

  localparam SAMP_RATE = 1_000_000;
  localparam CLK_FREQ = 125_000_000; 
  localparam UART_BAUD = 115_200; 
  localparam UART_FIFO_ABITS = 3;
  localparam MIXER_FREQ = 45_700;

  logic rst; 

  wire vp; 
  wire vn;

  wire [11:0] adc_sample; 
  wire adc_sample_valid;

  logic datapath_en; 
  wire [15:0] datapath_out;
  wire datapath_out_valid;

  wire [7:0] uart_data; 
  wire uart_wr_en; 

  assign datapath_en = 1'h1;
  assign rst = btn[0];

  assign vp = Vp_Vn_0_v_p; 
  assign vn = Vp_Vn_0_v_n;

  XADC_wrapper xadc (
    .clk(clk), 
    .rst(rst), 
    .vp(vp), 
    .vn(vn), 
    .data_o(adc_sample), 
    .valid_o(adc_sample_valid)
  );

  DataPath #(
    .SAMP_RATE(SAMP_RATE), 
    .MIXER_FREQ(MIXER_FREQ)
  ) datapath (
    .clk(clk), 
    .rst(rst), 
    .en_i(datapath_en), 
    .adc_sample_i(adc_sample), 
    .adc_sample_valid_i(adc_sample_valid),
    .dB_o(datapath_out), 
    .valid_o(datapath_out_valid)
  );

  DataFramer data_framer (
    .clk(clk), 
    .rst(rst), 
    .data_i(datapath_out), 
    .valid_i(datapath_out_valid), 
    .uart_data(uart_data), 
    .wr_en_o(uart_wr_en)
  );

  UartTx #(
    .CLK_FREQ(CLK_FREQ), 
    .BAUD(UART_BAUD), 
    .FIFO_ADDR_BITS(UART_FIFO_ABITS)
  ) uart_tx (
    .clk(clk), 
    .rst(rst), 
    .data_i(uart_data), 
    .wr_en_i(uart_wr_en), 
    .tx_o(ck_io13), 
    .fifo_full_o(), 
    .fifo_empty_o()
  );

endmodule
