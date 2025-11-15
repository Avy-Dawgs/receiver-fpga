module ThresholdTracker2 #(
  DW, 
  COUNT_BITS, 
  THRESHOLD
  ) (
  input clk, 
  input rst, 
  input clr_i,
  input [DW - 1:0] signal_i, 
  input valid_i,
  output reg [COUNT_BITS - 1:0] samples_since_threshold_o,
  output reg threshold_reached
  ); 

  always_ff @(posedge clk, posedge rst) begin 
    if (rst || clr_i) begin 
      samples_since_threshold_o <= 'h0;
      threshold_reached <= 1'h0;
    end 
    else if (valid_i) begin 
      if (signal_i > THRESHOLD) begin 
        samples_since_threshold_o <= 'h0;
        threshold_reached <= 1'h1;
      end
      else begin 
        samples_since_threshold_o <= samples_since_threshold + 1'h1;
      end
    end
  end

endmodule
