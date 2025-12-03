/*
* Transmit and receive UART with async clocks. 
*
* Self generates baud clock via clock division.
*/
module Uart_async
#(
  CLK_FREQ, 
  BAUD = 115_200, 
  FIFO_ADDR_BITS = 3
)
(
  input clk, 
  input rst, 
  input wr_clk, 
  input rd_clk,
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
  fifo_async 
  tx_fifo 
  (
    .rst(rst), 
    .wr_clk(wr_clk), 
    .rd_clk(clk),
    .din(data_i), 
    .wr_en(wr_en_i),
    .dout(tx_fifo_rd_data), 
    .rd_en(tx_fifo_rd_en), 
    .full(tx_fifo_full_o), 
    .empty(tx_fifo_empty_o)
  );

  fifo_async
  rx_fifo 
  (
    .rst(rst), 
    .wr_clk(clk), 
    .rd_clk(rd_clk),
    .dout(data_o), 
    .rd_en(rd_en_i), 
    .din(rx_fifo_wr_data), 
    .wr_en(rx_fifo_wr_en), 
    .full(rx_fifo_full_o), 
    .empty(rx_fifo_empty_o)
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
