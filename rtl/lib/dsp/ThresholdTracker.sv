/*
* Tracks time since a threshold value has been reached.
*/
module ThresholdTracker #(
  DW, 
  MAX_TIME, 
  THRESHOLD
  ) (
  input clk, 
  input rst, 
  input clr_i,
  input tu_en,  // time unit enable
  input [DW - 1:0] signal_i, 
  input valid_i, 
  output reg [$clog2(MAX_TIME) - 1:0] tu_since_threshold_o
  ); 

  always_ff @(posedge clk, posedge rst) begin 
    if (rst || clr_i) begin 
      tu_since_threshold_o <= MAX_TIME;
    end 
    else begin 
      if (valid_i) begin 
        if (signal_i > THRESHOLD) begin 
          tu_since_threshold_o <= 'h0;
        end
      end
      else if (tu_en) begin 
        if (tu_since_threshold_o < MAX_TIME) begin 
            tu_since_threshold_o <= tu_since_threshold_o + 1'h1;
          end
        end
    end
  end

endmodule
