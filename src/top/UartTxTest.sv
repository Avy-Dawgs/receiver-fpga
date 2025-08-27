module UartTxTest
(
  input clk, 
  input rst, 
  output uart_tx
);

  localparam CLK_FREQ = 50_000_000;
  localparam BAUD = 115200;

  logic tx_data; 
  logic wr_en; 

  assign tx_data = "E";
  assign wr_en = 1'h1;

  UartTx 
  #(
    .CLK_FREQ(CLK_FREQ), 
    .BAUD(BAUD)
  )
  uart_tx
  (
    .clk(clk), 
    .rst(rst), 
    .data_i(tx_data), 
    .wr_en_i(wr_en), 
    .tx_o(uart_tx)
  );

endmodule
