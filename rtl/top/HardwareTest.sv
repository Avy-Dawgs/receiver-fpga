/*
* Test communication with all hardware.
*/
module HardwareTest ( 
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
  input pio20,    // miso
  // ----- UART -----
  output pio29,   // tx
  // ----- PGA -----
  output pio42,   // mosi
  output pio44,   // cs_n
  output pio46,   // sck
  // ----- HGA -----
  output pio48    // bypass
); 

  localparam real ADC_SCK_FREQ = 87.49091e6;
  localparam real PGA_SCK_FREQ = 20e6;   // pga_sck

  localparam real UART_BAUD = 115.2e3;
  localparam UART_FIFO_ABITS = 3;

  localparam LED_PWM_FREQ = 1000;

  /************* 
  * WIRES 
  * ***********/
  // ----- IO -----
  // adc
  wire adc_cs_n; 
  wire adc_sck; 
  wire adc_miso; 
  wire adc_error;
  // uart
  wire uart_tx; 
  // pga
  wire pga_mosi;
  wire pga_cs_n; 
  wire pga_sck; 
  // hga
  wire hga_active;
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
  wire [11:0] adc_data; // acd = adc clock domain
  wire adc_valid;
  // ----- PGA ---- 
  wire [7:0] pga_code;  // pcd = pga clock domain
  wire pga_set;
  wire pga_ready; 

  // ----- CTRL ----- 
  wire set_gain; 
  wire [7:0] gain_dB;

  /**********************
  * Sequaential 
  * ********************/

  localparam MAX_ADC_SAMPLE_COUNT = 2000;

  reg [15:0] adc_sample_count;
  logic max_adc_sample_count_reached;

  always_ff @(posedge adc_sck, posedge rst) begin 
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

  /**************** 
  * ASSIGNMENTS 
  * **************/

  // ----- IO mapping -----
  assign pio16 = adc_cs_n; 
  assign pio18 = adc_sck; 
  assign adc_miso = pio20; 
  assign pio29 = uart_tx; 
  assign pio42 = pga_mosi; 
  assign pio44 = pga_cs_n; 
  assign pio46 = pga_sck; 
  assign pio48 = hga_active;

  assign led_ctrl = gain_dB[5:2];
  assign led0_r_ctrl = hga_active;
  assign led0_g_ctrl = 1'h0; 
  assign led0_b_ctrl = 1'h0;

  assign rst = 1'h0;

  assign uart_data = adc_data[7:0];

  /**************** 
  * MODULES 
  * **************/

  // led controller
  CmodS7Bsm #(
    .CLK_FREQ(PGA_SCK_FREQ), 
    .LED_PWM_FREQ(LED_PWM_FREQ)
  ) bsm (
    .clk(pga_sck), 
    .rst(rst), 
    .led0_r_i(led0_r_ctrl), 
    .led0_g_i(led0_g_ctrl), 
    .led0_b_i(led0_b_ctrl),
    .led0_r_o(led0_r), 
    .led0_g_o(led0_g), 
    .led0_b_o(led0_b),
    .led_i(led_ctrl), 
    .led_o(led),
    .btn_i(btn), 
    .btn_o(btn_debounced)
  );
  // mmcm  
  mmcm mmcm_inst (
    .sys_clk_i(clk),
    .adc_sck(adc_sck),     
    .pga_sck(pga_sck)
  );
  // uart 
  UartTx #(
    .CLK_FREQ(ADC_SCK_FREQ), 
    .BAUD(UART_BAUD), 
    .FIFO_ADDR_BITS(UART_FIFO_ABITS)
  ) uart_tx_i (
    .clk(adc_sck), 
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
    .miso(adc_miso),
    .cs_n(adc_cs_n),
    .data_o(adc_data), 
    .valid_o(adc_valid), 
    .error_o(adc_error)
  );
  adc_ila adc_ila_i (
    .clk(adc_sck), 
    .probe0(adc_data), 
    .probe1(adc_valid),
    .probe2(adc_error)
  );
  // pga interface 
  PgaInterface pga (
    .sck(pga_sck), 
    .rst(rst), 
    .code_i(pga_code), 
    .set_i(pga_set), 
    .ready_o(pga_ready), 
    .cs_n(pga_cs_n), 
    .mosi(pga_mosi)
  );
  AfeControl afe_control (
    .clk(pga_sck), 
    .rst(rst), 
    .gain_dB_i(gain_dB), 
    .set_gain_i(set_gain), 
    .pga_code_o(pga_code), 
    .set_pga_o(pga_set),
    .pga_ready_i(pga_ready), 
    .hga_active_o(hga_active), 
    .set_in_progress_o()
  );
  ManualControl manual_control (
    .clk(pga_sck), 
    .rst(rst), 
    .btn_i(btn_debounced), 
    .gain_dB_o(gain_dB), 
    .set_gain_o(set_gain)
  );

endmodule

/*
* Set gain manually with button for testing.
*/
module ManualControl (
  input clk, 
  input rst, 

  input [1:0] btn_i, 

  output reg signed [7:0] gain_dB_o,
  output reg set_gain_o
);

  wire btn0_rising; 
  wire btn1_rising;

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      gain_dB_o <= 'h0;
      set_gain_o <= 1'h0;
    end 
    else begin 
      if (btn0_rising) begin 
        set_gain_o <= 1'h1;
        if (gain_dB_o == 'd44) begin 
          gain_dB_o <= -16;
        end
        else begin
          gain_dB_o <= gain_dB_o + 'd4;
        end
      end
      else begin
        set_gain_o <= 1'h0;
      end
    end
  end

  // button edge detectors
  EdgeDetector_synchronous btn0_edge (
    .clk(clk), 
    .rst(rst), 
    .test_clk(btn_i[0]),  
    .rising_edge(btn0_rising), 
    .falling_edge()
  );
  EdgeDetector_synchronous btn1_edge (
    .clk(clk), 
    .rst(rst), 
    .test_clk(btn_i[1]),  
    .rising_edge(btn1_rising), 
    .falling_edge()
  );


endmodule
