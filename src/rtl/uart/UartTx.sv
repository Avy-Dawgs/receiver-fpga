/*
* Transmit only UART. 
*
* Self generates baud clock via clock division.
*/
module UartTx
#(
  CLK_FREQ, 
  BAUD = 115_200, 
  FIFO_ADDR_BITS = 3
)
(
  input clk, 
  input rst, 
  input [7:0] data_i, 
  input wr_en_i,
  output tx_o, 
  output fifo_full_o, 
  output fifo_empty_o
);

  localparam DW = 8;

  wire [DW - 1:0] fifo_rd_data;
  logic fifo_rd_en;

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
    .fifo_rd_data_i(fifo_rd_data),
    .fifo_rd_en_o(fifo_rd_en),
    .tx_o(tx_o)
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
    .wr_en_i(wr_en_i),
    .rd_en_i(fifo_rd_en), 
    .wr_data_i(data_i), 
    .rd_data_o(fifo_rd_data), 
    .full_o(fifo_full_o), 
    .empty_o(fifo_empty_o)
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
