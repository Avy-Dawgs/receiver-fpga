/*
* Signal processing part of design.
*/
module DataPath #(
  SAMP_RATE, 
  MIXER_FREQ
) (
  input clk, 
  input rst, 
  input en_i,
  input [11:0] adc_sample_i, 
  input adc_sample_valid_i, 
  output [15:0] dB_o,
  output valid_o
); 

  localparam ADC_DW = 12;
  localparam MIXER_LUT_ABITS = 10;
  localparam DC_BLOCK_FRAC_BITS = 4;
  localparam MIXER_DW = 12;

  localparam COMP2POW_DW = 16;

  logic rst_n;

  wire signed [ADC_DW + DC_BLOCK_FRAC_BITS - 1:0] dc_block_output; 
  wire dc_block_output_valid;

  logic signed [MIXER_DW - 1:0] dc_block_no_qbits;

  wire signed [MIXER_DW - 1:0] mixer_output; 
  wire mixer_output_valid; 
  wire mixer_output_last;

  wire signed [15:0] decimator_data; 
  logic signed [15:0] decimator_data_sh;
  wire decimator_last; 
  wire decimator_valid;
  wire decimator_ready_o;
  wire decimator_last_missing; 
  wire decimator_last_unexpected;

  wire [2*COMP2POW_DW - 1:0] power;
  logic [2*COMP2POW_DW - 1:0] power_scaled;
  wire power_valid;

  assign rst_n = ~rst;
  assign dc_block_no_qbits = dc_block_output >>> 4;
  assign power_scaled = power;
  assign decimator_data_sh = decimator_data >>> 2;

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
  .data_i(adc_sample_i), 
  .valid_i(adc_sample_valid_i), 
  .data_o(dc_block_output), 
  .valid_o(dc_block_output_valid)
);

// mixer 
Mixer #(
  .DW(MIXER_DW), 
  .SAMP_RATE(SAMP_RATE), 
  .FREQ(MIXER_FREQ), 
  .LUT_ABITS(MIXER_LUT_ABITS)
  ) mixer (
    .clk(clk), 
    .rst(rst), 
    .data_i(dc_block_no_qbits), 
    .valid_i(dc_block_output_valid), 
    .ready_i(decimator_ready_o),
    .data_o(mixer_output), 
    .valid_o(mixer_output_valid), 
    .last_o(mixer_output_last)
    );

// lowpass filter(s) 
cic_decimator decimator (
  .aclk(clk),                                      // input wire aclk
  .aresetn(rst_n),                                // input wire aresetn
  .s_axis_data_tdata(mixer_output),            // input wire [15 : 0] s_axis_data_tdata
  .s_axis_data_tvalid(mixer_output_valid),          // input wire s_axis_data_tvalid
  .s_axis_data_tready(decimator_ready_o),          // output wire s_axis_data_tready
  .s_axis_data_tlast(mixer_output_last),            // input wire s_axis_data_tlast
  .m_axis_data_tdata(decimator_data),            // output wire [15 : 0] m_axis_data_tdata
  .m_axis_data_tuser(),            // output wire [15 : 0] m_axis_data_tuser
  .m_axis_data_tvalid(decimator_valid),          // output wire m_axis_data_tvalid
  .m_axis_data_tlast(decimator_last),            // output wire m_axis_data_tlast
  .event_tlast_unexpected(decimator_last_unexpected),  // output wire event_tlast_unexpected
  .event_tlast_missing(decimator_last_missing)        // output wire event_tlast_missing
);


// assign decimator_data = mixer_output; 
// assign decimator_valid = mixer_output_valid; 
// assign decimator_last = mixer_output_last;

// complex to power
Complex2Power #(
  .DW(COMP2POW_DW)
  ) comp2pow (
    .clk(clk), 
    .rst(rst), 
    .data_i(decimator_data_sh), 
    .valid_i(decimator_valid), 
    .last_i(decimator_last),
    .power_o(power), 
    .valid_o(power_valid)
    );

PowerToDB pow2db (
  .clk(clk), 
  .rst(rst), 
  .power_i(power_scaled), 
  .valid_i(power_valid), 
  .dB_o(dB_o), 
  .valid_o(valid_o)
  );


endmodule
