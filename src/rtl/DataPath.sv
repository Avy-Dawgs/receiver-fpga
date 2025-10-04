module DataPath(
  input clk, 
  input rst, 
  input en_i, 
  input start_block_i, 
  input [11:0] adc_sample_i, 
  input adc_sample_valid_i
); 
  localparam SAMPLE_RATE = 5_000_000; 
  localparam TARGET_FREQ = 457_000;

  localparam ADC_DW = 12;
  localparam DC_BLOCK_FRAC_BITS = 4;

  localparam GOERTZEL_BLOCK_SIZE_POW2 = 15; 
  localparam GOERTZEL_FRAC_BITS = 4;
  localparam GOERTZEL_DW = ADC_DW + DC_BLOCK_FRAC_BITS;

  wire [ADC_DW + DC_BLOCK_FRAC_BITS - 1:0] dc_block_output; 
  wire dc_block_output_valid;

  wire [GOERTZEL_DW*2 - 1:0] goertzel_output; 
  wire goertzel_done;

// dc blocking filter
DcBlocker #(
  .INPUT_DW(ADC_DW), 
  .INTERNAL_FRAC_BITS(DC_BLOCK_FRAC_BITS), 
  .OUTPUT_FRAC_BITS(DC_BLOCK_FRAC_BITS)
)
dc_blocker (
  .clk(clk), 
  .rst(rst), 
  .en_i(en_i), 
  .data_i(adc), 
  .valid_i(adc_sample_valid_i), 
  .data_o(dc_block_output), 
  .valid_o(dc_block_output_valid)
);

// goertzel alg 
GoertzelPower #(
  .FREQ(TARGET_FREQ), 
  .SIZE_POW2(GOERTZEL_BLOCK_SIZE_POW2), 
  .SAMP_RATE(SAMPLE_RATE), 
  .FRAC_BITS(GOERTZEL_FRAC_BITS), 
  .DW(GOERTZEL_DW)
)
goertzel (
  .clk(clk), 
  .rst(rst), 
  .start_i(start_block_i), 
  .data_i(dc_block_output), 
  .valid_i(dc_block_output_valid), 
  .done_o(goertzel_done), 
  .power_o(goertzel_output)
);

// power to dB converter
PowerConverter
power_converter (
  .clk(clk),
  .rst(rst), 
  .power_i(goertzel_output), 
  .valid_i(goertzel_done),
  .amplifier_gain_i(), 
  .rssi_dBFS_o(), 
  .adc_dB_o(),
  .valid_o()
);

endmodule
