module minimal ( 
  // ----- CLK -----
  input clk, 
  // ----- BTN -----
  input [1:0] btn, 
  // ----- LED -----
  output led0_r, 
  output led0_g, 
  output led0_b,
  output [3:0] led, 
  // ----- ADC -----
  output pio16,   // cs_n
  output pio18,   // sck
  input pio20,    // mosi
  // ----- UART -----
  output pio29,   // tx
  // ----- PGA -----
  output pio42,   // miso
  output pio44,   // cs_n
  output pio46,   // sck
  // ----- HGA -----
  output pio48    // bypass
); 

  localparam REF_CLK_FREQ = 12_000_000;   // clk 
  localparam CORE_CLK_FREQ = 50_000_000;  // core_clk
  localparam ADC_SCK_FREQ = 87_500_000;   // adc_sck
  localparam PGA_SCK_FREQ = 25_000_000;   // pga_sck

  localparam MIXER_FREQ = 457_000;
  localparam SAMP_RATE = 1_000_000;

  localparam UART_BAUD = 115_200;
  localparam UART_FIFO_ABITS = 3;

  localparam BTN_DW = 2;

  localparam LED_PWM_FREQ = 50_000;

  /************* 
  * WIRES 
  * ***********/
  // ----- IO -----
  // adc
  wire adc_cs_n; 
  wire adc_sck; 
  wire adc_mosi; 
  // uart
  wire uart_tx; 
  // pga
  wire pga_miso;
  wire pga_cs_n; 
  wire pga_sck; 
  // hga
  wire hga_bypass;
  // ----- MMCM -----
  wire mmcm_locked;
  wire core_clk; 
  // ----- BTN -----
  wire [1:0] btn_debounced;
  // ----- LED -----
  wire led0_r_ctrl; 
  wire led0_g_ctrl; 
  wire led0_b_ctrl;
  wire [3:0] led_ctrl;
  // ----- UART ----- 
  wire [7:0] uart_data; 
  wire uart_wr_en;
  wire uart_fifo_full; 
  wire uart_fifo_empty;
  // ----- ADC -----
  wire [11:0] adc_data__acd; // acd = adc clock domain
  wire adc_valid__acd;
  // ----- PGA ---- 
  wire [7:0] pga_code__pcd;  // pcd = pga clock domain
  wire pga_set__pcd;
  wire pga_ready__pcd; 
  // ----- AFE control ----- 
  wire [7:0] gain_dB;
  wire gain_dB_set;
  wire [7:0] pga_code__ccd;   // ccd = core clock domain
  wire pga_set__ccd; 
  wire gain_set_in_progress;
  // ----- DATAPATH ----- 
  wire datapath_en;
  wire [11:0] adc_data__ccd;   // ccd = core clock domain
  wire adc_valid__ccd; 
  wire [15:0] rssi_dB;
  wire rssi_dB_valid;

  /**************** 
  * ASSIGNMENTS 
  * **************/

  // ----- IO mapping -----
  assign pio16 = adc_cs_n; 
  assign pio18 = adc_sck; 
  assign adc_mosi = pio20; 
  assign pio29 = uart_tx; 
  assign pio42 = pga_miso; 
  assign pio44 = pga_cs_n; 
  assign pio46 = pga_sck; 
  assign pio48 = hga_bypass;

  /**************** 
  * MODULES 
  * **************/

  // led controller
  CmodS7Led #(
    .CLK_FREQ(CLK_FREQ), 
    .PWM_FREQ(LED_PWM_FREQ)
  ) led_ctrl (
    .clk(core_clk), 
    .rst(rst), 
    .led0_r_i(led0_r_ctrl), 
    .led0_g_i(led0_g_ctrl), 
    .led0_b_i(led0_b_ctrl),
    .led0_r_o(led0_r), 
    .led0_g_o(led0_g), 
    .led0_b_o(led0_b),
    .led_i(led_ctrl), 
    .led_o(led)
  );
  // TODO reset controller
  // mmcm  
  mmcm mmcm_i (
    // Clock out ports
    .adc_sck(adc_sck),     
    .core_clk(core_clk),     
    .pga_sck(pga_sck),     
    // Status and control signals
    .reset(rst), 
    .locked(mmcm_locked),       
   // Clock in ports
    .clk_in1(clk) 
  );
  // uart 
  UartTx #(
    .CLK_FREQ(CLK_FREQ), 
    .BAUD(UART_BAUD), 
    .FIFO_ADDR_BITS(UART_FIFO_ABITS)
  ) uart_tx (
    .clk(core_clk), 
    .rst(rst),
    .data_i(uart_data), 
    .wr_en_i(uart_wr_en), 
    .tx_o(uart_tx), 
    .fifo_full_o(uart_fifo_full), 
    .fifo_empty_o(uart_fifo_empty)
  );
  // adc interface 
  AdcInterface adc (
    .sck(adc_sck), 
    .rst(rst), 
    .mosi(adc_mosi),
    .cs_n(adc_cs_n),
    .data_o(adc_data__acd), 
    .valid_o(adc_valid__acd)
  );
  // pga interface 
  PgaInterface pga (
    .sck(pga_sck), 
    .rst(rst), 
    .code_i(pga_code__pcd), 
    .set_i(pga_set__pcd), 
    .ready_o(pga_ready__pcd), 
    .cs_n(pga_cs_n), 
    .miso(pga_miso)
  );
  // afe control 
  AfeControl afe_ctrl (
    .clk(core_clk), 
    .rst(rst), 
    .gain_dB_i(gain_dB), 
    .set_gain_i(gain_dB_set), 
    .pga_code_o(pga_code__ccd), 
    .set_pga_o(pga_set__ccd), 
    .set_pga_done_i(),  // TODO using ready signal now
    .hga_bypass_o(hga_bypass), 
    .set_in_progress_o(gain_set_in_progress)
  );
  // TODO control module
  // button debounce TODO time reference (change intenral to MS impl?)
  Debounce_wide #(
    .DW(BTN_DW), 
    .STEADY_STATE_EN_COUNT()
  ) btn_debounce (
    .clk(core_clk), 
    .rst(rst), 
    .en_i(),
    .in(btn), 
    .out(btn_debounced)
  );
  // datapath 
  DataPath #(
    .SAMP_RATE(SAMP_RATE), 
    .MIXER_FREQ(MIXER_FREQ)
  ) datapath (
    .clk(core_clk), 
    .rst(rst), 
    .en_i(datapath_en), 
    .adc_sample_i(adc_data__ccd), 
    .adc_sample_valid_i(adc_valid__ccd), 
    .dB_o(rssi_dB), 
    .valid_o(rssi_dB_valid)
  );
  // output data framing
  DataFramer data_framer (
    .clk(core_clk), 
    .rst(rst), 
    .data_i(rssi_dB), 
    .valid_i(rssi_dB_valid), 
    .uart_data(uart_data), 
    .wr_en_o(uart_wr_en)
  );

endmodule
