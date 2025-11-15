/*
* Simple counter with a max value.
*/
module Counter_max #(
  MAX_COUNT
) (
  input clk, 
  input rst,
  input en_i, 
  input clr_i,
  output reg [$clog2(MAX_COUNT) - 1:0] count_o,
  output logic max_count_reached_o
); 

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      count_o <= 'h0;
    end
    else if (en_i) begin
      if (clr_i || max_count_reached_o) begin 
        count_o <= 'h0;
      end
      else begin 
        count_o <= count_o + 1'h1;
      end
    end
  end

  assign max_count_reached_o = (count == MAX_COUNT);

endmodule
