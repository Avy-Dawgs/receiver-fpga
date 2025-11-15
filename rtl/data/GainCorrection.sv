/*
* Corrects the input signal with the gain of the amplifier to 
* produce an absolute RSSI value in dBFS.
*/
module GainCorrection (
  input clk, 
  input rst, 
  input [7:0] signal_dB_i,
  input valid_i,
  input signed [5:0] gain_dB_i,  
  output reg signed [15:0] rssi_dBFS_o,
  output reg valid_o
  ); 

  localparam signed [15:0] MAX_DB = 72;

  logic signed [15:0] actual_gain;

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      valid_o <= 1'h0; 
      rssi_dBFS_o <= 'h0;
    end
    else begin 
      if (valid_i) begin 
        rssi_dBFS_o <= $signed({8'h0, signal_dB_i}) - MAX_DB - actual_gain;
        valid_o <= 1'h1;
      end 
      else begin 
        valid_o <= 1'h0;
      end
    end
  end

  // gain is in 4dB increments, so multiply by 4 to get actual gain
  assign actual_gain = {{8{gain_dB_i[5]}}, gain_dB_i, 2'h0};

endmodule
