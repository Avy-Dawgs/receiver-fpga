module UartTxTest
(
  input clk, 
  input [0:0] btn, 
  output ck_io13
);

  wire rst; 
  wire uart_tx;

  localparam CLK_FREQ = 125_000_000;
  localparam BAUD = 115_200;

  logic [7:0] tx_data; 
  logic wr_en; 
  wire fifo_full; 
  wire fifo_empty;

  assign tx_data = 8'h45;
  assign wr_en = 1'h1;

  assign ck_io13 = uart_tx;
  assign rst = btn[0];

  UartTx 
  #(
    .CLK_FREQ(CLK_FREQ), 
    .BAUD(BAUD)
  )
  uart
  (
    .clk(clk), 
    .rst(rst), 
    .data_i(tx_data), 
    .wr_en_i(wr_en), 
    .tx_o(uart_tx), 
    .fifo_full_o(fifo_full), 
    .fifo_empty_o(fifo_empty)
  );

endmodule
