/*
* Generate an enable signal at a given frequency.
*/
module EnableGenerator
#(
  CLK_FREQ, 
  EN_FREQ
) 
(
  input clk, 
  input rst, 
  output reg en_o
); 

  localparam MAX_COUNT = $rtoi(real'(CLK_FREQ) / real'(EN_FREQ)) - 1;

  reg [$clog2(MAX_COUNT) - 1:0] count;

  logic max_count_reached;

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      count <= 'd0;
      en_o <= 1'h0;
    end
    else begin 
      if (max_count_reached) begin 
        count <= 'd0;
        en_o <= 1'h1;
      end
      else begin 
        en_o <= 1'h0;
        count <= count + 1'd1;
      end
    end
  end

  assign max_count_reached = (count == MAX_COUNT);

endmodule
