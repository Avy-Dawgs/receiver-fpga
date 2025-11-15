/*
* Minimal test of signal path using XADC.
*/
module DdcTest (
  input clk, 
  input [0:0] btn, 
  input vaux5_p, 
  input vaux5_n, 
  output pio29
); 

  localparam SAMP_RATE = 1_000_000;
  localparam CLK_FREQ = 52_000_000; 
  localparam UART_BAUD = 115_200; 
  localparam UART_FIFO_ABITS = 3;

  logic rst; 

  wire [11:0] adc_data; 
  wire adc_valid;

  wire core_clk;

  logic datapath_en; 
  wire [31:0] sigchain_data;
  wire sigchain_valid;

  wire uart_fifo_full;

  wire [7:0] uart_data; 
  wire uart_wr_en; 

  assign sigchain_en = 1'h1;
  // assign rst = 1'h0;
  assign rst = btn[0];

  mmcm_core mmcm_i (
    .clk_out1(core_clk),     
    .clk_in1(clk)      
  );

  XADC_wrapper xadc (
    .clk(core_clk), 
    .rst(rst), 
    .vauxp5(vaux5_p), 
    .vauxn5(vaux5_n), 
    .data_o(adc_data), 
    .valid_o(adc_valid)
  );

  Signal_Chain sig_chain (
    .clk(core_clk), 
    .rst(rst), 
    .clk_en(sigchain_en), 
    .data_i(adc_data), 
    .valid_i(adc_valid), 
    .ce_out(), 
    .data_o(sigchain_data), 
    .valid_o(sigchain_valid)
  );

  DataFramer #(
    .NBYTES(4)
    ) data_framer (
    .clk(core_clk), 
    .rst(rst), 
    .data_i(sigchain_data), 
    .valid_i(sigchain_valid), 
    .uart_fifo_full_i(uart_fifo_full),
    .uart_data(uart_data), 
    .uart_wr_en_o(uart_wr_en)
  );

ila_0 ila_i (
	.clk(core_clk), // input wire clk


	.probe0(adc_data), // input wire [11:0]  probe0  
	.probe1(adc_valid), // input wire [0:0]  probe1 
	.probe2(sigchain_data), // input wire [31:0]  probe2 
	.probe3(sigchain_valid), // input wire [0:0]  probe3 
	.probe4(uart_data), // input wire [7:0]  probe4 
	.probe5(uart_wr_en), // input wire [0:0]  probe5 
	.probe6(uart_fifo_full), // input wire [0:0]  probe6 
	.probe7(pio29) // input wire [0:0]  probe7
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
    .fifo_full_o(uart_fifo_full), 
    .fifo_empty_o()
  );

endmodule
