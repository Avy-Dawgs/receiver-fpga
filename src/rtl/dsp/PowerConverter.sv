/*
* Converts power to RSSI in dBFS and 
* also to dB relative to 1.
*/
module PowerConverter
(
  input clk,
  input rst, 
  input [31:0] power_i, 
  input valid_i, 
  input [7:0] amplifier_gain_i,
  output reg signed [23:0] rssi_dBFS_o,  // Q16.8
  output reg [15:0] adc_dB_o,     // Q8.8
  output reg valid_o
  ); 

  localparam signed MAX_POWER_DB = 72;

  wire [15:0] dB;
  reg [15:0] dB_reg;
  wire dB_valid;
  reg dB_reg_valid;

  // steps: 
  //  - PowerToDB registers input
  //  - wait for dB conversion and register result
  //  - calculate dBFS and register output

  // calculation registers
  always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin 
      dB_reg <= 'h0;
    end
    else begin 
      dB_reg <= dB;
      adc_dB_o <= dB_reg;
      rssi_dBFS_o <= dB_reg - MAX_POWER_DB - amplifier_gain_i;
    end
  end

  // valid registers
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin 
      dB_reg_valid <= 1'h0;
      valid_o <= 1'h0;
    end
    else begin 
      dB_reg_valid <= dB_valid;
      valid_o <= dB_reg_valid;
    end
  end
  
  
  PowerToDB power_to_dB(
    .clk(clk), 
    .rst(rst), 
    .valid_i(valid_i), 
    .power_i(power_i), 
    .dB_o(dB), 
    .valid_o(dB_valid)
  );

endmodule
