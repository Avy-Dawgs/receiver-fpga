/*
* For testing receiving data from the adc.
*/
module AdcOnly (
  input clk,
  input [1:0] btn, 

  output pio16,     // adc cs_n
  // output pio17,
  output pio18,     // adc sck
  // output pio19,
  input pio20,      // adc miso

  output pio29,     // uart tx

  output pio48,     // hga bypass

  output [3:0] led, 
  output led0_r, 
  output led0_g, 
  output led0_b
); 

  assign pio48 = 1'h0;


  localparam real CLK_FREQ = 87.49091e6;
  // localparam real CLK_FREQ = 30e6;
  localparam real LED_PWM_FREQ = 2000;

  localparam MAX_ADC_SAMPLE_COUNT = 2000;

  localparam UART_BAUD = 115200;
  localparam UART_FIFO_ABITS = 2;

  logic rst; 

  wire sck; 
  wire miso; 
  wire cs_n; 
  wire [11:0] adc_data;
  wire adc_valid;
  wire adc_error;

  reg [15:0] adc_sample_count;
  logic max_adc_sample_count_reached;

  logic [3:0] led_ctrl; 
  logic led_r_ctrl; 
  logic led_g_ctrl; 
  logic led_b_ctrl;

  logic uart_wr_en;
  wire uart_tx;


  always_ff @(posedge sck, posedge rst) begin 
    if (rst) begin 
      adc_sample_count <= 'h0;
    end 
    else if (adc_valid) begin 
      if (max_adc_sample_count_reached) begin 
        adc_sample_count <= 'h0;
      end
      else begin
        adc_sample_count <= adc_sample_count + 1'h1;
      end
    end
  end

  assign max_adc_sample_count_reached = (adc_sample_count == MAX_ADC_SAMPLE_COUNT);
  assign uart_wr_en = adc_valid && max_adc_sample_count_reached;

  assign pio16 = cs_n; 
  // assign pio17 = cs_n; 
  assign pio18 = sck; 
  // assign pio19 = sck;
  assign miso = pio20;

  assign pio29 = uart_tx;

  assign rst = 1'h0;

  // mmcm  
  mmcm mmcm_inst (
    .sys_clk_i(clk),
    .adc_sck(sck)
    // .pga_sck()
  );
  adc_ila adc_ila_i (
    .clk(sck), // input wire clk
    // .trig_in(adc_valid),// input wire trig_in 
    // .trig_in_ack(),// output wire trig_in_ack 
    .probe0(adc_data), // input wire [11:0] probe0
    .probe1(adc_valid),
    .probe2(adc_error)
  );

  UartTx #(
    .CLK_FREQ(CLK_FREQ), 
    .BAUD(UART_BAUD), 
    .FIFO_ADDR_BITS(UART_FIFO_ABITS)
  ) uart (
    .clk(sck), 
    .rst(rst), 
    .data_i(adc_data[7:0]), 
    .wr_en_i(uart_wr_en), 
    .tx_o(uart_tx), 
    .fifo_full_o(), 
    .fifo_empty_o()
  );

  CmodS7Led #(
    .CLK_FREQ(CLK_FREQ), 
    .PWM_FREQ(LED_PWM_FREQ)
  ) leds (
    .clk(sck), 
    .rst(rst), 
    .led0_r_i(led_r_ctrl), 
    .led0_g_i(led_g_ctrl), 
    .led0_b_i(led_b_ctrl), 
    .led0_r_o(led0_r), 
    .led0_g_o(led0_g), 
    .led0_b_o(led0_b), 
    .led_i(led_ctrl), 
    .led_o(led)
  );

  AdcInterface (
    .sck(sck), 
    .rst(rst), 
    .miso(miso), 
    .cs_n(cs_n), 
    .data_o(adc_data), 
    .valid_o(adc_valid), 
    .error_o(adc_error)
  );

endmodule
