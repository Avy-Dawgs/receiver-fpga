/*
* Transmit only UART.
*/
module UartTx
#(
  CLK_FREQ, 
  BAUD = 115_200
)
(
  input clk, 
  input rst, 
  input [7:0] data_i, 
  input wr_en_i,
  output tx_o
);

wire [7:0] fifo_rd_data;
wire fifo_full, fifo_empty; 
logic fifo_rd_en;

wire baud_clk;
wire baud_clk_rising_edge, baud_clk_falling_edge;

/* 
* MODULES 
*/

UartSerializer 
serializer 
(
  .clk(clk), 
  .rst(rst), 
  .baud_clk_rising_edge(baud_clk_rising_edge), 
  .baud_clk_falling_edge(baud_clk_falling_edge), 
  .fifo_empty_i(fifo_empty), 
  .fifo_rd_data_i(fifo_rd_data),
  .fifo_rd_en_o(fifo_rd_en),
  .tx_o(tx_o)
);

// fifo 
Fifo #(.DW(8), .SIZE_POW2(3)) 
tx_fifo 
(
  .clk(clk), 
  .rst(rst), 
  .wr_en_i(wr_en_i),
  .rd_en_i(fifo_rd_en), 
  .wr_data_i(data_i), 
  .rd_data_o(fifo_rd_data), 
  .full_o(fifo_full), 
  .empty_o(fifo_empty)
);

// baud clock generator 
ClockGenerator 
#(
  .CLK_FREQ(CLK_FREQ), 
  .TARGET_CLK_FREQ(BAUD)
)
baud_clk_gen
(
  .clk(clk), 
  .rst(rst), 
  .gen_clk(baud_clk),
);

// baud clock edge detector
EdgeDetector_synchronous 
baud_clk_edge_detect
(
  .clk(clk), 
  .rst(rst), 
  .test_clk(baud_clk), 
  .rising_edge(baud_clk_rising_edge), 
  .falling_edge(baud_clk_falling_edge)
);

endmodule
