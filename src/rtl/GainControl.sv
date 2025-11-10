/*
* Track signal level, and choose new gain.
*/
module GainControl #(
  DW,
  LOW_RANGE,
  HIGH_RANGE
  )
  (
    input clk, 
    input rst, 
    input [DW - 1:0] data_i, 
    input valid_i, 
    output signed [7:0] gain_dB_o
    output set_gain_o
  ); 


  // if signal is
  always_comb begin 
    // signal too high 
    if (dB_i > HIGH_RANGE) begin 
      
    end
    else if ()
  end


  //  * combinationally calculate a new value for gain 
  //  * on every gain eval period: 
  //    * if calculated gain doesn't equal current gain: 
  //      * perform a gain set

  ThresholdTracker2 #(
    
    ) thres_tracker (

    );

endmodule
