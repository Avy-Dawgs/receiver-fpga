/*
* Minimal test of signal path.
*/
module DdcTest (
  input clk, 
  input [0:0] btn, 
  input vauxp5, 
  input vauxn5, 
  output pio29
); 

  localparam SAMP_RATE = 962_000;
  localparam CLK_FREQ = 50_000_000; 
  localparam UART_BAUD = 115_200; 
  localparam UART_FIFO_ABITS = 3;
  localparam MIXER_FREQ = 45_700;

  logic rst; 

  wire [11:0] adc_sample; 
  wire adc_sample_valid;

  wire core_clk;

  logic datapath_en; 
  wire [15:0] datapath_out;
  wire datapath_out_valid;

  wire [7:0] uart_data; 
  wire uart_wr_en; 

  assign datapath_en = 1'h1;
  assign rst = btn[0];

  mmcm_core mmcm_i
   (
    // Clock out ports
    .clk_out1(core_clk),     // output clk_out1
    // Status and control signals
    .reset(rst), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk)      // input clk_in1
);

  XADC_wrapper xadc (
    .clk(core_clk), 
    .rst(rst), 
    .vauxp5(vauxp5), 
    .vauxn5(vauxn5), 
    .data_o(adc_sample), 
    .valid_o(adc_sample_valid)
  );

  // TODO switch with matlab generated
  DataPath #(
    .SAMP_RATE(SAMP_RATE), 
    .MIXER_FREQ(MIXER_FREQ)
  ) datapath (
    .clk(core_clk), 
    .rst(rst), 
    .en_i(datapath_en), 
    .adc_sample_i(adc_sample), 
    .adc_sample_valid_i(adc_sample_valid),
    .dB_o(datapath_out), 
    .valid_o(datapath_out_valid)
  );

  DataFramer data_framer (
    .clk(core_clk), 
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
    .clk(core_clk), 
    .rst(rst), 
    .data_i(uart_data), 
    .wr_en_i(uart_wr_en), 
    .tx_o(pio29), 
    .fifo_full_o(), 
    .fifo_empty_o()
  );

endmodule
