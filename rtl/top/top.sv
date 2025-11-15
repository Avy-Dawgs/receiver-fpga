module top (
  input clk
  ); 

localparam SYS_CLK_FREQ = 125_000_000;

wire ms_en, us_en;

// uart 
UartTx #(
  .CLK_FREQ(SYS_CLK_FREQ), 
  .BAUD(), 
  .FIFO_ADDR_BITS()
  ) uart (
    .clk(clk), 
    .rst(rst), 
    .data_i(), 
    .wr_en_i(), 
    .tx_o(), 
    .fifo_full_o(), 
    .fifo_empty_o()
  );

// TODO pll for ADC interface, maybe pll for system clock

// ADC
AdcInterface adc (
  .io_clk(), 
  .sys_clk(clk), 
  .rst(rst), 
  .sck(), 
  .mosi(), 
  .cs_n(), 
  .data_o(), 
  .valid_o()
  );

// SPI / PGA 
PgaInterface #(
  .CLK_FREQ(SYS_CLK_FREQ)
  ) pga (
    .clk(clk), 
    .rst(rst), 
    .gain_i(),  // this likely will end up as digipot code not gain
    .set_i(), 
    .done_o(), 
    .sck(), 
    .cs_n(), 
    .miso()
  );

// datapath 
DataPath datapath (
  .clk(clk), 
  .rst(rst), 
  .en_i(), 
  .start_block_i(), 
  .adc_sample_i(), 
  .adc_sample_valid_i(), 
  // TODO add these to module 
  .gain_dB_i(),
  .adc_raw_dB_o(), 
  .adc_rssi_o()
  );

// controller

// time generator
TimeUnitGenerator #(
  .CLK_FREQ(SYS_CLK_FREQ)
  ) time_gen (
    .clk(clk), 
    .rst(rst), 
    .us_en(us_en), 
    .ms_en(ms_en)
  );


endmodule
