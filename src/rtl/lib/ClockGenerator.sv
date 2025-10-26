/*
* Generate a clock via clock division.
*/
module ClockGenerator
#(
  CLK_FREQ, 
  TARGET_CLK_FREQ
)
(
  input clk, 
  input rst, 
  output reg gen_clk_o
);
  
  localparam MAX_COUNT = $rtoi((real'(CLK_FREQ) / real'(TARGET_CLK_FREQ)) / 2.0) - 1;

  reg [$clog2(MAX_COUNT) - 1:0] count;

  logic max_count_reached;

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      count <= 'd0;
      gen_clk_o <= 1'h0;
    end
    else begin 
      if (max_count_reached) begin 
        count <= 'd0;
        gen_clk_o <= ~gen_clk_o;
      end
      else begin 
        count <= count + 1'd1;
      end
    end
  end

  assign max_count_reached = (count == MAX_COUNT);

endmodule
