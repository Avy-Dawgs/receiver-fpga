/*
* Transmit and receive UART. 
*
* Self generates baud clock via clock division.
*/
module Uart
#(
  CLK_FREQ, 
  BAUD = 115_200, 
  FIFO_ADDR_BITS = 3
)
(
  input clk, 
  input rst, 
  input [7:0] data_i, 
  output [7:0] data_o,
  input wr_en_i,
  input rd_en_i,
  input rx_i,
  output tx_o, 
  output tx_fifo_full_o, 
  output tx_fifo_empty_o,
  output rx_fifo_full_o, 
  output rx_fifo_empty_o
);

  localparam DW = 8;

  wire [DW - 1:0] tx_fifo_rd_data;
  wire [DW - 1:0] rx_fifo_wr_data;
  wire tx_fifo_rd_en;
  wire rx_fifo_wr_en;

  wire baud_en;

  /* 
  * MODULES 
  */

  UartSerializer 
  serializer 
  (
    .clk(clk), 
    .rst(rst), 
    .baud_en_i(baud_en), 
    .fifo_empty_i(fifo_empty_o), 
    .fifo_rd_data_i(tx_fifo_rd_data),
    .fifo_rd_en_o(tx_fifo_rd_en),
    .tx_o(tx_o)
  );

  UartDeserializer 
  #(
    .CLK_FREQ(CLK_FREQ), 
    .BAUD(BAUD)
  ) 
  deserializer 
  (
    .clk(clk), 
    .rst(rst), 
    .rx_i(rx_i), 
    .data_o(rx_fifo_wr_data), 
    .wr_en_o(rx_fifo_wr_en)
  );

  // fifo 
  Fifo 
  #(
    .DW(DW), 
    .SIZE_POW2(FIFO_ADDR_BITS)
  ) 
  tx_fifo 
  (
    .clk(clk), 
    .rst(rst), 
    .wr_data_i(data_i), 
    .wr_en_i(wr_en_i),
    .rd_data_o(tx_fifo_rd_data), 
    .rd_en_i(tx_fifo_rd_en), 
    .full_o(tx_fifo_full_o), 
    .empty_o(tx_fifo_empty_o)
  );

  Fifo 
  #(
    .DW(DW), 
    .SIZE_POW2(FIFO_ADDR_BITS)
  )
  rx_fifo 
  (
    .clk(clk), 
    .rst(rst), 
    .rd_data_o(data_o), 
    .rd_en_i(rd_en_i), 
    .wr_data_i(rx_fifo_wr_data), 
    .wr_en_i(rx_fifo_wr_en), 
    .full_o(rx_fifo_full_o), 
    .empty_o(rx_fifo_empty_o)
  );

  // baud clock generator 
  EnableGenerator 
  #(
    .CLK_FREQ(CLK_FREQ), 
    .EN_FREQ(BAUD)
  )
  baud_clk_gen
  (
    .clk(clk), 
    .rst(rst), 
    .en_o(baud_en)
  );

endmodule
